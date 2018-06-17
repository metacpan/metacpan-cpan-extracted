#!perl

use strict;
use warnings;

use Cwd            ('abs_path');
use File::Basename ('dirname');
use File::Path     ('make_path', 'remove_tree');
use File::Spec     ();
use Test::More;

my $testlib = File::Spec->catdir(abs_path(dirname($0)), "lib");
unshift @INC, $testlib;

my $testautolib     = File::Spec->catdir($testlib,     "auto");
my $testsharedirold = File::Spec->catdir($testautolib, qw(ShareDir TestClass));

END { remove_tree($testautolib); }

use_ok('File::ShareDir', 'module_dir', 'module_file', 'dist_dir', 'dist_file', 'class_file');
use_ok("ShareDir::TestClass");

is(File::ShareDir::_MODULE('ShareDir::TestClass'), 'ShareDir::TestClass', '_MODULE returns correct for known loaded module',);
is(File::ShareDir::_DIST('ShareDir-TestClass'),    'ShareDir-TestClass',  '_DIST returns correct for known good dist',);

remove_tree($testautolib);
make_path($testsharedirold, {mode => 0700});
open(my $fh, ">", File::Spec->catfile($testsharedirold, qw(sample.txt)));
close($fh);

my $module_dir = module_dir('ShareDir::TestClass');
ok($module_dir,    'Can find our own module dir');
ok(-d $module_dir, '... and is a dir');
ok(-r $module_dir, '... and have read permissions');

my $dist_dir = dist_dir('ShareDir-TestClass');
ok($dist_dir,    'Can find our own dist dir');
ok(-d $dist_dir, '... and is a dir');
ok(-r $dist_dir, '... and have read permissions');

my $dist_file = dist_file('ShareDir-TestClass', 'sample.txt');
ok($dist_file,    'Can find our sample module file');
ok(-f $dist_file, '... and is a file');
ok(-r $dist_file, '... and have read permissions');

done_testing;
