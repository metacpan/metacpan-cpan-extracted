use warnings;
use strict;
use Math::GMPf qw(:mpf);
use Config;

print "1..1\n";

print "# Using gmp version ", Math::GMPf::gmp_v(), "\n";

my $_64 = Math::GMPf::_has_longlong();

if($_64) {print "Using 64-bit integer\n"}
else {print "Using 32-bit integer\n"}

Rmpf_set_default_prec(300);

my $ok = '';

if($_64) {
  use integer;
  my $int1 = Rmpf_init_set_str(2 ** 57 + 12345, 10);
  $int1 *= -1;
  if($int1 == -144115188075868217
     && $int1 == "-144115188075868217"

     && $int1 >= -144115188075868217
     && $int1 >= "-144115188075868217"

     && $int1 <= -144115188075868217
     && $int1 <= "-144115188075868217"

     && $int1 > -144115188075868218
     && $int1 > "-144115188075868218"

     && $int1 < -144115188075868216
     && $int1 < "-144115188075868216"

     && $int1 != -144115188075868216
     && $int1 != "-144115188075868216"

     && ($int1 <=> -144115188075868217) == 0
     && ($int1 <=> "-144115188075868217") == 0

     && ($int1 <=> -144115188075868218) > 0
     && ($int1 <=> "-144115188075868218") > 0

     && ($int1 <=> -144115188075868216) < 0
     && ($int1 <=> "-144115188075868216") < 0

    ) {$ok = 'a'}
  else {print "\$int1: $int1\n"}

  #print "\$int1: $int1\n";

  my $int2 = Rmpf_init();
  eval{Rmpf_set_str($int2, '1.5', 10);};
  $int1 =~ s/\./,/ if $@;
  Rmpf_set_str($int2, $int1, 10);
  $int1 += 14;
  if($int2 - $int1 + 14 == 0
     && !($int2 - $int1 + 14)
     ) {$ok .= 'b'}
  else {print "\$int1: $int1\n\$int2: $int2\n"}

  {
  no integer;
  $int2 -= 5 / 100; # $int2 is no longer an integer value
  }

  if($int2 != -144115188075868217
     && $int2 != "-144115188075868217"

     && $int2 >= -144115188075868218
     && $int2 >= "-144115188075868218"

     && $int2 <= -144115188075868217
     && $int2 <= "-144115188075868217"

     && $int2 > -144115188075868218
     && $int2 > "-144115188075868218"

     && $int2 < -144115188075868217
     && $int2 < "-144115188075868217"

     && ($int2 <=> -144115188075868217) < 0
     && ($int2 <=> "-144115188075868217") < 0

     && ($int2 <=> -144115188075868218) > 0
     && ($int2 <=> "-144115188075868218") > 0

    ) {$ok .= 'c'}
  else {print "\$int2: $int2\n"}

  my $uintmax = ~0;
  my $mpf1 = Math::GMPf->new($uintmax);
  my $mpf2 = Math::GMPf::new($uintmax);

  if($mpf1 == $mpf2 &&
     $mpf2 == $uintmax &&
     $uintmax == $mpf1) {$ok .= 'd'}

  if($ok eq 'abcd') {print "ok 1\n"}
  else {print "not ok 1 $ok\n"}
}

else {
  my $uintmax = ~0;
  my $mpf1 = Math::GMPf->new($uintmax);
  my $mpf2 = Math::GMPf::new($uintmax);

  if($mpf1 == $mpf2 &&
     $mpf2 == $uintmax &&
     $uintmax == $mpf1) {print "ok 1\n"}
  else {print "not ok 1\n"}
}
