#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use Test::More;

use Game::Snake;
use Game::Snake::Bot;

# NO WINDOW, NO RAYLIB. The module must compile with no raylib installed
# (t/00 walks every .pm), and everything in it that does not need a window
# is tested here: the tile table against the old Head.pm, Tail.pm and
# Food.pm, the key table, the sheet, and what it says when raylib is absent.
# The picture itself is the gate's (plan_update_snake/06).

use_ok('Game::Snake::Raylib');
ok(!$INC{'Raylib/FFI.pm'}, 'loading the module did not load raylib');

subtest 'the tiles, from 0.11' => sub {
	my $t = 'Game::Snake::Raylib';
	is_deeply($t->tile_for('head', { dir => 'up' }),    [ 192, 0 ],  'head up');
	is_deeply($t->tile_for('head', { dir => 'right' }), [ 256, 0 ],  'head right');
	is_deeply($t->tile_for('head', { dir => 'left' }),  [ 192, 64 ], 'head left');
	is_deeply($t->tile_for('head', { dir => 'down' }),  [ 256, 64 ], 'head down');

	is_deeply($t->tile_for('body', { dir => 'up', last => 1, bend => 0 }),    [ 192, 128 ], 'tail up');
	is_deeply($t->tile_for('body', { dir => 'right', last => 1, bend => 0 }), [ 256, 128 ], 'tail right');
	is_deeply($t->tile_for('body', { dir => 'left', last => 1, bend => 0 }),  [ 192, 192 ], 'tail left');
	is_deeply($t->tile_for('body', { dir => 'down', last => 1, bend => 0 }),  [ 256, 192 ], 'tail down');
	is_deeply($t->tile_for('body', { dir => 'left', last => 1, bend => 'up' }), [ 192, 128 ],
		'a tail with a bend follows the bend, as Tail.pm did');

	is_deeply($t->tile_for('body', { dir => 'left', bend => 0 }),  [ 64, 0 ],   'straight horizontal');
	is_deeply($t->tile_for('body', { dir => 'right', bend => 0 }), [ 64, 0 ],   'either way');
	is_deeply($t->tile_for('body', { dir => 'up', bend => 0 }),    [ 128, 64 ], 'straight vertical');
	is_deeply($t->tile_for('body', { dir => 'down', bend => 0 }),  [ 128, 64 ], 'either way');

	my %bend = (
		'left:down' => [ 0, 0 ],     'up:right' => [ 0, 0 ],
		'right:down' => [ 128, 0 ],  'up:left' => [ 128, 0 ],
		'left:up' => [ 0, 64 ],      'down:right' => [ 0, 64 ],
		'right:up' => [ 128, 128 ],  'down:left' => [ 128, 128 ],
	);
	for my $pair (sort keys %bend) {
		my ($dir, $bend) = split /:/, $pair;
		is_deeply($t->tile_for('body', { dir => $dir, bend => $bend }), $bend{$pair}, "bend $pair");
	}
	is_deeply($t->tile_for('body', { dir => 'left', bend => 'right' }), [ 64, 0 ],
		'an impossible pair falls back to the straight tile');

	is_deeply($t->tile_for('food'), [ 0, 192 ], 'food');

	my $tiles = $t->tiles;
	my @offsets;
	for my $kind (qw/ head tail body bend /) {
		push @offsets, values %{ $tiles->{$kind} };
	}
	push @offsets, $tiles->{food};
	for my $tile (@offsets) {
		ok($tile->[0] % 64 == 0 && $tile->[1] % 64 == 0 && $tile->[0] < 320 && $tile->[1] < 256,
			"tile $tile->[0],$tile->[1] is on a 64 grid inside 320x256");
	}
};

