#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
	if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
	if $@;

# Object::Proto::Sugar installs new, prototype, set_prototype and BUILD on
# every class; exactly those four are excluded and nothing else. Every `has`
# accessor is ours to document.
#
# The modules are found under lib, not blib: ExtUtils::Depends writes
# Install/Files.pm into blib/arch on every configure, and all_pod_coverage_ok
# would read that generated file as a module of ours with no POD.
my @modules = all_modules('lib');
plan tests => scalar @modules;
pod_coverage_ok($_, { also_private => [ qr/\A(?:new|prototype|set_prototype|BUILD)\z/ ] })
	for @modules;
