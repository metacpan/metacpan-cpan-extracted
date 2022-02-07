use warnings;
use strict;
use Math::MPFR qw(:mpfr);

print "1..1\n";

print  "# Using Math::MPFR version ", $Math::MPFR::VERSION, "\n";
print  "# Using mpfr library version ", MPFR_VERSION_STRING, "\n";
print  "# Using gmp library version ", Math::MPFR::gmp_v(), "\n";

my $rop1 = Math::MPFR->new();
my $rop2 = Math::MPFR->new();
my $state1 = Rmpfr_randinit_default();
my $state2 = Rmpfr_randinit_lc_2exp('123456789123456789', 98765432123456789, 50);
my $state3 = Rmpfr_randinit_lc_2exp_size(100);
my $state4 = Rmpfr_randinit_mt();

Rmpfr_randseed($state1, '2345678909876543210');
Rmpfr_randseed($state2, '3456789098765432123');
Rmpfr_randseed_ui($state3, 12345678909);

my $ok = '';


if(MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) {
  Rmpfr_grandom($rop1, $rop2, $state1, GMP_RNDN);
  if($rop1 && $rop2 && $rop1 != $rop2
     && !Rmpfr_nan_p($rop1) && !Rmpfr_nan_p($rop2)) {$ok .= 'a'}

  #print "$rop1 $rop2\n";

  Rmpfr_grandom($rop1, $rop2, $state2, GMP_RNDN);
  if($rop1 && $rop2 && $rop1 != $rop2
     && !Rmpfr_nan_p($rop1) && !Rmpfr_nan_p($rop2)) {$ok .= 'b'}

  #print "$rop1 $rop2\n";

  Rmpfr_grandom($rop1, $rop2, $state3, GMP_RNDN);
  if($rop1 && $rop2 && $rop1 != $rop2
     && !Rmpfr_nan_p($rop1) && !Rmpfr_nan_p($rop2)) {$ok .= 'c'}

  #print "$rop1 $rop2\n";

  Rmpfr_grandom($rop1, $rop2, $state4, GMP_RNDN);
  if($rop1 && $rop2 && $rop1 != $rop2
     && !Rmpfr_nan_p($rop1) && !Rmpfr_nan_p($rop2)) {$ok .= 'd'}

  #print "$rop1 $rop2\n";

  if($ok eq 'abcd') {print "ok 1\n"}
  else {
    warn "1: \$ok: $ok\n";
    print "not ok 1\n";
  }
}
else {
  eval{Rmpfr_grandom($rop1, $rop2, $state1, GMP_RNDN);};
  if(MPFR_VERSION_MAJOR > 3) {
    if($@ =~ /Rmpfr_grandom is deprecated/) {print "ok 1\n"}
    else {
      warn "\$\@: $@";
      print "not ok 1\n";
    }
  }
  else {
    if($@ =~ /Rmpfr_grandom was not introduced/) {print "ok 1\n"}
    else {
      warn "\$\@: $@";
      print "not ok 1\n";
    }
  }
}
