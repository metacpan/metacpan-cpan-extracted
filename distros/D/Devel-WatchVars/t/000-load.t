#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use Cwd qw(abs_path);
use FindBin;
use lib map { abs_path("$FindBin::Bin/../$_") } qw(lib);

use Test::More;

plan tests => 1;

my $MODULE;

BEGIN {
    $MODULE = "Devel::WatchVars";
    use_ok($MODULE) || print "Bail out!\n";
}

diag sprintf "Testing %s %s using perl v%vd in %s", $MODULE, $MODULE->VERSION, $^V, $^X;
