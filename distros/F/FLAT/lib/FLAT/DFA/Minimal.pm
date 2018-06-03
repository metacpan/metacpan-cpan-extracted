package FLAT::DFA::Minimal;

use strict;
use warnings;
use parent qw(FLAT::DFA);
use Storable qw(dclone);

sub new {
    my $pkg  = shift;
    my $self = $pkg->SUPER::new(@_);
    $self->{EQUIVALENCE_CLASSES} = [];
    return $self;
}

sub get_equivalence_classes {
    my $self = shift;
    return $self->{EQUIVALENCE_CLASSES};
}

sub set_equivalence_classes {
    my $self      = shift;
    my $e_classes = shift;
    die qq{Must be an array reference\n} if ref $e_classes ne q{ARRAY};
    $self->{EQUIVALENCE_CLASSES} = $e_classes;
    return $self->{EQUIVALENCE_CLASSES};
}

1;

__END__

=head1 NAME

FLAT::DFA::Minimal - Deterministic finite automata

=head1 SYNOPSIS

A FLAT::DFA::Minimal object is a finite automata whose transitions are labeled
with single characters. Furthermore, each state has exactly one outgoing
transition for each available label/character. Additionally, it is meant to
be created by first creating a FLAT::DFA, then running the C<as_min_dfa>
method.

=head1 USAGE

In addition to implementing the interface specified in L<FLAT> and L<FLAT::NFA>, 
FLAT::DFA objects provide DFA-specific methods. In addition, it provides the following
methods meant for use with a minimal DFA.

=over

=item $dfa-E<gt>get_equivalence_classes

This method provides the set of states from the original DFA that are
considered equivalent; this is returned as an ordered array ref of array refs.

=item $dfa-E<gt>set_equivalence_classes

Setter for the equivalence classes member. Meant to be used internally when
constructing and finally returning the FLAT::DFA:Minimal obect.

=back

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and 
Brett Estrade E<lt>estradb at gmail dot comE<gt>.

The initial version (FLAT::Legacy) by Brett Estrade was work towards an 
MS thesis at the University of Southern Mississippi.

Please visit the Wiki at http://www.0x743.com/flat

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
