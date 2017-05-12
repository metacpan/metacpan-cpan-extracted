# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib './';
use Data::Dumper;

use Test;
BEGIN { plan tests => 8 };

use Image::Magick;
print "ok 1\n";

my $image = new Image::Magick;
print "ok 2\n";

$image->ReadImage ('t/data/Monument.jpg');
print "ok 3\n";

use Image::Photo;
print "ok 4\n";

my $object = new Image::Photo (image => $image,
                              radlum => 10,
                              sample => 'simple');
print "ok 5\n";

my $numbers;

$numbers = join ' ', map ord (substr $object->Pixel (142.4, 80.4), $_), (0, 1, 2, 3);
print "ok 6\n" if ($numbers eq "119 156 204 255");

$object = new Image::Photo (image => $image,
                           radlum => 10,
                           sample => 'linear');

$numbers = join ' ', map ord (substr $object->Pixel (142.4, 80.4), $_), (0, 1, 2, 3);
print "ok 7\n" if ($numbers eq "109 148 197 254");

$object = new Image::Photo (image => $image,
                           radlum => 10,
                           sample => 'spline16');

$numbers = join ' ', map ord (substr $object->Pixel (142.4, 80.4), $_), (0, 1, 2, 3);
print "ok 8\n" if ($numbers eq "107 146 196 255");

