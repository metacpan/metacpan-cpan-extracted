#!/usr/bin/perl -w

use strict;
use FFMPEG::Effects;

my $effect = FFMPEG::Effects->new('debug=0');

my $help = $effect->Help();

