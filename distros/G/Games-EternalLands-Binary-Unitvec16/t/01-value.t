#!perl -T

use Test::More tests => 14;
use Games::EternalLands::Binary::Unitvec16 ':all';

my $v = [1, 0, 0];
my $s = pack_unitvec16($v);
ok(defined $s, "pack returns defined value");
ok($s >= 0, "pack returns non-negative integer");
ok($s < 65536, "pack returns unsigned short");
ok($v->[0] == 1, "pack did not modify 1st component");
ok($v->[1] == 0, "pack did not modify 2st component");
ok($v->[2] == 0, "pack did not modify 3st component");
my $t = 12345;
my $u = unpack_unitvec16($t);
ok(defined $u, "unpack returns defined value");
ok(ref($u) eq 'ARRAY', "unpack returns array reference");
ok(@$u == 3, "unpack returns vector with 3 components");
ok(defined($u->[0]), "unpacked 1st component is defined");
ok(defined($u->[1]), "unpacked 2st component is defined");
ok(defined($u->[2]), "unpacked 3st component is defined");
my $l = sqrt($u->[0]*$u->[0] + $u->[1]*$u->[1] + $u->[2]*$u->[2]);
ok(defined $l, "returned vector has defined length");
cmp_ok(abs($l - 1.0), '<', 0.01, "returned vector is close to unit length");
