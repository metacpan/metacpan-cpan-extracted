#!perl -T

use Test::More tests => 5 * 6;
use Games::EternalLands::Binary::Float16 ':all';

my @v = (1.234, -567.8, 0.003, -0.123, 1234.0, 12345.789);
for my $f (@v) {
  my $s = pack_float16($f);
  ok(defined $s, "pack($f) returns defined value");
  ok($s >= 0, "pack($f) returns non-negative integer ($s)");
  ok($s < 65536, "pack($f) returns unsigned short ($s)");
  my $g = unpack_float16($s);
  ok(defined $g, "unpack($s) returns defined value ($g)");
  my $e = abs(($f - $g) / $f) * 100.0;
  my $m = 0.5;
  cmp_ok($e, '<', $m, "percent error (|$f - $g| / |$f| = $e%) is less than $m%");
}
