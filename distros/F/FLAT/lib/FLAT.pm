package FLAT;
use FLAT::Regex;
use FLAT::NFA;
use FLAT::DFA;
use Carp;

use vars '$VERSION';
$VERSION = 0.9.1;

=head1 NAME

FLAT - Formal Language & Automata Toolkit

=head1 SYNOPSIS

FLAT.pm is the base class of all regular language objects. For more
information, see other POD pages.

=head1 USAGE

All regular language objects in FLAT implement the following methods.
Specific regular language representations (regex, NFA, DFA) may implement
additional methods that are outlined in the repsective POD pages.

=cut

## let subclasses implement a minimal set of closure properties.
## they can override these with more efficient versions if they like.

sub as_dfa {
    $_[0]->as_nfa->as_dfa;
}

sub as_min_dfa {
    $_[0]->as_dfa->as_min_dfa;
}

sub is_infinite {
    ! $_[0]->is_finite;
}

sub star {
    $_[0]->kleene
}

sub difference {
    $_[0]->intersect( $_[1]->complement );
}

sub symdiff {
    my $self = shift;
    return $self if not @_;
    my $next = shift()->symdiff(@_);
    ( $self->difference($next) )->union( $next->difference($self) );
}

sub equals {
    $_[0]->symdiff($_[1])->is_empty
}

sub is_subset_of {
    $_[0]->difference($_[1])->is_empty
}

BEGIN {
    for my $method (qw[ as_nfa as_regex union intersect complement concat
                        kleene reverse is_empty is_finite ])
    {
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

Returns a regular language object that is the set difference of $lang1 and
$lang2. Equivalent to

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

Returns a boolean value indicating whether $lang1 is a subset of
$lang2.

=item $lang-E<gt>contains($string)

Returns a boolean value indicating whether $string is in the language
represented by $lang.

=back

=head1 AUTHORS & ACKNOWLEDGEMENTS

FLAT is written by Mike Rosulek E<lt>mike at mikero dot comE<gt> and Brett 
Estrade E<lt>estradb at gmail dot comE<gt>.

The initial version (FLAT::Legacy) by Brett Estrade was work towards an MS 
thesis at the University of Southern Mississippi.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 MORE INFO

Please visit the Wiki at http://www.0x743.com/flat
