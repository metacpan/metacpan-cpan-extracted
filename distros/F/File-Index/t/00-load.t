#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Index' ) || print "Bail out!\n";
}

diag( "Testing File::Index $File::Index::VERSION, Perl $], $^X" );
