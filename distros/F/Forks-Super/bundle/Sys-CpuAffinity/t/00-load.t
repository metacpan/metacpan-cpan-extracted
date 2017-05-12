#!perl -T

use Test::More tests => 1;

eval "alarm 10";

BEGIN {
    use_ok( 'Sys::CpuAffinity' ) || print "Bail out!\n";
}

diag("Testing Sys::CpuAffinity $Sys::CpuAffinity::VERSION, Perl $], $^X, $^O");
