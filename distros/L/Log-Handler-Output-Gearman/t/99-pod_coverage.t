#!perl -T

use Test::More;
use FindBin qw( $Bin );
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "This is an author only test" if !-f "$Bin/../MANIFEST.SKIP";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();
