#!perl

use strict;
use warnings;
use Test::More 0.98;

use Filename::Image qw(check_image_filename);

ok(!check_image_filename(filename=>"foo.txt"));
ok(!check_image_filename(filename=>"foo.mp4"));
ok( check_image_filename(filename=>"foo.jpg"));
ok( check_image_filename(filename=>"foo.PNG"));

done_testing;
