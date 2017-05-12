#!perl -T
use Test::More;
if ( not $ENV{FILEBSED_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{FILEBSED_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
