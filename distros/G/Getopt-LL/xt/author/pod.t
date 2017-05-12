#!perl -T

use Test::More;
if ( not $ENV{GETOPTLL_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{GETOPTLL_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
