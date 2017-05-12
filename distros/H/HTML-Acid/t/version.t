use Test::More;
   
if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval "use Test::ConsistentVersion";
plan skip_all => "Test::ConsistentVersion required for checking versions" if $@;
Test::ConsistentVersion::check_consistent_versions();

