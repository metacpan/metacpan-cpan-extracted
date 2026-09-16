#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Dominoes::Layout;
use Game::Dominoes::Tile;

plan tests => 10;

sub tile { Game::Dominoes::Tile->of(@_) }
sub layout { Game::Dominoes::Layout->new }

subtest 'an empty table' => sub {
	plan tests => 6;

	my $l = layout();

	ok $l->is_empty, 'a new layout is empty';
	is $l->count, 0, 'with nothing on it';
	is_deeply [ $l->arms_open ], ['L'],
		'only L is open, which is where the opening tile goes by convention';
	is $l->spinner, undef, 'and there is no spinner';
	is $l->sides_covered, 0, 'so no sides are covered';
	is_deeply [ $l->ends ], [], 'and there are no ends';
};

subtest 'the opening tile is laid against nothing' => sub {
	plan tests => 7;

	my $l = layout();
	my $play = $l->place(tile(6, 4), 'L');

	ok $play->is_opening, 'the first play is an opening';
	is $play->matched, undef, 'it matched no face';
	is $play->showing, undef, 'and shows both of its own';
	ok !$play->spinner, '6-4 is not a double, so it is not the spinner';

	is_deeply [ sort { $a <=> $b } $l->open_ends ], [ 4, 6 ],
		'both its faces are open';
	is_deeply [ $l->arms_open ], [ 'L', 'R' ], 'and the line has two ends';

	# One tile is ONE end, not two, or its faces would be counted twice.
	my @ends = $l->ends;
	is scalar(@ends), 1, 'a single tile is one end, marked sole';
};

subtest 'a double opening is the spinner immediately' => sub {
	plan tests => 5;

	my $l = layout();
	my $play = $l->place(tile(5, 5), 'L');

	ok $play->spinner, 'the first double played is the spinner';
	is $l->spinner->stringify, '5-5', 'and the layout knows which tile it is';
	is $l->spinner_index, 0, 'sitting at the start of the line';

	is $l->sides_covered, 0,
		'a spinner laid as the opening tile covers neither of its sides';
	is_deeply [ $l->arms_open ], [ 'L', 'R' ],
		'so the perpendicular arms are still shut';
};

subtest 'the arms stay shut until both sides are covered' => sub {
	plan tests => 9;

	my $l = layout();
	$l->place(tile(5, 5), 'L');

	$l->place(tile(5, 2), 'L');
	is $l->sides_covered, 1, 'one tile against the spinner covers one side';
	is_deeply [ $l->arms_open ], [ 'L', 'R' ], 'the arms are still shut';
	is $l->spinner_index, 1, 'and the spinner moved right as the line grew left';
	is $l->spinner->stringify, '5-5', 'it is still the same tile';

	ok !$l->can_place(tile(5, 6), 'U'), 'a tile cannot go on a shut arm';
	ok !eval { $l->place(tile(5, 6), 'U'); 1 }, 'and placing on one dies';

	$l->place(tile(5, 3), 'R');
	is $l->sides_covered, 2, 'a tile on the other side covers the second';
	is_deeply [ $l->arms_open ], [ 'L', 'R', 'U', 'D' ], 'and the arms open';
	is $l->face_of('U'), 5, 'an empty arm shows the spinner own face';
};

subtest 'the worked example: the ends at every step' => sub {
	plan tests => 7;

	# The five step example from plan_game_dominoes/06-scoring.md, checked
	# here for the GEOMETRY only. What these ends are WORTH is Scoring's
	# question and is tested there.
	#
	# ends() is the scoring list and open_ends() is the legality list, and
	# they are deliberately different: an empty arm is somewhere a tile may
	# go, so it is in open_ends, but it is not an end that counts, so it is
	# not in ends.
	my $l = layout();
	my $faces = sub { [ sort { $a <=> $b } map { $_->{face} } $l->ends ] };

	$l->place(tile(5, 5), 'L');
	is_deeply $faces->(), [5],
		'1. the spinner alone is one end, and sole marks it';
	ok +($l->ends)[0]->{sole},
		'   so the scorer counts its pips once and not a face twice';

	$l->place(tile(5, 2), 'L');
	is_deeply $faces->(), [ 2, 5 ],
		'2. a 5-2 on one side leaves a two and the spinner still at an end';

	$l->place(tile(5, 3), 'R');
	is_deeply $faces->(), [ 2, 3 ],
		'3. a 5-3 on the other leaves two and three: the spinner is interior now';

	# The spinner stopping counting needs no rule of its own. It is simply
	# not at an end any more, which is the whole point of modelling the line
	# as one array.
	ok !(grep { $_->{tile}->is_double } $l->ends),
		'   and it is gone from the ends without a special case';

	$l->place(tile(5, 6), 'U');
	is_deeply $faces->(), [ 2, 3, 6 ], '4. an arm opens and adds a six';

	$l->place(tile(5, 4), 'D');
	is_deeply $faces->(), [ 2, 3, 4, 6 ], '5. and the last arm adds a four';
};

