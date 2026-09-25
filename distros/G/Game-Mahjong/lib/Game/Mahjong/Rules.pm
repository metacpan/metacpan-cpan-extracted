package Game::Mahjong::Rules;

use 5.010;
use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Mahjong::Tiles;
use Game::Mahjong::Notation;
use Game::Mahjong::Wall;
use Game::Mahjong::Hand;
use Game::Mahjong::Decompose;
use Game::Mahjong::Score;
use Game::Mahjong::Result;
use Game::Mahjong::Error;

our $VERSION = '0.01';

our %PRIORITY;
BEGIN { %PRIORITY = (pass => 0, chow => 1, pung => 2, kong => 2, win => 3) }

has seed => (is => 'ro', isa => Str, required => 1);

has hand_no => (is => 'rw', isa => Int, default => 1);

has dealer => (is => 'rw', isa => Int, default => 0);

has totals => (is => 'rw', isa => ArrayRef, default => sub { [ 0, 0, 0, 0 ] });

has wall => (is => 'rw');

has hands => (is => 'rw', isa => ArrayRef, default => []);

has pools => (is => 'rw', isa => ArrayRef, default => sub { [ [], [], [], [] ] });

has phase => (is => 'rw', isa => Str, default => 'discard');

has turn => (is => 'rw');

has window => (is => 'rw');

has drawn => (is => 'rw');

has drawn_from => (is => 'rw');

has replacement => (is => 'rw');

has claimed_this_turn => (is => 'rw', default => 0);

has last_draw_emptied => (is => 'rw', default => 0);

has last_discard_is_last => (is => 'rw', default => 0);

has status => (is => 'rw', isa => Str, default => 'active');

has history => (is => 'rw', isa => ArrayRef, default => []);

has outcomes => (is => 'rw', isa => ArrayRef, default => []);

has last => (is => 'rw');

has winner => (is => 'rw');

has result => (is => 'rw');

has position => (is => 'ro');

has moves => (is => 'rw', isa => Int, default => 0);

sub BUILD {
	my ($self) = @_;
	die 'Game::Mahjong::Rules: a seed is a non-empty string' unless length $self->seed;
	die 'Game::Mahjong::Rules: hand_no is 1 to ' . Game::Mahjong::Result::HANDS
		unless $self->hand_no >= 1 && $self->hand_no <= Game::Mahjong::Result::HANDS;
	die 'Game::Mahjong::Rules: totals are four numbers' unless @{ $self->totals } == 4;
	if ($self->position) { $self->_take_written_position($self->position) }
	else { $self->_deal }
	return;
}

sub prevailing { my ($self) = @_; return int(($self->hand_no - 1) / 4) }

sub round { my ($self) = @_; return $self->prevailing + 1 }

sub seat_wind { my ($self, $seat) = @_; return ($seat - $self->dealer) % 4 }

sub next_seat { my ($self, $seat) = @_; return ($seat + 1) % 4 }

sub _emit {
	my ($self, $actor, $kind, %payload) = @_;
	push @{ $self->outcomes }, { actor => $actor, kind => $kind, %payload };
	return;
}

sub take_outcomes {
	my ($self) = @_;
	my @out = @{ $self->outcomes };
	@{ $self->outcomes } = ();
	return @out;
}

sub _deal {
	my ($self) = @_;
	$self->dealer(($self->hand_no - 1) % 4);
	my $wall = Game::Mahjong::Wall->new(seed => $self->seed, hand => $self->hand_no);
	my $deal = $wall->deal($self->dealer);
	$self->wall($wall);
	$self->hands([ map { Game::Mahjong::Hand->new } 0 .. 3 ]);
	$self->pools([ [], [], [], [] ]);
	$self->_reset_turn_state;
	$self->window(undef);
	$self->_emit('sys', 'deal',
		hand => $self->hand_no, round => $self->round, prevailing => $self->prevailing,
		dealer => $self->dealer, winds => [ map { $self->seat_wind($_) } 0 .. 3 ]);

	for my $i (0 .. 3) {
		my $seat = ($self->dealer + $i) % 4;
		for my $kind (@{ $deal->{hands}{$seat} }) {
			if (Game::Mahjong::Tiles::is_bonus($kind)) { $self->hands->[$seat]->add_flower($kind); $self->_emit('sys', 'flower', seat => $seat, tile => $kind) }
			else { $self->hands->[$seat]->add($kind) }
		}
	}
	for my $i (0 .. 3) {
		my $seat = ($self->dealer + $i) % 4;
		while ($self->hands->[$seat]->total < ($seat == $self->dealer ? 14 : 13)) {
			return $self->_exhausted if $self->wall->is_empty;
			my $kind = $self->wall->replace;
			$self->_emit('sys', 'drew', seat => $seat, from => 'back');
			if (Game::Mahjong::Tiles::is_bonus($kind)) { $self->hands->[$seat]->add_flower($kind); $self->_emit('sys', 'flower', seat => $seat, tile => $kind) }
			else { $self->hands->[$seat]->add($kind) }
		}
	}
	$self->phase('discard');
	$self->turn($self->dealer);
	return;
}

