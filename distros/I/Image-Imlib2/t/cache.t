#!/usr/bin/perl -w
use strict;
use Test::More tests => 7;
use FindBin qw($Bin);
use File::Spec;
use File::Copy;

use_ok('Image::Imlib2');

# create 2 differently-sized images, and save them as differennt files.

my $file1 = File::Spec->catfile($Bin, "test1.jpg");
my $file2 = File::Spec->catfile($Bin, "test2.jpg");
my $file3 = File::Spec->catfile($Bin, "test3.jpg");

my $image1 = Image::Imlib2->new(580, 200);
$image1->save($file1);

my $image2 = Image::Imlib2->new(580, 300);
$image2->save($file2);

my $image3 = Image::Imlib2->new(580, 400);
$image3->save($file3);

###############################################################

# no cache, please, we're british.
Image::Imlib2->set_cache_size(0);
is( Image::Imlib2->get_cache_size, 0, "no cache now" );

# load the first file, we expect it to be a given size.
my $im = Image::Imlib2->load($file1);
is( $im->get_height, 200, "right height for original" );

# now overwrite the image with the other one.
copy($file2, $file1) or die $!;

# we _expect_ this to be image2, now, but the cache disagrees.
$im = Image::Imlib2->load($file1);
is( $im->get_height, 200, "image (wrongly) still original height" );

# try again, without cache
undef $im;
 
$im = Image::Imlib2->load($file1);
is( $im->get_height, 300, "image now new (image2) height" );

# now overwrite the image with the _other_ other one.
copy($file3, $file1) or die $!;

# we _expect_ this to be image3, now, but the cache disagrees.
$im = Image::Imlib2->load($file1);
is( $im->get_height, 300, "image (wrongly) still image2 height" );

# force re-load again
undef $im;

$im = Image::Imlib2->load($file1);
is( $im->get_height, 400, "image now image3 height" );

