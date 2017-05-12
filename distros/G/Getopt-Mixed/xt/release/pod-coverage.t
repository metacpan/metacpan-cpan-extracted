#! /usr/bin/perl -T
#---------------------------------------------------------------------
# release-pod-coverage.t
#---------------------------------------------------------------------

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my @private = map { qr/^\Q$_\E$/ } qw(
  findMatch
);

my @trust = map { qr/^\Q$_\E$/ } qw(
  abortMsg badOption checkArg cleanup getOptions init nextOption
);

all_pod_coverage_ok({
  also_private => \@private,
  trustme      => \@trust,
});
