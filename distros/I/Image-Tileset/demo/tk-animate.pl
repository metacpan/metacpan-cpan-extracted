#!/usr/bin/perl -w

use strict;
use warnings;
use lib "../lib";
use Image::Tileset;
use Tk;
use Tk::PNG;
use MIME::Base64 qw(encode_base64);

# Usage: tk-animate.pl <tileset> <scale>
# Example: tk-animate.pl hero-battle
#          tk-animate.pl hero-battle 2
#          tk-animate.pl hero-battle 96x96
#          (uses hero-battle.xml and hero-battle.png)

my $name = $ARGV[0] || die "Usage: tk-animate.pl <tileset> <scale>\n"
	. "Example: tk-animate.pl hero-battle\n"
	. "         tk-animate.pl hero-battle 2\n"
	. "         tk-animate.pl hero-battle 96x96\n"
	. "         (uses hero-battle.xml and hero-battle.png)";

my @opts = ();
if (scalar(@ARGV) == 2) {
	if ($ARGV[1] =~ /^[0-9\.]+$/) {
		push (@opts, scale => $ARGV[1]);
	}
	elsif ($ARGV[1] =~ /^\d+x\d+$/) {
		push (@opts, size => $ARGV[1]);
	}
}

# Load the tileset.
my $ts = new Image::Tileset (
	image => "$name.png",
	xml   => "$name.xml",
);

# Make Tk window.
my $mw = MainWindow->new (
	-title => 'Animation Test',
);

# Get the animation info.
my @animations = $ts->animations();
if (scalar(@animations) == 0) {
	die "This tileset has no animation definitions!";
}
print "Animations: @animations\n";

# Load the PNG's of all animated images.
my $pngs = {};
foreach my $id (@animations) {
	$pngs->{$id} = $ts->animation($id);
	$pngs->{$id}->{photos} = [];
	foreach my $tile (@{$pngs->{$id}->{tiles}}) {
		my $bin = $ts->tile($tile, @opts) or die $ts->error();
		push (@{$pngs->{$id}->{photos}},
			$mw->Photo (
				-data   => encode_base64($bin),
				-format => 'PNG',
			),
		);
	}
}

# Draw the animation label.
my $label = $mw->Label ()->pack (-side => 'top');

# Enter the main loop.
my $animation_index = -1;
my $tile_index = -1;
my $time_offset = 0;
my $next_change = 0;
my $repeat = 4; # play each animation for 5 loops
$| = 1;

# First.. bindings to help skip to the next animation.
$mw->bind('<Button>', sub {
	$time_offset = 0;
	$next_change = 0;
	$animation_index++;
	$tile_index = -1;
	if ($animation_index >= scalar @animations) {
		$animation_index = 0;
	}
	$repeat = 4;
});
$mw->bind('<Escape>', sub {
	exit(0);
});
while (1) {
	select(undef,undef,undef,0.01);
	print ".";
	$time_offset += 0.01;

	# Do we need to show another image?
	my $next_img = 0;
	if ($animation_index == -1) {
		# We haven't started yet, show the first image of the first animation.
		print "Time to show first image of first animation!\n";
		$animation_index = 0;
		$next_img = 1;
	}
	if ($time_offset > $next_change) {
		# Time to show the next one!
		print "Time to show next frame!\n";
		$next_img = 1;
	}

	# Show a new image?
	if ($next_img) {
		$tile_index++;

		# What animation are we on?
		my $cur_anim = $animations[ $animation_index ];
		print "Current Animation Playing: $cur_anim [id: $animation_index; tile: $tile_index]\n";

		# Does this animation have another pic?
		if ($tile_index < scalar @{$pngs->{$cur_anim}->{photos}}) {
			print "Displaying tile $pngs->{$cur_anim}->{tiles}->[$tile_index]\n";
			$label->configure(-image => $pngs->{$cur_anim}->{photos}->[$tile_index]);
			$next_change = $time_offset + ($pngs->{$cur_anim}->{speed} / 1000);
			print "Next image changes at: $next_change (right now: $time_offset)\n";
		}
		else {
			# We've reached the end of this animation. Loop it a few times though.
			if ($repeat > 0) {
				$tile_index = -1;
				$repeat--;
				next;
			}

			# We need to change the animation.
			$animation_index++;
			$tile_index = -1;
			if ($animation_index == scalar @animations) {
				$animation_index = 0;
			}

			# Reset the repeat.
			$repeat = 4;
			next;
		}
	}

	$mw->update;
}

