use v5.36;

package Ekorn::Pipeline;

use experimental qw(builtin try);

use builtin   qw(refaddr);
use Carp      qw(croak);
use Exporter  qw(import);
use Ref::Util qw(is_arrayref is_coderef is_ref);

use Ekorn::Pipeline::Errors qw(croakf);

use namespace::clean -except => 'import';

use overload '&{}' => sub ($self, @) { $self->{call} }, fallback => 1;

our $VERSION = 'v0.2.0';

our @EXPORT_OK = qw(is_stage);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return true if what's given can go where a stage goes: a code reference,
# or a pipeline, whose stages go in its place.
sub is_stage ($thing) {
    return !!($thing isa 'Ekorn::Pipeline' || is_coderef($thing));
}


# Return a pipeline, called with values to run each of them through the
# stages. A pipeline given as a stage has its stages spliced in, each
# named by its place in each pipeline, such as "2.3".
sub new ($class, @given) {
    my(@stages, @names);
    for my $n (1 .. @given) {
        my $stage = $given[$n - 1];
        croakf 'Expected stage #%d to be a code reference or a pipeline', $n
            unless is_stage($stage);
        if ($stage isa 'Ekorn::Pipeline') {
            my($inner, $inner_names) = _composed($stage);
            croakf 'Expected stage #%d to be a code reference or a pipeline', $n
                unless $inner_names;
            push @stages, @$inner;
            push @names,  map { "$n.$_" } @$inner_names;
            next;
        }
        push @stages, $stage;
        push @names,  $n;
    }
    return bless {
        stages => \@stages,
        names  => \@names,
        call   => sub (@values) {
            return @values unless @stages;
            my $next
                = _iterator(\@stages, \@names, sub { @values ? shift @values : () });
            my @results;
            while (my($result) = $next->()) { push @results, $result }
            return @results;
        },
    }, $class;
}

