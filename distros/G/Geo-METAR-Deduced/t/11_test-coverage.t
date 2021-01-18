use strict;
use warnings;
use utf8;

use Test::More;

if ( not $ENV{AUTHOR_TESTING} ) {
    my $msg = 'Set $ENV{AUTHOR_TESTING} to run author tests.';
    plan( skip_all => $msg );
}

if ( !eval { require Test::TestCoverage; 1 } ) {
    plan skip_all => q{Test::TestCoverage required for testing test coverage};
}
plan tests => 1;
TODO: {
    todo_skip q{Fails on calling add_method on an immutable Moose object}, 1
      if 1;
    Test::TestCoverage::test_coverage('Geo::METAR::Deduced');
    Test::TestCoverage::test_coverage_except( 'Geo::METAR::Deduced', 'meta' );
    my $obj = Geo::METAR::Deduced->new();

    Test::TestCoverage::ok_test_coverage('Geo::METAR::Deduced');
}
