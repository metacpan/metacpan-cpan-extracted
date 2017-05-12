use strict;
use warnings;
use Math::Float128 qw(:all);

print "1..11\n";

print "ok 1\n"; # so far, so good.

my ($check, $check1) = (NaNF128(), NaNF128());

erf_F128($check, NVtoF128(0.07));
erfc_F128($check1, NVtoF128(0.07));

if($check1 == UnityF128(1) - $check) {print "ok 2\n"}
else {
  warn "Expected complementary values\nbut erf returned $check\nand erfc returned $check1\n";
  print "not ok 2\n";
}

fma_F128($check, IVtoF128(10), NVtoF128(3.5), IVtoF128(15));

if($check == IVtoF128(50)) {print "ok 3\n"}
else {
  warn "\nExpected 50\nGot $check\n";
  print "not ok 3\n";
}

tgamma_F128($check, NVtoF128(1.25));

if(approx($check, 0.90640247705547705)) {print "ok 4\n"}
else {
  warn "\nExpected approx 0.90640247705547705\nGot $check\n";
  print "not ok 4\n";
}

lgamma_F128($check, NVtoF128(1.25));

if(approx($check, -0.0982718364218132)) {print "ok 5\n"}
else {
  warn "\nExpected approx -0.0982718364218132\nGot $check\n";
  print "not ok 5\n";
}

j0_F128($check, NVtoF128(1.25));

if(approx($check, 0.64590608527128524)) {print "ok 6\n"}
else {
  warn "\nExpected approx 0.64590608527128524\nGot $check\n";
  print "not ok 6\n";
}

j1_F128($check, NVtoF128(1.25));

if(approx($check, 0.51062326031988048)) {print "ok 7\n"}
else {
  warn "\nExpected approx 0.51062326031988048\nGot $check\n";
  print "not ok 7\n";
}

jn_F128($check, 2, NVtoF128(1.25));

if(approx($check, 0.17109113124052347)) {print "ok 8\n"}
else {
  warn "\nExpected approx 0.17109113124052347\nGot $check\n";
  print "not ok 8\n";
}

y0_F128($check, NVtoF128(1.25));

if(approx($check, 2.5821685159454077e-1)) {print "ok 9\n"}
else {
  warn "\nExpected approx 2.5821685159454077e-1\nGot $check\n";
  print "not ok 9\n";
}

y1_F128($check, NVtoF128(1.25));

if(approx($check, -5.8436403661500813e-1)) {print "ok 10\n"}
else {
  warn "\nExpected approx -5.8436403661500813e-1\nGot $check\n";
  print "not ok 10\n";
}

yn_F128($check, 2, NVtoF128(1.25));

if(approx($check, -1.1931993101785539)) {print "ok 11\n"}
else {
  warn "\nExpected approx -1.1931993101785539\nGot $check\n";
  print "not ok 11\n";
}


sub approx {
    my $eps = abs($_[0] - Math::Float128->new($_[1]));
    return 0 if $eps > Math::Float128->new(0.000000001);
    return 1;
}
