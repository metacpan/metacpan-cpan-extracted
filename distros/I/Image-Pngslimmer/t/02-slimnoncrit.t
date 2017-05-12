
use strict;
use Image::Pngslimmer();

use Test::More tests =>1;

my ($pngfile, $blob1, $blob2, $read, $lengthfat, $lengthslim, $weightloss);


sysopen($pngfile, "./t/test1.png", 0x0);
$read = (stat ($pngfile))[7];
(sysread($pngfile, $blob1, $read) == $read) or die "Could not open PNG\n";
$blob2 = Image::Pngslimmer::discard_noncritical($blob1);
$lengthfat = length($blob1);
$lengthslim = length($blob2);
$weightloss = $lengthfat - $lengthslim;
print "Fat file was $lengthfat bytes long, slimmed file was $lengthslim bytes, saving $weightloss bytes\n";
ok($weightloss > 0);

close($pngfile);
