#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Flock::Tiny' ) || print "Bail out!\n";
}

diag( "Testing File::Flock::Tiny $File::Flock::Tiny::VERSION, Perl $], $^X" );
