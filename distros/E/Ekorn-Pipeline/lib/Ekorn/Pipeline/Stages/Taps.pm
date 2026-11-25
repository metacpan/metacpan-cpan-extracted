use v5.36;

package Ekorn::Pipeline::Stages::Taps;

use Data::Dumper qw();
use Exporter     qw(import);
use Ref::Util    qw(is_coderef is_plain_scalarref);
use Scalar::Util qw(openhandle);

use Ekorn::Pipeline         qw();
use Ekorn::Pipeline::Errors qw(croakf);
use Ekorn::Pipeline::Gather qw(gather);
use Ekorn::Pipeline::Stage  qw();

use namespace::clean -except => 'import';

our $VERSION = 'v0.4.0';

our @EXPORT = qw(peek count_into);    ## no critic (Modules::ProhibitAutomaticExportation)

our @EXPORT_OK   = (@EXPORT, qw(dump_to tee));
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# True, dump_to writes secrets as they are, without redacting them. A
# package variable, so that it can be localised, as Data::Dumper's are.
our $DumpSecrets;    ## no critic (Variables::ProhibitPackageVars)

# What dump_to redacts with, looked for at its first dump: undef until
# then; then Text::Redact::Secrets' redact, '' when the module isn't
# installed, or why it's there but can't be used.
my $redactor;

# Return a stage calling the block given with each value, for its side
# effects, and passing the value on.
sub peek : prototype(&) ($block) {
    croakf 'Expected a code reference' unless is_coderef($block);
    return Ekorn::Pipeline::Stage->new(sub ($value) {
        $block->($value);
        return $value;
    });
}

# Return a stage counting the values into the scalar given, from 0 on
# each run, and passing them on.
sub count_into ($count) {
    croakf 'Expected a reference to a scalar'
        unless is_plain_scalarref($count);
    return gather {
        $$count = 0;

        # Without a signature, as it's called for each value.
        return sub {
            $$count++;
            return $_[0];
        };
    };
}

# Return a stage running each value through a branch of the stages
# given, one run of its own beside the main run, fed by the stage, and
# passing the value on unchanged. What comes out of the branch is
# dropped; a stop in it ends only it; it's closed, so its flushes are
# called, in the stage's flush, or in its end if the main run stopped
# first, and finished in its end if the main run died. A branch with
# nothing to flush or end needs neither, so the stage has none, and
# the main run can take the plain loop.
sub tee (@stages) {
    my $branch = Ekorn::Pipeline->new(@stages);
    return gather {
        my $feed = $branch->feed;
        # The feed's own code for push and ended, called directly, as
        # they're called for each value: the branch can't reach its feed,
        # so the checks push makes of it, that it's open and not pushed
        # from inside, are made here, by $open, or can't fail.
        my($push, $ended) = @$feed{qw(push ended)};
        my $open = 1;
        # The step, without a signature, as it's called for each value:
        # into the branch while it's open, and on.
        my $step = sub {
            if ($open) {
                $push->($_[0]);
                $open = !defined $ended->();
            }
            return $_[0];
        };
        return $step if $feed->{plain};
        # The flush: the branch's input has run out.
        my $flush = sub () {
            $feed->close if $open;
            $open = 0;
            return;
        };
        # The end: a branch still open is closed, as a stop ends the
        # branch's input as much as running out would (roadmap
        # 2026-0050), unless the main run died, when it's finished, its
        # ends told it stopped. What its flushes give is dropped.
        my $end = sub ($how) {
            return unless $open;
            $open = 0;
            $how eq 'died' ? $feed->finish : $feed->close;
            return;
        };
        return ($step, $flush, $end);
    };
}

# Return a stage writing each value, with Data::Dumper, to the filehandle
# given, or STDERR, and passing it on, with its secrets redacted when
# Text::Redact::Secrets is installed, unless $DumpSecrets is true.
sub dump_to ($fh = \*STDERR) {
    croakf 'Expected an open filehandle' unless defined openhandle($fh);
    # Without a signature, as it's called for each value.
    return Ekorn::Pipeline::Stage->new(sub {
        my $dump = _dump($_[0]);
        unless ($DumpSecrets) {
            my $redact = _redactor();
            $dump = $redact->($dump) if $redact;
        }
        print { $fh } $dump;
        return $_[0];
    });
}


sub _dump ($value) {
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;
    return Data::Dumper::Dumper($value);
}

# Return Text::Redact::Secrets' redact, or nothing when it isn't
# installed; croak when it's there but can't be used. It's looked for
# once, and the answer kept.
sub _redactor () {
    $redactor //= _find_redactor();
    croakf 'Text::Redact::Secrets %s, so dump_to won\'t write a dump that'
        . ' may hold secrets; local $Ekorn::Pipeline::Stages::Taps::DumpSecrets'
        . ' = 1 dumps them without redacting', $redactor
        unless ref $redactor || $redactor eq '';
    return ref $redactor ? $redactor : ();
}

