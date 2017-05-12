#!/usr/bin/perl -w
# converts a GIF image to a (greyscale) printer-friendly version:
# - converts to greyscale
# - first frame of animated images

use strict;

use Image::ParseGIF;

foreach my $f (@ARGV)
{
		my $gif = new Image::ParseGIF($f, Desaturate => 1);
		warn ("could not parse [$f]: $@\n"), next unless $gif;

		$f =~ s/\.gif$/_printable.gif/;

		$gif->output(IO::File->new(">$f")) or die "$!\n";
		$gif->deanimate(0);
}
