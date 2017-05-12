
use strict;
use Image::Pngslimmer();

use Test::More tests =>1;

my ($pngfile, $blob1, $blob2, $read, $lengthfat, $lengthslim, $weightloss);

print "****QUANTIZING IMAGE USING MEDIAN CUT AND THEN DITHERING****\n";
sysopen($pngfile, "./t/test2.png", 0x0);
$read = (stat ($pngfile))[7];
(sysread($pngfile, $blob1, $read) == $read) or die "Could not open PNG\n";
print "Input file looks like this:\n";
print Image::Pngslimmer::analyze($blob1);
$lengthfat = length($blob1);
print "Input file is $lengthfat bytes long\n";
$blob2 = Image::Pngslimmer::palettize($blob1, 0, 1);
$lengthslim = length($blob2);
print "After colour indexation the file is $lengthslim bytes long.\n";
open (PNGTEST, ">./t/testdither.png");
print PNGTEST $blob2;
close (PNGTEST);
print "Output file looks like this:\n";
print Image::Pngslimmer::analyze($blob2);

ok($lengthfat > $lengthslim);

close($pngfile);
