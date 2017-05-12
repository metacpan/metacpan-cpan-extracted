#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Devel::DumpTrace' ) || print "Bail out!
";
}

diag( "Testing Devel::DumpTrace $Devel::DumpTrace::VERSION, Perl $], $^X" );
