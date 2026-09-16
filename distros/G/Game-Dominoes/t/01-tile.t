#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes::Tile;

plan tests => 8;

subtest 'a tile has one representation' => sub {
	plan tests => 6;

	my $a = Game::Dominoes::Tile->of(4, 6);
	my $b = Game::Dominoes::Tile->of(6, 4);

	is $a->high, 6, 'of() sorts the faces, whichever way round they came';
	is $a->low, 4, 'and keeps the smaller as low';
	is $b->high, 6, 'the other order gives the same tile';
	is $b->low, 4, 'both faces agree';
	ok $a->equals($b), '4-6 and 6-4 are the same tile';
	is $a->stringify, '6-4', 'and print higher face first';
};

subtest 'the canonical numbering covers the set exactly once' => sub {
	plan tests => 5;

	my (%seen, @ids);
	for my $low (0 .. 6) {
		for my $high ($low .. 6) {
			my $tile = Game::Dominoes::Tile->new(high => $high, low => $low);
			push @ids, $tile->id;
			$seen{ $tile->id }++;
		}
	}

	is scalar(@ids), 28, 'a double six set holds 28 tiles';
	is scalar(keys %seen), 28, 'and 28 distinct ids';
	is_deeply [ sort { $a <=> $b } @ids ], [ 1 .. 28 ],
		'which are exactly 1 to 28 with no gap and no repeat';

	# The four corners of the numbering, derived by hand from the order
	# 0-0, 0-1 .. 0-6, 1-1 .. 1-6, 2-2 .. 6-6.
	is(Game::Dominoes::Tile->of(0, 0)->id, 1, '0-0 is first');
	is(Game::Dominoes::Tile->of(6, 6)->id, 28, '6-6 is last');
};

subtest 'from_id is the inverse of id' => sub {
	plan tests => 29;

	for my $id (1 .. 28) {
		my $tile = Game::Dominoes::Tile->from_id($id);
		is $tile->id, $id, "id $id round-trips through from_id";
	}

	# Hand-derived: the 0-row holds ids 1 to 7, so id 7 is 6-0.
	is(Game::Dominoes::Tile->from_id(7)->stringify, '6-0', 'id 7 is 6-0');
};

subtest 'doubles' => sub {
	plan tests => 4;

	ok(Game::Dominoes::Tile->of(5, 5)->is_double, '5-5 is a double');
	ok !Game::Dominoes::Tile->of(6, 4)->is_double, '6-4 is not';
	ok(Game::Dominoes::Tile->of(0, 0)->is_double, 'the double blank is a double');
	is scalar(grep { Game::Dominoes::Tile->from_id($_)->is_double } 1 .. 28), 7,
		'a double six set holds seven doubles';
};

subtest 'the set holds 168 pips' => sub {
	plan tests => 3;

	my $total = 0;
	$total += Game::Dominoes::Tile->from_id($_)->pips for 1 .. 28;

	# Pagat's mathematics page states 168, and it is hand-derivable as 7 x 24:
	# each of the seven faces appears eight times across the set, so the total
	# is 8 x (0+1+2+3+4+5+6) = 8 x 21 = 168.
	is $total, 168, 'the whole set holds 168 pips';

	is(Game::Dominoes::Tile->of(6, 4)->pips, 10, '6-4 is ten pips');
	is(Game::Dominoes::Tile->of(0, 0)->pips, 0, 'the double blank is none');
};

subtest 'matching a face' => sub {
	plan tests => 7;

	my $tile = Game::Dominoes::Tile->of(6, 4);

	ok $tile->has_face(6), '6-4 carries a six';
	ok $tile->has_face(4), 'and a four';
	ok !$tile->has_face(5), 'and not a five';
	ok !$tile->has_face(undef), 'an undefined face matches nothing';

	is $tile->other(6), 4, 'matching the six leaves the four showing';
	is $tile->other(4), 6, 'and matching the four leaves the six';

	is(Game::Dominoes::Tile->of(5, 5)->other(5), 5,
		'a double leaves itself, which is why a double at an end counts twice');
};

subtest 'the five opening tiles that score at once' => sub {
	plan tests => 2;

	# Cited: Wikipedia's Muggins article names 6-4, 5-5, 5-0, 4-1 and 3-2 as
	# the opening tiles whose pips are a multiple of five and so score
	# immediately. Hand-checked here: 10, 10, 5, 5, 5.
	#
	# 0-0 is deliberately absent. Its count of zero is arithmetically a
	# multiple of five and is not a score, and this list is the published
	# evidence for that.
	my @scoring = sort { $a <=> $b }
		map  { $_->id }
		grep { $_->pips > 0 && $_->pips % 5 == 0 }
		map  { Game::Dominoes::Tile->from_id($_) } 1 .. 28;

	my @expected = sort { $a <=> $b }
		map { Game::Dominoes::Tile->of(@$_)->id }
		([ 6, 4 ], [ 5, 5 ], [ 5, 0 ], [ 4, 1 ], [ 3, 2 ]);

	is scalar(@scoring), 5, 'exactly five tiles score as an opening lead';
	is_deeply \@scoring, \@expected, 'and they are 6-4, 5-5, 5-0, 4-1 and 3-2';
};

subtest 'programmer error dies, player error never reaches here' => sub {
	plan tests => 5;

	ok !eval { Game::Dominoes::Tile->new(high => 7, low => 0); 1 },
		'a face above six dies';
	ok !eval { Game::Dominoes::Tile->new(high => 3, low => -1); 1 },
		'a negative face dies';
	ok !eval { Game::Dominoes::Tile->new(high => 2, low => 5); 1 },
		'high below low dies rather than silently swapping';
	ok !eval { Game::Dominoes::Tile->from_id(29); 1 },
		'an id past the end of the set dies';
	ok !eval { Game::Dominoes::Tile->of(6, 4)->other(5); 1 },
		'asking for the other face of a face it does not carry dies';
};
