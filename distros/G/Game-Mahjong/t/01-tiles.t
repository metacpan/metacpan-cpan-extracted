#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

# THE TABLE, WRITTEN HERE FROM THE RULEBOOK AND NOT FROM mahjong_tiles.c.
#
# 3.5.5.1: "There are 108 numbered suit tiles divided into 3 suits ... 28
# Honor Tiles divided into 2 suits. Winds: East, West, South, North ...
# Dragons: White, Green, and Red ... Flowers ... There is only 1 of each
# flower tile for a total of 8 tiles." A terminal is a one or a nine (3.4.16).
# The green set is fan 3's: "2 Bam, 3 Bam, 4 Bam, 6 Bam, 8 Bam, and Green
# Dragon". The reversible set is fan 40's: "1, 2, 3,4,5,8, and 9 Dots, the 2,
# 4,5,6,8, and 9 Bams, and the White Dragon".

my @EXPECT;    # index = kind id; [ code, suit letter or undef, rank or undef, { flag => 1 } ]
my $id = 0;
for my $suit (qw(m p s)) {
	for my $rank (1 .. 9) {
		my %f = (suit => 1, ($rank == 1 || $rank == 9) ? (terminal => 1) : (simple => 1));
		$EXPECT[++$id] = [ "$suit$rank", $suit, $rank, \%f ];
	}
}
$EXPECT[++$id] = [ $_, undef, undef, { honour => 1, wind => 1 } ] for qw(we ws ww wn);
$EXPECT[++$id] = [ $_, undef, undef, { honour => 1, dragon => 1 } ] for qw(dr dg dw);
$EXPECT[++$id] = [ $_, undef, undef, { bonus => 1, flower => 1 } ] for qw(f1 f2 f3 f4);
$EXPECT[++$id] = [ $_, undef, undef, { bonus => 1, season => 1 } ] for qw(t1 t2 t3 t4);

my %GREEN      = map { $_ => 1 } qw(s2 s3 s4 s6 s8 dg);
my %REVERSIBLE = map { $_ => 1 } qw(p1 p2 p3 p4 p5 p8 p9 s2 s4 s5 s6 s8 s9 dw);

my @PREDICATES = qw(suit honour wind dragon terminal simple bonus flower season green reversible);

plan tests => 11;

subtest 'the ABI door is open' => sub {
	is(Game::Mahjong::Tiles::_abi_version(), 1, 'ABI version 1');
	is(Game::Mahjong::Tiles::_abi_kinds(), 42, 'forty-two patterns in the C table');
	ok(Game::Mahjong::Tiles::_abi_ptr() > 0, 'and the table has an address');
};

subtest 'the constants agree with the table and the set' => sub {
	is(Game::Mahjong::Tiles::PATTERNS, 42, 'PATTERNS');
	is(Game::Mahjong::Tiles::KINDS, 34, 'KINDS');
	is(Game::Mahjong::Tiles::BONUS, 8, 'BONUS');
	is(Game::Mahjong::Tiles::PER_KIND, 4, 'PER_KIND');
	is(Game::Mahjong::Tiles::TILES, 144, 'TILES');
	is(Game::Mahjong::Tiles::KINDS + Game::Mahjong::Tiles::BONUS, Game::Mahjong::Tiles::PATTERNS,
		'and 34 + 8 = 42');
	is(Game::Mahjong::Tiles::KINDS * Game::Mahjong::Tiles::PER_KIND + Game::Mahjong::Tiles::BONUS,
		Game::Mahjong::Tiles::TILES, 'and 34 * 4 + 8 = 144');
	is(scalar @EXPECT - 1, 42, 'the hand-written table has forty-two rows');
};

subtest 'the set is 144 tiles, counted' => sub {
	my @set = Game::Mahjong::Tiles::set();
	is(scalar @set, 144, '144 tiles');
	my %count;
	$count{$_}++ for @set;
	is(scalar keys %count, 42, 'of forty-two kinds');
	is_deeply([ grep { $count{$_} != 4 } 1 .. 34 ], [], 'four of every kind 1 to 34');
	is_deeply([ grep { $count{$_} != 1 } 35 .. 42 ], [], 'one of every bonus kind');
	is_deeply([ Game::Mahjong::Tiles::kinds() ], [ 1 .. 34 ], 'kinds');
	is_deeply([ Game::Mahjong::Tiles::patterns() ], [ 1 .. 42 ], 'patterns');
};

subtest 'every code round-trips' => sub {
	for my $kind (1 .. 42) {
		my $code = Game::Mahjong::Tiles::code_of($kind);
		is($code, $EXPECT[$kind][0], "$kind is $EXPECT[$kind][0]");
		is(Game::Mahjong::Tiles::id_of($code), $kind, "and $code is $kind");
	}
};

subtest 'suit and rank' => sub {
	for my $kind (1 .. 42) {
		my ($code, $suit, $rank) = @{ $EXPECT[$kind] };
		is(Game::Mahjong::Tiles::suit_of($kind), $suit, "$code suit");
		is(Game::Mahjong::Tiles::rank_of($kind), $rank, "$code rank");
	}
};

