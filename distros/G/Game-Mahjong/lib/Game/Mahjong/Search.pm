package Game::Mahjong::Search;

use 5.010;
use strict;
use warnings;

use Digest::SHA ();
use Game::Mahjong::Tiles;
use Game::Mahjong::Hand;
use Game::Mahjong::Meld;
use Game::Mahjong::Decompose;
use Game::Mahjong::Shanten;
use Game::Mahjong::Score;

our $VERSION = '0.01';

our %OFF;

sub view_of {
	my ($rules, $seat) = @_;
	my $hand = $rules->hand_of($seat)->clone;
	my %visible;
	for my $s (0 .. 3) {
		$visible{$_}++ for @{ $rules->pool_of($s) };
		for my $m (@{ $rules->hand_of($s)->melds }) {
			next if $m->concealed && $s != $seat;
			$visible{$_}++ for @{ $m->tiles };
		}
	}
	$visible{$_}++ for $hand->tiles;
	my @melds;
	for my $s (0 .. 3) {
		push @melds, [ map {
			{ kind => $_->kind, tiles => ($_->concealed && $s != $seat) ? [] : [ @{ $_->tiles } ], concealed => $_->concealed ? 1 : 0 }
		} @{ $rules->hand_of($s)->melds } ];
	}
	my $w = $rules->window;
	return {
		seat       => $seat,
		hand       => $hand,
		phase      => $rules->phase,
		turn       => $rules->turn,
		window     => $w ? { tile => $w->{tile}, from => $w->{from}, kind => $w->{kind} } : undef,
		prevailing => $rules->prevailing,
		seat_wind  => $rules->seat_wind($seat),
		wall       => $rules->wall->remaining,
		pools      => [ map { [ @{ $rules->pool_of($_) } ] } 0 .. 3 ],
		melds      => \@melds,
		visible    => \%visible,
		totals     => [ @{ $rules->totals } ],
		hand_no    => $rules->hand_no,
		moves      => $rules->moves,
		drawn      => $rules->drawn,
		legal      => [ $rules->legal($seat) ],
	};
}

sub _word {
	my ($view, $tag, $n) = @_;
	my $seed = $view->{seed} // 'search';
	my ($w) = unpack 'N', Digest::SHA::sha256("$seed:$view->{hand_no}:$view->{moves}:$tag");
	return $w % $n;
}

sub best {
	my ($view, $level, $word) = @_;
	$word ||= sub { _word($view, @_) };
	my @legal = @{ $view->{legal} };
	return undef unless @legal;
	return $legal[0] if @legal == 1;

	my ($win) = grep { $_->{kind} eq 'win' } @legal;
	return $win if $win;

	if ($view->{phase} eq 'discard') {
		my $kong = _self_kong($view, $level, \@legal);
		return $kong if $kong;
		return _discard($view, $level, \@legal, $word);
	}
	return _answer($view, $level, \@legal, $word);
}

sub _isolation {
	my ($hand, $kind) = @_;
	my $c = $hand->count($kind);
	my $n = ($c - 1) * 3;
	if (my $rank = Game::Mahjong::Tiles::rank_of($kind)) {
		$n += 2 * $hand->count($kind - 1) if $rank > 1;
		$n += 2 * $hand->count($kind + 1) if $rank < 9;
		$n += $hand->count($kind - 2) if $rank > 2;
		$n += $hand->count($kind + 2) if $rank < 8;
	}
	my $tie = Game::Mahjong::Tiles::is_honour($kind) ? 0 : Game::Mahjong::Tiles::is_terminal($kind) ? 1 : 2;
	return $n * 10 + $tie;
}

sub _remaining {
	my ($view, $kind) = @_;
	my $r = Game::Mahjong::Tiles::PER_KIND - ($view->{visible}{$kind} || 0);
	return $r < 0 ? 0 : $r;
}

sub _acceptance {
	my ($view, $kind) = @_;
	my $after = $view->{hand}->clone;
	$after->remove($kind);
	my $n = 0;
	$n += _remaining($view, $_) for Game::Mahjong::Shanten::ukeire($after);
	return $n;
}

