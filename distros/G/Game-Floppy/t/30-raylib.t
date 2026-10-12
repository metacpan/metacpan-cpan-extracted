#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use Test::More;

use Game::Floppy;

# NO WINDOW, NO RAYLIB. The module must compile with no raylib installed
# (t/00 walks every .pm), and everything in it that does not need a window is
# tested here: the bird's frames and their sheet rectangles, where the pipes
# are drawn (0.08's positions, 20 px inside the collision gap), the keys, the
# three sprites and their sizes read from the PNG headers, and what it says
# when raylib is absent. The picture itself is the gate's.

use_ok('Game::Floppy::Raylib');
ok(!$INC{'Raylib/FFI.pm'}, 'loading the module did not load raylib');

my $r = 'Game::Floppy::Raylib';

subtest 'the bird frames' => sub {
	is_deeply([ map { $r->frame_for($_) } 0 .. 9 ], [ 0, 1, 2, 3, 0, 1, 2, 3, 0, 1 ], 'four frames cycled a tick');
	is_deeply($r->source_for(0), [ 0, 0, 34, 24 ], 'frame 0 is the first 34x24 of the sheet');
	is_deeply($r->source_for(1), [ 34, 0, 34, 24 ], 'frame 1 the second');
	is_deeply($r->source_for(3), [ 102, 0, 34, 24 ], 'frame 3 the last');
	is_deeply($r->source_for(4), [ 0, 0, 34, 24 ], 'and a fifth wraps');
};

subtest 'where the pipes are drawn' => sub {
	my $at = $r->pipe_at({ x => 300, gap_top => 150, gap_bottom => 290 });
	is_deeply($at->{top}, [ 352, 170, 180 ], 'the top pipe at (x + 52, gap_top + 20), rotated 180 about that corner');
	is_deeply($at->{bottom}, [ 300, 270, 0 ], 'the bottom pipe at (x, gap_bottom - 20), upright');
	is($r->inset, 20, 'the inset is 20, as 0.08 drew it');
	is($at->{bottom}[1] - $at->{top}[1], 100, 'so the drawn gap is 100 over a collision gap of 140');
};

subtest 'the keys' => sub {
	is($r->key_for(32), 'flap', 'space');
	is($r->key_for(265), 'flap', 'up');
	is($r->key_for(257), 'flap', 'enter');
	is($r->key_for(87), 'flap', 'w');
	is($r->key_for(75), 'flap', 'k');
	is($r->key_for(80), 'pause', 'p');
	is($r->key_for(81), 'quit', 'q');
	is($r->key_for(256), 'quit', 'escape');
	is($r->key_for(264), undef, 'down does nothing');
	is($r->key_for(0), undef, 'no key');
	is($r->key_for(undef), undef, 'undef');
};

sub png_size {
	my ($path) = @_;
	open my $fh, '<:raw', $path or return;
	read $fh, my $header, 24;
	return unpack 'x16 N N', $header;
}

subtest 'the sprites' => sub {
	for my $case ([ background => 'background-day.png', 288, 512 ], [ bird => 'bluebird.png', 136, 24 ], [ pipe => 'pipe-green.png', 52, 320 ]) {
		my ($name, $file, $w, $h) = @$case;
		my $path = $r->sheet($name);
		like($path, qr{resources/\Q$file\E\z}, "$name is $file");
		ok(-f $path, 'and is there');
		is_deeply([ png_size($path) ], [ $w, $h ], "and is ${w}x$h by its header");
		is_deeply($r->sprite_size($name), [ $w, $h ], 'which is the size the module believes');
	}
	ok(!-f "$FindBin::Bin/../lib/Game/Floppy/resources/bluebird-upflap.png", 'the sprite 0.08 never drew is gone');
	my $bad = eval { $r->sheet('cat') };
	like($@, qr/'cat' is not a sprite/, 'an unknown sprite dies');
};

subtest 'when raylib is absent' => sub {
	local @INC = ("$FindBin::Bin/lib/absent", @INC);
	local %INC = %INC;
	delete $INC{'Raylib/FFI.pm'};
	delete $INC{'Raylib/Color.pm'};
	is($r->available, 0, 'not available');
	like($r->why_not, qr/Raylib::FFI/, 'the reason names Raylib::FFI');
	unlike($r->why_not, qr/ at \S+ line \d+/, 'with no file and line');
	unlike($r->why_not, qr/\n/, 'on one line');
	my $window = $r->new(seed => 'absent');
	is($window->start, undef, 'and start returns nothing without trying to open a window');
};

subtest 'the arguments' => sub {
	my $w = $r->new(seed => 'args');
	is($w->game->width, 516, 'the field is 516');
	is($w->game->height, 400, 'by 400');
	is($w->fps, 20, 'twenty frames a second');
	is($w->level, 3, 'the bot at the top rung');
	is($w->best, 0, 'no best yet');
	for my $case (
		[ { level => 7 },  qr/a level is one of 1 2 3/,    'a level off the ladder' ],
		[ { fps => 0 },    qr/frame rate is at least 1/,   'no frames' ],
		[ { fps => 'x' },  qr/fps must be a whole number/, 'a rate that is not a number' ],
	) {
		my ($args, $why, $name) = @$case;
		my $bad = eval { $r->new(seed => 'bad', %$args) };
		like($@, $why, "$name is refused");
	}
};

done_testing();
