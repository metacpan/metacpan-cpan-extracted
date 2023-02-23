
use strict;
use warnings;
use Math::MPFI qw(:mpfi);

print "1..4\n";

Rmpfi_set_default_prec(113);

my $nv = 1.2345678e-56;

my $fi = Rmpfi_init();

Rmpfi_set_NV($fi, $nv);

if($fi == $nv) {print "ok 1\n"}
else {
  warn "\n $fi != $nv\n";
  print "not ok 1\n";
}

if($nv == Rmpfi_get_NV($fi)) {print "ok 2\n"}
else {
  warn "\n $nv != ", Rmpfi_get_NV($fi), "\n";
  print "not ok 2\n";
}

Rmpfi_set_NV($fi, 999**(999**999));

if(Rmpfi_inf_p($fi)) {print "ok 3\n"}
else {
  warn "\n expected 'inf'\n got $fi\n";
  print "not ok 3\n";
}

$nv = Rmpfi_get_NV($fi);

if($nv == 999**(999**999)) {print "ok 4\n"}
else {
  warn "\n expected 'inf'\n got $nv\n";
  print "not ok 4\n";
}

