use warnings;
use strict;
use Math::GMPz qw(:mpz);
use Config;

print "1..3\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $_64 = Math::GMPz::_has_longlong();

my $ok = '';

if($_64) {print "Using 64-bit integer\n"}
else {print "Using 32-bit integer\n"}

if($_64) {
  use integer;
  my $int1 = Math::GMPz->new(2 ** 57 + 12345);
  $int1 *= -1;
  if(
     $int1 == -144115188075868217 &&
     $int1 == "-144115188075868217"
    ) {$ok = 'a'}

  my $pp1 = Rmpz_get_str($int1, 10);
  if($pp1 == -144115188075868217) {$ok .= 'b'}

  $pp1 += 14;

  my $int2 = Math::GMPz::new();
  Rmpz_set_str($int2, $pp1, 0);
  if($int2 == $pp1
     && $int2 - $int1 - 14 == 0
     && !($int2 - $int1 - 14)
     ) {$ok .= 'c'}

my $uintmax = ~0;
my $mpz1 = Math::GMPz->new($uintmax);
my $mpz2 = Math::GMPz::new($uintmax);

if($mpz1 == $mpz2 &&
   $mpz2 == $uintmax &&
   $uintmax == $mpz1) {$ok .= 'd'}


  if($ok eq 'abcd') {print "ok 1\n"}
  else {print "not ok 1 $ok\n"}
}


$ok = '';

if($_64) {
  my $int3;
  my $pp2 = 2 ** 57 + 12345;
  if(Math::GMPz::_itsa($pp2) == 2) {$ok = 'a1'}
  else {
   $int3 = Math::GMPz->new($pp2);
   if(Math::GMPz::_has_longdouble()) {
     if($int3 == "144115188075868217"){$ok = 'a2'}
   }
   else {
     if($int3 == "144115188075868224"){$ok = 'a3'}
     print "Beware ... you may not have the precision you think\n";
   }
  }

# By way of explanation regarding perls built with -Duse64bitint, but not -Duselongdouble:
# If you don't 'use integer;' then the assignment of 2 ** 57 + 12345 to $pp2 will mean
# that $pp2 is created as an NV (not an IV), and consequently incur a loss of precision - the
# result being that $pp2 holds a value of 144115188075868224, despite the fact that
# 2 ** 57 + 12345 == 144115188075868217. If one were to 'use integer;' then $pp2 would have
# been created as an IV and would have contained the correct value of 144115188075868217.
# It bothers me that perl behaves this way - but it doesn't bother anyone else, least of all
# those that are in a position to change the behaviour. So ... if you don't 'use integer;',
# you can easily end up assigning values that you don't really intend to assign - and you
# you won't even get a warning.

  if($ok =~ /a/) {print "ok 2 $ok\n"}
  else {print "not ok 2 \n"}
}

$ok = '';

if($_64) {
  my $int = Rmpz_init_set_ui(2);
  my $pint = -144115188075868217;

  if(Math::GMPz::_itsa($pint) == 2) {$ok .= 'a'}

  $int *= $pint;

  if($int == -288230376151736434
     && $int <= -288230376151736434
     && $int >= -288230376151736434
     && ($int <=> -288230376151736434) == 0
     && ($int <=> -288230376151736435) == 1
     && $int != -288230376151736435
    ) {$ok .= 'b'}

  $int += $pint;

  if($int == -432345564227604651
     && ($int <=> -432345564227604651) == 0
     && ($int <=> -432345564227604649) == -1
     && $int != -432345564227604653
    ) {$ok .= 'c'}

  $int -= $pint;

  if($int == -288230376151736434
     && $int == "-288230376151736434"
     && ($int <=> -288230376151736434) == 0
     && ($int <=> -288230376151736435) == 1
     && $int != -288230376151736435
    ) {$ok .= 'd'}

  if($ok eq 'abcd') {print "ok 3\n"}
  else {print "not ok 3 $ok\n"}
}

$ok = '';

if(!$_64) {
  my $uintmax = ~0;
  my $mpz1 = Math::GMPz->new($uintmax);
  my $mpz2 = Math::GMPz::new($uintmax);

  if($mpz1 == $mpz2 &&
     $mpz2 == $uintmax &&
     $uintmax == $mpz1) {print "ok 1\n"}
  else {print "not ok 1\n"}
  warn "Skipping test 2 - nothing to test\n";
  print "ok 2\n";
  warn "Skipping test3 - nothing to test\n";
  print "ok 3\n";
}
