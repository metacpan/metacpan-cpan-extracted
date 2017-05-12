print "1..5\n";
chdir "t";
use Image::IPTCInfo::RasterCaption;
use Image::Magick;
use strict;

# Load the binary rasterized caption from an image:
my $iptc = create Image::IPTCInfo::RasterCaption('has_caption.jpg');
unless ($iptc){
	print "not ok 1\nnot ok 2\nnot ok 3\n";
	exit;
}
print "ok 1\n";

# Get caption from image
$iptc->load_raster_caption('has_caption.jpg');
my $rasterized_caption_data = $iptc->Attribute('rasterized caption');

if ($rasterized_caption_data){
	print "ok 2\n";
} else {
	print "not ok 2\n";
}

my $new_im = new Image::Magick;
$new_im->Set(size=>'460x128');
$new_im->ReadImage('xc:white');
if ($new_im->Write('no_caption.jpg')){
	print "not ok 3\n";
} else {
	print "ok 3\n";
}



## Add the caption to an image:
my $image = create Image::IPTCInfo::RasterCaption ('no_caption.jpg');

unless ($image){
	print "not ok 4\n";
} else {
	print "ok 4\n";
}

$image->SetAttribute('rasterized caption',$rasterized_caption_data);

if ($image->SaveAs('new_caption.jpg')){
	print "ok 5\n";
} else {
	print "not ok 5\n";
}

unlink "no_caption.jpg";
