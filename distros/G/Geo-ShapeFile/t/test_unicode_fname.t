use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use rlib '../lib', './lib';

use Geo::ShapeFile;
use Geo::ShapeFile::Shape;
use Geo::ShapeFile::Point;

#  should use $FindBin::bin for this
use FindBin;
my $dir = "$FindBin::Bin/test_data";

my $fname = 'unicode_name_ñøß.shp';

lives_ok (
    sub {my $shp = Geo::ShapeFile->new("$dir/$fname")},
    'opens unicode file name',
);

dies_ok (
    sub {my $shp = Geo::ShapeFile->new("$dir/nonexistent_$fname")},
    'dies on unicode file name that does not exist',
);



done_testing();

