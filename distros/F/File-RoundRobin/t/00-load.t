#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::RoundRobin' ) || print "Bail out!\n";
}

diag( "Testing File::RoundRobin $File::RoundRobin::VERSION, Perl $], $^X" );
