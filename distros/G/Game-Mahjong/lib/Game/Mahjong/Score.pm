package Game::Mahjong::Score;

use 5.010;
use strict;
use warnings;

use Game::Mahjong::Tiles;
use Game::Mahjong::Decompose;
use Game::Mahjong::Fans;
use Game::Mahjong::Tally;

our $VERSION = '0.01';

use constant MINIMUM => 8;

sub score {
	my ($hand, $winning, $ctx) = @_;
	$ctx = { %{ $ctx || {} } };
	$winning ||= 0;
	die 'Game::Mahjong::Score: a hand scores at fourteen tiles, this one is ' . $hand->total
		unless $hand->total == 14;

	if ($winning) {
		$ctx->{winning} = $winning;
		unless ($ctx->{waits}) {
			my $thirteen = $hand->clone;
			$thirteen->remove($winning);
			$ctx->{waits} = [ Game::Mahjong::Decompose::waits($thirteen) ];
		}
	}

	my @splits = Game::Mahjong::Decompose::decompose($hand, $winning);
	return undef unless @splits;

	my $best;
	for my $split (@splits) {
		my $found = Game::Mahjong::Fans::check_all($split, $ctx);
		my @fans = _combine($found);
		my $basic = 0;
		$basic += $_->{total} for @fans;
		if (!$basic) {
			my $chicken = Game::Mahjong::Fans::by_key('chicken_hand');
			@fans = ({ key => $chicken->key, name => $chicken->name, points => $chicken->points, times => 1, total => $chicken->points });
			$basic = $chicken->points;
		}
		next if $best && $basic <= $best->{basic};
		$best = { basic => $basic, fans => \@fans, split => $split };
	}

	my $flowers = $ctx->{flowers} || 0;
	my @fans = @{ $best->{fans} };
	if ($flowers) {
		my $f = Game::Mahjong::Fans::by_key('flower_tiles');
		push @fans, { key => $f->key, name => $f->name, points => $f->points, times => $flowers, total => $flowers * $f->points };
	}

	return Game::Mahjong::Tally->new(
		points      => $best->{basic} + $flowers,
		basic       => $best->{basic},
		flowers     => $flowers,
		fans        => \@fans,
		split       => $best->{split},
		minimum_met => $best->{basic} >= MINIMUM ? 1 : 0,
	);
}

sub minimum_met {
	my ($tally) = @_;
	return $tally && $tally->basic >= MINIMUM ? 1 : 0;
}

sub _combine {
	my ($found) = @_;
	my @candidates;
	for my $key (keys %$found) {
		next if $key eq 'flower_tiles';
		my $fan = Game::Mahjong::Fans::by_key($key);
		push @candidates, { fan => $fan, instances => $found->{$key} };
	}
	@candidates = sort { $b->{fan}->points <=> $a->{fan}->points || $a->{fan}->n <=> $b->{fan}->n } @candidates;

	my (%kept, %blocked, %used);
	my @out;
	for my $c (@candidates) {
		my $fan = $c->{fan};
		my $key = $fan->key;
		next if $blocked{$key};

		my %fan_used;
		my ($times, $total) = (0, 0);
		for my $inst (@{ $c->{instances} }) {
			my @sets = @{ $inst->{sets} || [] };
			if ($fan->combining) {
				next if grep { $fan_used{$_} } @sets;
				next unless grep { !$used{$_} } @sets;
				$fan_used{$_} = 1 for @sets;
			}
			$times++;
			$total += defined $inst->{points} ? $inst->{points} : $fan->points;
		}
		next unless $times;

		$used{$_} = 1 for keys %fan_used;
		$kept{$key} = 1;
		$blocked{$_} = 1 for @{ $fan->excludes }, @{ $fan->implies };
		push @out, { key => $key, name => $fan->name, points => $fan->points, times => $times, total => $total };
	}

	my @final;
	for my $f (@out) {
		my $fan = Game::Mahjong::Fans::by_key($f->{key});
		my $clash = 0;
		for my $other (@{ $fan->excludes }, @{ $fan->implies }) {
			$clash = 1 if $kept{$other} && Game::Mahjong::Fans::by_key($other)->points >= $fan->points && $other ne $f->{key};
		}
		push @final, $f unless $clash;
	}
	return @final;
}

