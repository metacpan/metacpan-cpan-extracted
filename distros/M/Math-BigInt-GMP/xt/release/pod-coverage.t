#!perl

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        print "1..0 # SKIP these tests are for release candidate testing";
        exit;
    }
}

use strict;                     # restrict unsafe constructs
use warnings;                   # enable optional warnings

use Test::More;

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

my $trustme = {
               # By default, the "private" key includes qr/^_/,
               private => [ qr/^__/,
                            qr/^(un)?import$/,
                            qr/^DESTROY$/,
                            qr/^bootstrap$/,
                          ],
               trustme => [ 'api_version',
                            'STORABLE_freeze',
                            'STORABLE_thaw',
                            '_new_attach',
                            '_set',
                          ],
               coverage_class => 'Pod::Coverage::CountParents',
              };

all_pod_coverage_ok($trustme, "All modules are covered");
