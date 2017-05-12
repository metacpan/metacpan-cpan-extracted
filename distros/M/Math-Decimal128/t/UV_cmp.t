use warnings;
use strict;
use Math::Decimal128 qw(:all);

print "1..1\n";

my $dec1 = NVtoD128(1.7);

my $uv = ~0;
my $uv_d128 = PVtoD128("$uv");

my($ok, $c);

if($dec1 * $uv > $uv)          {$ok .= 'a'}
if($dec1 < $uv)                {$ok .= 'b'}
if($uv_d128 == $uv)             {$ok .= 'c'}
if(($uv_d128 <=> $uv) == 0)     {$ok .= 'd'}
if(($dec1 * $uv <=> $uv) == 1) {$ok .= 'e'}
if(($dec1 <=> $uv) == -1)      {$ok .= 'f'}
if(!defined(NaND128() <=> $uv)) {$ok .= 'g'}

if($dec1 * $uv >= $uv)         {$ok .= 'h'}
if($dec1 <= $uv)               {$ok .= 'i'}


if($ok eq 'abcdefghi') {print "ok 1\n"}
else {
  warn "\n1: \$ok: $ok\n";
  print "not ok 1\n";
}
