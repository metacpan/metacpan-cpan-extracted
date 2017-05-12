use Test::More; 

eval
{
    require Test::Kwalitee;

    # Skip pod and coverage checks, as these are in the xt/ directory.
    Test::Kwalitee->import( tests =>
              [ qw( -has_test_pod -has_test_pod_coverage ) ]
    );
};
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
