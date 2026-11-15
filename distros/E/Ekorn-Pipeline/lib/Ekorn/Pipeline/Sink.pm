use v5.36;

package Ekorn::Pipeline::Sink;

use parent 'Ekorn::Pipeline::Element';

use Ref::Util               qw(is_coderef);
use Ekorn::Pipeline         qw();
use Ekorn::Pipeline::Errors qw(croakf);
use namespace::clean;

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# Return a sink made afresh for each run by the set-up given, which
# returns its step, its flush, giving its result, and, optionally, its
# end. new_sink_many makes one whose result is a list, offered by
# EKORN_SINK_MANY; new_sink_one makes one whose result is one value,
# offered by EKORN_SINK_ONE. Called with values, a sink pushes them
# through a fresh sink of its set-up, as a pipeline of the one sink
# would, and gives its result: the closure holds the set-up, not the
# sink, so it works however long it's kept.
sub new_sink_many ($class, $setup) {
    return _made(
        $class->can('EKORN_SINK_MANY') ? $class : 'Ekorn::Pipeline::Sink::Many',
        $setup,
    );
}


# Return a sink, as new_sink_many does, whose result is one value.
sub new_sink_one ($class, $setup) {
    return _made(
        $class->can('EKORN_SINK_ONE') ? $class : 'Ekorn::Pipeline::Sink::One',
        $setup,
    );
}


sub _made ($into, $setup) {
    croakf 'Expected a code reference' unless is_coderef($setup);
    return bless {
        setup => $setup,
        call  => sub (@values) {
            return Ekorn::Pipeline->new(_made($into, $setup))->(@values);
        },
    }, $into;
}

# A sink whose result is one value.
package Ekorn::Pipeline::Sink::One {    ## no critic (Modules::ProhibitMultiplePackages)
    use parent -norequire, 'Ekorn::Pipeline::Sink';


    sub EKORN_SINK_ONE ($self) {
        return $self->{setup}->();
    }
}

# A sink whose result is a list.
package Ekorn::Pipeline::Sink::Many {    ## no critic (Modules::ProhibitMultiplePackages)
    use parent -norequire, 'Ekorn::Pipeline::Sink';


    sub EKORN_SINK_MANY ($self) {
        return $self->{setup}->();
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Ekorn::Pipeline::Sink - a sink made afresh for each run

=head1 SYNOPSIS

    use Ekorn::Pipeline::Sink;

    # One value: the total
    my $total = Ekorn::Pipeline::Sink->new_sink_one(sub {
        my $sum = 0;    # this run's
        return (sub ($x) { $sum += $x }, sub () { $sum });
    });

    my $sum = Ekorn::Pipeline->new(
        sub { $_ * 2 },
        $total,
    )->(1 .. 4);    # 20
    $total->(1 .. 4);    # 10

    # A list: each value, written as it comes, given back
    sub logged_to ($path) {
        return Ekorn::Pipeline::Sink->new_sink_many(sub {
            open my $fh, '>', $path or die "Can't write $path: $!\n";
            my @seen;
            return (
                sub ($x)   { print {$fh} "$x\n"; push @seen, $x },
                sub ()     { @seen },
                sub ($how) { close $fh },
            );
        });
    }

=head1 DESCRIPTION

A sink consumes every value it's given and, when they run out, gives
its result: one value, such as a count or a total, for a I<sink of
one>, or a list, such as every value, for a I<sink of many>. It's
usually a pipeline's last stage, so that its result is what a run
gives. Anywhere else, its result goes on through the stages after it.

A sink is made afresh for each run, by its I<set-up>, a code reference
called at the start of the run. The set-up declares, with C<my>,
whatever the run needs, and returns closures sharing it:

=over

=item * the I<step>, called with each value, in C<$_> and as its
argument. What it returns is ignored;

=item * the I<flush>, called with nothing, and C<$_> undefined, once
its input runs out, returning the result. It's required. A sink of
one's flush gives one value: the first it returns, or C<undef> if it
returns none;

=item * optionally, the I<end>, called once, when the run has ended,
however it ended, told how: C<done>, C<stopped> or C<died>. What it
returns is dropped.

=back

It returns them as a list, in that order, or by name, as a hash
reference, as in C<< {step => $step, flush => $flush} >>:
L<Ekorn::Pipeline/Made for a run> has how.

Its input runs out when the values run out, or after a stop in a stage
before it. So a sink after C<take(5)> gives its result, and is told
C<done>. A sink's step can stop the run itself, with
L<Ekorn::Pipeline::Stop>, once it has all it wants, as C<keep_first>
does: it still gives its result, and is told C<done>.
L<Ekorn::Pipeline/How a run ends> has the rest.

A pipeline ending in a sink gives the sink's result. In list context,
that's the list, or, from a sink of one, its one value. In scalar
context, a sink of one gives its value, and a sink of many its list as
an array reference:

    my @all = Ekorn::Pipeline->new(keep_all)->(1, 2);    # (1, 2)
    my $all = Ekorn::Pipeline->new(keep_all)->(1, 2);    # [1, 2]

A sink can be called as a code reference with values, as a pipeline of
the one sink would be, and gives its result. It makes a fresh sink of
its set-up for each call, so it can be kept and called again.

The words C<sink_one {...}> and C<sink_many {...}>, in
L<Ekorn::Pipeline::Factories>, make these from a block, and
L<Ekorn::Pipeline::Sinks> has ready-made ones.

A class of your own needn't be one of these to be a sink. Any object
with an C<EKORN_SINK_ONE> or an C<EKORN_SINK_MANY> method, returning
the step, the flush, and optionally the end, as a list or by name, is
one. Offering both, or either with C<EKORN_STAGE>, croaks where it's
given as a stage, as it couldn't say which it is.

=head1 METHODS

=head2 new_sink_one

    my $sink = Ekorn::Pipeline::Sink->new_sink_one($setup);

Returns a sink of one, made afresh for each run by C<$setup>, a code
reference, as L</DESCRIPTION> describes. Anything else croaks. It's an
Ekorn::Pipeline::Sink::One, unless the class it's called on has an
C<EKORN_SINK_ONE> method of its own, when it's of that class.

=head2 new_sink_many

    my $sink = Ekorn::Pipeline::Sink->new_sink_many($setup);

Returns a sink of many, as L</new_sink_one> does: an
Ekorn::Pipeline::Sink::Many, or of the class it's called on, if that
has an C<EKORN_SINK_MANY> method of its own.

=head2 EKORN_SINK_ONE

    my @parts = $sink->EKORN_SINK_ONE;

A sink of one's: calls the set-up, for a new run, and returns what it
returns: the parts, as a list or by name. A run calls it as it starts;
you needn't.

=head2 EKORN_SINK_MANY

    my @parts = $sink->EKORN_SINK_MANY;

A sink of many's, as L</EKORN_SINK_ONE> is a sink of one's.

=head1 DIAGNOSTICS

=over

=item Expected a code reference

L</new_sink_one> or L</new_sink_many> was given something other than a
code reference.

=item Expected sink #%s to return a code reference, a flush, and optionally an end

The set-up of the sink at that place in the pipeline returned
something else. It's reported as the run starts. The sink is named by
its position, as L<Ekorn::Pipeline/DIAGNOSTICS> describes.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Source>, and the ready-made
sinks in L<Ekorn::Pipeline::Sinks>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
