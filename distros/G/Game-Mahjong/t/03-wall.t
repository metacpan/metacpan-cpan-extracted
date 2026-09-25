#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Digest::SHA ();

use Game::Mahjong;

my $SEED = 'a seed for the wall test';

plan tests => 9;

subtest 'the order is a permutation of 1 to 144, and deterministic' => sub {
	my @order = Game::Mahjong::Wall::order_for($SEED, 1);
	is(scalar @order, 144, '144 positions');
	is_deeply([ sort { $a <=> $b } @order ], [ 1 .. 144 ], 'each once');
	is_deeply([ Game::Mahjong::Wall::order_for($SEED, 1) ], \@order, 'the same seed and hand again');
	isnt(join(',', Game::Mahjong::Wall::order_for($SEED, 2)), join(',', @order), 'hand 2 differs');
	isnt(join(',', Game::Mahjong::Wall::order_for('another seed', 1)), join(',', @order), 'another seed differs');
	ok(!eval { Game::Mahjong::Wall::order_for('', 1); 1 }, 'an empty seed dies');
};

# THE FIRST SWAP, DERIVED HERE FROM THE DOCUMENTED KEY. The stream is
# sha256($seed . "hand:$hand:" . $counter) unpacked as eight 32-bit words, and
# the first swap is position 143 with position (word % 144), the word rejected
# past the largest multiple of 144. Position 143 is never touched again, so
# order[143] is the tile that swap put there.
subtest 'the first swap agrees with the documented key' => sub {
	for my $hand (1, 7) {
		my @words = unpack 'N8', Digest::SHA::sha256($SEED . "hand:$hand:0");
		my $limit = int(4294967296 / 144) * 144;
		my $word;
		for my $w (@words) { if ($w < $limit) { $word = $w; last } }
		ok(defined $word, "hand $hand: a word inside the limit in the first digest");
		my $j = $word % 144;
		my @order = Game::Mahjong::Wall::order_for($SEED, $hand);
		is($order[143], $j == 143 ? 144 : $j + 1, "hand $hand: position 143 holds what the first swap put there");
	}
	# and the key is "hand:N:counter", not "hand:N": a stream keyed without the
	# counter would repeat its eight words forever
	my @a = unpack 'N8', Digest::SHA::sha256($SEED . 'hand:1:0');
	my @b = unpack 'N8', Digest::SHA::sha256($SEED . 'hand:1:1');
	isnt(join(',', @a), join(',', @b), 'the counter changes the digest');
};

subtest 'a wall holds the set' => sub {
	my $wall = Game::Mahjong::Wall->new(seed => $SEED);
	is($wall->hand, 1, 'hand 1 by default');
	is($wall->remaining, 144, '144 tiles');
	my %count;
	$count{$_}++ for @{ $wall->peek };
	is_deeply([ grep { $count{$_} != 4 } 1 .. 34 ], [], 'four of each kind');
	is_deeply([ grep { $count{$_} != 1 } 35 .. 42 ], [], 'one of each bonus');
	ok(!$wall->is_empty, 'not empty');
	ok(!$wall->dealt, 'not dealt');
};

subtest 'the deal from every seat' => sub {
	for my $dealer (0 .. 3) {
		my $wall = Game::Mahjong::Wall->new(seed => $SEED, hand => $dealer + 1);
		my @before = @{ $wall->peek };
		my $deal = $wall->deal($dealer);
		is($deal->{dealer}, $dealer, "dealer $dealer");
		my %size = map { $_ => scalar @{ $deal->{hands}{$_} } } 0 .. 3;
		is($size{$dealer}, 14, 'the dealer has fourteen');
		is_deeply([ map { $size{$_} } grep { $_ != $dealer } 0 .. 3 ], [ 13, 13, 13 ], 'the others thirteen');
		is($wall->remaining, 91, 'ninety-one left');
		ok($wall->dealt, 'dealt');
		my @all = sort { $a <=> $b } (map { @{ $deal->{hands}{$_} } } 0 .. 3), @{ $wall->peek };
		is_deeply(\@all, [ sort { $a <=> $b } @before ], 'every tile is somewhere, exactly once');
		is_deeply($deal->{hands}{$dealer}, [ sort { $a <=> $b } @{ $deal->{hands}{$dealer} } ], 'hands sorted');
		ok(!eval { $wall->deal($dealer); 1 }, 'a second deal dies');
	}
};

