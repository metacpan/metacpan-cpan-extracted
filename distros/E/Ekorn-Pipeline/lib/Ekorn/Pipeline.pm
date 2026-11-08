use v5.36;

package Ekorn::Pipeline;

use experimental qw(try);

use Carp      qw(croak);
use Ref::Util qw(is_arrayref is_coderef is_ref);

use Ekorn::Pipeline::Errors qw(croakf);

use namespace::clean;

use overload '&{}' => sub ($self, @) { $self->{call} }, fallback => 1;

our $VERSION = 'v0.1.1';

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a pipeline, called with values to run each of them through the
# stages.
sub new ($class, @stages) {
    for my $n (1 .. @stages) {
        croakf 'Expected stage #%d to be a code reference', $n
            unless is_coderef($stages[$n - 1]);
    }
    return bless {
        stages => \@stages,
        call   => sub (@values) {
            return @values unless @stages;
            my $next = _iterator(\@stages, sub { @values ? shift @values : () });
            my @results;
            while (my($result) = $next->()) { push @results, $result }
            return @results;
        },
    }, $class;
}

# Return a closure handing out, one per call, the values from $source run
# through the stages.
sub iterator ($self, $source) {
    croakf 'Expected a code reference' unless is_coderef($source);
    return _iterator($self->{stages}, $source);
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

# Return a closure handing out, one per call, the values from $source run
# through the stages in @$stages.
sub _iterator ($stages, $source) {
    my(@stages, @ends);
    for my $n (0 .. $#$stages) {
        my $stage = $stages->[$n];
        unless ($stage isa 'Ekorn::Pipeline::Gather') {
            $stages[$n] = $stage;
            next;
        }
        my @made = $stage->();
        croakf
            'Expected stage #%d, made with gather, to return one or two code references',
            $n + 1
            unless (@made == 1 || @made == 2) && @made == grep { is_coderef($_) } @made;
        ($stages[$n], $ends[$n]) = @made;
    }

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
                die "Pipeline stage #@{[ $n + 1 ]} failed$at:\n$message\n";
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

A pipeline is a list of stages, each a code reference. A stage is
called with one value, as its argument and in C<$_>, so it can name the
value with a signature, C<sub ($row) { $row-E<gt>[1] }>, or leave the
signature out and use C<$_>, C<sub { $_-E<gt>[1] }>. C<$_> is localised for
each call, so the caller's is left as it was. A stage returns a list:

=over

=item * nothing, to drop the value (a filter);

=item * one value, to pass it on (a map);

=item * several, each of which goes through the rest of the stages
on its own (a flatMap).

=back

Each value goes through every stage before the next one starts, so the
values come out in order, and a stage sees them in the order a C<for>
loop would.

A stage can end the pipeline early with L<Ekorn::Pipeline::Stop>. The
values already out are kept, any values the stop carries go on through
the rest of the stages, and nothing else is processed:

    sub ($row) { $row->{id} == $wanted ? Stop($row) : () }

A stage made with L<Ekorn::Pipeline::Gather> is made afresh for each
run of the pipeline, and can have a function called once the values run
out, whose values go through the rest of the stages. Each push of
values, and each iterator, is a run.

=head2 Stages from your caller

A pipeline is for the author of any function that hands out values.
The function takes stages from its caller, as its last arguments, and
runs what it would return through them, so the caller says what they
want done with each value, beside the call, and gets back only what
they want:

    sub bands (@stages) {
        return Ekorn::Pipeline->new(@stages)->(load_bands());
    }

    my @names = bands(sub { $_->{name} }, take(5));

With L</iterator>, the values are made one at a time, as the caller
asks for them, so a function reading a file or a socket reads no more
than it has to. Once a stage has stopped the pipeline, the source isn't
called again.

The canned stages, in L<Ekorn::Pipeline::Stages::Flow>,
L<Ekorn::Pipeline::Stages::Batch> and L<Ekorn::Pipeline::Stages::Taps>,
work in any pipeline, and L<Ekorn::Pipeline::Pipes> gives a class of
your own C<pipe> and C<tap> methods, which run the object through
stages.

=head1 METHODS

=head2 new

    my $p = Ekorn::Pipeline->new(@stages);

Returns a pipeline running values through C<@stages>, in order. It
croaks if a stage isn't a code reference. With no stages, a pipeline
returns its values as they are.

A pipeline is an object that can be called as a code reference. Called
with values, it returns the list that comes out of the last stage:

    my @results = $p->(@values);

In scalar context, it returns how many results came out, as an array
would:

    my $count = $p->(@values);

=head2 iterator

    my $next = $p->iterator($source);

Returns a closure handing out, one per call, the values that come out
of the stages. C<$source> is a code reference returning the next value
or values on each call, and an empty list when there are no more; it's
called only when the values from its last call have all been handed
out.

The closure returns an empty list when the values run out, or once a
stage has stopped the pipeline and the values its stop carried are
handed out, and on every call after that. After a stop, the source
isn't called again. Read it in list context, so an C<undef> value
isn't mistaken as the end:

    while (my($x) = $next->()) { ... }

The end functions of stages made with L<Ekorn::Pipeline::Gather> are
called once the source runs out, or after a stop, before the closure
returns an empty list.

If a stage or an end function dies, the call dies with it, and the
iterator has ended: every call after returns an empty list, nothing
waiting goes on through the stages, no end function is called, and the
source isn't called again, as when a pushed run dies. To skip a bad
value and carry on, catch the error inside the stage.

=head2 stages

    my @stages = $p->stages;

Returns the pipeline's stages, in order, as given to L</new>. In
scalar context, it returns how many there are.

A pipeline isn't a stage, but its stages can be spliced into another
pipeline, or given to any function that takes stages, so a pipeline
made once can be used wherever stages go:

    my $clean  = Ekorn::Pipeline->new(sub { s( \A \s+ | \s+ \z )()xgr }, sub { length ? $_ : () });
    my @titles = Ekorn::Pipeline->new($clean->stages, take(10))->(@raw);

The stages run in the other pipeline's run, as if listed there: a stop
in one ends that run, and a stage made with L<Ekorn::Pipeline::Gather>
is made afresh for each run, so its state isn't shared between the
pipelines it's spliced into. A plain closure is the same code
reference wherever it goes, so whatever it keeps is shared; keep state
in C<gather>. A stage that dies is named by its place in the pipeline
it was spliced into.

=head1 FUNCTIONS

=head2 ending

    Ekorn::Pipeline::ending()

True while the values going through the stages come from an end
function, rather than from the source. It's for code that tells its
stages about the value they're given, such as the value it came from,
which a value an end function gives doesn't have. It isn't exported.

=head1 DIAGNOSTICS

=over

=item Expected stage #%d to be a code reference

A stage given to L</new> wasn't a code reference.

=item Expected a code reference

The source given to L</iterator> wasn't a code reference.

=item Expected stage #%d, made with gather, to return one or two code references

The block given to L<Ekorn::Pipeline::Gather/gather> for that stage
returned something other than a stage, or a stage and an end function.

=item Pipeline stage #%d failed at %s line %d:

A stage, or its end function, died. The message it died with follows,
indented. An exception object is passed on as it is.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline::Gather>, L<Ekorn::Pipeline::Stop>,
L<Ekorn::Pipeline::Pipes>, and L<DBIx::Squirrel>, where the pipeline
began

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