subtest 'open_ends is legality, ends is scoring' => sub {
	plan tests => 3;

	my $l = layout();
	$l->place(tile(5, 5), 'L');
	$l->place(tile(5, 2), 'L');
	$l->place(tile(5, 3), 'R');

	# Both arms are open and empty. A five may be played on either, so a five
	# is matchable; but an empty arm is not an end and contributes nothing.
	is_deeply [ sort { $a <=> $b } $l->open_ends ], [ 2, 3, 5, 5 ],
		'an empty arm offers the spinner face to match against';
	is_deeply [ sort { $a <=> $b } map { $_->{face} } $l->ends ], [ 2, 3 ],
		'but it is not an end, so it is not counted';
	ok $l->can_place(tile(5, 6), 'U'),
		'and a tile carrying that face really can go there';
};

subtest 'a spinner played onto a line that runs past it' => sub {
	plan tests => 8;

	# The case that breaks a model built from two arms growing out of a root:
	# the double lands partway along a line that already has tiles beyond it.
	my $l = layout();
	$l->place(tile(6, 4), 'L');
	$l->place(tile(4, 1), 'R');
	is $l->count, 2, 'a line of two, no spinner yet';
	is $l->spinner, undef, 'because no double has been played';

	my $play = $l->place(tile(6, 6), 'L');
	ok $play->spinner, 'the 6-6 is the first double, so it is the spinner';
	is $l->spinner_index, 0, 'it sits at the left end of the line';

	is $l->sides_covered, 1,
		'one side is covered already: the tile it was laid against is against it';
	is_deeply [ $l->arms_open ], [ 'L', 'R' ], 'so the arms are still shut';

	$l->place(tile(6, 3), 'L');
	is $l->sides_covered, 2, 'a tile on its free side covers the second';
	is $l->spinner_index, 1, 'and the spinner is interior, one in from the left';
};

subtest 'only the first double is a spinner' => sub {
	plan tests => 4;

	my $l = layout();
	$l->place(tile(5, 5), 'L');
	$l->place(tile(5, 3), 'L');
	$l->place(tile(5, 2), 'R');

	my $play = $l->place(tile(3, 3), 'L');
	ok !$play->spinner, 'a later double is not a spinner';
	is $l->spinner->stringify, '5-5', 'the first one keeps the job';
	is $l->spinner_index, 2, 'and its index tracked the line growing left';

	# A later double is laid crosswise and the line runs straight through it,
	# so it never blocks: the arm it is on is still open.
	is $l->face_of('L'), 3, 'the line continues through it, showing its face';
};

subtest 'matching' => sub {
	plan tests => 7;

	my $l = layout();
	$l->place(tile(6, 4), 'L');

	is $l->face_of('L'), 6, 'the left end shows a six';
	is $l->face_of('R'), 4, 'the right end shows a four';
	is $l->face_of('U'), undef, 'a shut arm shows nothing';

	ok $l->can_place(tile(6, 2), 'L'), 'a tile carrying a six goes on the left';
	ok !$l->can_place(tile(5, 2), 'L'), 'one that does not, does not';
	ok !$l->can_place(tile(6, 2), 'Z'), 'there is no arm Z';
	ok !$l->can_place(undef, 'L'), 'and nothing is not a tile';
};

subtest 'the pips on the table are part of the 168' => sub {
	plan tests => 3;

	my $l = layout();
	$l->place(tile(5, 5), 'L');
	$l->place(tile(5, 2), 'L');
	$l->place(tile(5, 3), 'R');

	is $l->count, 3, 'three tiles down';
	is $l->pips, 10 + 7 + 8, 'their pips add up';
	is scalar @{ $l->tiles }, 3, 'and tiles() lists every one of them';
};
