#!/usr/bin/perl -w
# extracts a random frame of an animated gif

use strict;

use Image::ParseGIF;

foreach my $f (@ARGV)
{
	my $gif = new Image::ParseGIF($f);
	warn ("could not parse [$f]: $@\n"), next unless $gif;

	$f =~ s/\.gif$/_static.gif/;

	$gif->output(IO::File->new(">$f")) or die "$!\n";
	$gif->deanimate(-1);

}
