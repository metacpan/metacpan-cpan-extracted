use strict;
use warnings;

use Test::More;

eval "use Test::ConsistentVersion";
plan skip_all => "Test::ConsistentVersion required for this test"
    if $@;

Test::ConsistentVersion::check_consistent_versions();
