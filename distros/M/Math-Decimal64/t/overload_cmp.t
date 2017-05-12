use warnings;
use strict;
use Math::Decimal64 qw(:all);
use Config;

print "1..10\n";

my $have_ld = $Config::Config{nvsize} > 8 ? 1 : 0;

my $dec1 = NVtoD64(1.7);
$dec1 /= 20;

if($dec1 == MEtoD64('85', -3)) {print "ok 1\n"}
else {
  warn "\n1: \$dec1: $dec1\n";
  print "not ok 1\n";
}

my $nv = 1.7;
$nv /= 20;

if($nv == 0.085) {warn "\n1: Unexpected result, but ok\n" unless $have_ld}
print "ok 2\n";

assignME($dec1, '17', -1);
$dec1 *= MEtoD64('209', -1);
if($dec1 == MEtoD64('3553', -2)) {print "ok 3\n"}
else {
  warn "\n3: \$dec1 : $dec1\n";
  print "not ok 3\n";
}

$nv = 1.7;
$nv *= 20.9;

if($nv == 35.53) {warn "\n4: Unexpected result, but ok\n" unless $have_ld}
print "ok 4\n";

# Test 5 demonstrates the unreliability of NVtoD64() as regards accuracy.
# For me, D64toME(NVtoD64(0.085)) returns ('8500000000000001', -17).
if(NVtoD64(0.085) == MEtoD64('85', -3)) {warn "\n5: Unexpected but desirable result\n" unless $have_ld}
print "ok 5\n";

if(PVtoD64(0.085) == MEtoD64('85', -3)) {print "ok 6\n"}
else {
  my @me = D64toME(PVtoD64(0.085));
  warn "\n6: @me\n";
  print "not ok 6\n";
}

if(PVtoD64(8.5e-2) == MEtoD64('85', -3)) {print "ok 7\n"}
else {
  my @me = D64toME(PVtoD64(8.5e-2));
  warn "\n7: @me\n";
  print "not ok 7\n";
}

$nv = 0.085;

if(PVtoD64("$nv") == MEtoD64('85', -3)) {print "ok 8\n"}
else {
  my @me = D64toME(PVtoD64("$nv"));
  warn "\n8: @me\n";
  print "not ok 8\n";
}

if(Math::Decimal64::_itsa($nv) == 3) {print "ok 9\n"}
else {
  warn "\n9: ", Math::Decimal64::_itsa($nv), "\n";
  print "not ok 9\n";
}

assignME($dec1, '17', -1);

my($ok, $c);

if($dec1 > -1)                {$ok .= 'a'}
if($dec1 < 2)                 {$ok .= 'b'}
if($dec1 * 30 == 51)          {$ok .= 'c'}
if(($dec1 * 30 <=> 51) == 0)  {$ok .= 'd'}
if(($dec1 <=> 1) == 1)        {$ok .= 'e'}
if(($dec1 <=> 2) == -1)       {$ok .= 'f'}
if(!defined(NaND64() <=> 5))  {$ok .= 'g'}

eval{$c = ($dec1 > $nv)};
if($@)                        {$ok .= 'h'}

eval{$c = ($dec1 < $nv)};
if($@)                        {$ok .= 'i'}

eval{$c = ($dec1 == $nv)};
if($@)                        {$ok .= 'j'}

eval{$c = ($dec1 <=> $nv)};
if($@)                        {$ok .= 'k'}

if($dec1 >= -1)               {$ok .= 'l'}
if($dec1 <= 2)                {$ok .= 'm'}

eval{$c = ($dec1 >= $nv)};
if($@)                        {$ok .= 'n'}

eval{$c = ($dec1 <= $nv)};
if($@)                        {$ok .= 'o'}

if($ok eq 'abcdefghijklmno') {print "ok 10\n"}
else {
  warn "\n10: \$ok: $ok\n";
  print "not ok 10\n";
}
