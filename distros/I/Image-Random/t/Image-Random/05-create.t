# Pragmas.
use strict;
use warnings;

# Modules.
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Image::Random;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Image::Random->new;
my $temp_dir = tempdir('CLEANUP' => 1);
my $ret = $obj->create(catfile($temp_dir, 'foo.bmp'));
is($ret, 'bmp', 'create() method return image type.');
