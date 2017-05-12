use strict;
use warnings;
use Math::GMPf qw(:mpf);

print "1..8\n";

my $prec;

$prec = Math::GMPf::_required_ldbl_mant_dig() == 2098 ? 2098 : 113;

warn "\n# Precision: $prec\n";

Rmpf_set_default_prec($prec);

my $nv = 1.2345678e-53;

my $fi = Rmpf_init();

Rmpf_set_NV($fi, $nv);

if($fi == $nv) {print "ok 1\n"}
else {
  warn "\n $fi != $nv\n";
  print "not ok 1\n";
}

if($nv == Rmpf_get_NV($fi)) {print "ok 2\n"}
else {
  warn "\n $nv != ", Rmpf_get_NV($fi), "\n";
  print "not ok 2\n";
}


my $inf = 999**(999**999);
my $nan = $inf / $inf;

eval {Rmpf_set_NV($fi, $inf);};

if($@ =~ /cannot coerce an Inf to a Math::GMPf object/) {print "ok 3\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 3\n";
}

eval {Rmpf_set_NV($fi, $nan);};

if($@ =~ /cannot coerce a NaN to a Math::GMPf object/) {print "ok 4\n"}
else {
  warn "\n \$\@: $@\n";
  print "not ok 4\n";
}

$nv = -123.45678;

Rmpf_set_NV($fi, $nv);

if($fi == $nv) {print "ok 5\n"}
else {
  warn "\n $fi != $nv\n";
  print "not ok 5\n";
}

if($nv == Rmpf_get_NV($fi)) {print "ok 6\n"}
else {
  warn "\n $nv != ", Rmpf_get_NV($fi), "\n";
  print "not ok 6\n";
}

$nv = -123456.78e70;

Rmpf_set_NV($fi, $nv);

if($fi == $nv) {print "ok 7\n"}
else {
  warn "\n $fi != $nv\n";
  print "not ok 7\n";
}

if($nv == Rmpf_get_NV($fi)) {print "ok 8\n"}
else {
  warn "\n $nv != ", Rmpf_get_NV($fi), "\n";
  print "not ok 8\n";
}



