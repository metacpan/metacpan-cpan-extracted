use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval {
        require Test::Kwalitee;
        Test::Kwalitee->import( tests =>
            [ qw(
                    -has_test_pod
                    -has_test_pod_coverage
                    -no_pod_errors
                    -use_strict
                ) ]
        );
    };

if ( $@ ) {
    my $msg = 'Test::Kwalitee is required for basic meta-testing.';
    plan( skip_all => $msg );
}
