#!/usr/bin/perl -w

use strict;
use warnings;
use lib "../lib";
use Image::Tileset;

# Usage: extract.pl <tileset>
# Example: extract.pl faces
#          (uses faces.xml and faces.png)

my $name = $ARGV[0] || die "Usage: extract.pl <tileset>\n"
	. "Example: extract.pl faces\n"
	. "         (uses faces.xml and faces.png)";
mkdir("./out") unless -d "./out";

my $ts = new Image::Tileset();

# Read the files ourselves.
{
	local $/ = undef; # slurp the files
	open (XML, "$name.xml");
	my $xml = <XML>;
	close (XML);

	open (PNG, "$name.png");
	binmode PNG;
	my $bin = <PNG>;
	close (PNG);

	$ts->data($bin);
	$ts->xml($xml);
}

# Dump all the tiles.
my @tiles = $ts->tiles();
foreach my $tile (@tiles) {
	print "Extracting $tile -> ./out/$tile.png!\n";
	open (OUT, ">out/$tile.png");
	binmode OUT;
	print OUT $ts->tile($tile);
	close (OUT);
}