subtest 'every segment a long game produces has a tile' => sub {
	my $game = Game::Snake->new(cols => 20, rows => 14, seed => 'tiles');
	my %seen;
	while ($game->status ne 'finished' && $game->ticks < 3000) {
		my $segments = $game->segments;
		for my $i (0 .. $#$segments) {
			my $segment = $segments->[$i];
			my $kind = $i == 0 ? 'head' : 'body';
			my $tile = Game::Snake::Raylib->tile_for($kind, $segment);
			$seen{"$kind:$segment->{dir}:$segment->{bend}:$segment->{last}"} = $tile ? 1 : 0;
		}
		my $direction = Game::Snake::Bot->choose($game, level => 2);
		$game->turn($direction) if $direction ne $game->heading;
		$game->tick;
	}
	my @without = grep { !$seen{$_} } sort keys %seen;
	is_deeply(\@without, [], 'no segment shape without a tile') or diag explain \@without;
	cmp_ok(scalar keys %seen, '>', 15, scalar(keys %seen) . ' shapes were seen');
};

subtest 'the keys' => sub {
	my $t = 'Game::Snake::Raylib';
	is($t->key_for(265), 'up', 'the up arrow');
	is($t->key_for(264), 'down', 'down');
	is($t->key_for(263), 'left', 'left');
	is($t->key_for(262), 'right', 'right');
	is($t->key_for(87), 'up', 'w');
	is($t->key_for(72), 'left', 'h');
	is($t->key_for(81), 'quit', 'q');
	is($t->key_for(256), 'quit', 'escape');
	is($t->key_for(80), 'pause', 'p');
	is($t->key_for(32), 'pause', 'space');
	is($t->key_for(257), 'again', 'enter');
	is($t->key_for(0), undef, 'no key');
	is($t->key_for(999), undef, 'an unknown code');
	is($t->key_for(undef), undef, 'undef');
};

subtest 'the sheet' => sub {
	my $sheet = Game::Snake::Raylib->sheet;
	like($sheet, qr{resources/snake-graphics\.png\z}, 'ends in resources/snake-graphics.png');
	ok(-f $sheet, 'and is there');
	cmp_ok(-s $sheet, '>', 1000, 'with something in it');
};

subtest 'when raylib is absent' => sub {
	local @INC = ("$FindBin::Bin/lib/absent", @INC);
	local %INC = %INC;
	delete $INC{'Raylib/FFI.pm'};
	delete $INC{'Raylib/Color.pm'};
	is(Game::Snake::Raylib->available, 0, 'not available');
	like(Game::Snake::Raylib->why_not, qr/Raylib::FFI/, 'the reason names Raylib::FFI');
	unlike(Game::Snake::Raylib->why_not, qr/ at \S+ line \d+/, 'with no file and line');
	unlike(Game::Snake::Raylib->why_not, qr/\n/, 'on one line');
	my $window = Game::Snake::Raylib->new(cols => 10, rows => 8, seed => 'absent');
	is($window->start, undef, 'and start returns nothing without trying to open a window');
};

subtest 'the arguments' => sub {
	my $w = Game::Snake::Raylib->new(seed => 'args');
	is($w->game->cols, 40, 'the default board is 40');
	is($w->game->rows, 28, 'by 28');
	is($w->cell, 20, 'a 20 pixel cell');
	is($w->top, 24, 'under a 24 pixel band');
	is($w->fps, 60, 'at 60 frames a second');
	is($w->level, 2, 'the bot at the top rung');
	is($w->high, 0, 'no high score yet');
	for my $case (
		[ { level => 7 },   qr/a level is one of 1 2/,      'a level off the ladder' ],
		[ { cell => 2 },    qr/a cell is at least 4 pixels/, 'a cell too small to see' ],
		[ { fps => 0 },     qr/frame rate is at least 1/,   'no frames' ],
		[ { cols => 'x' },  qr/cols must be a whole number/, 'a width that is not a number' ],
		[ { cols => 4 },    qr/at least 6 by 6/,            'a board the engine refuses' ],
	) {
		my ($args, $why, $name) = @$case;
		my $bad = eval { Game::Snake::Raylib->new(seed => 'bad', %$args) };
		like($@, $why, "$name is refused");
	}
};

done_testing();
