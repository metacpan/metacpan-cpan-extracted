#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Getopt::CommandLineExports' ) || print "Bail out!\n";
}

diag( "Testing Getopt::CommandLineExports $Getopt::CommandLineExports::VERSION, Perl $], $^X" );
