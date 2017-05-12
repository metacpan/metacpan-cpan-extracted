use warnings;
use strict;
use Devel::Peek;
use Math::GMPq qw(:mpq);
use Math::GMPz qw(:mpz);
use Math::MPFR qw(:mpfr);
use Math::MPC  qw(:mpc);
use Math::MPFI qw(:mpfi);

# A perl script to check that Math::GMPz, Math::GMPq, Math::GMPf,
# Math::MPFR, Math::MPC and Math::MPFI are (in various regards)
# behaving consistenctly and as expected.


my $inf_fin = '8876543210' x 3000;
my $inf = 999**(999**999);
my $ninf = $inf * -1;
my $nan = $inf / $inf;

my $dis = ($inf_fin > 0); # $inf_fin is now a POK/NOK dualvar.

# Check that NOK/POK inf/finite dualvar is handled by new()  and set_NV as expected.

my $q = Math::GMPq->new($inf_fin);
if("$q" eq '8876543210' x 3000) {print "ok 1\n"}
else {
  warn "\$q: $q\n";
  print "not ok 1\n";
}

eval {Rmpq_set_NV($q, $inf_fin);};

if($@ =~ /^In Rmpq_set_NV, cannot coerce an Inf to a Math::GMPq value/) {print "ok 2\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 2\n";
}

my $z = Math::GMPz->new($inf_fin);
if("$z" eq '8876543210' x 3000) {print "ok 3\n"}
else {
  warn "\$z: $z\n";
  print "not ok 3\n";
}

eval {Rmpz_set_NV($z, $inf_fin);};

if($@ =~ /^In Rmpz_set_NV, cannot coerce an Inf to a Math::GMPz value/) {print "ok 4\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 4\n";
}

my $fr = Math::MPFR->new($inf_fin);
if("$fr" eq '8.876543210887654e29999') {print "ok 5\n"} # Assuming that *is* the correct value. (Haven't checked.)
else {
  warn "\$fr: $fr\n";
  print "not ok 5\n";
}

if(Rmpfr_get_NV($fr, MPFR_RNDN) == $inf) {print "ok 6\n"}
else {
  warn Rmpfr_get_NV($fr) != $inf;
  print "not ok 6\n";
}

Rmpfr_set_NV($fr, $inf_fin, MPFR_RNDN);

if(Rmpfr_inf_p($fr)) {print "ok 7\n"}
else {
  warn "\$fr: $fr\n";
  print "not ok 7\n";
}

my $fi = Math::MPFI->new($inf_fin);
if("$fi" eq '[8.876543210887654e29999,8.8765432108876553e29999]') {print "ok 8\n"} # Assuming that *is* the correct
                                                                                # value. (Haven't checked.)
else {
  warn "\$fi: $fi\n";
  print "not ok 8\n";
}

if(Rmpfi_get_NV($fi) == $inf) {print "ok 9\n"}
else {
  warn Rmpfi_get_NV($fi) != $inf;
  print "not ok 9\n";
}

Rmpfi_set_NV($fi, $inf_fin);

if(Rmpfi_inf_p($fi)) {print "ok 10\n"}
else {
  warn "\$fi: $fi\n";
  print "not ok 10\n";
}

my $fc = Math::MPC->new($inf_fin);
if("$fc" eq '(8.876543210887654e29999 0)') {print "ok 11\n"} # Assuming that *is* the correct
                                                                                # value. (Haven't checked.)
else {
  warn "\$fc: $fc\n";
  print "not ok 11\n";
}

my $check = Math::MPFR->new();
RMPC_RE($check, $fc);

if(Rmpfr_get_NV($check, MPFR_RNDN) == $inf) {print "ok 12\n"}
else {
  warn Rmpfr_get_NV($check) != $inf;
  print "not ok 12\n";
}

Rmpc_set_NV($fc, $inf_fin, MPC_RNDNN);

RMPC_RE($check, $fc);

if(Rmpfr_inf_p($check)) {print "ok 13\n"}
else {
  warn "\$check: $check\n";
  print "not ok 13\n";
}

# Check that NOK/POK inf/finite dualvar is handled by set_str() and init_set_str()
# as expected.

Rmpq_set_str($q, $inf_fin, 10);

if("$q" eq '8876543210' x 3000) {print "ok 14\n"}
else {
  warn "\$q: $q\n";
  print "not ok 14\n";
}

my $z2 = Rmpz_init_set_str($inf_fin, 10);

if("$z2" eq '8876543210' x 3000) {print "ok 15\n"}
else {
  warn "\$q: $q\n";
  print "not ok 15\n";
}

Rmpz_set_str($z, $inf_fin, 10);

if("$z" eq '8876543210' x 3000) {print "ok 16\n"}
else {
  warn "\$q: $q\n";
  print "not ok 16\n";
}


