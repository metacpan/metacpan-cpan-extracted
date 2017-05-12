
use strict;
use Image::Pngslimmer();

use Test::More tests =>1;

my ($pngfile, $blob1, $blob2, $read, @analfat, @analslim, $weightloss, $fatel, $slimel);


sysopen($pngfile, "./t/test1.png", 0x0);
$read = (stat ($pngfile))[7];
(sysread($pngfile, $blob1, $read) == $read) or die "Could not open PNG\n";
$blob2 = Image::Pngslimmer::discard_noncritical($blob1);
$fatel = Image::Pngslimmer::analyze($blob1);
$slimel = Image::Pngslimmer::analyze($blob2);
$weightloss = $fatel - $slimel;
print "Fat file had $fatel chunks, slimmed file has $slimel chunks, saving $weightloss chunks\n";
print "Fat file details:\n";
print Image::Pngslimmer::analyze($blob1);
print "\nSlimmed file details:\n";
print Image::Pngslimmer::analyze($blob2);
ok($weightloss > 0);

close($pngfile);
