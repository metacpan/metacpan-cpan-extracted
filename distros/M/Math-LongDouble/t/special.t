use strict;
use warnings;
use Math::LongDouble qw(:all);

print "1..5\n";

print "ok 1\n"; # so far, so good.

my ($check, $check1) = (NaNLD(), NaNLD());

erf_LD($check, NVtoLD(0.07));
erfc_LD($check1, NVtoLD(0.07));

#print "\n$check\n$check1\n\n";

if($check1 == UnityLD(1) - $check) {print "ok 2\n"}
elsif(approx2($check1, UnityLD(1) - $check)) {
  warn "\nAccepting that $check1 and ", UnityLD(1) - $check, " are not exact complements\n",
        "Most likely erfl and/or erfcl do not provide advertised precision\n";
  print "ok 2\n";
}
else {
  warn "Expected complementary values\nbut erf returned $check\nand erfc returned $check1\n";
  print "not ok 2\n";
}

fma_LD($check, IVtoLD(10), NVtoLD(3.5), IVtoLD(15));

if($check == IVtoLD(50)) {print "ok 3\n"}
else {
  warn "\nExpected 50\nGot $check\n";
  print "not ok 3\n";
}

tgamma_LD($check, NVtoLD(1.25));

if(approx($check, 0.90640247705547705)) {print "ok 4\n"}
else {
  warn "\nExpected approx 0.90640247705547705\nGot $check\n";
  print "not ok 4\n";
}

lgamma_LD($check, NVtoLD(1.25));

if(approx($check, -0.0982718364218132)) {print "ok 5\n"}
else {
  warn "\nExpected approx -0.0982718364218132\nGot $check\n";
  print "not ok 5\n";
}

sub approx {
    my $eps = abs($_[0] - Math::LongDouble->new($_[1]));
    return 0 if $eps > Math::LongDouble->new(0.000000001);
    return 1;
}

sub approx2 {
    my $eps = abs($_[0] - Math::LongDouble->new($_[1]));
    return 0 if $eps > Math::LongDouble->new('1e-16');
    return 1;
}

__END__

#Not implemented

j0_LD($check, NVtoLD(1.25));

if(approx($check, 0.64590608527128524)) {print "ok 6\n"}
else {
  warn "\nExpected approx 0.64590608527128524\nGot $check\n";
  print "not ok 6\n";
}

j1_LD($check, NVtoLD(1.25));

if(approx($check, 0.51062326031988048)) {print "ok 7\n"}
else {
  warn "\nExpected approx 0.51062326031988048\nGot $check\n";
  print "not ok 7\n";
}

jn_LD($check, 2, NVtoLD(1.25));

if(approx($check, 0.17109113124052347)) {print "ok 8\n"}
else {
  warn "\nExpected approx 0.17109113124052347\nGot $check\n";
  print "not ok 8\n";
}

y0_LD($check, NVtoLD(1.25));

if(approx($check, 2.5821685159454077e-1)) {print "ok 9\n"}
else {
  warn "\nExpected approx 2.5821685159454077e-1\nGot $check\n";
  print "not ok 9\n";
}

y1_LD($check, NVtoLD(1.25));

if(approx($check, -5.8436403661500813e-1)) {print "ok 10\n"}
else {
  warn "\nExpected approx -5.8436403661500813e-1\nGot $check\n";
  print "not ok 10\n";
}

yn_LD($check, 2, NVtoLD(1.25));

if(approx($check, -1.1931993101785539)) {print "ok 11\n"}
else {
  warn "\nExpected approx -1.1931993101785539\nGot $check\n";
  print "not ok 11\n";
}

