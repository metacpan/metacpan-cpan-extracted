use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use File::Copy;
use rlib '../lib', './lib';

use Geo::ShapeFile;
use Geo::ShapeFile::Shape;
use Geo::ShapeFile::Point;

#  should use $FindBin::bin for this
use FindBin;
my $dir = "$FindBin::Bin/test_data";

#  make the data

my $unicode_suffix = 'ñøß';
$unicode_suffix = "\x{241}\x{248}\x{223}";
my $fname_base = 'unicode_name_xxx';
my $fname = $fname_base;
$fname =~ s/_xxx/_$unicode_suffix/;

my @files = glob "$dir/$fname_base.*";
my @unicode_files;
foreach my $file (@files) {
    my $new_name = $file;
    $new_name =~ s/_xxx/_$unicode_suffix/;
    # say STDERR "$file, $new_name, $unicode_suffix";
    File::Copy::copy $file, $new_name;
    push @unicode_files, $new_name;
}

lives_ok (
    sub {my $shp = Geo::ShapeFile->new("$dir/$fname.shp")},
    'opens unicode file name',
);

dies_ok (
    sub {my $shp = Geo::ShapeFile->new("$dir/nonexistent_$fname")},
    'dies on unicode file name that does not exist',
);

#  cleanup - we should use a temp dir for this
unlink @unicode_files;

done_testing();

