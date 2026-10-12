#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# Object::Proto::Sugar gives every class new, prototype and set_prototype, and
# BUILD is its hook. Those four and nothing else are trusted: every accessor a
# `has` makes is ours to document.
all_pod_coverage_ok({ trustme => [qr/\A(?:new|prototype|set_prototype|BUILD)\z/] });
