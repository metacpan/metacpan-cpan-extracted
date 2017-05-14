#!/usr/bin/env perl

use strict;
use warnings;

use Cwd 'abs_path';
use File::Basename;
use Test::More;

my $fullpath = join "/", abs_path, $0;
my $testdir = dirname $fullpath;
my $testfile = join "/", $testdir , "testfile";

use_ok( 'File::Details' );

my $filedetails = File::Details->new( $testfile );

diag $filedetails->abspath();

is( $filedetails->abspath(), $testfile, "The absolute path of file is correct");

done_testing;

__END__
5dd39cab1c53c2c77cd352983f9641e1  t/testfile