# Return the stages of a pipeline given as a stage, from its stages
# method, as giving its stages would, and their names: its own, if the
# method returns the stages it was made with, as it does unless a
# subclass overrides it, or else their places in what it returns. The
# names are undefined if what it returns isn't all code references.
sub _composed ($pipeline) {
    my @stages = $pipeline->stages;
    my $made   = $pipeline->{stages};
    my $same   = @stages == @$made;
    for my $i (0 .. $#stages) {
        last unless $same;
        $same = (refaddr($stages[$i]) // 0) == refaddr($made->[$i]);
    }
    return \@stages, $pipeline->{names} if $same;
    return \@stages, undef              if grep { !is_coderef($_) } @stages;
    return \@stages, [1 .. @stages];
}


# Return a closure handing out, one per call, the values from $source run
# through the stages.
sub iterator ($self, $source) {
    croakf 'Expected a code reference' unless is_coderef($source);
    return _iterator($self->{stages}, $self->{names}, $source);
}


# Return the stages, in order, as a list, to splice into another
# pipeline or give to any function taking stages.
sub stages ($self) {
    return @{ $self->{stages} };
}

# What a pipeline is doing while its stages run.
my %running;

# For code telling its stages about the value they're given: true while
# the values going through the stages come from an end function, rather
# than from the source.
sub ending () {
    return $running{ending};
}

# Make the stages of a run from @$stages, named by @$names, into the
# lists in %$run: each gather stage's block is called, so it's made
# afresh, and a pipeline it returns as its stage has its stages made in
# its place, followed by the block's end function, if any, on a stage
# of its own that passes values on.
sub _make_run ($stages, $names, $run) {
    for my $i (0 .. $#$stages) {
        my($stage, $name) = ($stages->[$i], $names->[$i]);
        unless ($stage isa 'Ekorn::Pipeline::Gather') {
            push @{ $run->{stages} }, $stage;
            push @{ $run->{names} },  $name;
            push @{ $run->{ends} },   undef;
            next;
        }
        my @made = $stage->();
        my($inner, $inner_names)
            = @made && $made[0] isa 'Ekorn::Pipeline' ? _composed($made[0]) : ();
        croakf
            'Expected stage #%s, made with gather, to return a code reference or a pipeline, and optionally an end function',
            $name
            unless (@made == 1 || @made == 2)
            && ($inner ? $inner_names : is_coderef($made[0]))
            && (@made == 1 || is_coderef($made[1]));
        if ($inner) {
            _make_run($inner, [map { "$name.$_" } @$inner_names], $run);
            next unless $made[1];
            @made = (sub ($value) { $value }, $made[1]);
        }
        push @{ $run->{stages} }, $made[0];
        push @{ $run->{names} },  $name;
        push @{ $run->{ends} },   $made[1];
    }
    return;
}


# Return a closure handing out, one per call, the values from $source run
# through the stages in @$stages, named in messages by @$names.
sub _iterator ($stages, $names, $source) {
    my %run = (stages => [], names => [], ends => []);
    _make_run($stages, $names, \%run);
    my @stages = @{ $run{stages} };
    my @ends   = @{ $run{ends} };
    $names = $run{names};

    # Each value waiting to go through a stage, as the stage's index, the
    # value, and whether it came from an end, the next on top. A value a
    # stage returns on its own, as most are, carries on through the stages
    # without waiting here. Once the values run out, the ends are called in
    # order, from the first not called or passed over by a stop.
    my(@todo, $done);
    my $next_end = 0;
    return sub () {
        while (1) {
            my($n, $value, $from_end, $end);
            if (@todo) {
                ($n, $value, $from_end) = @{ pop @todo };
            }
            elsif (!$done) {
                my @values = $source->();
                unless (@values) {
                    $done = 1;
                    next;
                }
                ($n, $value) = (0, shift @values);
                push @todo, map { [0, $_] } reverse @values;
            }
            else {
                ($n) = grep { $ends[$_] } $next_end .. $#stages;
                last unless defined $n;
                ($next_end, $end, $from_end) = ($n + 1, $ends[$n], 1);
            }
            return $value if $n == @stages;
            # Set only when it changes, as most values come from the source.
            local $running{ending} = $from_end
                if $from_end || $running{ending};
            my $kept = 1;
            try {
                if ($end) {
                    local $_ = undef;
                    my @values = $end->();
                    $n++;
                    $kept  = @values;
                    $value = shift @values;
                    push @todo, map { [$n, $_, 1] } reverse @values;
                }
                while ($kept && $n < @stages) {
                    local $_ = $value;
                    my @values = $stages[$n]->($value);
                    $n++;
                    unless (@values) {
                        $kept = 0;
                        last;
                    }
                    $value = shift @values;
                    push @todo, map { [$n, $_, $from_end] } reverse @values;
                }
            }
            catch ($e) {
                if ($e isa 'Ekorn::Pipeline::Stop') {
                    # A stop made by throw is an array; one made otherwise
                    # carries nothing.
                    my(undef, @values) = is_arrayref($e) ? @$e : ();
                    $done     = 1;
                    $next_end = $n + 1 if $next_end < $n + 1;
                    @todo     = map { [$n + 1, $_, $from_end] } reverse @values;
                    next;
                }
                # A stage that dies ends the run: nothing waiting goes on,
                # no end is called, and the source isn't called again.
                ($done, $next_end, @todo) = (1, scalar @stages);
                croak $e if is_ref($e);
                my $at      = Carp::shortmess() =~ s( \.? \n \z )()xr;
                my $message = $e =~ s( \n \z )()xr =~ s( ^ )(    )xmgr;
                die "Pipeline stage #$names->[$n] failed$at:\n$message\n";
            }
            return $value if $kept;
        }
        return;
    };
}

1;
__END__

=encoding utf8

=for stopwords flatMap

=head1 NAME

Ekorn::Pipeline - run values through a list of stages

=head1 SYNOPSIS

    use Ekorn::Pipeline;

    my $p = Ekorn::Pipeline->new(
        sub { $_->{active} ? $_ : () },          # filter
        sub ($user) { @{ $user->{roles} } },     # flatMap
        sub { uc },                              # map
    );

    # Push: values in, a list out
    my @roles = $p->(@users);

    # Pull: one value per call, from a source
    my $next = $p->iterator(sub { shift @queue // () });
    while (my($role) = $next->()) { ... }

    # A function of your own, taking stages from its caller
    sub lines_of ($file, @stages) {
        open my $fh, '<', $file or die "Can't read $file: $!\n";
        return Ekorn::Pipeline->new(@stages)->iterator(sub { scalar(<$fh>) // () });
    }

=head1 DESCRIPTION

A pipeline is a list of stages. A stage is a code reference, or
another pipeline, which stands for its own stages (see
L</A pipeline as a stage>).

A code reference is called with one value, both as its argument and
in C<$_>. It can name the value with a signature,
C<sub ($row) { $row-E<gt>[1] }>, or use C<$_>, C<sub { $_-E<gt>[1] }>.
C<$_> is localised for each call, so the caller's is left alone. It
returns a list:

=over

=item * nothing, to drop the value (a filter);

=item * one value, to pass it on (a map);

=item * several, each of which goes through the rest of the stages
on its own (a flatMap).

=back

Each value goes through every stage before the next one starts. The
values come out in order, and each stage sees them in the order a
C<for> loop would.

A stage can end the pipeline early with L<Ekorn::Pipeline::Stop>. The
values already out are kept, and any values the stop carries go on
through the rest of the stages. Nothing else is processed:

    sub ($row) { $row->{id} == $wanted ? Stop($row) : () }

A stage made with L<Ekorn::Pipeline::Gather> is made afresh for each
run of the pipeline. It can also have an end function, called once the
values run out, whose values go through the rest of the stages. Each
call of a pipeline with values is a run, and so is each iterator.

=head2 Stages from your caller

A pipeline is for the author of any function that hands out values.
The function takes stages from its caller, as its last arguments, and
runs what it would return through them. The caller says what they want
done with each value, beside the call, and gets back only what they
want:

    sub bands (@stages) {
        return Ekorn::Pipeline->new(@stages)->(load_bands());
    }

    my @names = bands(sub { $_->{name} }, take(5));

With L</iterator>, the values are made one at a time, as the caller
asks for them. A function reading a file or a socket reads no more
than it has to. Once a stage has stopped the pipeline, the source isn't
called again.

The canned stages, in L<Ekorn::Pipeline::Stages::Flow>,
L<Ekorn::Pipeline::Stages::Batch> and L<Ekorn::Pipeline::Stages::Taps>,
work in any pipeline. L<Ekorn::Pipeline::Pipes> gives a class of your
own C<pipe> and C<tap> methods, which run an object through stages.

=head1 METHODS

=head2 new

    my $p = Ekorn::Pipeline->new(@stages);

Returns a pipeline that runs values through C<@stages>, in order. Each
stage must be a code reference or a pipeline (see
L</A pipeline as a stage>); anything else croaks. With no stages, a
pipeline returns its values unchanged.

A pipeline is an object that can be called as a code reference. Called
with values, it returns the list that comes out of the last stage:

    my @results = $p->(@values);

In scalar context, it returns how many results came out, as an array
would:

    my $count = $p->(@values);

=head3 A pipeline as a stage

You can give C<new> a pipeline wherever it takes a stage. Its stages
are spliced in where it stands, so these two run the same:

    my $clean = Ekorn::Pipeline->new(sub { s( \A \s+ | \s+ \z )()xgr }, sub { length ? $_ : () });

    Ekorn::Pipeline->new($clean, take(10));
    Ekorn::Pipeline->new($clean->stages, take(10));

The spliced stages belong to the new pipeline's run. A C<take> inside
C<$clean> limits the whole run, not each value.

The only difference is in error messages. Given C<$clean> itself, a
stage inside it is named by its position in each pipeline: the third
stage of a pipeline given second is C<#2.3>, and three levels down,
C<#1.2.3>. Given C<< $clean->stages >>, it's named by its position in
the combined list.

The stages spliced in are whatever the pipeline's L</stages> method
returns, so a subclass can override it. If the override returns a
different list, its stages are named by their position in that list.

To run a pipeline on each value separately instead, call it from a
stage: C<sub { $clean-E<gt>($_) }>. Each call is then a run of its
own, and a C<take> inside limits each call.

=head2 iterator

    my $next = $p->iterator($source);

Returns a closure that hands out the values that come out of the
stages, one per call. C<$source> is a code reference that returns the
next value or values each time it's called, and an empty list when
there are no more. It's called only once the values from its last
call have all been handed out.

The closure returns an empty list when the values run out, and on
every call after that. After a stop, it returns an empty list once the
values the stop carried are handed out, and the source isn't called
again. Read the closure in list context, so that an C<undef> value
isn't mistaken for the end:

    while (my($x) = $next->()) { ... }

The end functions of stages made with L<Ekorn::Pipeline::Gather> are
called once the source runs out, or after a stop, before the closure
returns an empty list.

If a stage or an end function dies, the call dies with it, and the
iterator has ended, as a pushed run does. Every call after returns an
empty list. Nothing waiting goes on through the stages, no end
function is called, and the source isn't called again. To skip a bad
value and carry on, catch the error inside the stage.

=head2 stages

    my @stages = $p->stages;

Returns the pipeline's stages, in order. A pipeline that was given as
a stage appears as the stages it was made of. In scalar context, it
returns how many there are.

The list can go anywhere stages go, including to a function that
accepts only code references:

    my $clean  = Ekorn::Pipeline->new(sub { s( \A \s+ | \s+ \z )()xgr }, sub { length ? $_ : () });
    my @titles = Ekorn::Pipeline->new($clean->stages, take(10))->(@raw);

To give C<new> the pipeline itself, see L</A pipeline as a stage>.
Either way, the stages run as if they had been written out in full:

=over

=item * A stop in one of them ends the whole run.

=item * A stage made with L<Ekorn::Pipeline::Gather> starts afresh on
each run, so pipelines that share it don't share its state.

=item * A plain closure is the same code reference wherever it goes,
so anything it keeps is shared. Keep state in C<gather> instead.

=item * A stage that dies is named by its position, as
L</A pipeline as a stage> describes.

=back

=head1 FUNCTIONS

=head2 is_stage

    use Ekorn::Pipeline v0.1.3 qw(is_stage);

    is_stage($thing)

True if C<$thing> can be used as a stage: a code reference (including
a stage made with L<Ekorn::Pipeline::Gather>), or a pipeline of this
class or a subclass. It's the same test L</new> uses.

Use it in a function that takes its stages from the end of its
arguments, so that it accepts the same stages C<new> does, pipelines
included:

    sub fetch ($url, @args) {
        my @stages;
        unshift @stages, pop @args while @args && is_stage($args[-1]);
        ...
    }

It's exported on request. It's new in v0.1.3, so ask for that version
on the C<use> line, as above: v0.1.2 has no C<import>, so without the
version, C<use Ekorn::Pipeline qw(is_stage)> compiles under it, and
fails only when C<is_stage> is called.

A pipeline is a blessed hash, so C<is_hashref> is true of one too. A
function that takes a hash reference of options before its stages
should test C<is_stage> first, or it takes a pipeline for the options.

Exporter provides the C<import> method,
and a subclass inherits it, so C<use My::Pipeline qw(name)> croaks
unless the subclass exports C<name> itself.

=head2 ending

    Ekorn::Pipeline::ending()

True while the values going through the stages come from an end
function, rather than from the source. It's for code that tells its
stages more about each value, such as where it came from: a value from
an end function has no such origin. It isn't exported.

=head1 DIAGNOSTICS

=over

=item Expected stage #%d to be a code reference or a pipeline

A stage given to L</new> wasn't a code reference or a pipeline. It's
also raised for a pipeline whose overridden C<stages> method returned
something that isn't a code reference.

=item Expected a code reference

The source given to L</iterator> wasn't a code reference.

=item Expected stage #%s, made with gather, to return a code reference or a pipeline, and optionally an end function

The block given to L<Ekorn::Pipeline::Gather/gather> for that stage
returned something else.

=item Pipeline stage #%s failed at %s line %d:

A stage, or its end function, died. The message it died with follows,
indented. An exception object is passed on unchanged.

In this message and the one above, a stage is named by its position:
C<#2> for the second stage, or C<#2.3> for the third stage of a
pipeline given as the second stage.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline::Gather>, L<Ekorn::Pipeline::Stop>,
L<Ekorn::Pipeline::Pipes>, and L<DBIx::Squirrel>, where the pipeline
began

L<Ekorn::Pipeline::Manual::HowTo> shows how to do common tasks, one
recipe at a time, and L<Ekorn::Pipeline::Manual::Reference> describes
every module, function and method in full.

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
