#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl relative.t'

use strict;
use warnings;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('File::Spec::Link') };

#########################

is( File::Spec->canonpath(
	File::Spec::Link->relative_to_file(
	    File::Spec->catfile(qw(dir foo.ext)),
	    File::Spec->catfile(qw(dir1 dir2 bar.xyz)))),
    File::Spec->canonpath(
	File::Spec->catfile(qw(dir1 dir2 dir foo.ext))),
    "relative_to_file(dir/foo.ext,dir1/dir2/bar.xyz)");


my $path = File::Spec->catfile(File::Spec->rootdir,qw(dir foo.ext));
is( File::Spec->canonpath(
	File::Spec::Link->relative_to_file($path,
	    File::Spec->catfile(qw(dir1 dir2 bar.xyz)))),
    File::Spec->canonpath($path),
    "relative_to_file(/dir/foo.ext,dir1/dir2/bar.xyz)");

# $Id: relative.t 82 2006-07-26 08:55:37Z rmb1 $

