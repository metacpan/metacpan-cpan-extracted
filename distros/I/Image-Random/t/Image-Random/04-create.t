use strict;
use warnings;

use English qw(-no_match_vars);
#use Filesys::POSIX;
#use Filesys::POSIX::Mem;
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Image::Random;
use Imager::Color;
use Imager;
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $obj = Image::Random->new;
my $temp_dir = tempdir('CLEANUP' => 1);
my $temp_file = catfile($temp_dir, 'foo.bmp');
my $ret = $obj->create($temp_file);
is($ret, 'bmp', 'create() method return image type.');
my $i = Imager->new('file' => $temp_file);
isa_ok($i, 'Imager');

# Test.
$obj = Image::Random->new(
	'color' => Imager::Color->new('#ff0000'),
);
$ret = $obj->create($temp_file);
is($ret, 'bmp', 'create() method return image type.');
$i = Imager->new('file' => $temp_file);
isa_ok($i, 'Imager');

# Test.
$obj = Image::Random->new(
	'type' => undef,
);
$ret = $obj->create($temp_file);
is($ret, 'bmp', 'create() method return image type.');
$i = Imager->new('file' => $temp_file);
isa_ok($i, 'Imager');

# Test.
$obj = Image::Random->new(
	'type' => undef,
);
$temp_file = catfile($temp_dir, 'foo.jpg');
$ret = $obj->create($temp_file);
is($ret, 'jpeg', 'create() method return image type.');
$i = Imager->new('file' => $temp_file);
isa_ok($i, 'Imager');

# Test.
# TODO Opravit.
#$obj = Image::Random->new;
#my $fs = Filesys::POSIX->new(
#	Filesys::POSIX::Mem->new,
#);
#$temp_file = catfile($temp_dir, 'foo.jpg');
#eval {
#	$obj->create($temp_file);
#};
#is($EVAL_ERROR, '');
