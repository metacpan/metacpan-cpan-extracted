use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_COVERAGE} ) {
    my $msg = 'Author test.  Set $ENV{TEST_COVERAGE} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Strict; };

if ( $@ ) {
    my $msg = 'Test::Strict required to test code coverage.';
    plan( skip_all => $msg );
}

my $coverage = Test::Strict::all_cover_ok( 75, 't/' );
diag( "Bundled tests exercise ** $coverage\% ** of this code-base." );
