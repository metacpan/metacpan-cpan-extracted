print "1..3\n";
use Image::IPTCInfo::RasterCaption;
print "ok 1\n";

chdir "t";

use strict;


## Load the binary rasterized caption from an image:
my $iptc = create Image::IPTCInfo::RasterCaption('sample.jpg');
unless ($iptc){
	print "not ok 2\nnot ok 3\n";
	exit;
}
print "ok 2\n";

$iptc->load_raster_caption('sample.jpg');
my $rasterized_caption_data = $iptc->Attribute('rasterized caption');

if ($rasterized_caption_data){
	print "ok 3\n";
} else {
	print "not ok 3\n";
}