use strict;
use warnings;
use Math::GMPz qw(:mpz);

#$| = 1;
print "1..13\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my
 $n1 = '10101010101010101111111111111111111111000000001110101';
my
 $n2 =  '1010101010101010000000000000000000000111111110001010';

my $y = Rmpz_init_set_str($n1, 2);
my $x = Rmpz_init_set_str( $n2, 2);
my $z = Rmpz_init2(45);
my $q = Rmpz_init();
my $r = Rmpz_init2(45);
my $p = Rmpz_init();
my $ret;
my $ul = 1009;

Rmpz_powm($z, $x, $y, $y);
if(Rmpz_get_str($z, 10) eq '729387446576188')
     {print "ok 1\n"}
else {print "not ok 1\n"}

Rmpz_powm_ui($z, $x, $ul, $y);
if(Rmpz_get_str($z, 10) eq '4846795053899029')
     {print "ok 2\n"}
else {print "not ok 2\n"}

Rmpz_pow_ui($z, $z, 3);
if(Rmpz_get_str($z, 10) eq '113858109386036422141170669965214409511474201389')
     {print "ok 3\n"}
else {print "not ok 3\n"}

Rmpz_set($q, $z);

Rmpz_ui_pow_ui($z, $ul, 7);
if(Rmpz_get_str($z, 10) eq '1064726745878753869969')
     {print "ok 4\n"}
else {print "not ok 4\n"}

$ret = Rmpz_root($z, $z, 7);
if($ret != 0
   &&
   Rmpz_get_str($z, 10) eq $ul)
     {print "ok 5\n"}
else {print "not ok 5\n"}

Rmpz_sqrt($z, $q);
if(Rmpz_get_str($z, 10) eq '337428673034815495866230')
     {print "ok 6\n"}
else {print "not ok 6\n"}

Rmpz_sqrtrem($z, $r, $q);
if(Rmpz_get_str($z, 10) eq '337428673034815495866230'
   &&
   Rmpz_get_str($r, 10) eq '602387222931293419788489')
     {print "ok 7\n"}
else {print "not ok 7\n"}

if(Rmpz_perfect_power_p($q))
     {print "ok 8\n"}
else {print "not ok 8\n"}

if(!Rmpz_perfect_square_p($q))
     {print "ok 9\n"}
else {print "not ok 9\n"}

Rmpz_set_ui($z, 90);
Rmpz_rootrem($p, $q, $z, 4);
if($p == 3 && $q == 9) {print "ok 10\n"}
else {print "not ok 10\n$p $q\n"}

if(Math::GMPz::__GNU_MP_VERSION > 4 && !Math::GMPz::_using_mpir()) {
  Rmpz_powm_sec($z, $x, $y, $y);
  if(Rmpz_get_str($z, 10) eq '729387446576188')
       {print "ok 11\n"}
  else {print "not ok 11\n"}
}
else {
  eval{Rmpz_powm_sec($z, $x, $y, $y);};
  if($@ =~ /Rmpz_powm_sec not implemented/)
       {print "ok 11\n"}
  else {print "not ok 11\n"}
}

eval{$q = $p ** -1;};
if($@ =~ /Negative argument/) {
  print "ok 12\n";
}
else {
  warn "\$\@: $@\n";
  print "not ok 12\n";
}
eval{$p **= -1;};
if($@ =~ /Negative argument/) {
  print "ok 13\n";
}
else {
  warn "\$\@: $@\n";
  print "not ok 13\n";
}
