use warnings;
use strict;
use Math::GMPf qw(:mpf);
use Math::BigInt;
use Config;

print "1..4\n";

print "# Using gmp version ", Math::GMPf::gmp_v(), "\n";

my @version = split /\./, Math::GMPf::gmp_v();
my $old = 0;
if($version[0] == 4 && $version[1] < 2) {$old = 1}
if($old) {warn "Test 1 should fail - GMP version ", Math::GMPf::gmp_v(), " is old and doesn't support base 62\n";}

Rmpf_set_default_prec(64);

my $ui = 123569;
my $si = -19907;
my $d = -1.625;
my $dp;

# Allow "." or "," as the decimal point (according to whichever is valid for the locale).
eval {Rmpf_init_set_str("-119.125", 10);};
$dp = '.' unless $@;
eval {Rmpf_init_set_str("-119,125", 10);};
$dp = ',' unless $@;

#warn "Decimal point: $dp\n";

my $str = $dp ? "-119${dp}125"
             : '-119125@-3';

my $str62 = 'zxfy@0';
my $strn = '12@1';

my $ok = '';

my $f000 = Math::GMPf->new($str62, 62);
if($f000 == 14767406) {$ok .= 'a'}

my $f00 = new Math::GMPf();
Rmpf_set_ui($f00, $ui);
if($f00 == $ui) {$ok .= 'b'}

my $f01 = new Math::GMPf($ui);
if($f01 == $ui) {$ok .= 'c'}

my $f02 = new Math::GMPf($si);
if($f02 == $si) {$ok .= 'd'}

my $f03 = new Math::GMPf($d);
if($f03 == $d) {$ok .= 'e'}

my $f04 = new Math::GMPf($str);
if($f04 == $str) {$ok .= 'f'}

my $f05 = new Math::GMPf($str, 10);
if($f05 == $str) {$ok .= 'g'}

my $f06 = new Math::GMPf($d);
if($f06 == $d) {$ok .= 'h'}

my $f07 = Math::GMPf->new($strn, -37);
if($f07 == 1443 ){$ok .= 'i'}

if($ok eq 'abcdefghi') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

#############################


$ok = '';

my $f10 = Math::GMPf::new();
Rmpf_set_ui($f10, $ui);
if($f10 == $ui) {$ok .= 'b'}

my $f11 = Math::GMPf::new($ui);
if($f11 == $ui) {$ok .= 'c'}

my $f12 = Math::GMPf::new($si);
if($f12 == $si) {$ok .= 'd'}

my $f13 = Math::GMPf::new($d);
if($f13 == $d) {$ok .= 'e'}

my $f14 = Math::GMPf::new($str);
if($f14 == $str) {$ok .= 'f'}

my $f15 = Math::GMPf::new($str, 10);
if($f15 == $str) {$ok .= 'g'}

my $f16 = Math::GMPf::new($d);
if($f16 == $d) {$ok .= 'h'}

#my $f17 = Math::GMPf::new($f16);
#if($f17 == $d) {$ok .= 'i'}

if($ok eq 'bcdefgh') {print "ok 2\n"}
else {print "not ok 2 $ok\n"}

################################

$ok = '';

my $f20 = Math::GMPf->new();
Rmpf_set_ui($f20, $ui);
if($f20 == $ui) {$ok .= 'b'}
else{warn "3b: Expected $ui\n    Got $f20\n"}

my $f21 = Math::GMPf->new($ui);
if($f21 == $ui) {$ok .= 'c'}
else{warn "3c: Expected $ui\n    Got $f21\n"}

my $f22 = Math::GMPf->new($si);
if($f22 == $si) {$ok .= 'd'}
else{warn "3d: Expected $si\n    Got $f22\n"}

my $f23 = Math::GMPf->new($d);
if($f23 == $d) {$ok .= 'e'}
else{warn "3e: Expected $d\n    Got $f23\n"}

my $f24 = Math::GMPf->new($str);
if($f24 == $str) {$ok .= 'f'}
else{warn "3f: Expected $str\n    Got $f24\n"}

my $f25 = Math::GMPf->new($str, 10);
if($f25 == $str) {$ok .= 'g'}
else{warn "3g: Expected $str\n    Got $f25\n"}

my $f26 = Math::GMPf->new($d);
if($f26 == $d) {$ok .= 'h'}
else{warn "3h: Expected $d\n    Got $f26\n"}

Rmpf_set_default_prec(100);
my $f27 = Math::GMPf->new(36028797018964023);
my $f28 = Math::GMPf->new('36028797018964023');

if($Config{ivsize} > 4 || Math::GMPf::_has_longdouble()) {
  if($f27 == $f28) {$ok .= 'i'}
  else{warn "3i: Should have $f27 == $f28\n"}
}
else {
  if($f27 != $f28) {$ok .= 'i'}
  else{warn "3i: Should have $f27 != $f28\n"}
}

my $f29 = Math::GMPf->new($f26);
if($f29 == $d) {$ok .= 'j'}
else{warn "3j: Expected $d\n    Got $f29\n"}

if($ok eq 'bcdefghij') {print "ok 3\n"}
else {
  warn "\$ok: $ok\n";
  print "not ok 3\n";
}

#############################

my $bi = Math::BigInt->new(123456789);

$ok = '';

eval{my $f30 = Math::GMPf->new(17, 12);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) {$ok = 'a'}
else {warn "4a: $@\n"}

eval{my $f31 = Math::GMPf::new(17, 12);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) {$ok .= 'b'}
else {warn "4b: $@\n"}

eval{my $f32 = Math::GMPf->new($str, 12, 7);};
if($@ =~ /Too many arguments supplied to new\(\)/) {$ok .= 'c'}
else {warn "4c: $@\n"}

eval{my $f33 = Math::GMPf::new($str, 12, 7);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected no more than two/) {$ok .= 'd'}
else {warn "4d: $@\n"}

eval{my $f34 = Math::GMPf->new($bi);};
if($@ =~ /Inappropriate argument/) {$ok .= 'e'}
else {warn "4e: $@\n"}

eval{my $f35 = Math::GMPf::new($bi);};
if($@ =~ /Inappropriate argument/) {$ok .= 'f'}
else {warn "4f: $@\n"}

eval{my $f36 = Math::GMPf->new($f27, 10);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) {$ok .= 'g'}
else {warn "4g: $@\n"}

eval{my $f37 = Math::GMPf::new($f27, 10);};
if($@ =~ /Too many arguments supplied to new\(\) \- expected only one/) {$ok .= 'h'}
else {warn "4h: $@\n"}

eval{my $f38 = Math::GMPf::new('123.abc');};
if($@ =~ /is not a valid base 10 number/) {$ok .= 'i'}
else {warn "4i: $@\n"}

eval{my $f39 = Math::GMPf->new('123.abc');};
if($@ =~ /is not a valid base 10 number/) {$ok .= 'j'}
else {warn "4j: $@\n"}

eval{my $f40 = Math::GMPf::new('123.abc', 8);};
if($@ =~ /is not a valid base 8 number/) {$ok .= 'k'}
else {warn "4k: $@\n"}

eval{my $f41 = Math::GMPf->new('123.abc', 8);};
if($@ =~ /is not a valid base 8 number/) {$ok .= 'l'}
else {warn "4l: $@\n"}

if($ok eq 'abcdefghijkl') {print "ok 4\n"}
else {print "not ok 4 $ok\n"}