# Load Text::Redact::Secrets, check its version and that it redacts, and
# return its redact, '' when it isn't installed, or why it can't be used.
sub _find_redactor () {
    my $loaded = eval { require Text::Redact::Secrets; 1 };
    unless ($loaded) {
        my $error = $@;
        return ''
            if $error =~ m( \A Can't\ locate\ Text/Redact/Secrets\.pm\ in\ \@INC )x;
        return 'failed to load: ' . ($error =~ s( \s* \n .* )()xsr);
    }
    my $version = eval { version->parse(Text::Redact::Secrets->VERSION) };
    return 'has no version we can read' unless defined $version;
    return "is $version, not v1.x"      if $version < v1.0.0 || $version >= v2.0.0;
    my $redact = Text::Redact::Secrets->can('redact');
    return 'has no redact'        unless $redact;
    return 'failed its self-test' unless _redacts($redact);
    return $redact;
}

# Whether redact takes each of a few made-up secrets out of a dump. Each
# is built from pieces, so that no line holds one whole for a scanner.
sub _redacts ($redact) {
    my $password = join '', 'Zq8vR2mX', 'kP4wL9nT';
    my $key_id   = join '', 'AKIA',     'QYLPMN5H', 'HHFPZAM2';
    my $dump     = _dump({
        password => $password,
        dsn      => "postgres://app:$password\@db/app",
        key_id   => $key_id,
    });
    my $redacted = eval { $redact->($dump) };
    return 0 if !defined $redacted || ref $redacted;
    return 0 if index($redacted, $password) >= 0 || index($redacted, $key_id) >= 0;
    return 0 if index($redacted, '*REDACTED*') < 0;
    return 1;
}

# Forget what was found, so the next dump looks again. For the tests.
sub _forget_redactor () {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    undef $redactor;
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Stages::Taps - stages run for their side effects: peek, count_into, dump_to and tee

=head1 SYNOPSIS

    use Ekorn::Pipeline;
    use Ekorn::Pipeline::Stages::Taps;    # peek and count_into

    my $read = 0;
    my @names = Ekorn::Pipeline->new(
        count_into(\$read),                 # how many values were read
        peek { log_user($_) },              # each value, as it goes by
        sub { $_->{name} },
    )->(@users);

    use Ekorn::Pipeline::Stages::Taps qw(dump_to tee);

    Ekorn::Pipeline->new(dump_to)->(@users);    # to STDERR

    # A tap of any shape: a branch of stages, beside the main run
    my @names = Ekorn::Pipeline->new(
        tee(take_if { $_->{admin} }, take(1), sub { log_first_admin($_); () }),
        sub { $_->{name} },
    )->(@users);

=head1 DESCRIPTION

Stages that look at each value as it goes by and pass it on unchanged,
for logging, counting or debugging. A stage passes on what it returns,
so a stage of your own that runs for its side effects has to return
its value. These do that for you. Each function returns a stage, and
checks its arguments when it's called, not on each value.

C<peek>, C<count_into> and C<dump_to> each do one thing. C<tee> takes
stages, so a tap can be anything a pipeline can do: look only at some
values, or the first few, batch them, total them when the values run
out, or write them through a sink.

Each stage is an object, an L<Ekorn::Pipeline::Stage> or, for those
that keep state, an L<Ekorn::Pipeline::Gather>, called as a code
reference, so it goes wherever a stage goes. Code testing it with
C<ref> or C<is_coderef> sees an object: v0.2.0 gave code references.

They work wherever stages do: in any pipeline, or on an object with
C<pipe> and C<tap>, from L<Ekorn::Pipeline::Pipes>, where the first
value is the object:

    $client->tap(peek { say "connected to $_->{host}" })->run;

=head1 FUNCTIONS

C<peek> and C<count_into> are exported by default. C<dump_to> and
C<tee> are exported on request, and C<:all> gives all four.

=head2 peek

    peek { ... }

Calls the block with each value, in C<$_> and as its argument, and
passes the value on, whatever the block returns.

=head2 count_into

    count_into(\$count)

Counts the values into C<$count>. It sets C<$count> to 0 at the start
of each run, so after a run it holds how many values went by, even if
none did.

=head2 dump_to

    dump_to($fh)
    dump_to

Writes each value to C<$fh>, or to STDERR, with Data::Dumper, keys
sorted, and passes it on.

When L<Text::Redact::Secrets> is installed, a v1.x, each secret it
finds in what's written, such as a password, a token or the password
in a DSN, is written as C<*REDACTED*>. Only the dump is redacted: the
value passed on is as it came. Without the module, values are written
as they are. It's looked for once, at the first dump, and tested then,
by redacting a few made-up secrets. If it's there but fails to load,
isn't a v1.x, or fails the test, C<dump_to> croaks, on that dump and
each after, rather than write a dump that may hold secrets.

To write secrets as they are, set
C<$Ekorn::Pipeline::Stages::Taps::DumpSecrets> true, with C<local>,
for as long as you need it. It's read as each value is dumped, and
while it's true, the module is neither loaded nor tested:

    {
        local $Ekorn::Pipeline::Stages::Taps::DumpSecrets = 1;
        $pipeline->(@rows);
    }

It's for debugging. Text::Redact::Secrets finds the secrets its rules
know, not every secret, so a dump can still hold some. It doesn't
escape control characters in strings, so a value from outside can send
escape sequences to a terminal.

=head2 tee

    tee(@stages)

Runs each value through a branch of C<@stages>, for what they do on
the side, and passes the value on unchanged. What comes out of the
branch is dropped. C<@stages> are whatever L<Ekorn::Pipeline/new>
takes, a pipeline or a sink last included, and are made into a
pipeline when C<tee> is called, so a mistake croaks then, at your
line, with C<new>'s message, a stage counted among the tee's. With no
stages, it does nothing.

The branch is one run of its own, beside the main run, fed a value at
a time by an L<Ekorn::Pipeline::Feed> that the tee makes for each main
run. So the branch's stages see every value the tee does, in order,
and keep their state across them, and each main run gets a fresh
branch:

    # Note the first two big hits, and pass every track on
    tee(take_if { $_->{plays} > 6000 }, take(2), sub { note_hit($_); () })

=over

=item * B<A stop> in the branch, such as C<take(2)>'s, ends only the
branch. The tee passes the values after it on, without running them
through the branch.

=item * B<A death> in the branch kills the main run, as any stage's
error does, and its message names the tee's stage, then, within it,
the branch's:

    Pipeline stage #1 failed at app.pl line 12:
        Pipeline stage #2 failed at app.pl line 12:
            bad value

=item * B<The branch's flushes> are called in the tee's flush, which
closes the branch: so once the main run's values have run out, before
the stages after the tee are flushed. A total, a last batch or a
sink's result is given then. If a stop after the tee ends the main
run first, such as C<take>'s or an iterator's C<first>, the tee's
flush isn't called, so the tee closes the branch in its end: a stop
ends the branch's input as much as running out would, so a writer in
the branch keeps what it holds. That's new in v0.3.10; before, the
branch's flushes weren't called, and what they held was lost. A
branch's flush that dies there kills the run, as an end that dies
does.

=item * B<The branch's ends> are called as its run ends, told how it
ended from where each stands: in the push that met a stop or a death
in it; or as the tee closes it, in its flush or its end. If the main
run died, the tee's end doesn't close the branch, but finishes it, its
flushes not called, and its ends told C<stopped>, as the branch's
input was cut short, as they are for an iterator read as a source by a
run that dies.

=item * B<The value itself> goes into the branch, not a copy, as it
goes to C<peek>'s block. A branch that changes a hash changes it for
the main run too.

=item * B<The main run's context> is the branch's: in the branch,
L<Ekorn::Pipeline/run_context> gives what it gives in the main run,
such as a statement's columns.

=back

Each value costs a push into the branch: about 1.3 microseconds a
value through a branch of one plain stage, against C<peek>'s 0.4, on
Perl 5.36. A tee has a flush and an end only if its branch needs
them, so a branch of plain stages leaves the main run on the plain
loop. A branch with a flush, such as C<batch>'s, puts the main run on
the full path, and costs about 2.2 microseconds a value. It's for
logging, debugging and side jobs, not a hot loop.

=head1 DIAGNOSTICS

=over

=item Expected a code reference

C<peek> was given something other than a block or code reference.

=item Expected a reference to a scalar

C<count_into> was given something other than a reference to a scalar.

=item Expected an open filehandle

C<dump_to> was given something other than an open filehandle.

=item Text::Redact::Secrets %s, so dump_to won't write a dump that may hold secrets; local $Ekorn::Pipeline::Stages::Taps::DumpSecrets = 1 dumps them without redacting

C<dump_to> found L<Text::Redact::Secrets> installed, but can't redact
with it: it failed to load, with the first line of its error; it isn't
a v1.x, the versions C<dump_to> takes; it has no C<redact>; or it
failed the self-test, leaving a made-up secret in a dump. Install a
v1.x that works, or set C<$Ekorn::Pipeline::Stages::Taps::DumpSecrets>
true to write dumps without redacting them.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Gather>,
L<Ekorn::Pipeline::Feed>, L<Data::Dumper>, L<Text::Redact::Secrets>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
