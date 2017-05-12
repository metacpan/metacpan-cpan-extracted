
use strict;
use Image::Pngslimmer();

use Test::More tests =>1;

my ($pngfile, $blob1, $blob2, $read, $lengthfat, $lengthslim, $weightloss);

print "INDEXING IMAGE\n";
sysopen($pngfile, "./t/test6.png", 0x0);
$read = (stat ($pngfile))[7];
(sysread($pngfile, $blob1, $read) == $read) or die "Could not open PNG\n";
print "Input file looks like this:\n";
print Image::Pngslimmer::analyze($blob1);
$lengthfat = length($blob1);
print "Input file is $lengthfat bytes long\n";
print "Colour information is:\n";
Image::Pngslimmer::reportcolours($blob1);
$blob2 = Image::Pngslimmer::indexcolours($blob1);
$lengthslim = length($blob2);
print "After colour indexation the file is $lengthslim bytes long.\n";
open (PNGTEST, ">./t/testind.png");
print PNGTEST $blob2;
close (PNGTEST);
print "Output file looks like this:\n";
print Image::Pngslimmer::analyze($blob2);

ok($lengthfat > $lengthslim);

close($pngfile);
