#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Temp::Trace' ) || print "Bail out!
";
}

diag( "Testing File::Temp::Trace $File::Temp::Trace::VERSION, Perl $], $^X" );
