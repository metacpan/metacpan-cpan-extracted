use strict;
use warnings;
use Image::libsiftfast;
use Test::More;
use FindBin::libs;
use File::Spec;

my $sift          = Image::libsiftfast->new;
my $siftfast_path = $sift->{siftfast_path};

unless ( $siftfast_path and -e $siftfast_path ) {
    plan skip_all => "siftfast is not installed.";
}
else {
    plan tests => 3;
}

my $jpeg
    = File::Spec->catfile( $FindBin::RealBin, "../sample", "lena_std.jpg" );
my $pnm = $sift->convert_to_pnm($jpeg);
is( $pnm,
    File::Spec->catfile( $FindBin::RealBin, "../sample", "lena_std.pnm" ) );

my $data = $sift->extract_keypoints($pnm);
is( $data->{keypoint_num}, int @{ $data->{keypoints} } );
is( $data->{image_size},   '512x512' );
