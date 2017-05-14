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

is( ref $filedetails, 'File::Details', "Object created with sucess");

#use Data::Dumper;
#diag Dumper $filedetails;

done_testing;

