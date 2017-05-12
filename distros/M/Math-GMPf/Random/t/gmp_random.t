use strict;
use warnings;
use Math::GMPf qw(:mpf);

print "1..18\n";

print "# Using gmp version ", Math::GMPf::gmp_v(), "\n";

my $ui = 12345679;
my $mpz;
eval {require Math::GMPz;};
if(!$@) {$mpz = Math::GMPz->new($ui)}

if(!$mpz) {
  eval {require Math::GMP;};
  if(!$@) {$mpz = Math::GMP->new($ui)}
}

my @s;

my $r1 = Math::GMPf->new();
my $r2 = Math::GMPf->new();

############################
############################

$s[0] = fgmp_randinit_default();
if($mpz) {fgmp_randseed($s[0], $mpz)}
else {fgmp_randseed_ui($s[0], $ui)}
$s[1] = fgmp_randinit_default();
fgmp_randseed_ui($s[1], $ui);
$s[2] = fgmp_randinit_set($s[0]);
$s[3] = fgmp_randinit_set($s[1]);

Rmpf_urandomb($r1, $s[0], 100, 1);
Rmpf_urandomb($r2, $s[1], 100, 1);

if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 1\n"}
else {
  warn "\$r1 : $r1\n\$r2 : $r2\n";
  print "not ok 1\n";
}

Rmpf_urandomb($r2, $s[2], 100, 1);

if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 2\n"}
else {
  warn "\$r1 : $r1\n\$r2 : $r2\n";
  print "not ok 2\n";
}

Rmpf_urandomb($r2, $s[3], 100, 1);

if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 3\n"}
else {
  warn "\$r1 : $r1\n\$r2 : $r2\n";
  print "not ok 3\n";
}

undef($_) for @s;

############################
############################

$s[0] = fgmp_randinit_default();
if($mpz) {fgmp_randseed($s[0], $mpz)}
else {fgmp_randseed_ui($s[0], $ui)}
$s[1] = fgmp_randinit_mt();
fgmp_randseed_ui($s[1], $ui);
$s[2] = fgmp_randinit_set($s[0]);
$s[3] = fgmp_randinit_set($s[1]);

Rmpf_urandomb($r1, $s[0], 100, 1);
Rmpf_urandomb($r2, $s[1], 100, 1);

if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 4\n"}
else {
  warn "\$r1 : $r1\n\$r2 : $r2\n";
  print "not ok 4\n";
}

Rmpf_urandomb($r2, $s[2], 100, 1);

if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 5\n"}
else {
  warn "\$r1 : $r1\n\$r2 : $r2\n";
  print "not ok 5\n";
}

Rmpf_urandomb($r2, $s[3], 100, 1);

if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 6\n"}
else {
  warn "\$r1 : $r1\n\$r2 : $r2\n";
  print "not ok 6\n";
}

undef($_) for @s;

############################
############################
if($mpz) {
  $s[0] = fgmp_randinit_lc_2exp($mpz, $ui - 5, 24);
  if($mpz) {fgmp_randseed($s[0], $mpz)}
  else {fgmp_randseed_ui($s[0], $ui)}
  $s[1] = fgmp_randinit_lc_2exp($mpz, $ui - 5, 24);
  fgmp_randseed_ui($s[1], $ui);
  $s[2] = fgmp_randinit_set($s[0]);
  $s[3] = fgmp_randinit_set($s[1]);

  Rmpf_urandomb($r1, $s[0], 100, 1);
  Rmpf_urandomb($r2, $s[1], 100, 1);

  if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 7\n"}
  else {
    warn "\$r1 : $r1\n\$r2 : $r2\n";
    print "not ok 7\n";
  }

  Rmpf_urandomb($r2, $s[2], 100, 1);

  if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 8\n"}
  else {
    warn "\$r1 : $r1\n\$r2 : $r2\n";
    print "not ok 8\n";
  }

  Rmpf_urandomb($r2, $s[3], 100, 1);

  if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 9\n"}
  else {
    warn "\$r1 : $r1\n\$r2 : $r2\n";
    print "not ok 9\n";
  }
}
else {
  warn "Skipping test 7 ... no Math::GMP or Math::GMPz\n";
  print "ok 7\n";
  warn "Skipping test 8 ... no Math::GMP or Math::GMPz\n";
  print "ok 8\n";
  warn "Skipping test 9 ... no Math::GMP or Math::GMPz\n";
  print "ok 9\n";
}