sub _discard {
	my ($view, $level, $legal, $word) = @_;
	my @discards = grep { $_->{kind} eq 'discard' } @$legal;
	my $hand = $view->{hand};

	if ($level <= 1 || $OFF{shanten}) {
		my @ranked = sort { _isolation($hand, $a->{tile}) <=> _isolation($hand, $b->{tile}) || $a->{tile} <=> $b->{tile} } @discards;
		return $ranked[0];
	}

	my %after = map { $_->{tile} => Game::Mahjong::Shanten::after_discard($hand, $_->{tile}) } @discards;
	my $min = (sort { $a <=> $b } values %after)[0];
	my @keep = grep { $after{ $_->{tile} } == $min } @discards;

	my @safe = $level >= 3 && !$OFF{defence} ? _safe_kinds($view) : ();
	my %safe = map { $_ => 1 } @safe;
	if (@safe && Game::Mahjong::Shanten::shanten($hand) >= 2) {
		my @s = grep { $safe{ $_->{tile} } } @keep;
		@keep = @s if @s;
	}

	my %score;
	for my $d (@keep) {
		my $s = _acceptance($view, $d->{tile}) * 10;
		$s += _potential_after($view, $d->{tile}) if $level >= 3 && !$OFF{planning};
		$s -= _isolation($hand, $d->{tile}) / 100;
		$score{ $d->{tile} } = $s;
	}
	my @ranked = sort { $score{ $b->{tile} } <=> $score{ $a->{tile} } || $a->{tile} <=> $b->{tile} } @keep;
	return $ranked[0];
}

sub _safe_kinds {
	my ($view) = @_;
	my @near = grep { $_ != $view->{seat} && scalar(@{ $view->{melds}[$_] }) >= 3 } 0 .. 3;
	return () unless @near;
	my %safe;
	for my $kind ($view->{hand}->kinds) {
		$safe{$kind} = 1 if _remaining($view, $kind) == 0;
		for my $s (@near) {
			$safe{$kind} = 1 if grep { $_ == $kind } @{ $view->{pools}[$s] };
		}
	}
	return sort { $a <=> $b } keys %safe;
}

sub _potential_after {
	my ($view, $discard) = @_;
	my $hand = $view->{hand}->clone;
	$hand->remove($discard);
	my (%suit, $honours);
	my @tiles = ($hand->tiles, map { @{ $_->tiles } } @{ $hand->melds });
	for my $t (@tiles) {
		if (my $s = Game::Mahjong::Tiles::suit_of($t)) { $suit{$s}++ } else { $honours++ }
	}
	my ($big) = sort { $b <=> $a } values %suit;
	$big ||= 0;
	my $p = 0;
	$p += 24 * ($big / 14) if $big >= 9 && !$honours;
	$p += 6 * (($big + ($honours || 0)) / 14) if $big >= 8 && $honours;
	my $pungs = grep { $hand->count($_) >= 3 } $hand->kinds;
	$pungs += grep { $_->is_pung } @{ $hand->melds };
	$p += 6 * ($pungs / 4) if $pungs >= 2;
	for my $k ($hand->kinds) {
		next unless $hand->count($k) >= 2;
		$p += 2 if Game::Mahjong::Tiles::is_dragon($k);
		$p += 2 if Game::Mahjong::Tiles::is_wind($k) && (Game::Mahjong::Tiles::wind_index($k) == $view->{prevailing} || Game::Mahjong::Tiles::wind_index($k) == $view->{seat_wind});
		$p += 1 if Game::Mahjong::Tiles::is_terminal($k);
	}
	return $p;
}

sub _self_kong {
	my ($view, $level, $legal) = @_;
	return undef if $level <= 1;
	my @kongs = grep { $_->{kind} eq 'kong' } @$legal;
	return undef unless @kongs;
	my $hand = $view->{hand};
	my $now = Game::Mahjong::Shanten::shanten($hand);
	for my $k (@kongs) {
		my $after = $hand->clone;
		if ($after->holds_kong_of($k->{tile})) { $after->concealed_kong($k->{tile}) }
		else { $after->promote_kong($k->{tile}) }
		return $k if Game::Mahjong::Shanten::shanten($after) <= $now;
	}
	return undef;
}

sub _ctx {
	my ($view, $by, $from) = @_;
	return { by => $by, prevailing => $view->{prevailing}, seat => $view->{seat_wind}, from => $from,
		flowers => scalar @{ $view->{hand}->flowers } };
}

sub _reaches_eight {
	my ($view, $hand) = @_;
	return 0 unless $hand->total == 13;
	my @waits = Game::Mahjong::Decompose::waits($hand);
	for my $w (@waits) {
		my $with = $hand->clone;
		$with->add($w);
		my $ctx = _ctx($view, 'discard', undef);
		$ctx->{waits} = \@waits;
		my $t = Game::Mahjong::Score::score($with, $w, $ctx);
		return 1 if $t && $t->minimum_met;
	}
	return 0;
}

