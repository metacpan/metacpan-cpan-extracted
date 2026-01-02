use warnings;
use strict;
use Math::GMPz qw(:mpz);
use Math::BigFloat;
use Config;

print "1..6\n";

print "# Using gmp version ", Math::GMPz::gmp_v(), "\n";

my $ui = 123569;
my $si = -19907;
my $d = -1.625;
my $str = '-119';

my $ok = '';

my $f000 = new Math::GMPz('z', 62);
if($f000 == 61) {$ok .= 'a'}

my $f00 = new Math::GMPz();
Rmpz_set_ui($f00, $ui);
if($f00 == $ui) {$ok .= 'b'}

my $f01 = new Math::GMPz($ui);
if($f01 == $ui) {$ok .= 'c'}

my $f02 = new Math::GMPz($si);
if($f02 == $si) {$ok .= 'd'}

my $f03 = new Math::GMPz($d);
if($f03 == int($d)) {$ok .= 'e'}

my $f04 = new Math::GMPz($str);
if($f04 == $str) {$ok .= 'f'}

my $f05 = new Math::GMPz($str, 10);
if($f05 == $str) {$ok .= 'g'}

my $f06 = new Math::GMPz($d);
if($f06 == int($d)) {$ok .= 'h'}

if($ok eq 'abcdefgh') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

#############################


$ok = '';

my $f09 = Math::GMPz::new('0xf', 0);
if($f09 == 15) {$ok .= 'a'}

my $f10 = Math::GMPz::new();
Rmpz_set_ui($f10, $ui);
if($f10 == $ui) {$ok .= 'b'}

my $f11 = Math::GMPz::new($ui);
if($f11 == $ui) {$ok .= 'c'}

my $f12 = Math::GMPz::new($si);
if($f12 == $si) {$ok .= 'd'}

my $f13 = Math::GMPz::new($d);
if($f13 == int($d)) {$ok .= 'e'}

my $f14 = Math::GMPz::new($str);
if($f14 == $str) {$ok .= 'f'}

my $f15 = Math::GMPz::new($str, 10);
if($f15 == $str) {$ok .= 'g'}

my $f16 = Math::GMPz::new($d);
if($f16 == int($d)) {$ok .= 'h'}

if($ok eq 'abcdefgh') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

################################

$ok = '';

my $f19 = Math::GMPz->new('z', 62);
if($f19 == 61) {$ok .= 'a'}
else {warn "\n3a:\nExpected: 61\nGot: $f19\n"}

my $f20 = Math::GMPz->new();
Rmpz_set_ui($f20, $ui);
if($f20 == $ui) {$ok .= 'b'}
else {warn "\n3b:\nExpected: $ui\nGot: $f20\n"}

my $f21 = Math::GMPz->new($ui);
if($f21 == $ui) {$ok .= 'c'}
else {warn "\n3c:\nExpected: $ui\nGot: $f21\n"}

my $f22 = Math::GMPz->new($si);
if($f22 == $si) {$ok .= 'd'}
else {warn "\n3d:\nExpected: $si\nGot: $f22\n"}

my $f23 = Math::GMPz->new($d);
if($f23 == int($d)) {$ok .= 'e'}
else {warn "\n3e:\nExpected: ", int($d), "\nGot: $f23\n"}

my $f24 = Math::GMPz->new($str);
if($f24 == $str) {$ok .= 'f'}
else {warn "\n3f:\nExpected: $str\nGot: $f24\n"}

my $f25 = Math::GMPz->new($str, 10);
if($f25 == $str) {$ok .= 'g'}
else {warn "\n3g:\nExpected: $str\nGot: $f25\n"}

my $f26 = Math::GMPz->new($d);
if($f26 == int($d)) {$ok .= 'h'}
else {warn "\n3h:\nExpected: ", int($d), "\nGot: $f26\n"}


my $f27 = Math::GMPz->new(36028797018964023);
my $f28 = Math::GMPz->new('36028797018964023');

if($Config{ivsize} > 4 || $Config{nvsize} > 8) {
  if($f27 == $f28) {$ok .= 'i'}
  else {warn "\n3i:\nShould have got $f27 == $f28\n"}
}
else {
  if($f27 != $f28) {$ok .= 'i'}
  else {warn "\n3i:\nShould have got $f27 != $f28\n"}
}

if($ok eq 'abcdefghi') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3 $ok\n";
}

#############################

my $bi = Math::BigFloat->new(123456789);

$ok = '';

eval{my $f30 = Math::GMPz->new(17, 12);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) {$ok = 'a'}
else {print $@, "\n"}

eval{my $f31 = Math::GMPz::new(17, 12);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) {$ok .= 'b'}

eval{my $f32 = Math::GMPz->new($str, 12, 7);};
if($@ =~ /Too many arguments supplied to new\(\)/) {$ok .= 'c'}

eval{my $f33 = Math::GMPz::new($str, 12, 7);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected no more than two/) {$ok .= 'd'}

