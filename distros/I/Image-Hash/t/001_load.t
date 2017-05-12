# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 3;
use File::Slurp;

BEGIN { use_ok( 'Image::Hash' ); }

# Load the test image
my $image = read_file( 'eg/images/FishEyeViewofAtlantis.jpg', binmode => ':raw' ) ;

my $object = Image::Hash->new ($image);
isa_ok ($object, 'Image::Hash');


# Make the aHash and see if it is ok
my @a = $object->ahash();

ok (scalar @a == 64);
