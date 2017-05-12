use strict;
use warnings;
use Math::GMPz qw(:mpz);

print "1..17\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $ui = 12345679;
my $mpz = Math::GMPz->new($ui);
my @s;
my @r;

############################
############################

push @r, Math::GMPz->new() for (1..6);

$s[0] = zgmp_randinit_default();
zgmp_randseed($s[0], $mpz);
$s[1] = zgmp_randinit_default();
zgmp_randseed_ui($s[1], $ui);
$s[2] = zgmp_randinit_set($s[0]);
$s[3] = zgmp_randinit_set($s[1]);
$s[4] = zgmp_randinit_set($s[2]);
$s[5] = zgmp_randinit_set($s[3]);


Rmpz_urandomm($r[0], $s[0], $mpz, 1);
Rmpz_urandomm($r[1], $s[1], $mpz, 1);

if($r[0] == $r[1]) {print "ok 1\n"}
else {
  warn "\$r[0] : $r[0]\n\$r[1] : $r[1]\n";
  print "not ok 1\n";
}

Rmpz_urandomb($r[2], $s[2], 200, 1);
Rmpz_urandomb($r[3], $s[3], 200, 1);

if($r[2] == $r[3]) {print "ok 2\n"}
else {
  warn "\$r[2] : $r[2]\n\$r[3] : $r[3]\n";
  print "not ok 2\n";
}

Rmpz_rrandomb($r[4], $s[4], 200, 1);
Rmpz_rrandomb($r[5], $s[5], 200, 1);

if($r[4] == $r[5]) {print "ok 3\n"}
else {
  warn "\$r[4] : $r[4]\n\$r[5] : $r[5]\n";
  print "not ok 3\n";
}

undef($_) for @s;
undef($_) for @r;

#############################
#############################

my $r1 = Math::GMPz->new();
my $r2 = Math::GMPz->new();

$s[0] = zgmp_randinit_default();
zgmp_randseed($s[0], $mpz);
$s[1] = zgmp_randinit_mt();
zgmp_randseed_ui($s[1], $ui);
$s[2] = zgmp_randinit_set($s[0]);
$s[3] = zgmp_randinit_set($s[1]);
$s[4] = zgmp_randinit_set($s[2]);
$s[5] = zgmp_randinit_set($s[3]);

Rmpz_urandomm($r1, $s[0], $mpz, 1);
Rmpz_urandomm($r2, $s[5], $mpz, 1);

if($r1 == $r2) {print "ok 4\n"}
else {
  warn "\$r1 : $r1\n\$r2] : $r2]\n";
  print "not ok 4\n";
}

Rmpz_urandomb($r1, $s[2], 200, 1);
Rmpz_urandomb($r2, $s[3], 200, 1);

if($r1 == $r2) {print "ok 5\n"}
else {
  warn "\$r[2] : $r[2]\n\$r[3] : $r[3]\n";
  print "not ok 5\n";
}

Rmpz_rrandomb($r1, $s[4], 200, 1);
Rmpz_rrandomb($r2, $s[1], 200, 1);

if($r1 == $r2) {print "ok 6\n"}
else {
  warn "\$r[4] : $r[4]\n\$r[5] : $r[5]\n";
  print "not ok 6\n";
}

undef($_) for @s;

#############################
#############################

$s[0] = zgmp_randinit_lc_2exp($mpz, $ui - 5, 24);
zgmp_randseed($s[0], $mpz);
$s[1] = zgmp_randinit_lc_2exp($mpz, $ui - 5, 24);
zgmp_randseed_ui($s[1], $ui);
$s[2] = zgmp_randinit_set($s[0]);
$s[3] = zgmp_randinit_set($s[1]);
$s[4] = zgmp_randinit_set($s[2]);
$s[5] = zgmp_randinit_set($s[3]);

Rmpz_urandomm($r1, $s[0], $mpz, 1);
Rmpz_urandomm($r2, $s[5], $mpz, 1);

if($r1 == $r2) {print "ok 7\n"}
else {
  warn "\$r1 : $r1\n\$r2] : $r2]\n";
  print "not ok 7\n";
}

