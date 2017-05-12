#!/usr/bin/perl -w

use strict;
use FFMPEG::Effects;

my $videofile = "~/Your-Video.mpg";

my $effect = FFMPEG::Effects->new('debug=0');


$effect->FadeIn(
		"videofile=$videofile",
	   	"size=720x480",
	   	"color=black",
	   	"opacity=100", 
		"fadeinframes=50",
		"holdframes=10",
		);





