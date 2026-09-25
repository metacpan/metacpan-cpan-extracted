package Game::Mahjong::Shanten;

use 5.010;
use strict;
use warnings;

use Game::Mahjong::Tiles;

our $VERSION = '0.01';

our @FORMS = qw(standard seven_pairs thirteen_orphans honours_knitted);

sub shanten {
	my ($hand) = @_;
	return _shanten($hand->counts, $hand->meld_count);
}

sub forms {
	my ($hand) = @_;
	my $f = _forms($hand->counts, $hand->meld_count);
	return { map { $FORMS[$_] => $f->[$_] } 0 .. $#FORMS };
}

sub ukeire {
	my ($hand) = @_;
	return @{ _ukeire($hand->counts, $hand->meld_count) };
}

sub after_discard {
	my ($hand, $kind) = @_;
	my $counts = [ @{ $hand->counts } ];
	die 'Game::Mahjong::Shanten: the hand does not hold ' . Game::Mahjong::Tiles::code_of($kind)
		unless $counts->[$kind];
	$counts->[$kind]--;
	return _shanten($counts, $hand->meld_count);
}

1;

__END__

=head1 NAME

Game::Mahjong::Shanten - how far a hand is from ready, and what it accepts

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $n = Game::Mahjong::Shanten::shanten($hand);     # -1 complete, 0 ready, 1, 2 ...
    my %f = %{ Game::Mahjong::Shanten::forms($hand) };  # per form
    my @accepts = Game::Mahjong::Shanten::ukeire($hand); # the kinds that lower it
    my $after = Game::Mahjong::Shanten::after_discard($hand, $kind);

=head1 DESCRIPTION

The distance to ready is C (C<mahjong_shanten.c>, its interface in
C<include/mahjong_shanten.h>): the bot asks it for every candidate discard
and every accepting tile, which is a few hundred evaluations a move, and a
suit's nine counts are reduced once to their groupings and remembered.
This module is its Perl face over a L<Game::Mahjong::Hand>.

=head2 The number

-1 is complete, 0 is ready, and so on; the minimum over four sets and a
pair, seven pairs, thirteen orphans and the honours-and-knitted singles.
For a thirteen-tile hand the number is at least 0; for a fourteen it can
be -1.

=head1 FUNCTIONS

=head2 shanten

The number for a hand.

=head2 forms

The number for each form, keyed C<standard>, C<seven_pairs>,
C<thirteen_orphans>, C<honours_knitted>; a form the hand cannot take is 99.

=head2 ukeire

The kinds whose addition lowers the number, ascending.

=head2 after_discard

The number the hand would have after discarding a kind it holds.

=head1 SEE ALSO

L<Game::Mahjong::Search>, L<Game::Mahjong::Decompose>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
