#!/usr/bin/perl -w

use strict;
use FFMPEG::Effects;

my $videofile = "~/Your-Video.mpg";

my $effect = FFMPEG::Effects->new('debug=0');

$effect->FadeOut(
		"videofile=$videofile",
	   	"size=720x480",
	   	"color=green",
	   	"opacity=100", 
	   	"fadeoutframes=90",
	   	"holdframes=15",
		);





