#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# new, prototype and set_prototype are installed into every class by
# Object::Proto::Sugar, and BUILD is the constructor hook it calls: none of the
# four is this distribution's to document. Everything else is covered, and this
# test is never skipped for convenience: the same test in Game-Cribbage fails for
# all fifteen of its modules.
all_pod_coverage_ok(
    { also_private => [qr/^(?:new|prototype|set_prototype|BUILD)$/] },
    'POD coverage, less what Object::Proto::Sugar installs'
);
