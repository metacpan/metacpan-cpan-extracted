#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use File::ShareDir::Tiny ();

#####################################################################
# Loading and Importing

# Don't import by default
ok(!defined &dist_dir,    'dist_dir not imported by default');
ok(!defined &module_dir,  'module_dir not imported by default');
ok(!defined &dist_file,   'dist_file not imported by default');
ok(!defined &module_file, 'module_file not imported by default');

use_ok('File::ShareDir::Tiny', ':ALL');
ok(defined &dist_dir,    'dist_dir imported');
ok(defined &module_dir,  'module_dir imported');
ok(defined &dist_file,   'dist_file imported');
ok(defined &module_file, 'module_file imported');

####################################################################
# Module Tests

my $module_dir = module_dir('ShareDir::TestClass');
ok($module_dir,    'Can find our own module dir');
ok(-d $module_dir, '... and is a dir');
ok(-r $module_dir, '... and have read permissions');

my $module_file = module_file('ShareDir::TestClass', 'test_file.txt');
ok(-f $module_file, 'module_file ok') or diag $module_file;

#####################################################################
# Distribution Tests

my $dist_dir = dist_dir('ShareDir-TestClass');
ok($dist_dir,    'Can find our own dist dir');
ok(-d $dist_dir, '... and is a dir');
ok(-r $dist_dir, '... and have read permissions');

my $dist_file = dist_file('ShareDir-TestClass', 'sample.txt');
ok($dist_file,    'Can find our sample module file');
ok(-f $dist_file, '... and is a file');
ok(-r $dist_file, '... and have read permissions');

# Make sure the directory in dist_dir, matches the one from dist_file
# Bug found in Module::Install 0.54, fixed in 0.55
is(File::Spec->catfile($dist_dir, 'sample.txt'), $dist_file, 'dist_dir and dist_file find the same directory',);

done_testing;
