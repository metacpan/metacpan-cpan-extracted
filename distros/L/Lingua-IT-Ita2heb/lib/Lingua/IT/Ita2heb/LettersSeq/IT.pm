package Lingua::IT::Ita2heb::LettersSeq::IT;

use 5.010;
use strict;
use warnings;

use Readonly;

use Moose;

extends(
    'Lingua::IT::Ita2heb::LettersSeq'
);

has geminated => (
    isa => 'Bool',
    is => 'ro',
    traits => ['Bool'],
    default => 0,
    handles =>
    {
        '_set_geminated' => 'set',
        'unset_geminated' => 'unset',
    },
);

has should_add_geresh => (
    isa => 'Bool',
    is => 'ro',
    default => 0,
    traits => ['Bool'],
    handles =>
    {
        _set_add_geresh => 'set',
        unset_add_geresh => 'unset',
    },
);

with( 'Lingua::IT::Ita2heb::Role::Constants' );

our $VERSION = '0.01';

Readonly my $NO_CLOSED_PAST_THIS => 3;

sub closed_syllable {
    my ($self) = @_;

    if ($self->_count - 1 - $self->idx() < $NO_CLOSED_PAST_THIS) {
        return 0;
    }

    for my $offset (1, 2) {
        if ($self->_letter($self->idx+$offset) ~~ @{$self->all_latin_vowels}) {
            return 0;
        }
    }

    return 1;

}

sub _is_current_a_vowel {
    my ($seq) = @_;

    return $seq->current ~~ @{$seq->all_latin_vowels};
}

sub should_add_alef
{
    my ($self) = @_;

    return 
    (
        $self->_is_current_a_vowel
        and ($self->at_start or $self->wrote_vowel)
        and not (  $self->current ~~ @{$self->types_of_i}
            and $self->match_vowel_after
            and ($self->match_before([$self->all_latin_vowels])
                or $self->at_start))
    );
}

sub _test_for_geminated
{
    my ($seq) = @_;

    return
    (
        $seq->after_start
        and $seq->before_end
        # TODO : extract this clause.
        and not $seq->_is_current_a_vowel
        and $seq->curr_lett_eq_next
    );
}

sub try_geminated {
    my ($seq) = @_;

    my $verdict = $seq->_test_for_geminated;

    if ($verdict)
    {
        $seq->_set_geminated;
    }

    return $verdict;
}

sub match_cg_mod_after {
    my ($seq, $prefix) = @_;

    return $seq->match_after([@$prefix, $seq->cg_modifier]);
}

sub _match_optional_cg {
    my ($seq, $prefix) = @_;

    return ($seq->match_cg_mod_after([]) or $seq->match_cg_mod_after($prefix));
}

sub set_optional_cg_geresh {
    my $seq = shift;
    
    my $verdict = $seq->_match_optional_cg(@_);

    if ($verdict) {
        $seq->_set_add_geresh;
    }

    return $verdict;
}

sub should_add_sheva {
    my ($seq) = @_;

    return
    (
        (!$seq->curr_lett_eq_next)
            and
        (List::MoreUtils::none 
            { $seq->safe_match_places(@{$_}) }
            @{$seq->sheva_specs()},
        )
    );
}

sub match_vowel_before {
    my ($seq) = @_;

    return $seq->match_before([$seq->all_latin_vowels]);
}


sub match_vowel_after {
    my ($seq) = @_;

    return $seq->match_after([$seq->all_latin_vowels]);
}

sub does_v_require_bet {
    my ($seq) = @_;

    return (
        $seq->after_start
            and 
        ($seq->match_before([$seq->requires_bet_for_v])
        or $seq->match_after([$seq->requires_bet_for_v])
        or $seq->at_end)
    );
}

1;    # End of Lingua::IT::Ita2heb::LettersSeq::IT

__END__

=head1 NAME

Lingua::IT::Ita2heb::LettersSeq::IT - Italian-specific subclass of Lingua::IT::Ita2heb::LettersSeq

=head1 DESCRIPTION

A sequence of letters in Italian.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Lingua::IT::Ita2heb::LettersSeq::IT;

    my $seq = Lingua::IT::Ita2heb::LettersSeq::IT->new(
        {
            ita_letters => \@ita_letters,  
        }
    );

=head1 METHODS

=head2 $seq->closed_syllable()

Checks that the current letter is a closed syllable.

=head2 $seq->should_add_alef()

A predicate that determines if Alef should be added.

=head2 $seq->try_geminated()

Tests if geminated should be set, and returns it. If it should be set, sets
it to true.

=head2 $seq->match_cg_mod_after([@prefix])

Returns if it matches a CG modifier after the current position.

=head2 $seq->set_optional_cg_geresh([@prefix])

Returns if it matches a CG modifier with or without the prefix. If it matches,
sets add_geresh() .

=head2 $seq->should_add_sheva()

A predicate that returns whether a sheva should be added or not.

=head2 $seq->match_vowel_before()

A predicate that returns whether there's any Latin vowel in the character
before the current position.

=head2 $seq->match_vowel_after()

A predicate that returns whether there's any Latin vowel in the character
after the current position.

=head2 $seq->does_v_require_bet()

A predicate that returns whether the 'v' requires a Hebrew Bet.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::IT::Ita2heb::LettersSeq::IT

You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-IT-Ita2heb>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-IT-Ita2heb>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-IT-Ita2heb>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-IT-Ita2heb/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Amir E. Aharoni.

This program is free software; you can redistribute it and
modify it under the terms of either:

=over

=item * the GNU General Public License version 3 as published
by the Free Software Foundation.

=item * or the Artistic License version 2.0.

=back

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Amir E. Aharoni, C<< <amir.aharoni at mail.huji.ac.il> >>
and Shlomi Fish ( L<http://www.shlomifish.org/> ).


=cut
