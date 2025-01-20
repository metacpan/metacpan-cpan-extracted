use strict;
use warnings;
use Config;
use Math::FakeDD qw(:all);

use Test::More;

my @res = split /\n/, dd_dump($Math::FakeDD::DD_MAX);
cmp_ok(@res, '==', 3, "dd_dump splits as expected");
cmp_ok($res[0], 'eq', '[1.7976931348623157e+308 9.979201547673598e+291]', "decimal representation of DD_MAX is as expected");

if($Config{nvtype} eq 'double' || $Config{nvtype} eq '__float128') {
  cmp_ok($res[1], 'eq', '[0x1.fffffffffffffp+1023 0x1.fffffffffffffp+969]', "hex representation of DD_MAX is as expected");
}
else {
  # On -Duselongdouble builds, there are 4 acceptablw alternatives for presenting
  # "%a" formats when the long double is the 80-bit (extended precision) type.
  # For DD_MAX, those 4 alternatives (all of which are numerically equivalent to
  # each other) are
  # [0x1.fffffffffffffp+1023 0x1.fffffffffffffp+969]
  # [0x3.ffffffffffffep+1022 0x3.ffffffffffffep+968]
  # [0x7.ffffffffffffcp+1021 0x7.ffffffffffffcp+967]
  # [0xf.ffffffffffff8p+1020 0xf.ffffffffffff8p+966]
  # I believe that -Duselongdouble builds of perl will always present the last
  # of those 4 formats, but we'll also allow for the others.
  my $cmp = 0;
  for my $str( '[0x1.fffffffffffffp+1023 0x1.fffffffffffffp+969]', '[0x3.ffffffffffffep+1022 0x3.ffffffffffffep+968]',
       '[0x7.ffffffffffffcp+1021 0x7.ffffffffffffcp+967]', '[0xf.ffffffffffff8p+1020 0xf.ffffffffffff8p+966]') {
    $cmp = 1 if $str eq $res[1];
  }
  cmp_ok($cmp, '==', 1, "found a hex match for $res[1]");
}

cmp_ok($res[2], 'eq',
      '0.11111111111111111111111111111111111111111111111111111011111111111111111111111111111111111111111111111111111E1024', "mpfr key holds correct value");

my $inf = dd_nextup($Math::FakeDD::DD_MAX);
@res = split /\n/, dd_dump($inf);
like($res[0], qr/^\[Inf 0\]$/i,  "decimal representation of Inf is as expected");
like($res[1], qr/^\[Inf 0x0/i,  "hex representation of Inf is as expected");
like($res[0], qr/^\[Inf 0\]$/i,  "decimal representation of Inf is as expected");
like($res[2], qr/^\@Inf\@$/i,  "mpfr representation of Inf is as expected");

my $nan = $inf / $inf;
@res = split /\n/, dd_dump($nan);

like($res[0], qr/^\[NaN 0\]$/i,  "decimal representation of NaN is as expected");
like($res[1], qr/^\[NaN 0x0/i,  "hex representation of NaN is as expected");
like($res[0], qr/^\[NaN 0\]$/i,  "decimal representation of NaN is as expected");
like($res[2], qr/^\@NaN\@$/i,  "mpfr representation of NaN is as expected");
done_testing();
