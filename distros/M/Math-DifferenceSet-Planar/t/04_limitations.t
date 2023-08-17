# Copyright (c) 2021-2023 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 04_limitations.t'

#########################

use strict;
use warnings;
use File::Spec;
use Config;
use Math::DifferenceSet::Planar;
use constant MDP => Math::DifferenceSet::Planar::;

use Test::More tests => 7;

#########################

my $bits = $Config{'ivsize'} * 8;
my $bool = MDP->available(5, $bits);
ok(!$bool);
SKIP: {
    skip 'from_lambda not implemented', 2 if !MDP->can('from_lambda');
    my $much = 1 << ($bits >> 1);
    my $ds   = eval { MDP->from_lambda($much, 1, 0) };
    ok(!defined($ds));
    like($@, qr/^order [0-9]+ too large for this platform/);
}

SKIP: {
    skip 'order 100K sets not supported', 4 if !MDP->available(99991);
    skip 'not using 64bit integers',      4 if !$Config{'use64bitint'};
    my $d1 = MDP->new(99991);
    my $d2 = eval { $d1->multiply(9998300071) };
    ok($d2, 'rotation successful');
    skip 'second set not computed',       3 if !$d2;
    my @e = $d2->elements;
    my $c = eval { MDP->from_elements(@e) };
    ok($c, 'difference set looks good');
    my @m = $d1->find_all_linear_maps($d2);
    ok(3 == @m, 'number of mappings');
    ok((1 == grep {; "9998300071 0" eq "@{$_}" } @m), 'mapping found');
}

__END__
