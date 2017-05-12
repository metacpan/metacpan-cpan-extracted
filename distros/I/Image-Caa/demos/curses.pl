#!/usr/bin/perl -w

use strict;
use lib '../lib';
use Curses;
use Term::ReadKey;
use Image::Caa;
use Image::Magick;


#
# load the image
#

my $image = Image::Magick->new;

my $x = $image->Read('kitten.jpg');

warn "$x" if "$x";


#
# set up window
#

my ($cols, $lines) = GetTerminalSize;

initscr;

my $s = newwin($lines, $cols, 0, 0);

$s->erase;
$s->clear;


#
# output it
#

#my $caa = new Image::Caa('driver' => 'DriverCurses', 'window' => $s, 'black_bg' => 1);
my $caa = new Image::Caa('driver' => 'DriverCurses', 'window' => $s);

$caa->draw_bitmap(2, 2, $cols-2, $lines-5, $image);

$s->noutrefresh();

doupdate;
sleep(3);

endwin;