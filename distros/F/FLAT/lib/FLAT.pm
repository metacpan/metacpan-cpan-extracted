package FLAT;

use strict;
use warnings;
use FLAT::Regex;
use FLAT::DFA;
use Carp;

our $VERSION = q{1.0.4};

=head1 NAME

FLAT - Formal Language & Automata Toolkit

=head2 Name Change Possibility

Future releases of this module may very well reflect a name change that is
considered to me more I<normal> for Perl modules. When this was originally
written (2006) as a homework assignment, the original author was not very
well versed in the idiomatic aspects of C<PERL>. Shortly after, a friendly
fellow traveller rewrote it. Since then, this module has patiently sat on
CPAN waiting for a use. Recently, this use has come in the form of a module
for managing sequential consistency in Perl C<&> perl - L<Sub::Genius>.

=head1 SYNOPSIS

FLAT.pm is the base class of all regular language objects. For more
information, see other POD pages. It provides full support for the
I<shuffle> operator, which is useful for expressing the regular interleaving
of regular languages.

=head1 DESCRIPTION

This module provides an interface for manipulating the formal language
concept of Regular Expressions, which are used to describe Regular
Languages, and their equivalent forms of Automata.

It's notable that this module supports, in addition to the traditional
Regular Expression operators, the C<shuffle> operator (see [1]). This
is expressed as an ampersand, C<&>. In addition to this, logical symbols
may be multiple characters. This leads to some interesting applications.

While the module can do a lot, i.e.:

=over 4

=item * parse a regular expression (RE) (of the formal regular language
variety)

=item * convert a RE to a NFA (and similarly, a I<shuffle> of two regular
languages to a I<parallel> NFA (PFA))

=item * convert a PFA to a NFA (note, PFAs are equivalent to PetriNets
(see [2], L<Graph::PetriNet>)

=item * convert a NFA to a DFA

=item * convert a DFA to a minimal DFA

=item * generate strings that may be accepted by a DFA

=back

It is still missing some capabilities that one would expect:

=over 4

=item * generate equivalent REs from a NFA or DFA

=item * provide targeted conversion of PFAs, NFAs, DFAs to their more
explicit state forms; this is particularly interested to have in the case
of the PFA.

=item * provide targeted serialization of PREs (REs with a shuffle)
using direct, explicit manuplation of the AST produced by the parser

=item * provide other interesting graph-based manipulations that might
prove useful, particular when applied to a graph that represents some
form of a finite automata (FA)

=back

In addition to the above deficiencies, application of this toolkit in
interesting areas would naturally generate ideas for new and interesting
capabilities.

=head2 Sequential Consistency and PREs

Valid strings accepted by the shuffle of one or more regular languages is
necessarily I<sequentially consistent>. This results from the conversions
to a DFA that may be traversed inorder to discover valid string paths
necessarily obeys the total ordering constraints of each constituent
language of the two being shuffled; and the partial ordering that results
among valid string accepted by both (see [2] for more on how PetriNets
fit in).

=head1 USAGE

All regular language objects in FLAT implement the following methods.
Specific regular language representations (regex, NFA, DFA) may implement
additional methods that are outlined in the repsective POD pages.

=cut

## let subclasses implement a minimal set of closure properties.
## they can override these with more efficient versions if they like.

sub as_dfa {
    my @params = @_;
    return $params[0]->as_nfa->as_dfa;
}

sub as_min_dfa {
    my @params = @_;
    return $params[0]->as_dfa->as_min_dfa;
}

sub is_infinite {
    my @params = @_;
    return !$params[0]->is_finite;
}

sub star {
    my @params = @_;
    return $params[0]->kleene
}

sub difference {
    my @params = @_;
    return $params[0]->intersect($params[1]->complement);
}

sub symdiff {
    my $self = shift;
    return $self if not @_;
    my $next = shift()->symdiff(@_);
    return ($self->difference($next))->union($next->difference($self));
}

sub equals {
    my @params = @_;
    return $params[0]->symdiff($params[1])->is_empty();
}

sub is_subset_of {
    my @params = @_;
    return $params[0]->difference($params[1])->is_empty;
}

BEGIN {
    for my $method (
        qw[ as_nfa as_regex union intersect complement concat
        kleene reverse is_empty is_finite ]
        ) {
        no strict 'refs';
        *$method = sub {
            my $pkg = ref $_[0] || $_[0];
            carp "$pkg does not (yet) implement $method";
        };
    }
}

1;

__END__

=head2 Conversions Among Representations

=over

=item $lang-E<gt>as_nfa

=item $lang-E<gt>as_dfa

=item $lang-E<gt>as_min_dfa

=item $lang-E<gt>as_regex

Returns an equivalent regular language to $lang in the desired
representation. Does not modify $lang (even if $lang is already in the
desired representation).

For more information on the specific algorithms used in these conversions,
see the POD pages for a specific representation.

=back

=head2 Closure Properties

=over

=item $lang1-E<gt>union($lang2, $lang3, ... )

=item $lang1-E<gt>intersect($lang2, $lang3, ... )

=item $lang1-E<gt>concat($lang2, $lang3, ... )

=item $lang1-E<gt>symdiff($lang2, $lang3, ... )

Returns a regular language object that is the union, intersection,
concatenation, or symmetric difference of $lang1 ... $langN, respectively.
The return value will have the same representation (regex, NFA, or DFA)
as $lang1.

=item $lang1-E<gt>difference($lang2)

Returns a regular language object that is the set difference of $lang1
and $lang2. Equivalent to

  $lang1->intersect($lang2->complement)

The return value will have the same representation (regex, NFA, or DFA)
as $lang1.

=item $lang-E<gt>kleene

=item $lang-E<gt>star

Returns a regular language object for the Kleene star of $lang. The return
value will have the same representation (regex, NFA, or DFA) as $lang.

=item $lang-E<gt>complement

Returns a regular language object for the complement of $lang. The return
value will have the same representation (regex, NFA, or DFA) as $lang.

=item $lang-E<gt>reverse

Returns a regular language object for the stringwise reversal of $lang.
The return value will have the same representation (regex, NFA, or DFA)
as $lang.

=back

=head2 Decision Properties

=over

=item $lang-E<gt>is_finite

=item $lang-E<gt>is_infinite

Returns a boolean value indicating whether $lang represents a
finite/infinite language.

=item $lang-E<gt>is_empty

Returns a boolean value indicating whether $lang represents the empty
language.

=item $lang1-E<gt>equals($lang2)

Returns a boolean value indicating whether $lang1 and $lang2 are
representations of the same language.

=item $lang1-E<gt>is_subset_of($lang2)

Returns a boolean value indicating whether $lang1 is a subset of $lang2.

=item $lang-E<gt>contains($string)

Returns a boolean value indicating whether $string is in the language
represented by $lang.

=back

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and B.
Estarde E<lt>estradb at gmail dot comE<gt>.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 REFERENCES

=over 4

=item 1. Introduction to Automata Theory, Languages, and Computation;
John E. Hopcroft, Rajeev Motwani, Jeffrey D. Ullman

=item 2.Parallel Finite Automata for Modeling Concurrent Software
Systems (1994); P. David Stotts , William Pugh

=back
