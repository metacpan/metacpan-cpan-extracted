#!/usr/bin/env perl

use strict;
use warnings;
use warnings qw(FATAL utf8);

use Image::Magick::CommandParser;

# ----------------------------------------------

my($command)	= 'convert colors/*s*.png -append output.png';
my($processor)	= Image::Magick::CommandParser -> new
(
	command		=> $command,
	maxlevel	=> 'notice',
);

$processor -> run;

print 'Input:  ', $command, "\n";
print 'Result: ', $processor -> result, "\n";
