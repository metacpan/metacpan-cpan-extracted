use strict;
use warnings;

use lib './lib';
use Test::More tests => 6;                     

my $class= 'Image::Resize::Path';

BEGIN{ use_ok('Image::Resize::Path'); }

my $test_obj = Image::Resize::Path->new;

isa_ok($test_obj, $class);

$test_obj->src_path('foo');

is($test_obj->src_path, 'foo');

my $images_hr = $test_obj->supported_images(['png']);

is_deeply($images_hr, { png => 1 } );

$images_hr = $test_obj->supported_images('png');

is_deeply($images_hr, undef );

$test_obj->dest_path('foo');

is($test_obj->dest_path, 'foo');
