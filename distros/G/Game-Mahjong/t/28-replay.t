#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Mahjong;
use Play;

# A game is its seed and its player moves. The same seed fed the same moves
# gives the same outcomes and the same state, which is what the adapter's
# replay leans on; a log with a move the rules refuse is refused.

sub event_string {
	my ($e) = @_;
	return join '|', map { "$_=" . (ref $e->{$_} eq 'ARRAY' ? join(',', map { ref $_ ? '{..}' : $_ } @{ $e->{$_} }) : ref $e->{$_} ? '{..}' : ($e->{$_} // '')) } sort keys %$e;
}

plan tests => 4;

my @moves;
my ($g, $bad, $census) = Play::play_game(seed => 'replay', default => Play::eager_chooser(Play::new_rng('replay')),
	on_move => sub { my ($rules, $seat, $move) = @_; push @moves, [ $seat, { %$move } ] }, stop_after => 400);
is_deeply($bad, [], 'the game ran') or diag join "\n", @$bad;
my @first = map { event_string($_) } @{ $census->{events} };

subtest 'the same seed and moves give the same outcomes' => sub {
	my $again = Game::Mahjong::Rules->new(seed => 'replay');
	my @events = $again->take_outcomes;
	for my $m (@moves) {
		my ($seat, $move) = @$m;
		my $r = $again->apply($seat, $move);
		die "refused on replay: " . $r->code if ref $r && $r->can('error');
		push @events, $again->take_outcomes;
	}
	is(scalar @events, scalar @first, 'the same number of outcomes');
	is_deeply([ map { event_string($_) } @events ], \@first, 'every outcome identical');
	is($again->to_string, $g->to_string, 'the same position');
	is_deeply($again->totals, $g->totals, 'the same totals');
	is($again->hand_no, $g->hand_no, 'the same hand');
};

subtest 'another seed differs' => sub {
	my $other = Game::Mahjong::Rules->new(seed => 'replay-2');
	isnt($other->to_string, Game::Mahjong::Rules->new(seed => 'replay')->to_string, 'a different deal');
};

subtest 'a forged move is refused on replay' => sub {
	my $again = Game::Mahjong::Rules->new(seed => 'replay');
	$again->take_outcomes;
	my ($seat, $move) = @{ $moves[0] };
	my $forged = { %$move };
	# the first move is the dealer's discard; forge a tile the dealer does not hold
	my $hand = $again->hand_of($seat);
	my ($absent) = grep { !$hand->count($_) } 1 .. 34;
	$forged->{tile} = $absent;
	my $r = $again->apply($seat, $forged);
	ok(ref $r && $r->error, 'refused');
	is($r->code, 'tile_not_held', 'by name');
	my $wrong_seat = $again->apply(($seat + 1) % 4, $move);
	is($wrong_seat->code, 'not_your_turn', 'and a move from the wrong seat');
};