sub floor {
	my ($hand, $ctx) = @_;
	my @melds = @{ $hand->melds };
	return 0 unless @melds;
	my $split = {
		form  => 'standard',
		sets  => [ map { { kind => $_->kind, tiles => [ @{ $_->tiles } ], concealed => $_->concealed ? 1 : 0, melded => 1 } } @melds ],
		pair  => undef,
		singles => [],
		placement => { in => undef, index => 0, wait => undef },
	};
	my $found = Game::Mahjong::Fans::check_all($split, { %{ $ctx || {} }, by => undef, waits => [ 0, 0 ] });
	for my $key (keys %$found) {
		if (Game::Mahjong::Fans::by_key($key)->whole) { delete $found->{$key}; next }
		my @with_sets = grep { @{ $_->{sets} || [] } } @{ $found->{$key} };
		if (@with_sets) { $found->{$key} = \@with_sets } else { delete $found->{$key} }
	}
	my $total = 0;
	$total += $_->{total} for _combine($found);
	return $total;
}

1;

__END__

=head1 NAME

Game::Mahjong::Score - the points of a winning hand under the five principles

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $tally = Game::Mahjong::Score::score($hand, $winning_kind, {
        by => 'discard', prevailing => 0, seat => 1, flowers => 2,
    });
    $tally->points;         # 93
    $tally->minimum_met;    # 1: basic 91 >= 8

    Game::Mahjong::Score::MINIMUM;   # 8
    Game::Mahjong::Score::floor($hand, \%ctx);   # a lower bound from the melds

=head1 DESCRIPTION

For every split of the hand (L<Game::Mahjong::Decompose>) and every
placement of the winning tile in it, the fans the checkers find
(L<Game::Mahjong::Fans>) are combined under the rulebook's principles
(3.9.1.5) and the highest total is the score. Flowers are added after the
minimum is read, because a hand of seven points and a flower cannot win
(3.11.6.6: "at least 8 points ... not counting the points for Flowers").
A hand with no fan at all scores Chicken Hand's eight.

=head2 The principles as applied

The primary fan is the highest. A fan that a kept fan excludes or implies is
dropped, whichever of the two the rulebook wrote the exclusion on. Within a
fan the instances kept use disjoint sets. Across fans, an instance that
combines two or more sets is kept only while at least one of its sets is
not yet in any kept combination, which is the account-once rule read
literally: "you can only combine any remaining sets once with a set that
has already been used". So a pure straight with a fourth chow that doubles
one of its three scores one of Pure Double Chow, Short Straight or Two
Terminal Chows and not two, which is what Appendix 1's Full Flush example
says. A fan that names one set (a dragon pung) or none (a flush, a wait) is
not a combination and is never blocked by usage.

=head2 The waits are read from the thirteen

If the context carries no C<waits>, the scorer removes the winning tile and
asks the decomposer what the thirteen waited on, so the edge, closed and
single waits are scored only when that tile was the hand's only wait.

=head1 FUNCTIONS

=head2 score

    my $tally = score($hand, $winning_kind, \%ctx);

A L<Game::Mahjong::Tally>, or undef for a hand that is not complete. Dies
unless the hand is fourteen tiles' worth. The context is
L<Game::Mahjong::Fans>' plus C<flowers>.

=head2 minimum_met

Whether a tally's basic points reach C<MINIMUM>.

=head2 floor

A lower bound on a hand's eventual score from its exposed melds alone: the
set-based fans found within the melds, combined. Zero with no melds. For
the bot's "can I still reach eight" test.

=head2 MINIMUM

Eight.

=head1 SEE ALSO

L<Game::Mahjong::Fans>, L<Game::Mahjong::Tally>, L<Game::Mahjong::Result>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
