package Games::Poker::Omaha::Hutchison;

our $VERSION = '1.04';

use strict;
use warnings;

use List::Util 'sum';

use Class::Struct 'Games::Poker::Omaha::Hutchison::Card' =>
	[ suit => '$', pips => '$' ];

sub Games::Poker::Omaha::Hutchison::Card::rank {
	return (qw/ 0 0 l l l l x h h h c c c c a /)[ shift->pips ];
}

sub new {
	my $class  = shift;
	my @cardes = @_ > 1 ? @_ : split / /, +shift || die "Need a hand";
	my @cards  = map [ split // ], @cardes;
	my %remap  = (A => 14, K => 13, Q => 12, J => 11, T => 10);
	$_->[0] = $remap{ $_->[0] } || $_->[0] foreach @cards;
	bless {
		cards => [
			map Games::Poker::Omaha::Hutchison::Card->new(
				pips => $_->[0],
				suit => lc $_->[1]
			),
			@cards
		]
	} => $class;
}

sub _cards { @{ shift->{cards} } }

sub _by_suit {
	my $self = shift;
	my %suited;
	push @{ $suited{ $_->suit } }, $_->pips
		foreach sort { $b->pips <=> $a->pips } $self->_cards;
	return %suited;
}

sub _by_pips {
	my $self = shift;
	my %pips;
	push @{ $pips{ $_->pips } }, $_->suit foreach $self->_cards;
	return %pips;
}

sub _unique_pips {
	my $self = shift;
	my %seen;
	my %part = map { $_ => [] } qw/l x h c a/;
	my @uniq = grep !$seen{ $_->pips }++, $self->_cards;
	push @{ $part{ $_->rank } }, $_->pips foreach @uniq;
	return %part;
}

sub hand_score {
	my $self = shift;
	sum($self->flush_score, $self->pair_score, $self->straight_score);
}

use Object::Attribute::Cached
	flush_score    => \&_flush_score,
	pair_score     => \&_pair_score,
	straight_score => \&_straight_score;

sub _flush_score {
	my $self   = shift;
	my %suited = $self->_by_suit;
	my $score  = 0;
	foreach my $suit (keys %suited) {
		my @cards = @{ $suited{$suit} };
		next unless @cards > 1;
		$score += $self->_flush_pts($cards[0]);
		$score -= 2 if @cards == 4;
	}
	$score;
}

sub _pair_pts  { (0, 0, 4, 4, 4, 4, 4, 4, 4, 5,   6,   6, 7,   8, 9)[ $_[1] ] }
sub _flush_pts { (0, 0, 1, 1, 1, 1, 1, 1, 1, 1.5, 1.5, 2, 2.5, 3, 4)[ $_[1] ] }

sub _pair_score {
	my $self = shift;
	my %pips = $self->_by_pips;
	(sum map $self->_pair_pts($_), grep @{ $pips{$_} } == 2, keys %pips) || 0;
}

sub _straight_score {
	my $self = shift;
	my %seen;
	my @run = grep !$seen{$_}++, map $_->pips, $self->_cards;
	return Games::Poker::Omaha::Hutchison::StraightScorer->new(@run)->score;
}

package Games::Poker::Omaha::Hutchison::StraightScorer;

use List::Util qw/sum max/;

sub new {
	my ($proto, @cards) = @_;
	my $class = ref $proto || $proto;
	bless { cards => [ sort { $b <=> $a } @cards ] }, $class;
}

sub cards { @{ shift->{cards} } }

sub gap {
	my $self = shift;
	my @pips = sort { $b <=> $a } @_;
	my $gap  = ($pips[0] - $pips[-1]) - (@pips - 1);
	return $gap;
}

sub gaploss {
	my ($self, @pips) = @_;
	my $gap = $self->gap(@pips);
	return (0, 1, 1, 2, (0) x 10)[$gap];
}

sub ace     { grep { $_ == 14 }           shift->cards; }
sub court   { grep { $_ > 9 and $_ < 14 } shift->cards; }
sub twosix  { grep { $_ > 1 and $_ < 7 }  shift->cards; }
sub twofive { grep { $_ > 1 and $_ < 6 }  shift->cards; } 
sub sixup   { grep { $_ > 5 }             shift->cards; }
sub sixking { grep { $_ > 5 and $_ < 14 } shift->cards; }

sub score {
	my $self  = shift;
	my @cards = $self->cards;

	my $score = $self->_four_high_cards;
	return $score if $score;

	$score += $self->_ace_low;
	$score += $self->_two_low_cards;

	$score += my $high3 = $self->_three_high_cards;
	return $score if $high3;

	$score += $self->_two_high_cards || $self->_ace_court;
	return $score;
}

sub _two_low_cards { 
	my $self = shift;
	return 2 - $self->gaploss($self->twosix)
		if $self->twosix >= 2
		and $self->gap($self->twosix) < 4;
}
	
sub _two_high_cards { 
	my $self = shift;
	return 4 - $self->gaploss($self->sixking)
		if $self->sixking == 2
		and $self->gap($self->sixking) < 4;
}

sub _four_high_cards { 
	my $self = shift;
	return 0 unless $self->sixup == 4;
	return 0 if $self->gap($self->cards) > 3;
	return 12 - $self->gaploss($self->cards);
}

sub _three_high_cards { 
	my $self = shift;
	my @cards = $self->sixup;
	return 0 unless @cards >= 3;
	return 7 - $self->gaploss(@cards) if @cards == 3;
	# Want 3 from 4
	my @hi = @cards; pop @hi;
	my @lo = @cards; shift @lo;
	return max($self->new(@hi)->score, $self->new(@lo)->score);
}

sub _ace_court { 
	my $self = shift;
	return 0 unless $self->ace and $self->court;
	return 0 if $self->gap($self->ace, $self->court) > 3;
	return 2 - $self->gaploss($self->ace, $self->court);
}

sub _ace_low { 
	my $self = shift;
	return ($self->ace and $self->twofive) ? 1 : 0
}

__END__

=head1 NAME

Games::Poker::Omaha::Hutchison - Hutchison method for scoring Omaha hands

=head1 SYNOPSIS

	my $evaluator = Games::Poker::Omaha::Hutchison->new("Ah Qd 3s 1d");

	my $score = $evaluator->hand_score;

=head1 DESCRIPTION

This module implements the Hutchison Omaha Point System for evaluating
starting hands in Omaha poker, as described at
http://www.thepokerforum.com/omahasystem.htm

=head1 CONSTRUCTOR

=head2 new

	my $evaluator = Games::Poker::Omaha::Hutchison->new("Ah Qd Ts 3d");

This takes 4 cards, expresed as a single string. The 'pip value' of the
card should be 2-9,T,J,Q,K or A, and the suit, of course, s, h, c or d.

=head1 METHODS

=head2 hand_score

	my $score = $evaluator->hand_score;

This returns the number of points assigned to the hand by this System.
This figure is roughly equivalent to the percentage chance of this
turning into a winning hand in a 10 player game, where each player plays
until the end. See the URL above for more information.

=head2 flush_score / pair_score / straight_score

The final hand_score() is made up from three component scores, for
suited cards, paired cards, and straight cards. These component scores
can also be accessed individually.

=head1 AUTHOR

Tony Bowden, based on the rules created by Edward Hutchison.

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Games-Poker-Omaha-Hutchison@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2004-2005 Tony Bowden.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License; either version
  2 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

This is based on the version at http://www.thepokerforum.com/omahasystem.htm

An alternative version is available at http://erh.homestead.com/omaha.html



