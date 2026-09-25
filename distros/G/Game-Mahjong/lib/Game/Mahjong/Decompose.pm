package Game::Mahjong::Decompose;

use 5.010;
use strict;
use warnings;

use Game::Mahjong::Tiles;

our $VERSION = '0.01';

our %FORM = (
	1 => 'standard',
	2 => 'seven_pairs',
	3 => 'thirteen_orphans',
	4 => 'honours_knitted',
	5 => 'knitted_straight',
);

sub decompose {
	my ($hand, $winning) = @_;
	my $splits = _decompose($hand->counts, $hand->meld_count, $winning // 0);
	die 'Game::Mahjong::Decompose: more splits than the table holds' unless defined $splits;

	my @melded = map {
		{
			kind      => $_->kind,
			tiles     => [ @{ $_->tiles } ],
			concealed => $_->concealed ? 1 : 0,
			melded    => 1,
		}
	} @{ $hand->melds };

	for my $split (@$splits) {
		$_->{concealed} = 1, $_->{melded} = 0 for @{ $split->{sets} };
		push @{ $split->{sets} }, @melded;
	}
	return @$splits;
}

sub is_complete {
	my ($hand) = @_;
	return _is_complete($hand->counts, $hand->meld_count);
}

sub waits {
	my ($hand) = @_;
	die 'Game::Mahjong::Decompose: waits are asked of a hand between turns, not of one holding a fourteenth'
		unless $hand->total == 13;
	return @{ _waits($hand->counts, $hand->meld_count) };
}

1;

__END__

=head1 NAME

Game::Mahjong::Decompose - every way a hand is complete, and what it waits for

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $hand = Game::Mahjong::Hand->from_notation('11122233344455m');
    my @splits = Game::Mahjong::Decompose::decompose($hand, $winning_kind);
    # four of them: three pungs and a chow... see t/06-decompose.t

    Game::Mahjong::Decompose::is_complete($hand);     # 1
    my @waits = Game::Mahjong::Decompose::waits($thirteen);   # the kinds that complete it

=head1 DESCRIPTION

The decomposer is C (C<mahjong_decompose.c>, its interface published in
C<include/mahjong_decompose.h>), because the bot asks it for every candidate
discard and the scorer for every winning hand. This module is its Perl
face: it hands the C a hand's concealed counts and meld count, and puts the
hand's melds back beside the concealed sets the C found.

=head2 Every split, not the first

A hand can be complete more than one way. C<111222333m> is three pungs or
three chows, and the scoring rules let the winner take the higher
(3.9.1.5, "the High-versus-Low Principle"). So C<decompose> returns every
split and the scorer chooses.

=head2 A split

    {
        form      => 'standard' | 'seven_pairs' | 'thirteen_orphans'
                   | 'honours_knitted' | 'knitted_straight',
        sets      => [ { kind => 'chow' | 'pung' | 'kong' | 'knit',
                         tiles => [kinds], concealed => 0 | 1, melded => 0 | 1 }, ... ],
        pair      => kind | undef,
        singles   => [kinds],
        placement => { in => 'set' | 'pair' | 'single' | undef, index => n,
                       wait => 'edge' | 'closed' | 'two_sided' | 'pair' | 'pung'
                             | 'single' | 'knit' | undef },
    }

The concealed sets come first, in the order the walk found them, then the
melds in the order they were made; C<placement.index> counts from the first
concealed set. A kong on the table is a set of kind C<kong> with four tiles.
Seven pairs lists its pairs in C<singles>, one entry per pair; thirteen
orphans and the honours-and-knitted forms list every tile; a knitted
straight's three sequences are sets of kind C<knit>.

=head2 The placement is per split

With a winning kind given, a split is returned once for every place that
kind can sit in it: a chow, a pung, the pair, a single. The wait named is
what that placement alone says (the 3 of a 1-2-3 is an edge wait). Whether
the hand was waiting on that tile ALONE, which fans 77 to 79 require, is a
question about the thirteen tiles before it came, and C<waits> answers it.

=head1 FUNCTIONS

=head2 decompose

    my @splits = decompose($hand, $winning_kind);

Every split of a complete fourteen-tile hand (the concealed tiles plus
three a meld). An incomplete hand gives an empty list. C<$winning_kind> may
be omitted for the splits without placements.

=head2 is_complete

Whether the hand is complete in any form.

=head2 waits

    my @kinds = waits($hand);

The kinds whose addition completes a thirteen-tile hand, ascending. Dies
on a hand that is not thirteen tiles' worth.

=head1 SEE ALSO

L<Game::Mahjong::Hand>, L<Game::Mahjong::Meld>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
