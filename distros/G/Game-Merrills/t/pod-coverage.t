#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
    plan(skip_all => 'Author tests not required for installation');
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan(skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage")
    if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan(skip_all => "Pod::Coverage $min_pc required for testing POD coverage") if $@;

all_pod_coverage_ok(
    { also_private => [qr/^(?:new|prototype|set_prototype|BUILD)$/] },
    'POD coverage, less what Object::Proto::Sugar installs'
);
