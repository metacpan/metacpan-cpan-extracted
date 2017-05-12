#!perl -T

use Test::More;
use FindBin qw( $Bin );
eval "use Test::Pod 1.14";
plan skip_all => "This is an author only test" if !-f "$Bin/../MANIFEST.SKIP";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
