#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use Game::Floppy;
use Game::Floppy::Test::Fly;

# THE START IS 0.08'S, IN PIXELS: a 516x400 field, the bird's centre at x 80
# and y int(400/2) - 24 = 176, no tubes, twenty ticks a second.

subtest 'the default field' => sub {
	my $game = Game::Floppy->new;
	is($game->width, 516, '516 wide');
	is($game->height, 400, '400 high');
	is($game->status, 'ready', 'ready');
	is_deeply($game->bird, { x => 80, y => 176, radius => 24, tilt => 0 }, 'the bird at (80,176), radius 24, level');
	is_deeply($game->tubes, [], 'no tubes');
	is($game->score, 0, 'no score');
	is($game->passed, 0, 'no tubes passed');
	is($game->ticks, 0, 'no ticks');
	is($game->result, undef, 'no result');
	is($game->error, undef, 'no error');
	for my $pair ([ bird_x => 80 ], [ bird_radius => 24 ], [ gravity => 3 ], [ lift => 30 ],
		[ tube_every => 100 ], [ tube_speed => 3 ], [ tube_width => 52 ], [ gap => 140 ], [ tube_score => 100 ]) {
		my ($name, $value) = @$pair;
		is($game->$name, $value, "$name is $value");
	}
};

subtest 'an odd height starts at a whole pixel' => sub {
	is(Game::Floppy->new(height => 401)->bird->{y}, 176, 'int(401/2) - 24 is 176, not 176.5');
	is(Game::Floppy->new(height => 402)->bird->{y}, 177, 'and 402 gives 177');
};

subtest 'the arguments are checked' => sub {
	for my $case (
		[ { height => 199 },        qr/at least 200 high/,         'a field under 200 high' ],
		[ { width => 132 },         qr/has no room for a tube/,    'a field with no room past the bird' ],
		[ { width => 'x' },         qr/width must be a whole/,     'a width that is not a number' ],
		[ { gravity => 0 },         qr/gravity is 1 or more/,      'no gravity' ],
		[ { gap => 0 },             qr/gap is 1 or more/,          'no gap' ],
		[ { seed => '' },           qr/a seed is a string/,        'an empty seed' ],
	) {
		my ($args, $why, $name) = @$case;
		my $game = eval { Game::Floppy->new(%$args) };
		like($@, $why, "$name is refused");
		is($game, undef, 'and nothing is built');
	}
	ok(Game::Floppy->new(width => 133), 'a field with exactly room for a tube is fine');
};

subtest 'an argument name the class does not know is dropped' => sub {
	my $game = Game::Floppy->new(widthz => 9, height => 300);
	is($game->width, 516, 'a misspelt width is dropped and the default stands');
	is($game->height, 300, 'while the spelt one beside it is taken');
};

subtest 'bird and tubes are copies' => sub {
	my $game = Game::Floppy->new;
	Game::Floppy::Test::Fly->advance($game, 100);
	my $bird = $game->bird;
	$bird->{y} = 0;
	isnt($game->bird->{y}, 0, 'writing on the bird copy changes nothing');
	my $tubes = $game->tubes;
	is(scalar @$tubes, 1, 'one tube at tick 100');
	$tubes->[0]{x} = 0;
	is($game->tubes->[0]{x}, 516, 'writing on a tube copy changes nothing');
};

done_testing();
