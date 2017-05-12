#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Butler' ) || print "Bail out!
";
}

diag( "Testing File::Butler $File::Butler::VERSION, Perl $], $^X" );
