
use strict;
use Image::Pngslimmer();

use Test::More tests =>1;

my ($pngfile, $blob1, $blob2, $read, $lengthfat, $lengthslim, $weightloss);


sysopen($pngfile, "./t/test3.png", 0x0);
$read = (stat ($pngfile))[7];
(sysread($pngfile, $blob1, $read) == $read) or die "Could not open PNG\n";
print "*********************************FILTERING********************\n";
print "Input file looks like this:\n";
print Image::Pngslimmer::analyze($blob1);
$blob2 = Image::Pngslimmer::filter($blob1);
$lengthfat = length($blob2);
print "After filtering and best speed compression file is $lengthfat bytes long.\n";
print "Uncompressed filtered file looks like this:\n";
print Image::Pngslimmer::analyze($blob2);
print "********************************COMPRESSING*****************\n";
my $blob3 = Image::Pngslimmer::zlibshrink($blob2);
$lengthfat = length($blob1);
$lengthslim = length($blob3);
print "Length of unfiltered file was $lengthfat, length of filtered and recrushed file was $lengthslim\n";
print "Compressed and filtered file looks like this:\n";
print Image::Pngslimmer::analyze($blob3);
#save the file
open(PNGTEST, ">./t/testout.png");
print PNGTEST $blob3;
close (PNGTEST);


ok($lengthslim < $lengthfat);




close($pngfile);
