
use strict;
use Image::Pngslimmer();

use Test::More tests =>1;

my ($pngfile, $blob1, $blob2, $read, $lengthfat, $lengthslim, $weightloss);


sysopen($pngfile, "./t/test1.png", 0x0);
$read = (stat ($pngfile))[7];
(sysread($pngfile, $blob1, $read) == $read) or die "Could not open PNG\n";
$lengthfat = length($blob1);
$blob2 = Image::Pngslimmer::zlibshrink($blob1);
$lengthslim = length($blob2);
$weightloss = $lengthfat - $lengthslim;
print "Fat file was $lengthfat bytes long, zlibprocessed file was $lengthslim bytes, saving $weightloss bytes\n";
my $stillpng = Image::Pngslimmer::ispng($blob2);
print "Image::Pngslimmer::ispng returns $stillpng\n";
print "Zlib compressed file details:\n";
print Image::Pngslimmer::analyze($blob2);
print "\nUncompressed file details\n";
print Image::Pngslimmer::analyze($blob1);

ok($weightloss > 0);




close($pngfile);
