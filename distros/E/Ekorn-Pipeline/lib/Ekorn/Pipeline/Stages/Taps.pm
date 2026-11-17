use v5.36;

package Ekorn::Pipeline::Stages::Taps;

use Data::Dumper qw();
use Exporter     qw(import);
use Ref::Util    qw(is_coderef is_plain_scalarref);
use Scalar::Util qw(openhandle);

use Ekorn::Pipeline::Errors qw(croakf);
use Ekorn::Pipeline::Gather qw(gather);
use Ekorn::Pipeline::Stage  qw();

use namespace::clean -except => 'import';

our @EXPORT = qw(peek count_into);    ## no critic (Modules::ProhibitAutomaticExportation)

our @EXPORT_OK   = (@EXPORT, qw(dump_to));
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

Ekorn::Pipeline::Stages::Taps - stages run for their side effects: peek, count_into and dump_to

=head1 SYNOPSIS

    use Ekorn::Pipeline;
    use Ekorn::Pipeline::Stages::Taps;    # peek and count_into

    my $read = 0;
    my @names = Ekorn::Pipeline->new(
        count_into(\$read),                 # how many values were read
        peek { log_user($_) },              # each value, as it goes by
        sub { $_->{name} },
    )->(@users);

    use Ekorn::Pipeline::Stages::Taps qw(dump_to);

    Ekorn::Pipeline->new(dump_to)->(@users);    # to STDERR

=head1 DESCRIPTION

Stages that look at each value as it goes by and pass it on unchanged,
for logging, counting or debugging. A stage passes on what it returns,
so a stage of your own that runs for its side effects has to return
its value. These do that for you. Each function returns a stage, and
checks its arguments when it's called, not on each value.

Each stage is an object, an L<Ekorn::Pipeline::Stage> or, for those
that keep state, an L<Ekorn::Pipeline::Gather>, called as a code
reference, so it goes wherever a stage goes. Code testing it with
C<ref> or C<is_coderef> sees an object: v0.2.0 gave code references.

They work wherever stages do: in any pipeline, or on an object with
C<pipe> and C<tap>, from L<Ekorn::Pipeline::Pipes>, where the first
value is the object:

    $client->tap(peek { say "connected to $_->{host}" })->run;

=head1 FUNCTIONS

C<peek> and C<count_into> are exported by default. C<dump_to> is
exported on request, and C<:all> gives all three.

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

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Gather>, L<Data::Dumper>,
L<Text::Redact::Secrets>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
