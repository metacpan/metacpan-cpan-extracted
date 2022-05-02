#!perl
use strict;
use warnings;
use Test::More;
use Imager;
use File::Spec;
use Imager::Test qw(is_image);

# QOI_TEST_IMAGES is expected to point at an extracted version of the
# zip of test images from https://qoiformat.org/ , but any folder that
# has matched qoi and png image files will work
#
# It's unclear what the license is for the qoi test images or I'd
# bundle them.

my $test_image_dir = $ENV{QOI_TEST_IMAGES}
   or plan skip_all => "Set QOI_TEST_IMAGES for this test";

-d $test_image_dir
   or plan skip_all => "QOI_TEST_IMAGES isn't a directory";

grep { $_ eq "png" } Imager->read_types
  or plan skip_all => "no PNG support found";

opendir my $test_dir, $test_image_dir
   or die "Cannot opendir $test_image_dir: $!";

my @files = readdir($test_dir);

closedir $test_dir;

# match qoi to png files
my %files = map { $_ => 1 } @files;
my @tests;
for my $file (grep /\.qoi$/, @files) {
  (my $png = $file) =~ s/\.qoi/.png/;
  if ($files{$png}) {
    push @tests, [ $file, $png ];
  }
}

@tests
  or plan skip_all => "Couldn't match any PNG to QOI files";

FILE:
for my $test (@tests) {
  my ($qoi_name, $png_name) = @$test;
  my $qoi_full = File::Spec->catfile($test_image_dir, $qoi_name);
  my $png_full = File::Spec->catfile($test_image_dir, $png_name);
  my $im_png = Imager->new(file => $png_full);
  ok($im_png, "$png_name: load png comparison file")
    or next FILE;
  note $im_png->getchannels;
  my $im_qoi = Imager->new(file => $qoi_full, filetype => "qoi");
  ok($im_qoi, "$qoi_name: load qoi test file")
    or next FILE;
  is_image($im_qoi, $im_png, "$qoi_name: compare images");

  # test we can write and get it back
  my $data;
  ok($im_png->write(data => \$data, type => "qoi"),
     "$png_name: write to qoi")
    or next FILE;
  my $qoi_cmp = Imager->new(data => $data, filetype => "qoi");
  ok($qoi_cmp, "$png_name: read back the written qoi")
    or next FILE;
  is_image($qoi_cmp, $im_png, "$png_name: check we got back the original");
}

done_testing();
