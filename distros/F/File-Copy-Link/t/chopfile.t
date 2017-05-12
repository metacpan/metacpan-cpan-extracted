#!perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl chopfile.t'

use strict;
use warnings;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('File::Spec::Link') };

#########################

like( File::Spec::Link->chopfile(
	    File::Spec->catfile(qw(dir foo.ext))),
    qr(^dir\W?\z),
    "chopfile(dir/foo.ext)");

my $curr = File::Spec->curdir;
like( File::Spec::Link->chopfile('file.ext'),
	qr(^$curr\W?\z),
	"chopfile(foo.ext)");

# $Id: chopfile.t 82 2006-07-26 08:55:37Z rmb1 $