sub _answer {
	my ($view, $level, $legal, $word) = @_;
	my ($pass) = grep { $_->{kind} eq 'pass' } @$legal;
	return $pass if $level <= 1 || $OFF{claims};
	my $hand = $view->{hand};
	my $tile = $view->{window}{tile};
	my $from = $view->{window}{from};
	my $now  = Game::Mahjong::Shanten::shanten($hand);

	for my $claim (grep { $_->{kind} eq 'kong' || $_->{kind} eq 'pung' } @$legal) {
		my $after = $hand->clone;
		if ($claim->{kind} eq 'kong') { $after->claim_kong($tile, $from) } else { $after->claim_pung($tile, $from) }
		my $kept = _best_thirteen($after);
		my $s = Game::Mahjong::Shanten::shanten($kept);
		next unless $s < $now;
		my $scores = Game::Mahjong::Tiles::is_dragon($tile)
			|| (Game::Mahjong::Tiles::is_wind($tile) && (Game::Mahjong::Tiles::wind_index($tile) == $view->{prevailing} || Game::Mahjong::Tiles::wind_index($tile) == $view->{seat_wind}))
			|| Game::Mahjong::Tiles::is_terminal($tile);
		my $floor = Game::Mahjong::Score::floor($kept, _ctx($view, 'discard', $from));
		return $claim if $scores || $floor >= Game::Mahjong::Score::MINIMUM || ($s == 0 && _reaches_eight($view, $kept));
		return $claim if $level >= 3 && !$OFF{planning} && $s <= 1 && _potential_after_hand($view, $kept) >= 6;
	}

	my @chows = grep { $_->{kind} eq 'chow' } @$legal;
	for my $chow (@chows) {
		my $after = $hand->clone;
		$after->claim_chow($tile, @{ $chow->{tiles} }, $from);
		my $kept = _best_thirteen($after);
		my $s = Game::Mahjong::Shanten::shanten($kept);
		next unless $s < $now || ($now == 0 && $s == 0);
		return $chow if $s == 0 && _reaches_eight($view, $kept);
		return $chow if $level >= 3 && !$OFF{planning} && $s <= 1 && $s < $now && Game::Mahjong::Score::floor($kept, _ctx($view, 'discard', $from)) + _potential_after_hand($view, $kept) >= Game::Mahjong::Score::MINIMUM;
	}
	return $pass;
}

sub _best_thirteen {
	my ($after) = @_;
	return $after if $after->total == 13;
	my ($best, $best_s);
	for my $k ($after->kinds) {
		my $s = Game::Mahjong::Shanten::after_discard($after, $k);
		next if defined $best_s && $s >= $best_s;
		($best, $best_s) = ($k, $s);
	}
	my $h = $after->clone;
	$h->remove($best);
	return $h;
}

sub _potential_after_hand {
	my ($view, $hand) = @_;
	my $v = { %$view, hand => $hand };
	my ($k) = $hand->kinds;
	return $k ? _potential_after($v, $k) : 0;
}

1;

__END__

=head1 NAME

Game::Mahjong::Search - the three rungs of the bot, reading a view and nothing else

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $view = Game::Mahjong::Search::view_of($rules, $seat);
    my $move = Game::Mahjong::Search::best($view, 2);   # a member of $view->{legal}

=head1 DESCRIPTION

=head2 The view is all a rung may read

Its own hand, every pool, every exposed meld (another seat's concealed kong
shows as a kong with no tiles), what is visible and how many of each kind
remain, the wall count, the winds, the window, the legal moves. No field
for another hand and none for the wall's order, so a rung cannot cheat by
construction, and the tests hand the rungs written views.

=head2 The three rungs, each the one below plus one idea

    1  THE MOST ISOLATED TILE. Discard the tile with the fewest neighbours in
       hand, honours first, then terminals; pass every window; win when legal.

    2  SHANTEN AND ACCEPTANCE. For every candidate discard the distance to
       ready after it; keep the minimum; among those, the most accepting tiles
       still to be had. Declare a kong that does not lengthen the road. Claim a
       pung or kong that shortens it when the pung scores by itself (a dragon,
       the prevalent or seat wind, a terminal), when the melds already floor
       eight, or when it makes the hand ready to win eight; claim a chow only
       when it makes the hand ready to win eight.

    3  DEFENCE AND A TARGET. Against a seat with three melds exposed, while
       two or more from ready, discard a kind every copy of which is out or
       which that seat has discarded. Among equal discards prefer the one that
       keeps a flush, a pungs hand or scoring pairs in the making, and claim
       toward such a hand one step earlier.

C<%OFF> switches an idea off by name (C<shanten>, C<claims>, C<defence>,
C<planning>) so the ladder script can price it.

=head1 FUNCTIONS

=head2 view_of

The view of a L<Game::Mahjong::Rules> for a seat.

=head2 best

    my $move = best($view, $level, $word);

A member of the view's legal moves, or undef when there are none. C<$word>
breaks ties from the seed; the default hashes the view's seed, hand and
move count.

=head1 SEE ALSO

L<Game::Mahjong::Bot>, L<Game::Mahjong::Shanten>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