eval{my $f34 = Math::GMPz->new($bi);};
if($@ =~ /Inappropriate argument/) {$ok .= 'e'}

eval{my $f35 = Math::GMPz::new($bi);};
if($@ =~ /Inappropriate argument/) {$ok .= 'f'}

eval{my $f36 = Math::GMPz->new($f28, 12);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) {$ok .= 'g'}

eval{my $f37 = Math::GMPz->new($f28, 12);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) {$ok .= 'h'}
else{ warn "H: \$\@: $@\n" }

eval{my $f38 = Math::GMPz::new('z', -12);};
if($@ =~ /Invalid value for base/) {$ok .= 'i'}

eval{my $f39 = Math::GMPz->new('123.456');};
if($@ =~ /is not a valid base 0 integer/) { $ok .= 'j'}

eval{my $f40 = Math::GMPz::new('123.456');};
if($@ =~ /is not a valid base 0 integer/) { $ok .= 'k' }

eval{my $f41 = Math::GMPz->new('123.456', 10);};
if($@ =~ /is not a valid base 10 integer/) {$ok .= 'l'}

eval{my $f42 = Math::GMPz::new('123.456', 10);};
if($@ =~ /is not a valid base 10 integer/) {$ok .= 'm'}

if($ok eq 'abcdefghijklm') {print "ok 4\n"}
else {print "not ok 4 $ok\n"}

########################################################

$ok = '';

# Test 5 tests new behaviour added in Math-GMPz-0.65.

eval { require Math::GMP;};
unless($@) {
  my $gmp = Math::GMP->new(12345);
  my $z = Math::GMPz->new($gmp);
  $ok .= 'a' if $z == 12345;
}
else {
  warn "Could not load Math::GMP";
  $ok .= 'a';
}

eval { require Math::GMPq;};
unless($@) {
  my $mpq = Math::GMPq->new(12345.987);
  my $z = Math::GMPz->new($mpq);
  $ok .= 'b' if $z == 12345;
}
else {
  warn "Could not load Math::GMPq";
  $ok .= 'b';
}

eval { require Math::MPFR;};
unless($@) {
  my $fr = Math::MPFR->new(1234.5987);
  my $z = Math::GMPz->new($fr);
  $ok .= 'c' if $z == 1234;
}
else {
  warn "Could not load Math::MPFR";
  $ok .= 'c';
}

if($ok eq 'abc') {print "ok 5\n"}
else {print "not ok 5 $ok\n"}

# The GMP documentation says that the following should succeed:
my $z = Math::GMPz->new("1234  \n 56 \t 78");
if($z == 12345678) { print "ok 6\n" }
else {print "not ok 6 $z\n" }

__END__

# Math::GMPz does not currently support the below code.
#
#my $obj1 = Math::GMPz->new(123);
#my $obj2 = $obj1->new(456);
#
#if(ref($obj1) eq 'Math::GMPz' && ref($obj2) eq 'Math::GMPz') { print "ok 7\n"}
#else {
#  warn " REF 1: ", ref($obj1), "\n REF 2: ", ref($obj2), "\n";
#  print "not ok 7\n";
#}
#
#if($obj1 == 123 && $obj2 == 456) { print "ok 8\n" }
#else {
#  warn " OBJ 1: ", $obj1, "\n OBJ 2: ", $obj2, "\n";
#  print "not ok 8\n";
#}
#
#eval{ my $obj3 = $obj1->new(456, 16);};
#if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) { print "ok 9\n" }
#else {
#  warn "\$\@: $@\n";
#  print "not ok 9\n";
#}
#
#my $obj4 = $obj1->new('456', 16);
#if($obj4 == 1110) { print "ok 10\n" }
#else {
#  warn " Expected: 1110\n Got: $obj4\n";
#  print "not ok 10\n";
#}
#
#eval{ my $obj5 = $obj1->new('459', 8);};
#if($@ =~ /First argument supplied to Rmpz_init_set_str is not a valid base 8 integer/) { print "ok 11\n" }
#else {
#  warn "\$\@: $@\n";
#  print "not ok 11\n";
#}
#
#eval{ my $obj6 = $obj1->new('456', 16, 0);};
#if($@ =~ /Too many arguments supplied to new\(\)/) { print "ok 12\n" }
#else {
#  warn "\$\@: $@\n";
# print "not ok 12\n";
#}
#
#my $obj7 = $obj1->new();
#if("$obj7" eq "0") { print "ok 13\n" }
#else {
#  warn " Expected: 0\n Got: $obj7\n";
#  print "not ok 13\n";
#}
#
#my $obj8 = Math::GMPz->new($obj1);
#if($obj8 == 123) { print "ok 14\n" }
#else {
#  warn " Expected: 123\n Got: $obj8\n";
#  print "not ok 14\n";
#}
#
#my $obj9 = Math::GMPz::new($obj1);
#if($obj9 == 123) { print "ok 15\n" }
$else {
#  warn " Expected: 123\n Got: $obj9\n";
#  print "not ok 15\n";
#}
