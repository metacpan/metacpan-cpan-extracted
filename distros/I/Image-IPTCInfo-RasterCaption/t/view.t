print "1..3\n";
use Image::IPTCInfo::RasterCaption;
use strict;
chdir "t";

my $with_cap = new Image::IPTCInfo::RasterCaption('new_caption.jpg');

if ($with_cap){
	print "ok 1\n";
} else {
	print "not ok 1\n";
	print "not ok 2\n";
	print "not ok 3\n";
	exit;
}

if ($with_cap->save_raster_caption('extracted.jpg')){
	print "ok 2\n";
} else {
	print "not ok 2\n";
}
if (-e 'extracted.jpg'){
	print "ok 3\n";
} else {
	print "not ok 3\n";
}
unlink 'extracted.jpg';