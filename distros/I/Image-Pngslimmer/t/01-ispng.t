
use strict;
use Image::Pngslimmer();

use Test::More tests =>2;

my ($giffile, $pngfile, $blob1, $blob2, $read);

sysopen($giffile, "./t/test1.gif", 0x0);
$read = (stat ($giffile))[7];
(sysread($giffile, $blob1, $read) == $read) or die "Could not open GIF\n";

is(Image::Pngslimmer::ispng($blob1), 0);
close ($giffile);

sysopen($pngfile, "./t/test1.png", 0x0);
$read = (stat ($pngfile))[7];
(sysread($pngfile, $blob2, $read) == $read) or die "Could not open PNG\n";

is(Image::Pngslimmer::ispng($blob2), 1);

close($pngfile);