sub _reset_turn_state {
	my ($self) = @_;
	$self->drawn(undef);
	$self->drawn_from(undef);
	$self->replacement(undef);
	$self->claimed_this_turn(0);
	$self->last_draw_emptied(0);
	$self->last_discard_is_last(0);
	$self->last(undef);
	return;
}

sub _take_written_position {
	my ($self, $p) = @_;
	die 'Game::Mahjong::Rules: a position names four hands' unless ref $p->{hands} eq 'ARRAY' && @{ $p->{hands} } == 4;
	$self->dealer($p->{dealer} // (($self->hand_no - 1) % 4));
	$self->hands([ map { Game::Mahjong::Hand->from_notation($_) } @{ $p->{hands} } ]);
	$self->pools([ map { [ map { Game::Mahjong::Tiles::id_of($_) } @{ $_ } ] } @{ $p->{pools} || [ [], [], [], [] ] } ]);
	$self->wall(Game::Mahjong::Wall->new(seed => $self->seed, hand => $self->hand_no,
		tiles => [ map { /\A\d+\z/ ? $_ : Game::Mahjong::Tiles::id_of($_) } @{ $p->{wall} || [] } ]));
	$self->wall->dealt(1);
	$self->_reset_turn_state;
	$self->window(undef);
	my $turn = $p->{turn} // $self->dealer;
	for my $seat (0 .. 3) {
		my $want = $seat == $turn ? 14 : 13;
		die "Game::Mahjong::Rules: seat $seat holds " . $self->hands->[$seat]->total . " tiles' worth, not $want"
			unless $self->hands->[$seat]->total == $want;
	}
	$self->phase('discard');
	$self->turn($turn);
	$self->claimed_this_turn($p->{claimed_this_turn} ? 1 : 0);
	$self->drawn($p->{drawn} ? Game::Mahjong::Tiles::id_of($p->{drawn}) : undef);
	return;
}

sub hand_of { my ($self, $seat) = @_; return $self->hands->[$seat] }

sub pool_of { my ($self, $seat) = @_; return $self->pools->[$seat] }

sub is_active { return $_[0]->status eq 'active' ? 1 : 0 }

sub waiting_on {
	my ($self) = @_;
	return () unless $self->is_active;
	return ($self->turn) if $self->phase eq 'discard';
	return $self->_window_waiting if $self->phase eq 'claim' || $self->phase eq 'rob';
	return ();
}

sub _visible_count {
	my ($self, $kind) = @_;
	my $n = 0;
	for my $seat (0 .. 3) {
		$n += grep { $_ == $kind } @{ $self->pools->[$seat] };
		for my $meld (@{ $self->hands->[$seat]->melds }) {
			next if $meld->concealed;
			$n += grep { $_ == $kind } @{ $meld->tiles };
		}
	}
	return $n;
}

sub _waits_of {
	my ($self, $seat) = @_;
	my $hand = $self->hands->[$seat];
	return [] unless $hand->total == 13;
	$hand->waits([ Game::Mahjong::Decompose::waits($hand) ]) unless $hand->waits;
	return $hand->waits;
}

sub _win_ctx {
	my ($self, $seat, $by, $from, $tile) = @_;
	return {
		by           => $by,
		prevailing   => $self->prevailing,
		seat         => $self->seat_wind($seat),
		winning      => $tile,
		last_of_wall => ($by eq 'self' ? $self->last_draw_emptied : $self->last_discard_is_last) ? 1 : 0,
		replacement  => $by eq 'self' ? $self->replacement : undef,
		last_tile    => ($tile && $self->_visible_count($tile) == 3) ? 1 : 0,
		flowers      => scalar @{ $self->hands->[$seat]->flowers },
		from         => $from,
	};
}

sub _tally_on {
	my ($self, $seat, $tile, $by, $from) = @_;
	my $waits = $self->_waits_of($seat);
	return undef unless grep { $_ == $tile } @$waits;
	my $with = $self->hands->[$seat]->clone;
	$with->add($tile);
	my $ctx = $self->_win_ctx($seat, $by, $from, $tile);
	$ctx->{waits} = [ @$waits ];
	my $tally = Game::Mahjong::Score::score($with, $tile, $ctx);
	return $tally && $tally->minimum_met ? $tally : undef;
}

sub _tally_self {
	my ($self, $seat) = @_;
	my $hand = $self->hands->[$seat];
	return undef unless $hand->total == 14;
	my $tile = $self->drawn;
	my $ctx = $self->_win_ctx($seat, 'self', undef, $tile);
	if ($tile) {
		my $thirteen = $hand->clone;
		$thirteen->remove($tile);
		$ctx->{waits} = [ Game::Mahjong::Decompose::waits($thirteen) ];
	}
	my $tally = Game::Mahjong::Score::score($hand, $tile || 0, $ctx);
	return $tally && $tally->minimum_met ? $tally : undef;
}

sub legal {
	my ($self, $seat) = @_;
	return () unless $self->is_active && defined $seat;
	my $hand = $self->hands->[$seat];

	if ($self->phase eq 'discard') {
		return () unless $seat == $self->turn;
		my @legal = map { { kind => 'discard', tile => $_ } } $hand->kinds;
		unless ($self->claimed_this_turn) {
			for my $kind ($hand->kinds) {
				push @legal, { kind => 'kong', tile => $kind } if $hand->holds_kong_of($kind);
				push @legal, { kind => 'kong', tile => $kind } if $hand->exposed_pung_of($kind);
			}
		}
		push @legal, { kind => 'win' } if $self->_tally_self($seat);
		return @legal;
	}

	my $w = $self->window or return ();
	return () unless $w->{may}{$seat} && !exists $w->{answers}{$seat};
	my @legal = ({ kind => 'pass' });
	for my $claim (@{ $w->{may}{$seat} }) {
		if ($claim eq 'chow') {
			push @legal, map { { kind => 'chow', tiles => $_ } } $hand->chow_shapes($w->{tile});
		}
		else { push @legal, { kind => $claim } }
	}
	return @legal;
}

sub _refuse {
	my ($self, $code, $seat) = @_;
	return Game::Mahjong::Error->throw($code, legal => [ $self->legal($seat) ]);
}

sub apply {
	my ($self, $seat, $move) = @_;
	return $self->_refuse('game_over', $seat) unless $self->is_active;
	return $self->_refuse('bad_move', $seat) unless ref $move eq 'HASH' && defined $move->{kind};
	return $self->_refuse('bad_move', $seat) unless defined $seat && $seat =~ /\A[0-3]\z/;
	my $kind = $move->{kind};

	if ($self->phase eq 'discard') {
		return $self->_refuse('wrong_phase', $seat) if $kind eq 'pass' || $kind eq 'pung' || $kind eq 'chow';
		return $self->_refuse('not_your_turn', $seat) unless $seat == $self->turn;
		return $self->_discard($seat, $move) if $kind eq 'discard';
		return $self->_kong($seat, $move)    if $kind eq 'kong';
		return $self->_self_win($seat)       if $kind eq 'win';
		return $self->_refuse('bad_move', $seat);
	}

	return $self->_refuse('wrong_phase', $seat) if $kind eq 'discard';
	return $self->_answer($seat, $move);
}

sub _tile_arg {
	my ($self, $move, $seat) = @_;
	my $tile = $move->{tile};
	return (undef, $self->_refuse('bad_move', $seat)) unless defined $tile && $tile =~ /\A\d+\z/ && $tile >= 1 && $tile <= Game::Mahjong::Tiles::KINDS;
	return ($tile + 0, undef);
}

sub _discard {
	my ($self, $seat, $move) = @_;
	my ($tile, $err) = $self->_tile_arg($move, $seat);
	return $err if $err;
	my $hand = $self->hands->[$seat];
	return $self->_refuse('tile_not_held', $seat) unless $hand->count($tile);

	$hand->remove($tile);
	push @{ $self->pools->[$seat] }, $tile;
	$self->moves($self->moves + 1);
	$self->_emit($seat, 'discard', tile => $tile);
	$self->last({ seat => $seat, kind => 'discard', tile => $tile });
	$self->last_discard_is_last($self->last_draw_emptied ? 1 : 0);
	$self->last_draw_emptied(0);
	$self->drawn(undef);
	$self->replacement(undef);
	$self->claimed_this_turn(0);

	return $self->_open_window('claim', $tile, $seat);
}

sub _kong {
	my ($self, $seat, $move) = @_;
	my ($tile, $err) = $self->_tile_arg($move, $seat);
	return $err if $err;
	return $self->_refuse('no_kong', $seat) if $self->claimed_this_turn;
	my $hand = $self->hands->[$seat];

	if ($hand->holds_kong_of($tile)) {
		$hand->concealed_kong($tile);
		$self->moves($self->moves + 1);
		$self->_emit($seat, 'kong', tile => $tile, how => 'concealed');
		$self->last({ seat => $seat, kind => 'kong', tile => $tile });
		return $self->_replacement_draw($seat, 'kong');
	}
	if ($hand->exposed_pung_of($tile) && $hand->count($tile)) {
		$self->moves($self->moves + 1);
		$self->_emit($seat, 'kong', tile => $tile, how => 'promoted');
		$self->last({ seat => $seat, kind => 'kong', tile => $tile });
		return $self->_open_window('rob', $tile, $seat);
	}
	return $self->_refuse($hand->count($tile) ? 'no_kong' : 'tile_not_held', $seat);
}

sub _self_win {
	my ($self, $seat) = @_;
	my $hand = $self->hands->[$seat];
	my $tally = $self->_tally_self($seat);
	unless ($tally) {
		return $self->_refuse(Game::Mahjong::Decompose::is_complete($hand) ? 'too_few_points' : 'not_a_win', $seat);
	}
	$self->moves($self->moves + 1);
	$self->_emit($seat, 'win');
	return $self->_hand_won($seat, $tally, 'self', undef, $self->drawn);
}

sub _may_claim {
	my ($self, $seat, $tile, $from, $rob) = @_;
	my $hand = $self->hands->[$seat];
	my @may;
	push @may, 'win' if $self->_tally_on($seat, $tile, $rob ? 'rob' : 'discard', $from);
	unless ($rob) {
		push @may, 'kong' if $hand->holds_pung_of($tile) && $self->wall->remaining;
		push @may, 'pung' if $hand->holds_pair($tile);
		push @may, 'chow' if $seat == $self->next_seat($from) && $hand->chow_shapes($tile);
	}
	return @may;
}

sub _open_window {
	my ($self, $kind, $tile, $from) = @_;
	my %may;
	for my $seat (grep { $_ != $from } 0 .. 3) {
		my @claims = $self->_may_claim($seat, $tile, $from, $kind eq 'rob');
		$may{$seat} = \@claims if @claims;
	}
	if (!%may) {
		return $self->_close_window_with($kind, $tile, $from, undef);
	}
	$self->window({ kind => $kind, tile => $tile, from => $from, may => \%may, answers => {} });
	$self->phase($kind);
	$self->turn(undef);
	return 1;
}

sub _best_possible {
	my ($self, $seat) = @_;
	my $w = $self->window;
	my $best = 0;
	for my $c (@{ $w->{may}{$seat} }) { $best = $PRIORITY{$c} if $PRIORITY{$c} > $best }
	return $best;
}

sub _window_waiting {
	my ($self) = @_;
	my $w = $self->window or return ();
	my ($lodged, $lodged_seat) = $self->_lodged_best;
	my @waiting;
	for my $seat ($self->_seats_after($w->{from})) {
		next unless $w->{may}{$seat};
		next if exists $w->{answers}{$seat};
		my $best = $self->_best_possible($seat);
		next if $best < $lodged;
		next if $best == $lodged && !($best == $PRIORITY{win} && $self->_nearer($seat, $lodged_seat, $w->{from}));
		push @waiting, $seat;
	}
	return @waiting;
}

sub _seats_after {
	my ($self, $from) = @_;
	return map { ($from + $_) % 4 } 1 .. 3;
}

sub _distance { my ($self, $seat, $from) = @_; return ($seat - $from) % 4 }

sub _nearer {
	my ($self, $seat, $than, $from) = @_;
	return 1 unless defined $than;
	return $self->_distance($seat, $from) < $self->_distance($than, $from) ? 1 : 0;
}

sub _lodged_best {
	my ($self) = @_;
	my $w = $self->window;
	my ($best, $seat) = (0, undef);
	for my $s ($self->_seats_after($w->{from})) {
		my $a = $w->{answers}{$s} or next;
		next if !ref $a;
		my $p = $PRIORITY{ $a->{kind} };
		if ($p > $best || ($p == $best && $p == $PRIORITY{win} && $self->_nearer($s, $seat, $w->{from}))) {
			($best, $seat) = ($p, $s);
		}
	}
	return ($best, $seat);
}

sub _answer {
	my ($self, $seat, $move) = @_;
	my $w = $self->window or return $self->_refuse('no_window', $seat);
	my $kind = $move->{kind};
	return $self->_refuse('cannot_claim', $seat) unless $w->{may}{$seat};
	return $self->_refuse('already_answered', $seat) if exists $w->{answers}{$seat};

	my %waiting = map { $_ => 1 } $self->_window_waiting;
	if ($kind eq 'pass') {
		$w->{answers}{$seat} = 'pass';
	}
	else {
		return $self->_refuse('cannot_claim', $seat) unless $waiting{$seat};
		return $self->_refuse('cannot_claim', $seat) unless grep { $_ eq $kind } @{ $w->{may}{$seat} };
		my $answer = { kind => $kind };
		if ($kind eq 'chow') {
			my $tiles = $move->{tiles};
			return $self->_refuse('bad_move', $seat) unless ref $tiles eq 'ARRAY' && @$tiles == 2
				&& !grep { !defined $_ || !/\A\d+\z/ || $_ < 1 || $_ > Game::Mahjong::Tiles::KINDS } @$tiles;
			my ($a, $b) = sort { $a <=> $b } map { $_ + 0 } @$tiles;
			my $ok = grep { $_->[0] == $a && $_->[1] == $b } $self->hands->[$seat]->chow_shapes($w->{tile});
			return $self->_refuse('not_a_meld', $seat) unless $ok;
			$answer->{tiles} = [ $a, $b ];
		}
		$w->{answers}{$seat} = $answer;
	}
	$self->moves($self->moves + 1);
	$self->_emit($seat, $kind, ($kind eq 'chow' ? (tiles => $w->{answers}{$seat}{tiles}) : ()));

	return 1 if $self->_window_waiting;
	return $self->_resolve_window;
}

sub _resolve_window {
	my ($self) = @_;
	my $w = $self->window;
	my ($best, $seat) = $self->_lodged_best;
	my $answer = defined $seat ? $w->{answers}{$seat} : undef;
	return $self->_close_window_with($w->{kind}, $w->{tile}, $w->{from}, $seat, $answer);
}

sub _close_window_with {
	my ($self, $kind, $tile, $from, $seat, $answer) = @_;
	$self->window(undef);

	if (!defined $seat) {
		if ($kind eq 'rob') { return $self->_perform_promotion($from, $tile) }
		return $self->_draw_for($self->next_seat($from));
	}

	my $claim = $answer->{kind};
	if ($claim eq 'win') {
		my $tally = $self->_tally_on($seat, $tile, $kind eq 'rob' ? 'rob' : 'discard', $from);
		die 'Game::Mahjong::Rules: a lodged win that no longer scores' unless $tally;
		if ($kind eq 'rob') { $self->hands->[$from]->remove($tile) }
		else { pop @{ $self->pools->[$from] } }
		$self->hands->[$seat]->add($tile);
		$self->_emit('sys', 'claimed', seat => $seat, meld => 'win', tile => $tile, from => $from);
		return $self->_hand_won($seat, $tally, $kind eq 'rob' ? 'rob' : 'discard', $from, $tile);
	}

	pop @{ $self->pools->[$from] };
	my $hand = $self->hands->[$seat];
	if ($claim eq 'chow') { $hand->claim_chow($tile, @{ $answer->{tiles} }, $from) }
	elsif ($claim eq 'pung') { $hand->claim_pung($tile, $from) }
	elsif ($claim eq 'kong') { $hand->claim_kong($tile, $from) }
	$self->_emit('sys', 'claimed', seat => $seat, meld => $claim, tile => $tile, from => $from);
	$self->last({ seat => $seat, kind => $claim, tile => $tile, from => $from });

	if ($claim eq 'kong') { return $self->_replacement_draw($seat, 'kong') }
	$self->phase('discard');
	$self->turn($seat);
	$self->claimed_this_turn(1);
	$self->drawn(undef);
	$self->replacement(undef);
	return 1;
}

sub _perform_promotion {
	my ($self, $seat, $tile) = @_;
	$self->hands->[$seat]->promote_kong($tile);
	return $self->_replacement_draw($seat, 'kong');
}

sub _draw_for {
	my ($self, $seat) = @_;
	return $self->_exhausted if $self->wall->is_empty;
	my $kind = $self->wall->draw;
	$self->_emit('sys', 'drew', seat => $seat, from => 'wall');
	$self->last_draw_emptied($self->wall->is_empty ? 1 : 0);
	return $self->_took($seat, $kind, 'wall', undef);
}

sub _replacement_draw {
	my ($self, $seat, $why) = @_;
	return $self->_exhausted if $self->wall->is_empty;
	my $kind = $self->wall->replace;
	$self->_emit('sys', 'drew', seat => $seat, from => 'back');
	$self->last_draw_emptied($self->wall->is_empty ? 1 : 0);
	return $self->_took($seat, $kind, 'back', $why);
}

sub _took {
	my ($self, $seat, $kind, $from, $why) = @_;
	if (Game::Mahjong::Tiles::is_bonus($kind)) {
		$self->hands->[$seat]->add_flower($kind);
		$self->_emit('sys', 'flower', seat => $seat, tile => $kind);
		return $self->_replacement_draw($seat, 'flower');
	}
	$self->hands->[$seat]->add($kind);
	$self->drawn($kind);
	$self->drawn_from($from);
	$self->replacement($why);
	$self->claimed_this_turn(0);
	$self->phase('discard');
	$self->turn($seat);
	$self->last({ seat => $seat, kind => 'drew', from => $from });
	return 1;
}

sub _hand_won {
	my ($self, $seat, $tally, $by, $from, $tile) = @_;
	my $deltas = Game::Mahjong::Result::settle(winner => $seat, by => $by, from => $from, points => $tally->points);
	$self->_end_hand({
		winner  => $seat,
		by      => $by,
		from    => $from,
		tile    => $tile,
		fans    => [ map { { key => $_->{key}, points => $_->{points}, times => $_->{times} } } @{ $tally->fans } ],
		points  => $tally->points,
		flowers => $tally->flowers,
		deltas  => $deltas,
	});
	return 1;
}

sub _exhausted {
	my ($self) = @_;
	$self->_end_hand({ winner => undef, by => 'exhausted', from => undef, tile => undef, fans => [], points => 0, flowers => 0, deltas => [ 0, 0, 0, 0 ] });
	return 1;
}

sub _end_hand {
	my ($self, $record) = @_;
	my $totals = $self->totals;
	$totals->[$_] += $record->{deltas}[$_] for 0 .. 3;
	$record->{hand} = $self->hand_no;
	$record->{totals} = [ @$totals ];
	$record->{concealed_kongs} = [ map { [ map { $_->tile } @{ $self->hands->[$_]->concealed_kongs } ] } 0 .. 3 ];
	push @{ $self->history }, $record;
	$self->_emit('sys', 'hand_end', %$record);
	$self->window(undef);

	if (Game::Mahjong::Result::finished($self->hand_no)) {
		$self->status('finished');
		$self->phase('finished');
		$self->turn(undef);
		my $winner = Game::Mahjong::Result::winner($totals);
		$self->winner($winner);
		$self->result(defined $winner ? 'score' : 'draw');
		$self->_emit('sys', 'game_end', winner => $winner, result => $self->result,
			totals => [ @$totals ], places => Game::Mahjong::Result::places($totals));
		return;
	}
	$self->hand_no($self->hand_no + 1);
	$self->_deal;
	return;
}

sub check_invariants {
	my ($self) = @_;
	my @bad;
	return @bad unless $self->is_active;

	my %count;
	for my $seat (0 .. 3) {
		my $h = $self->hands->[$seat];
		$count{$_}++ for $h->tiles;
		$count{$_}++ for @{ $h->flowers };
		for my $m (@{ $h->melds }) { $count{$_}++ for @{ $m->tiles } }
		$count{$_}++ for @{ $self->pools->[$seat] };
	}
	$count{$_}++ for @{ $self->wall->peek };
	my $tiles = 0;
	$tiles += $_ for values %count;
	my $whole = $tiles == Game::Mahjong::Tiles::TILES;
	for my $kind (1 .. Game::Mahjong::Tiles::PATTERNS) {
		my $cap = Game::Mahjong::Tiles::is_bonus($kind) ? 1 : Game::Mahjong::Tiles::PER_KIND;
		my $seen = $count{$kind} || 0;
		push @bad, "kind $kind is seen $seen times, not $cap" if $whole && $seen != $cap;
		push @bad, "kind $kind is seen $seen times, more than the set holds" if !$whole && $seen > $cap;
	}

	my $on = $self->phase eq 'discard' ? $self->turn
	       : $self->phase eq 'rob' && $self->window ? $self->window->{from}
	       : undef;
	for my $seat (0 .. 3) {
		my $h = $self->hands->[$seat];
		my $want = (defined $on && $seat == $on) ? 14 : 13;
		push @bad, "seat $seat holds " . $h->total . " tiles' worth, not $want" unless $h->total == $want;
	}

	my $sum = 0;
	$sum += $_ for @{ $self->totals };
	push @bad, "totals sum to $sum" if $sum != 0;

	if ($self->phase eq 'discard') {
		my @w = $self->waiting_on;
		push @bad, 'discard phase waits on ' . scalar(@w) . ' seats' unless @w == 1;
		push @bad, 'a window is open in the discard phase' if $self->window;
	}
	elsif ($self->phase eq 'claim' || $self->phase eq 'rob') {
		my $w = $self->window;
		push @bad, 'no window in the ' . $self->phase . ' phase' unless $w;
		if ($w) {
			push @bad, 'the discarder is asked' if $w->{may}{ $w->{from} };
			for my $seat (keys %{ $w->{may} }) {
				push @bad, "seat $seat is asked with no claim" unless @{ $w->{may}{$seat} };
			}
			push @bad, 'a window with nobody left to answer' unless $self->_window_waiting;
		}
	}
	else { push @bad, 'phase ' . $self->phase . ' while active' }
	return @bad;
}

sub to_string {
	my ($self) = @_;
	return join "\n", map { "seat $_: " . $self->hands->[$_]->to_notation . ' | pool ' . Game::Mahjong::Notation::print(@{ $self->pools->[$_] }) } 0 .. 3;
}

1;

__END__

=head1 NAME

Game::Mahjong::Rules - the state of one game: the deal, the turns, the window, the sixteen hands

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $g = Game::Mahjong::Rules->new(seed => $bytes);
    my @events = $g->take_outcomes;          # the deal, its flowers and replacements
    my ($seat) = $g->waiting_on;             # the dealer, holding fourteen
    my @legal = $g->legal($seat);            # discards, kongs, a win
    my $r = $g->apply($seat, { kind => 'discard', tile => $kind });
    $r->error and warn $r->code;             # a refusal is an object, not an exception
    @events = $g->take_outcomes;             # the discard, and what the engine did next

=head1 DESCRIPTION

The rules of play under the competition rulebook, as a state machine over
four L<Game::Mahjong::Hand>s, a L<Game::Mahjong::Wall> and four discard
pools. Seats are 0 to 3, the dealer is seat C<(hand_no - 1) % 4>, play runs
counterclockwise (seat 0, 1, 2, 3), and a seat's wind is its distance from
the dealer. The engine prints nothing, reads nothing and never calls
C<rand>: everything that happens after a move is a function of the seed.

=head2 The turn

The seat on turn holds fourteen tiles' worth and is in the C<discard>
phase. It may discard, declare a kong (concealed with four in hand, or
promoted with an exposed pung and the fourth, never in a turn it came to by
a chow or pung claim, 3.6.8), or win on the fourteen it holds when the
scorer says eight or more.

=head2 The draw is not a move

After a window closes with no claim the next seat draws from the front of
the wall; after a kong, or when a drawn tile is a flower, the seat draws a
replacement from the back. None of that is a choice, so the engine does it
and reports it (C<drew>, C<flower>). A draw from an empty wall ends the hand
exhausted; the last tile of the wall is drawable and its discard may be
claimed (fans 44 and 45).

=head2 The window

A discard opens a window if any other seat can use it: win (its waits hold
the tile and the fourteen would score eight), kong (three in hand), pung (a
pair), or chow (the next seat only, with two tiles that run). Seats with
nothing are never asked. Each asked seat answers once: pass, or one of its
claims. A win beats a pung or kong, which beats a chow; among wins the
nearest seat after the discarder (3.7.1, 3.6.7, 3.7.2.4). C<waiting_on> is
the asked seats whose answer could still change the outcome, so a lodged
claim that nothing unanswered could beat closes the window at once, and a
seat made moot by a better claim is not waited on. A promoted kong opens the
same window for a robbing win (fan 47) and is performed only if nobody
takes it.

=head2 The end of a hand

A win is scored by L<Game::Mahjong::Score> with the context the rules know
(how, the winds, the waits, the last tile, the replacement, the flowers),
settled by L<Game::Mahjong::Result>, and recorded in C<history>; the deal
passes whatever happened (3.4.8) and the sixteenth hand ends the game.

=head2 Refusals are objects

C<apply> returns a L<Game::Mahjong::Error> for a move the rules refuse and
true for one they took. Only programmer error dies.

=head1 ATTRIBUTES

=head2 seed, hand_no, dealer, totals

The seed; the hand number, 1 to 16; the dealer's seat; the four running
totals.

=head2 wall, hands, pools

The L<Game::Mahjong::Wall>; the four L<Game::Mahjong::Hand>s; the four
discard pools, each the kinds discarded in order.

=head2 phase, turn, window

C<discard>, C<claim>, C<rob> or C<finished>; the seat on turn in the discard
phase, undef otherwise; the open window, C<< { kind, tile, from, may =>
{ seat => [claims] }, answers => { seat => 'pass' | { kind, tiles } } } >>.

=head2 drawn, drawn_from, replacement

The kind the seat on turn just drew, where from (C<wall> or C<back>), and
whether it was a replacement after a C<kong> or a C<flower>.

=head2 claimed_this_turn, last_draw_emptied, last_discard_is_last

Whether the seat on turn came to it by a chow or pung (no kong this turn);
whether the last draw emptied the wall; whether the last discard was the
tile that did.

=head2 status, winner, result, history, last, moves

C<active> or C<finished>; the winning seat or undef; C<score> or C<draw>;
one record per finished hand; the last thing that happened, for a view; a
count of player moves.

=head2 outcomes

The queue C<take_outcomes> drains.

=head2 position

A written position for tests: C<< { hands => [four notations], wall =>
[kinds], turn => seat, pools => [...], dealer, claimed_this_turn, drawn } >>.

=head1 METHODS

=head2 take_outcomes

The events since the last call, cleared: C<< { actor => 'sys' | seat, kind,
... } >>.

=head2 waiting_on

The seats whose action is awaited: one in the discard phase, the seats that
still matter in a window, none when finished.

=head2 legal

    my @moves = $g->legal($seat);

Every move the seat may make now: C<discard {tile}>, C<kong {tile}>,
C<win>, or in a window C<pass>, C<chow {tiles}>, C<pung>, C<kong>, C<win>.

=head2 apply

    my $r = $g->apply($seat, $move);

Takes the move or returns the refusal.

=head2 prevailing, round, seat_wind, next_seat, hand_of, pool_of, is_active

As named.

=head2 check_invariants

Strings naming what is broken, empty when sound: every tile somewhere
exactly once, thirteen between turns, totals summing to zero, one seat
waited on outside a window, a window asking only seats with a claim.

=head2 to_string

The four hands and pools in notation, for a failing test.

=head1 SEE ALSO

L<Game::Mahjong::Score>, L<Game::Mahjong::Result>, L<Game::Mahjong::Hand>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0.

=cut
