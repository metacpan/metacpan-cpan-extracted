use strict;
use warnings;
use Math::GMPz qw(:mpz);
use Config;

print "1..45\n";

#####################################

my $big_uv = ~0;
my $big_uv_mpz = Math::GMPz->new($big_uv);
my $mpz1 = Math::GMPz->new();

my $t1 = Rmpz_init_set_IV(MATH_GMPz_UV_MAX());
my $t2 = Rmpz_init_set_ui(MATH_GMPz_UV_MAX());
my $t3 = Rmpz_init_set_IV(MATH_GMPz_IV_MAX());
my $t4 = Rmpz_init_set_si(MATH_GMPz_IV_MAX());
my $t5 = Rmpz_init_set_IV(MATH_GMPz_IV_MIN());
my $t6 = Rmpz_init_set_si(MATH_GMPz_IV_MIN());

if(Rmpz_fits_UV_p($big_uv_mpz)) { print "ok 1\n"}
else {
  warn "$big_uv_mpz does not fit into a UV";
  print "not ok 1\n";
}

if(!Rmpz_fits_IV_p($big_uv_mpz)) { print "ok 2\n"}
else {
  warn "$big_uv_mpz fits into an IV";
  print "not ok 2\n";
}

Rmpz_set($mpz1, $big_uv_mpz + 1);

if(!Rmpz_fits_UV_p($mpz1)) { print "ok 3\n"}
else {
  warn "$mpz1 fits into a UV";
  print "not ok 3\n";
}

if(!Rmpz_fits_IV_p($mpz1)) { print "ok 4\n"}
else {
  warn "$mpz1 fits into an IV";
  print "not ok 4\n";
}

if($big_uv == MATH_GMPz_UV_MAX()) { print "ok 5\n" }
else {
  warn "$big_uv != ", MATH_GMPz_UV_MAX(), "\n";
  print "not ok 5\n";
}

#####################################
#####################################

my $big_iv = ($big_uv - 1) / 2;
my $big_iv_mpz = Math::GMPz->new($big_iv);

if(Rmpz_fits_IV_p($big_iv_mpz)) { print "ok 6\n"}
else {
  warn "$big_iv_mpz does not fit into a IV";
  print "not ok 6\n";
}

if(!Rmpz_fits_IV_p($big_iv_mpz * 2)) { print "ok 7\n"}
else {
  warn "$big_iv_mpz fits into an IV";
  print "not ok 7\n";
}

Rmpz_set($mpz1, $big_iv_mpz + 1);

if(!Rmpz_fits_IV_p($mpz1)) { print "ok 8\n"}
else {
  warn "$mpz1 fits into a IV";
  print "not ok 8\n";
}

if(!Rmpz_fits_IV_p($mpz1 * 4)) { print "ok 9\n"}
else {
  warn "$mpz1 fits into an IV";
  print "not ok 9\n";
}

if($big_iv == MATH_GMPz_IV_MAX()) { print "ok 10\n" }
else {
  warn "$big_iv != ", MATH_GMPz_IV_MAX(), "\n";
  print "not ok 10\n";
}

#####################################
#####################################

my $small_iv = -($big_iv + 1);
my $small_iv_mpz = Math::GMPz->new($small_iv);

if(Rmpz_fits_IV_p($small_iv_mpz)) { print "ok 11\n"}
else {
  warn "$small_iv_mpz does not fit into a IV";
  print "not ok 11\n";
}

if(!Rmpz_fits_IV_p($small_iv_mpz * 2)) { print "ok 12\n"}
else {
  warn "$small_iv_mpz fits into an IV";
  print "not ok 12\n";
}

Rmpz_set($mpz1, $small_iv_mpz - 1);

if(!Rmpz_fits_IV_p($mpz1)) { print "ok 13\n"}
else {
  warn "$mpz1 fits into a IV";
  print "not ok 13\n";
}

if(!Rmpz_fits_IV_p($mpz1 * 4)) { print "ok 14\n"}
else {
  warn "$mpz1 fits into an IV";
  print "not ok 14\n";
}

