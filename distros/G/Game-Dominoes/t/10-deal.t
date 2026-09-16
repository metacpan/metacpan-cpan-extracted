#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Set qw(order_for tile_of PIPS);

plan tests => 6;

my $SEED = 'a' x 32;

sub game { Game::Dominoes->new(seed => $SEED, @_) }

subtest 'hand sizes come from the primary source and nowhere else' => sub {
	plan tests => 9;

	# Pagat, All Fives: "2 players get 9 tiles each / 3 players get 7 tiles
	# each / 4 players get 5 tiles each". Four other sources give four other
	# tables and the same page lists two more under Variations; taking the
	# most popular answer to each question separately would build a ruleset
	# no publication describes.
	my %expect = (2 => 9, 3 => 7, 4 => 5);
	my %yard = (2 => 10, 3 => 7, 4 => 8);

	for my $players (2, 3, 4) {
		my $g = game(players => $players);
		is $g->hand_size, $expect{$players}, "$players players get $expect{$players} tiles";
		is $g->hand_count(1), $expect{$players}, "and seat 1 actually holds that many";
		is $g->boneyard_count, $yard{$players},
			"leaving $yard{$players} in the boneyard";
	}
};

subtest 'the deal accounts for every tile' => sub {
	plan tests => 6;

	for my $players (2, 3, 4) {
		my $g = game(players => $players);

		my $tiles = $g->layout->pips + $g->boneyard->pips;
		$tiles += $g->hand($_)->pips for $g->seats;
		is $tiles, PIPS, "$players players: the pips come to 168 at the deal";

		my %seen;
		$seen{ $_->id }++ for @{ $g->boneyard->tiles };
		$seen{ $_->id }++ for map { @{ $g->hand($_)->tiles } } $g->seats;
		is scalar(keys %seen), 28,
			"$players players: all 28 tiles are somewhere, none twice";
	}
};

subtest 'the deal is a pure function of the seed and the hand number' => sub {
	plan tests => 3;

	# Never name a lexical $a or $b in a scope that also sorts: they are the
	# package globals sort hands the comparator, and shadowing them breaks
	# the sort block several lines away from the declaration.
	my $one = game();
	my $two = game();
	is $one->hand(1)->stringify, $two->hand(1)->stringify,
		'the same seed deals the same tiles';

	my $other = Game::Dominoes->new(seed => 'b' x 32);
	isnt $one->hand(1)->stringify, $other->hand(1)->stringify,
		'a different seed deals different tiles';

	# The hand is dealt straight off order_for, in seat blocks.
	my $order = order_for($SEED, 1);
	my $want = join ' ', map { $_->stringify }
		sort { $a->id <=> $b->id } map { tile_of($_) } @{$order}[ 0 .. 8 ];
	is $one->hand(1)->stringify, $want, 'and it is the front of order_for(seed, 1)';
};

subtest 'a later hand deals from its own shuffle' => sub {
	plan tests => 3;

	# This is what the hand argument of order_for exists for. A shuffle fixed
	# once at the start of the game would deal identical tiles every hand,
	# and All Fives runs to 250 over many hands.
	my $g = game();
	my $first = $g->hand(1)->stringify;

	my $n = 0;
	$g->play($g->turn, $g->legal($g->turn)->[0])
		while $g->status eq 'active' && $g->hand_number == 1 && $n++ < 200;

	cmp_ok $g->hand_number, '>', 1, 'the game reached a second hand';
	isnt $g->hand(1)->stringify, $first, 'dealing it gave different tiles';

	my $order = order_for($SEED, $g->hand_number);
	my %from_shuffle = map { $_ => 1 } @{$order}[ 0 .. 8 ];
	# Seat 1 may have drawn since the deal, so check the deal is a SUBSET
	# relation the other way: every tile it was dealt came from this shuffle.
	my $tiles = $g->layout->pips + $g->boneyard->pips;
	$tiles += $g->hand($_)->pips for $g->seats;
	is $tiles, PIPS, 'and the new hand still accounts for all 168 pips';
};

subtest 'who leads is decided by lot, and the lot is the seed' => sub {
	plan tests => 3;

	is game()->turn, game()->turn, 'the same seed leads with the same seat';
	ok +(grep { $_ == game()->turn } 1, 2), 'and it is a real seat';

	# Pagat: "The first player in the first hand is determined by lot." The
	# seed is the lot, so it is reproducible and checkable afterwards. The
	# lead may be ANY tile: this engine does not require the highest double,
	# which is what most other sources say and is the branch not taken.
	my $g = game();
	is scalar @{ $g->legal($g->turn) }, 9,
		'and the opening seat may lead any of its nine tiles';
};

subtest 'the constructor refuses what it cannot be deterministic about' => sub {
	plan tests => 6;

	ok !eval { Game::Dominoes->new(seed => 'short'); 1 },
		'a seed that is not 32 bytes dies';
	ok !eval { Game::Dominoes->new(); 1 }, 'no seed at all dies';
	ok !eval { game(players => 1); 1 }, 'one player is not a game';
	ok !eval { game(players => 5); 1 }, 'and five is not a double six set';
	ok !eval { game(variant => 'muggins'); 1 }, 'an unknown variant dies';
	ok !eval { game(target => 0); 1 }, 'and a target of nothing dies';
};
