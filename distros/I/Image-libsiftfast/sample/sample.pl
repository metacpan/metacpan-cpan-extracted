use strict;
use warnings;
use FindBin::libs;
use File::Spec;
use Image::libsiftfast;
use Data::Dumper;

my $image_file = File::Spec->catfile( $FindBin::RealBin, "lena_std.jpg" );

my $sift     = Image::libsiftfast->new;
my $pnm_file = $sift->convert_to_pnm($image_file);
my $data     = $sift->extract_keypoints($pnm_file);

my $keypoint_num = $data->{keypoint_num};
my $elapsed      = $data->{elapsed};
my $image_size   = $data->{image_size};

print "IMAGE_SIZE    : ", $image_size,   "\n";
print "KEYPOINTS_NUM : ", $keypoint_num, "\n";
print "ELAPSED       : ", $elapsed,      "\n";

print "-" x 100, "\n";

print Dumper $data->{keypoints};