if($small_iv == MATH_GMPz_IV_MIN()) { print "ok 15\n" }
else {
  warn "$small_iv != ", MATH_GMPz_IV_MIN(), "\n";
  print "not ok 15\n";
}

#####################################
#####################################

if($big_uv == Math::GMPz->new($big_uv)) {print "ok 16\n"}
else {
  warn "$big_uv != ", Math::GMPz->new($big_uv), "\n";
  print "not ok 16\n";
}

if($big_uv == Math::GMPz->new("$big_uv")) {print "ok 17\n"}
else {
  warn "$big_uv != ", Math::GMPz->new("$big_uv"), "\n";
  print "not ok 17\n";
}

if($big_iv == Math::GMPz->new($big_iv)) {print "ok 18\n"}
else {
  warn "$big_iv != ", Math::GMPz->new($big_iv), "\n";
  print "not ok 18\n";
}

if($big_iv == Math::GMPz->new("$big_iv")) {print "ok 19\n"}
else {
  warn "$big_iv != ", Math::GMPz->new("$big_iv"), "\n";
  print "not ok 19\n";
}

if($small_iv == Math::GMPz->new($small_iv)) {print "ok 20\n"}
else {
  warn "$small_iv != ", Math::GMPz->new($small_iv), "\n";
  print "not ok 20\n";
}

if($small_iv == Math::GMPz->new("$small_iv")) {print "ok 21\n"}
else {
  warn "$small_iv != ", Math::GMPz->new("$small_iv"), "\n";
  print "not ok 21\n";
}

#####################################
#####################################

my $ok = '';

if(!Math::GMPz::_has_longlong()) { # _IV/_UV matches _si/_ui

  if($t1 == $t2) {$ok .= 'a'}
  else {warn "\n22a: $t1 != $t2\n"}

  if(Rmpz_get_IV($t1) == Rmpz_get_ui($t2)) {$ok .= 'b'}
  else {warn "\n22b: ", Rmpz_get_IV($t1), " != ", Rmpz_get_ui($t2), "\n"}

  $t1 += 1234567;

  my $overflow1_uv = Rmpz_get_IV($t1);
  my $overflow2_uv = Rmpz_get_ui($t1);

  $t1 -= 1234567; # restore to original value

  if($overflow1_uv == $overflow2_uv) {$ok .= 'c'}
  else {warn "\n22c: $overflow1_uv != $overflow2_uv\n"}

  if($t3 == $t4) {$ok .= 'd'}
  else {warn "\n22d: $t3 != $t4\n"}

  if(Rmpz_get_IV($t3) == Rmpz_get_si($t4)) {$ok .= 'e'}
  else {warn "\n22e: ", Rmpz_get_IV($t3), " != ", Rmpz_get_si($t4), "\n"}

  if(Rmpz_get_IV($t3) == Rmpz_get_ui($t4)) {$ok .= 'f'}
  else {warn "\n22f: ", Rmpz_get_IV($t3), " != ", Rmpz_get_ui($t4), "\n"}

  $t3 += 1234567;

  my $overflow1_iv = Rmpz_get_IV($t3);
  my $overflow2_iv = Rmpz_get_ui($t3);
  my $overflow3_iv = Rmpz_get_si($t3);

  $t3 -= 1234567; # restore to original value

  if($overflow1_iv += $overflow2_iv) {$ok .= 'g'}
  else {warn "\n22g: $overflow1_iv != $overflow2_iv\n"}

  if($overflow2_iv != $overflow3_iv) {$ok .= 'h'}
  else {warn "\n22h: $overflow2_iv == $overflow3_iv\n"}

  if($t5 == $t6) {$ok .= 'i'}
  else {warn "\n22i: $t5 != $t6\n"}

  if(Rmpz_get_IV($t5) == Rmpz_get_si($t6)) {$ok .= 'j'}
  else {warn "\n22j: ", Rmpz_get_IV($t5), " != ", Rmpz_get_si($t6), "\n"}

  if(Rmpz_get_IV($t5) != Rmpz_get_ui($t6)) {$ok .= 'k'}
  else {warn "\n22k: ", Rmpz_get_IV($t5), " != ", Rmpz_get_ui($t6), "\n"}

  $t5 -= 1234567;

  my $underflow1_iv = Rmpz_get_IV($t5);
  my $underflow2_iv = Rmpz_get_ui($t5);
  my $underflow3_iv = Rmpz_get_si($t5);

  if(-$t5 == $underflow2_iv) {$ok .= 'l'} # because the value of abs($t5) fits into a UV and
                                          # Rmpz_get_ui() simply ignores the sign and returns
                                          # abs($t5) coerced to an unsigned long.
  else {warn "\n22l: ", $t5 * -1, " != $underflow2_iv\n"}

  $t5 += 1234567; # restore to original value

  if($underflow1_iv != $underflow2_iv) {$ok .= 'm'}
  else {warn "\n22m: $underflow1_iv == $underflow2_iv\n"}

  if($underflow1_iv == $underflow3_iv) {$ok .= 'n'}
  else {warn "\n22n: $underflow1_iv != $underflow3_iv\n"}

  if($ok eq 'abcdefghijklmn') {print "ok 22\n"}
  else {
    warn "\n\$ok: $ok\n";
    print "not ok 22\n";
  }
}
else {
  warn "\nSkipping test 22\n";
  print "ok 22\n";
}

