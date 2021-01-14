#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::FormatIdentification::RandomSampling' ) || print "Bail out!\n";
}

diag( "Testing File::FormatIdentification::RandomSampling $File::FormatIdentification::RandomSampling::VERSION, Perl $], $^X" );