undef($_) for @s;

############################
############################

$s[0] = fgmp_randinit_lc_2exp_size(101);
if($mpz) {fgmp_randseed($s[0], $mpz)}
else {fgmp_randseed_ui($s[0], $ui)}
$s[1] = fgmp_randinit_lc_2exp_size(101);
fgmp_randseed_ui($s[1], $ui);
$s[2] = fgmp_randinit_set($s[0]);
$s[3] = fgmp_randinit_set($s[1]);

Rmpf_urandomb($r1, $s[0], 100, 1);
Rmpf_urandomb($r2, $s[1], 100, 1);

if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 10\n"}
else {
  warn "\$r1 : $r1\n\$r2 : $r2\n";
  print "not ok 10\n";
}

Rmpf_urandomb($r2, $s[2], 100, 1);

if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 11\n"}
else {
  warn "\$r1 : $r1\n\$r2 : $r2\n";
  print "not ok 11\n";
}

Rmpf_urandomb($r2, $s[3], 100, 1);

if($r1 == $r2 && $r1 > 0 && $r2 < 1) {print "ok 12\n"}
else {
  warn "\$r1 : $r1\n\$r2 : $r2\n";
  print "not ok 12\n";
}

undef($_) for @s;

#############################
#############################

eval {my $state = fgmp_randinit_lc_2exp_size(1991);};
if($@ =~ /Did you specify a value for 'size'that is bigger than the table provides/ &&
   $@ !~ /Second call to/) {print "ok 13\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 13\n";
}

eval {my $state = fgmp_randinit_lc_2exp_size_nobless(1991);};
if($@ =~ /Did you specify a value for 'size'that is bigger than the table provides/) {print "ok 14\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 14\n";
}

############################
#//////////////////////////#
#//////////////////////////#
############################
#Rmpf_random2(@r, $limbs, $exp, $how_many);

my @r;
my $ok = 1;

for(0 .. 49) {push @r, Math::GMPf->new()}

Rmpf_random2(@r, 10, 20, scalar(@r));

for(0 .. 49) {
  if($_) {
    if($r[$_] == $r[$_ - 1]) {
      warn "Consecutive numbers ", $_ - 1, " and $_ are equal\n";
      $ok = 0;
    }
  }
}

if($ok) {print "ok 15\n"}
else {print "not ok 15\n"}

$s[0] = fgmp_randinit_default();
fgmp_randseed_ui($s[0], $ui);
$s[1] = fgmp_randinit_mt();
fgmp_randseed_ui($s[1], $ui - 1);
if($mpz) {
  $s[2] = fgmp_randinit_lc_2exp($mpz, $ui - 5, 24);
  fgmp_randseed_ui($s[2], $ui + 3);
}
else {$s[2] = fgmp_randinit_set($s[1])}
$s[3] = fgmp_randinit_lc_2exp_size(104);
fgmp_randseed_ui($s[3], $ui - 234);
$s[4] = fgmp_randinit_set($s[3]);

$ok = 1;
for(0 .. 100) {
  my $x = fgmp_urandomb_ui($s[$_ % 5], 15);
  if($x >= 2 ** 15) {
    warn "$x is out of range\n";
    $ok = 0;
  }
}

if($ok) {print "ok 16\n"}
else {print "not ok 16\n"}

$ok = 1;
for(0 .. 100) {
  my $x = fgmp_urandomm_ui($s[$_ % 5], $ui);
  if($x >= $ui) {
    warn "$x is greater than $ui\n";
    $ok = 0;
  }
}

if($ok) {print "ok 17\n"}
else {print "not ok 17\n"}

eval {my $x = fgmp_urandomb_ui($s[0], $ui);};
if($@ =~ /In Math::GMPf::Random::Rgmp_urandomb_ui/) {print "ok 18\n"}
else {
  warn "\$\@: $@\n";
  print "not ok 18\n";
}