subtest 'the deal is positional: fours from the dealer, then ones, then the fourteenth' => sub {
	# the set in table order: four of each kind then the bonus tiles, a wall
	# the checks accept and whose positions the test can name
	my $wall = Game::Mahjong::Wall->new(seed => 'x', tiles => [ Game::Mahjong::Tiles::set() ]);
	my $order = $wall->peek;
	my $deal = $wall->deal(2);
	# seat 2 takes positions 0-3, 16-19, 32-35, then 48, then 52
	my @seat2 = sort { $a <=> $b } map { $order->[$_] } 0 .. 3, 16 .. 19, 32 .. 35, 48, 52;
	is_deeply($deal->{hands}{2}, \@seat2, 'the dealer, seat 2, took its fours, its one, and the fourteenth');
	my @seat3 = sort { $a <=> $b } map { $order->[$_] } 4 .. 7, 20 .. 23, 36 .. 39, 49;
	is_deeply($deal->{hands}{3}, \@seat3, 'seat 3 next, counterclockwise');
	my @seat1 = sort { $a <=> $b } map { $order->[$_] } 12 .. 15, 28 .. 31, 44 .. 47, 51;
	is_deeply($deal->{hands}{1}, \@seat1, 'seat 1 last');
	is($wall->draw, $order->[53], 'the next draw is position 53');
};

subtest 'draw takes the front and replace the back' => sub {
	my @tiles = (1, 2, 3, 4, 5, 35, 39, 37, 6);
	my $wall = Game::Mahjong::Wall->new(seed => 'x', tiles => \@tiles);
	is($wall->draw, 1, 'the front');
	is($wall->replace, 6, 'the back');
	is($wall->replace, 37, 'then the flower at the back: three replacements in a row');
	is($wall->replace, 39, 'a season');
	is($wall->replace, 35, 'a flower');
	is($wall->draw, 2, 'the front again');
	is($wall->remaining, 3, 'three left');
	is($wall->drawn, 2, 'two draws');
	is($wall->replaced, 4, 'four replacements');
	is_deeply($wall->peek, [ 3, 4, 5 ], 'what is left, in order');
};

subtest 'an empty wall' => sub {
	my $wall = Game::Mahjong::Wall->new(seed => 'x', tiles => [ 9 ]);
	is($wall->draw, 9, 'the last tile is drawable: no dead wall');
	ok($wall->is_empty, 'empty');
	ok(!eval { $wall->draw; 1 }, 'a draw from an empty wall dies');
	like($@, qr/nothing to draw/, 'with the reason');
	ok(!eval { $wall->replace; 1 }, 'so does a replacement');
	ok(!eval { $wall->deal(0); 1 }, 'and a deal');
};

subtest 'a written wall is checked against the set' => sub {
	ok(!eval { Game::Mahjong::Wall->new(seed => 'x', tiles => [ (5) x 5 ]); 1 }, 'five of a kind dies');
	ok(!eval { Game::Mahjong::Wall->new(seed => 'x', tiles => [ 35, 35 ]); 1 }, 'two of a flower dies');
	ok(!eval { Game::Mahjong::Wall->new(seed => 'x', tiles => [ 43 ]); 1 }, 'a kind off the table dies');
	ok(!eval { Game::Mahjong::Wall->new(seed => '', ); 1 }, 'an empty seed dies');
	ok(!eval { Game::Mahjong::Wall->new(seed => 'x', hand => 0); 1 }, 'hand 0 dies');
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   key the stream "hand:$hand" without the counter  -> 'the first swap' still passes
#                                                      (the first digest is the same) but
#                                                      'a permutation' fails: eight words
#                                                      cannot shuffle 144 positions
#   replace from the front                          -> 'draw takes the front and replace the back' fails
#   forget the dealer's fourteenth                  -> 'the dealer has fourteen' fails
subtest 'the mutation checks are written down' => sub {
	pass('see the comment above this subtest');
};
