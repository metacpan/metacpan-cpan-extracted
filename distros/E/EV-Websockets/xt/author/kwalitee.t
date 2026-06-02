use strict;
use warnings;
use Test::More 0.88;

# Author test: CPANTS kwalitee. Run with `prove -l xt/`.
eval "use Test::Kwalitee 1.21 'kwalitee_ok'; 1"
    or plan skip_all => "Test::Kwalitee required for kwalitee tests";

# Exclude metrics that require a packaged dist (generated META.* and a tarball
# MANIFEST), which don't exist in a plain checkout -- they're verified at
# `make dist` time instead.
kwalitee_ok(qw( -has_meta_yml -has_meta_json ));

done_testing;