my $inf = 999 ** (999 ** 999);
my $nan = $inf / $inf;

eval{my $x = Rmpz_init_set_NV($inf)};

if($@ =~ /cannot coerce an Inf to a Math::GMPz value/) {print "ok 23\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 23\n";
}

eval{my $x = Rmpz_init_set_NV($nan)};

if($@ =~ /cannot coerce a NaN to a Math::GMPz value/) {print "ok 24\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 24\n";
}

eval{my $x = Rmpz_init_set_d($inf)};

if($@ =~ /cannot coerce an Inf to a Math::GMPz value/) {print "ok 25\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 25\n";
}

eval{my $x = Rmpz_init_set_d($nan)};

if($@ =~ /cannot coerce a NaN to a Math::GMPz value/) {print "ok 26\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 26\n";
}

eval{Rmpz_set_NV($mpz1, $inf)};

if($@ =~ /cannot coerce an Inf to a Math::GMPz value/) {print "ok 27\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 27\n";
}

eval{Rmpz_set_NV($mpz1, $nan)};

if($@ =~ /cannot coerce a NaN to a Math::GMPz value/) {print "ok 28\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 28\n";
}

eval{Rmpz_set_d($mpz1, $inf)};

if($@ =~ /cannot coerce an Inf to a Math::GMPz value/) {print "ok 29\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 29\n";
}

eval{Rmpz_set_d($mpz1, $nan)};

if($@ =~ /cannot coerce a NaN to a Math::GMPz value/) {print "ok 30\n"}
else {
  warn "\n\$\@: $@";
  print "not ok 30\n";
}

################################

# UV_MAX

if($t1 == Math::GMPz->new(Rmpz_get_IV($t1))) {print "ok 31\n"}
else {
  warn "\n31: $t1 != ", Math::GMPz->new(Rmpz_get_IV($t1)), "\n";
  print "not ok 31\n";
}

Rmpz_set_IV($mpz1, Rmpz_get_IV($t1));

if($t1 == $mpz1) {print "ok 32\n"}
else {
  warn "\n32: $t1 != $mpz1\n";
  print "not ok 32\n";
}

################################

# IV_MAX

if($t3 == Math::GMPz->new(Rmpz_get_IV($t3))) {print "ok 33\n"}
else {
  warn "\n33: $t3 != ", Math::GMPz->new(Rmpz_get_IV($t3)), "\n";
  print "not ok 33\n";
}

Rmpz_set_IV($mpz1, Rmpz_get_IV($t3));

if($t3 == $mpz1) {print "ok 34\n"}
else {
  warn "\n34: $t3 != $mpz1\n";
  print "not ok 34\n";
}

################################

# IV_MIN

if($t5 == Math::GMPz->new(Rmpz_get_IV($t5))) {print "ok 35\n"}
else {
  warn "\n35: $t5 != ", Math::GMPz->new(Rmpz_get_IV($t5)), "\n";
  print "not ok 35\n";
}