Rmpz_urandomb($r1, $s[2], 200, 1);
Rmpz_urandomb($r2, $s[3], 200, 1);

if($r1 == $r2) {print "ok 8\n"}
else {
  warn "\$r[2] : $r[2]\n\$r[3] : $r[3]\n";
  print "not ok 8\n";
}

Rmpz_rrandomb($r1, $s[4], 200, 1);
Rmpz_rrandomb($r2, $s[1], 200, 1);

if($r1 == $r2) {print "ok 9\n"}
else {
  warn "\$r[4] : $r[4]\n\$r[5] : $r[5]\n";
  print "not ok 9\n";
}

undef($_) for @s;

#############################
#############################

$s[0] = zgmp_randinit_lc_2exp_size(91);
zgmp_randseed($s[0], $mpz);
$s[1] = zgmp_randinit_lc_2exp_size(91);
zgmp_randseed_ui($s[1], $ui);
$s[2] = zgmp_randinit_set($s[0]);
$s[3] = zgmp_randinit_set($s[1]);
$s[4] = zgmp_randinit_set($s[2]);
$s[5] = zgmp_randinit_set($s[3]);

Rmpz_urandomm($r1, $s[0], $mpz, 1);
Rmpz_urandomm($r2, $s[5], $mpz, 1);

if($r1 == $r2) {print "ok 10\n"}
else {
  warn "\$r1 : $r1\n\$r2] : $r2]\n";
  print "not ok 10\n";
}

Rmpz_urandomb($r1, $s[2], 200, 1);
Rmpz_urandomb($r2, $s[3], 200, 1);

if($r1 == $r2) {print "ok 11\n"}
else {
  warn "\$r[2] : $r[2]\n\$r[3] : $r[3]\n";
  print "not ok 11\n";
}

Rmpz_rrandomb($r1, $s[4], 200, 1);
Rmpz_rrandomb($r2, $s[1], 200, 1);

if($r1 == $r2) {print "ok 12\n"}
else {
  warn "\$r[4] : $r[4]\n\$r[5] : $r[5]\n";
  print "not ok 9\n";
}

undef($_) for @s;

#############################
#############################

eval {my $state = zgmp_randinit_lc_2exp_size(1991);};
if($@ =~ /Did you specify a value for 'size'that is bigger than the table provides/ &&
   $@ !~ /Second call to/) {print "ok 13\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 13\n";
}

eval {my $state = zgmp_randinit_lc_2exp_size_nobless(1991);};
if($@ =~ /Did you specify a value for 'size'that is bigger than the table provides/) {print "ok 14\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 14\n";
}

$s[0] = zgmp_randinit_default();
zgmp_randseed_ui($s[0], $ui);
$s[1] = zgmp_randinit_mt();
zgmp_randseed_ui($s[1], $ui - 1);
$s[2] = zgmp_randinit_lc_2exp($mpz, $ui - 5, 24);
zgmp_randseed_ui($s[2], $ui + 3);
$s[3] = zgmp_randinit_lc_2exp_size(104);
zgmp_randseed_ui($s[3], $ui - 234);
$s[4] = zgmp_randinit_set($s[3]);

my $ok = 1;
for(0 .. 100) {
  my $x = zgmp_urandomb_ui($s[$_ % 5], 15);
  if($x >= 2 ** 15) {
    warn "$x is out of range\n";
    $ok = 0;
  }
}

if($ok) {print "ok 15\n"}
else {print "not ok 15\n"}

$ok = 1;
for(0 .. 100) {
  my $x = zgmp_urandomm_ui($s[$_ % 5], $ui);
  if($x >= $ui) {
    warn "$x is greater than $ui\n";
    $ok = 0;
  }
}

if($ok) {print "ok 16\n"}
else {print "not ok 16\n"}

eval {my $x = zgmp_urandomb_ui($s[0], $ui);};
if($@ =~ /In Math::GMPz::Random::Rgmp_urandomb_ui/) {print "ok 17\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 17\n";
}
