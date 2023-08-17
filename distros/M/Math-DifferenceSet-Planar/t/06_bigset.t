# Copyright (c) 2022-2023 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 06_bigset.t'

#########################

use strict;
use warnings;
use File::Spec;
use Config;
use Math::DifferenceSet::Planar;
use constant MDP => Math::DifferenceSet::Planar::;

use Test::More;

#########################

my $ORDER     = 2096993;
my $DATABASE  = "extra_$ORDER.db";

diag("DB dir: $Math::DifferenceSet::Planar::Data::DATABASE_DIR");
my $have_data =
    MDP->available($ORDER) || eval { MDP->set_database($DATABASE) };
if (!$have_data) {
    plan skip_all => "order 2M set not available";
}
else {
    plan tests => 10;
}

my $ds1 = eval { MDP->new($ORDER) };
isa_ok($ds1, MDP, 'new set');
is($ds1->order, $ORDER, "order is $ORDER");

my $ds2 = eval { $ds1->multiply(19)->translate(1296013) };
isa_ok($ds2, MDP, 'multiplied+translated set');

my @maps = $ds1->find_all_linear_maps($ds2);
ok(3 == @maps, 'number of maps');
is("@{$maps[0]}", '19 1296013', 'first map is known map');

my @e2 = $ds2->elements;
my $ds3 = eval { MDP->from_elements(@e2) };
isa_ok($ds3, MDP, 'from elements created set');

@maps = $ds1->find_all_linear_maps($ds3);
ok(3 == @maps, 'number of maps');
is("@{$maps[0]}", '19 1296013', 'first map is known map');

my $x = ($ds2->largest_gap)[1];
my $ds4 = eval { MDP->from_elements(map { $_ == $x? $_-3461: $_ } @e2) };
is($ds4, undef, 'modified set rejected');
like($@,
    qr/
        ^(?:
            apparently[ ]not[ ]a[ ]planar[ ]difference[ ]set
        |
            bogus[ ]set:[ ]prime[ ]divisor[ ]2096993[ ]
            of[ ]order[ ]2096993[ ]is[ ]not[ ]a[ ]multiplier
        )
    /x,
    'rejection reason',
);

__END__