subtest 'every predicate against the hand-written table' => sub {
	for my $kind (1 .. 42) {
		my ($code, undef, undef, $flags) = @{ $EXPECT[$kind] };
		my %want = %$flags;
		$want{green}      = 1 if $GREEN{$code};
		$want{reversible} = 1 if $REVERSIBLE{$code};
		for my $p (@PREDICATES) {
			no strict 'refs';
			my $got = &{"Game::Mahjong::Tiles::is_$p"}($kind);
			is($got, $want{$p} ? 1 : 0, "$code is_$p");
		}
	}
	my @kinds = 1 .. 42;
	is(scalar(grep { Game::Mahjong::Tiles::is_terminal($_) } @kinds), 6, 'six terminal kinds');
	is(scalar(grep { Game::Mahjong::Tiles::is_simple($_) } @kinds), 21, 'twenty-one simple kinds');
	is(scalar(grep { Game::Mahjong::Tiles::is_honour($_) } @kinds), 7, 'seven honour kinds');
	is(scalar(grep { Game::Mahjong::Tiles::is_bonus($_) } @kinds), 8, 'eight bonus kinds');
	is(scalar(grep { Game::Mahjong::Tiles::is_green($_) } @kinds), 6, 'six green kinds');
	is(scalar(grep { Game::Mahjong::Tiles::is_reversible($_) } @kinds), 14,
		'fourteen reversible kinds: seven dots, six bamboo, the white dragon');
	is(scalar(grep { Game::Mahjong::Tiles::is_suit($_) } @kinds), 27, 'twenty-seven suit kinds');
};

subtest 'the order is part of the interface' => sub {
	is(Game::Mahjong::Tiles::suit_of(9), 'm', 'nine of characters');
	is(Game::Mahjong::Tiles::suit_of(10), 'p', 'and 10 is the one of dots, not a character');
	is(Game::Mahjong::Tiles::next_in_suit(5), 6, 'm5 + 1 is m6');
	is(Game::Mahjong::Tiles::next_in_suit(9), undef, 'm9 has no next in suit');
	is(Game::Mahjong::Tiles::next_in_suit(18), undef, 'nor p9');
	is(Game::Mahjong::Tiles::next_in_suit(28), undef, 'nor a wind');
	for my $kind (1 .. 26) {
		next unless Game::Mahjong::Tiles::rank_of($kind) < 9;
		is(Game::Mahjong::Tiles::suit_of($kind + 1), Game::Mahjong::Tiles::suit_of($kind),
			Game::Mahjong::Tiles::code_of($kind) . ' + 1 is the same suit');
		is(Game::Mahjong::Tiles::rank_of($kind + 1), Game::Mahjong::Tiles::rank_of($kind) + 1,
			'and the next rank');
	}
};

subtest 'the indices' => sub {
	is_deeply([ map { Game::Mahjong::Tiles::wind_index($_) } 28 .. 31 ], [ 0, 1, 2, 3 ],
		'east south west north');
	is_deeply([ map { Game::Mahjong::Tiles::dragon_index($_) } 32 .. 34 ], [ 0, 1, 2 ],
		'red green white');
	is_deeply([ map { Game::Mahjong::Tiles::bonus_index($_) } 35 .. 42 ], [ 0 .. 3, 0 .. 3 ],
		'the flowers and the seasons');
	is(Game::Mahjong::Tiles::wind_index(5), undef, 'a suit tile has no wind index');
	is(Game::Mahjong::Tiles::dragon_index(28), undef, 'a wind has no dragon index');
	is(Game::Mahjong::Tiles::bonus_index(1), undef, 'a suit tile has no bonus index');
	ok(Game::Mahjong::Tiles::flags_of(20) & Game::Mahjong::Tiles::flags_of(33),
		'the flag words share the green bit between s2 and the green dragon');
};

subtest 'the English' => sub {
	is(Game::Mahjong::Tiles::name_of(5), 'five of characters', 'm5');
	is(Game::Mahjong::Tiles::name_of(10), 'one of dots', 'p1');
	is(Game::Mahjong::Tiles::name_of(27), 'nine of bamboo', 's9');
	is(Game::Mahjong::Tiles::name_of(28), 'east wind', 'we');
	is(Game::Mahjong::Tiles::name_of(34), 'white dragon', 'dw');
	is(Game::Mahjong::Tiles::name_of(35), 'plum', 'f1');
	is(Game::Mahjong::Tiles::name_of(37), 'bamboo', 'f3, the rulebook order');
	is(Game::Mahjong::Tiles::name_of(38), 'chrysanthemum', 'f4');
	is(Game::Mahjong::Tiles::name_of(42), 'winter', 't4');
	is(Game::Mahjong::Tiles::suit_name('p'), 'dots', 'suit_name');
	my %seen;
	$seen{ Game::Mahjong::Tiles::name_of($_) }++ for 1 .. 42;
	is(scalar keys %seen, 42, 'forty-two distinct names');
};

subtest 'a number off the table dies' => sub {
	for my $bad (0, 43, -1, 'x', undef) {
		my $shown = defined $bad ? $bad : 'undef';
		ok(!eval { Game::Mahjong::Tiles::code_of($bad); 1 }, "code_of($shown) dies");
		like($@, qr/Game::Mahjong::Tiles/, 'with the module named');
	}
	ok(!eval { Game::Mahjong::Tiles::id_of('zz'); 1 }, "id_of('zz') dies");
	like($@, qr/there is no tile 'zz'/, 'naming the code');
	ok(!eval { Game::Mahjong::Tiles::id_of('m10'); 1 }, "id_of('m10') dies");
	ok(!eval { Game::Mahjong::Tiles::id_of(undef); 1 }, 'id_of(undef) dies');
	ok(!eval { Game::Mahjong::Tiles::is_green(43); 1 }, 'is_green(43) dies');
	ok(!eval { Game::Mahjong::Tiles::suit_name('x'); 1 }, "suit_name('x') dies");
};

# THE MUTATION CHECKS, named so they can be run by hand:
#   drop s6 from the green row in mahjong_tiles.c   -> 'six green kinds' and 's6 is_green' fail
#   change PER_KIND to 3 in Tiles.pm                -> '34 * 4 + 8 = 144' and '144 tiles' fail
#   swap the order of we and ws in the C table      -> 'east south west north' and '28 is we' fail
subtest 'the mutation checks are written down' => sub {
	pass('see the comment above this subtest');
};
