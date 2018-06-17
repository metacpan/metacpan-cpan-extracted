#!/usr/bin/perl

# Compile-testing for File::ShareDir

use strict;

BEGIN
{
    $|  = 1;
    $^W = 1;
}

use Test::More;
use File::ShareDir;

# Print the contents of @INC
#diag("\@INC = qw{");
#foreach ( @INC ) {
#	diag("    $_");
#}
#diag("    }");

#####################################################################
# Loading and Importing

# Don't import by default
ok(!defined &dist_dir,    'dist_dir not imported by default');
ok(!defined &module_dir,  'module_dir not imported by default');
ok(!defined &dist_file,   'dist_file not imported by default');
ok(!defined &module_file, 'module_file not imported by default');
ok(!defined &class_file,  'class_file not imported by default');
use_ok('File::ShareDir', ':ALL');

# Import as needed
ok(defined &dist_dir,    'dist_dir imported');
ok(defined &module_dir,  'module_dir imported');
ok(defined &dist_file,   'dist_file imported');
ok(defined &module_file, 'module_file imported');
ok(defined &class_file,  'class_file imported');

# Allow all named functions
use_ok('File::ShareDir', 'module_dir', 'module_file', 'dist_dir', 'dist_file', 'class_file',);

#####################################################################
# Support Methods

is(File::ShareDir::_MODULE('File::ShareDir'), 'File::ShareDir', '_MODULE returns correct for known loaded module',);
is(File::ShareDir::_DIST('File-ShareDir'),    'File-ShareDir',  '_DIST returns correct for known good dist',);

#####################################################################
# Module Tests

my $module_dir = module_dir('File::ShareDir');
ok($module_dir,    'Can find our own module dir');
ok(-d $module_dir, '... and is a dir');
ok(-r $module_dir, '... and have read permissions');

my $module_file = module_file('File::ShareDir', 'test_file.txt');
ok(-f $module_file, 'module_file ok');

#####################################################################
# Distribution Tests

my $dist_dir = dist_dir('File-ShareDir');
ok($dist_dir,    'Can find our own dist dir');
ok(-d $dist_dir, '... and is a dir');
ok(-r $dist_dir, '... and have read permissions');

my $dist_file = dist_file('File-ShareDir', 'sample.txt');
ok($dist_file,    'Can find our sample module file');
ok(-f $dist_file, '... and is a file');
ok(-r $dist_file, '... and have read permissions');

# Make sure the directory in dist_dir, matches the one from dist_file
# Bug found in Module::Install 0.54, fixed in 0.55
is(File::Spec->catfile($dist_dir, 'sample.txt'), $dist_file, 'dist_dir and dist_file find the same directory',);

done_testing;
