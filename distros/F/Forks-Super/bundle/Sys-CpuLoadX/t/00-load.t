#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::CpuLoadX' ) || print "Bail out!
";
}

diag( "Testing Sys::CpuLoadX $Sys::CpuLoadX::VERSION, Perl $], $^X" );
