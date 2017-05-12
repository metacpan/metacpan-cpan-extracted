#!/usr/bin/perl -w

use strict;
use FFMPEG::Effects;

my $textfile = "~/Title-Text-File.txt";


my $effect = FFMPEG::Effects->new('debug=0');


$effect->TitleSplash(
		"size=cif",
	  	"framerate=30",
	   	"fadeinframes=55",
	   	"fadeoutframes=55",
	   	"holdframes=30",
	   	"titleframes=160",
	   	"justify=center",
	   	"fontcolor=yellow",
	   	"color=black",
	   	"font=Helvetica",
		"textfile=$textfile",
		);

