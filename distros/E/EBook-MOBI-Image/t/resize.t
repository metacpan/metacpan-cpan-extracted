#!/usr/bin/perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use Image::Imlib2;

#######################
# TESTING starts here #
#######################
use Test::More tests => 8;

###########################
# General module tests... #
###########################

my $module = 'EBook::MOBI::Image';
use_ok( $module );

my $obj = $module->new();

isa_ok($obj, $module);

can_ok($obj, 'new');
can_ok($obj, 'debug_on');
can_ok($obj, 'debug_off');
can_ok($obj, 'rescale_dimensions');

# we generate any image
my ($fh,$f_name) = tempfile();
unlink $f_name;

my $image = Image::Imlib2->new(500, 700);
$image->set_colour(  0,   0, 255, 255); # blue
$image->fill_rectangle(0, 0, 500, 500);
$image->save("$f_name.png");

# rescale the image
my $resized_pic_path = $obj->rescale_dimensions("$f_name.png");

# check the rescales size
my $resized = Image::Imlib2->load($resized_pic_path);
cmp_ok($resized->width() , '<=',  520, 'Image resized width');
cmp_ok($resized->height(), '<=',  622, 'Image resized heigth');

# remove the image, since it was just a test
unlink $resized_pic_path;
unlink "$f_name.png";

########
# done #
########
1;

