# -*- perl -*-

# t/002_lengths.t - check output lengths

use lib "lib";

use strict;
use warnings;

use Test::More tests => 28;
use File::Slurp;

my @modules =  ('GD', 'Image::Magick', 'Imager' );

BEGIN { use_ok( 'Image::Hash' ); }


# Test to see what modules are installed. Have to do it this way instead of in a loop 
# because "require GD" is not the same as "require 'GD'"
my %have;
eval { require GD; }; 
if (!$@) {$have{'GD'} = 1;}

eval { require Image::Magick};
if (!$@) {$have{'Image::Magick'} = 1;}

eval { require Imager; require Imager::File::JPEG};
if (!$@) {$have{'Imager'} = 1;}


# Load the test image
my $image = read_file( 'eg/images/FishEyeViewofAtlantis.jpg', binmode => ':raw' ) ;

# Test individual hash functions
# aHash
for my $module ( @modules ) {
    SKIP: {
        skip "module $module is not installed", 3 if !$have{$module};

        my $ihash = Image::Hash->new($image, $module);
        isa_ok ($ihash, 'Image::Hash');

	
        ok (length(scalar $ihash->ahash()) == 16, 	" aHash with $module is 16 bytes in scalar context");
        ok (length( join('', $ihash->ahash())) == 64,	" aHash with $module is 64 bytes in array context");

    };
}

# dHash
for my $module ( @modules ) {
    SKIP: {
        skip "module $module is not installed", 3 if !$have{$module};

        my $ihash = Image::Hash->new($image, $module);
        isa_ok ($ihash, 'Image::Hash');

	
        ok (length(scalar $ihash->dhash()) == 16, 	" dHash with $module is 16 bytes in scalar context");
        ok (length( join('', $ihash->dhash())) == 64,	" dHash with $module is 64 bytes in array context");

    };
}

# pHash
for my $module ( @modules ) {
    SKIP: {
        skip "module $module is not installed", 3 if !$have{$module};

        my $ihash = Image::Hash->new($image, $module);
        isa_ok ($ihash, 'Image::Hash');

	
        ok (length(scalar $ihash->phash()) == 16, 	" pHash with $module is 16 bytes in scalar context");
        ok (length( join('', $ihash->phash())) == 64,	" pHash with $module is 64 bytes in array context");

    };
}
