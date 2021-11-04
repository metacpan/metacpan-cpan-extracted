# Copyright (c) 2020-2021 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 03_aurifeuille.t'

use strict;
use warnings;
use Math::Polynomial::Cyclotomic qw(:all);

use Test::More tests => 58;

my $table = {};

my ($c, $d) = cyclo_lucas_cd(13, $table);
is(join(q[ ], $c->coeff), '1 7 15 19 15 7 1');
is(join(q[ ], $d->coeff), '1 3 5 5 3 1');
my ($C, $D) = cyclo_schinzel_cd(13, 13, $table);
is("$C", "$c");
is("$D", "$d");

($c, $d) = cyclo_lucas_cd(14, $table);
is(join(q[ ], $c->coeff), '1 7 3 -7 3 7 1');
is(join(q[ ], $d->coeff), '1 2 -1 -1 2 1');
($c, $d) = cyclo_lucas_cd(15, $table);
is(join(q[ ], $c->coeff), '1 8 13 8 1');
is(join(q[ ], $d->coeff), '1 3 3 1');
($c, $d) = cyclo_lucas_cd(39, $table);
is(join(q[ ], $c->coeff), '1 20 73 119 142 173 193 173 142 119 73 20 1');
is(join(q[ ], $d->coeff), '1 7 16 21 25 30 30 25 21 16 7 1');

($C, $D) = cyclo_schinzel_cd(12, 2, $table);
is(join(q[ ], $C->coeff), '1 1 1');
is(join(q[ ], $D->coeff), '1 1');
($C, $D) = cyclo_schinzel_cd(18, 3, $table);
is(join(q[ ], $C->coeff), '1 0 0 1');
is(join(q[ ], $D->coeff), '0 1');
($C, $D) = cyclo_schinzel_cd(36, 2, $table);
is(join(q[ ], $C->coeff), '1 0 0 1 0 0 1');
is(join(q[ ], $D->coeff), '0 1 0 0 1');
($C, $D) = cyclo_schinzel_cd(15, 5, $table);
is(join(q[ ], $C->coeff), '1 2 3 2 1');
is(join(q[ ], $D->coeff), '1 1 1 1');
($C, $D) = cyclo_schinzel_cd(45, 5, $table);
is(join(q[ ], $C->coeff), '1 0 0 2 0 0 3 0 0 2 0 0 1');
is(join(q[ ], $D->coeff), '0 1 0 0 1 0 0 1 0 0 1');
($C, $D) = cyclo_schinzel_cd(60, 2, $table);
is(join(q[ ], $C->coeff), '1 1 2 3 3 3 2 1 1');
is(join(q[ ], $D->coeff), '1 1 2 2 2 2 1 1');

my @f = cyclo_int_factors(13, 13, $table);
is("@f", '12 1803647 13993643');
@f = cyclo_int_factors(52, 13, $table);
is("@f", '51 12070179083 33018670127');
@f = cyclo_int_factors(13, 39, $table);
is("@f", '12 183 1803647 13993643 8680819918681 57745124662681');
@f = cyclo_int_factors(14, 28, $table);
is("@f", '13 15 197 8108731 7027567 2826601 19955461');
@f = cyclo_int_factors(15, 30, $table);
is("@f", '14 16 241 54241 211 47461 2392743361 19231 142111');
@f = cyclo_int_factors(144, 15, $table);
is("@f", '11 13 157 22621 7 19 19141 394379701 13051 35671');
@f = cyclo_int_factors(9, 15, $table);
is("@f", '2 4 13 121 7 61 4561 31 271');
@f = cyclo_int_factors(48, 6, $table);
is("@f", '47 49 2353 37 61');
@f = cyclo_int_factors(3, 0, $table);
is("@f", '0');
@f = cyclo_int_factors(1, 3, $table);
is("@f", '0');
@f = cyclo_int_factors(3, 1, $table);
is("@f", '2');
@f = cyclo_int_factors(0, 3, $table);
is("@f", '-1');
@f = cyclo_int_factors(2, 8, $table);
is("@f", '3 5 17');

@f = cyclo_int_plusfactors(14, 14, $table);
is("@f", '197 2826601 19955461');
@f = cyclo_int_plusfactors(56, 14, $table);
is("@f", '3137 18758166253 50690605477');
@f = cyclo_int_plusfactors(15, 15, $table);
is("@f", '16 211 47461 19231 142111');
@f = cyclo_int_plusfactors(60, 15, $table);
is("@f", '61 3541 12747541 7925851 21544711');
@f = cyclo_int_plusfactors(144, 15, $table);
is("@f", '145 20593 427016305 186168115009253521');
@f = cyclo_int_plusfactors(9, 15, $table);
is("@f", '10 73 5905 47763361');
@f = cyclo_int_plusfactors(3, 0, $table);
is("@f", '2');
@f = cyclo_int_plusfactors(1, 3, $table);
is("@f", '2');
@f = cyclo_int_plusfactors(3, 1, $table);
is("@f", '4');
@f = cyclo_int_plusfactors(0, 3, $table);
is("@f", '1');
@f = cyclo_int_plusfactors(5, 9, $table);
is("@f", '6 21 15501');

my @cd = eval { cyclo_lucas_cd(1) };
ok(!@cd);
like($@, qr/^1: not a square-free integer greater than one /);
@cd = eval { cyclo_lucas_cd(4) };
ok(!@cd);
like($@, qr/^4: not a square-free integer greater than one /);

@cd = eval { cyclo_schinzel_cd(3, 1) };
ok(!@cd);
like($@, qr/^1: not a square-free integer greater than one /);
@cd = eval { cyclo_schinzel_cd(4, 4) };
ok(!@cd);
like($@, qr/^4: not a square-free integer greater than one /);
@cd = eval { cyclo_schinzel_cd(10, 5) };
ok(!@cd);
like($@, qr/^10: n is not an odd multiple of k /);
@cd = eval { cyclo_schinzel_cd(8, 2) };
ok(!@cd);
like($@, qr/^8: n is not an odd multiple of 2\*k /);

__END__
