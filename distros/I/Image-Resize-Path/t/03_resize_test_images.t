use strict;
use warnings;
use Cwd;
use Carp qw(croak carp);
use GD::Image;
use Test::MockObject;
use Data::Dumper;
use Image::Resize::Path;


use Test::More tests => 1;                      # last test to print


my $test_obj = Image::Resize::Path->new;
$test_obj->supported_images(['png']);
my $dest_path = getcwd . '/test_data/dest';
my $src_path = getcwd . '/test_data';
$test_obj->dest_path($dest_path);
diag $src_path;
$test_obj->src_path($src_path);


my @images = $test_obj->resize_images(100,100);

diag @images;
diag Dumper(\@images);

is_deeply(\@images, ['test.png']);


