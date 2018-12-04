package
  TestImage;
use strict;
use Imager;

our @EXPORT_OK = qw(alpha_test_image);
use Exporter qw(import);


sub alpha_test_image {
  my $check = Imager->new(xsize => 20, ysize => 20, channels => 4);
  $check->box(xmax => 9, color => [ 0, 0, 255, 128], filled => 1);
  $check->box(xmin => 10, color => [ 255, 255, 0, 192 ], filled => 1);
  $check;
}

1;