Rmpz_set_IV($mpz1, Rmpz_get_IV($t5));

if($t5 == $mpz1) {print "ok 36\n"}
else {
  warn "\n36: $t5 != $mpz1\n";
  print "not ok 36\n";
}

################################
################################

# UV_MAX

if($t1 - 123456 == Math::GMPz->new(Rmpz_get_IV($t1 - 123456))) {print "ok 37\n"}
else {
  warn "\n37: ", $t1 - 123456, " != ", Math::GMPz->new(Rmpz_get_IV($t1 - 123456)), "\n";
  print "not ok 37\n";
}

Rmpz_set_IV($mpz1, Rmpz_get_IV($t1 - 123456));

if($t1 - 123456 == $mpz1) {print "ok 38\n"}
else {
  warn "\n38: ", $t1 - 123456, " != $mpz1\n";
  print "not ok 38\n";
}

################################

# IV_MAX (Tests pass because IV_MAX + 123456 is less than UV_MAX)

if($t3 + 123456 == Math::GMPz->new(Rmpz_get_IV($t3 + 123456))) {print "ok 39\n"}
else {
  warn "\n39: ", $t3 + 123456, " != ", Math::GMPz->new(Rmpz_get_IV($t3 + 123456)), "\n";
  print "not ok 39\n";
}

Rmpz_set_IV($mpz1, Rmpz_get_IV($t3 + 123456));

if($t3 + 123456 == $mpz1) {print "ok 40\n"}
else {
  warn "\n40: ", $t3 + 123456, " != $mpz1\n";
  print "not ok 40\n";
}

################################

# IV_MIN

if($t5 + 123456 == Math::GMPz->new(Rmpz_get_IV($t5 + 123456))) {print "ok 41\n"}
else {
  warn "\n41: ", $t5 + 123456," != ", Math::GMPz->new(Rmpz_get_IV($t5 + 123456)), "\n";
  print "not ok 41\n";
}

Rmpz_set_IV($mpz1, Rmpz_get_IV($t5 + 123456));

if($t5 + 123456 == $mpz1) {print "ok 42\n"}
else {
  warn "\n42: ", $t5 + 123456," != $mpz1\n";
  print "not ok 42\n";
}

################################

my $big_z = Math::GMPz->new(1);
$big_z <<= 1000;

my $check = Rmpz_init_set_NV(2 ** 1000);

if($check == $big_z) {print "ok 43\n"}
else {
  warn "\n43: $big_z != $check\n";
  print "not ok 43\n";
}

$big_z >>= 4;

Rmpz_set_NV($check, 2 ** 996);

if($check == $big_z) {print "ok 44\n"}
else {
  warn "\n44: $big_z != $check\n";
  print "not ok 44\n";
}

if($Config::Config{nvtype} eq '__float128') {
  if(!Math::GMPz::_has_longdouble() && Math::GMPz::_has_float128()) {print "ok 45\n"}
  else {
    warn "\n __float128:\n Math::GMPz::_has_longdouble(): ", Math::GMPz::_has_longdouble(),
         "\n Math::GMPz::_has_float128(): ", Math::GMPz::_has_float128(), "\n";
    print "not ok 45\n";
  }
}
elsif($Config::Config{nvtype} eq 'long double') {
  if(Math::GMPz::_has_longdouble() && !Math::GMPz::_has_float128()) {print "ok 45\n"}
  else {
    warn "\n long double:\n Math::GMPz::_has_longdouble(): ", Math::GMPz::_has_longdouble(),
         "\n Math::GMPz::_has_float128(): ", Math::GMPz::_has_float128(), "\n";
    print "not ok 45\n";
  }
}
else {
  if(!Math::GMPz::_has_longdouble() && !Math::GMPz::_has_float128()) {print "ok 45\n"}
  else {
    warn "\n double:\n Math::GMPz::_has_longdouble(): ", Math::GMPz::_has_longdouble(),
         "\n Math::GMPzV_has_float128(): ", Math::GMPzV_has_float128(), "\n";
    print "not ok 45\n";
  }
}

