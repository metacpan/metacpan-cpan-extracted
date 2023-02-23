use warnings;
use strict;
use Math::MPC qw(:mpc);
use Math::MPFR qw(:mpfr);
use Math::BigInt;

print "1..7\n";

my $mbi2;
my $ok = '';
my $string = 'hello world';
my $mbi = Math::BigInt->new(123456);
my @prec = Rmpc_get_default_prec2();
my $mpc = Rmpc_init3(@prec);
Rmpc_set_ui_ui($mpc, 10, 10, MPC_RNDNN);

eval {$mbi2 = $mpc + $string;};
if($@ =~ /Math::MPC::overload_add/) {$ok = 'a'}
eval {$mbi2 = $mpc - $string;};
if($@ =~ /Math::MPC::overload_sub/) {$ok .= 'b'}
eval {$mbi2 = $mpc / $string;};
if($@ =~ /Math::MPC::overload_div/) {$ok .= 'c'}
eval {$mbi2 = $mpc * $string;};
if($@ =~ /Math::MPC::overload_mul/) {$ok .= 'd'}
eval {$mbi2 = $mpc + $mbi;};
if($@ =~ /Math::MPC::overload_add/) {$ok .= 'e'}
eval {$mbi2 = $mpc - $mbi;};
if($@ =~ /Math::MPC::overload_sub/) {$ok .= 'f'}
eval {$mbi2 = $mpc / $mbi;};
if($@ =~ /Math::MPC::overload_div/) {$ok .= 'g'}
eval {$mbi2 = $mpc * $mbi;};
if($@ =~ /Math::MPC::overload_mul/) {$ok .= 'h'}
eval {$mbi2 = $mpc ** $mbi;};
if($@ =~ /Math::MPC::overload_pow/) {$ok .= 'i'}

eval {$mpc += $string;};
if($@ =~ /Math::MPC::overload_add_eq/) {$ok .= 'j'}
eval {$mpc -= $string;};
if($@ =~ /Math::MPC::overload_sub_eq/) {$ok .= 'k'}
eval {$mpc /= $string;};
if($@ =~ /Math::MPC::overload_div_eq/) {$ok .= 'l'}
eval {$mpc *= $string;};
if($@ =~ /Math::MPC::overload_mul_eq/) {$ok .= 'm'}
eval {$mpc += $mbi;};
if($@ =~ /Math::MPC::overload_add_eq/) {$ok .= 'n'}
eval {$mpc -= $mbi;};
if($@ =~ /Math::MPC::overload_sub_eq/) {$ok .= 'o'}
eval {$mpc /= $mbi;};
if($@ =~ /Math::MPC::overload_div_eq/) {$ok .= 'p'}
eval {$mpc *= $mbi;};
if($@ =~ /Math::MPC::overload_mul_eq/) {$ok .= 'q'}
eval {$mpc **= $mbi;};
if($@ =~ /Math::MPC::overload_pow_eq/) {$ok .= 'r'}

if($ok eq 'abcdefghijklmnopqr') {print "ok 1\n"}
else {print "not ok 1 $ok\n"}

my $num = Math::MPC->new(200, 40);
if(Math::MPC::overload_string($num) eq '(2e2 4e1)') {print "ok 2\n"}
else {
  warn "\nTest 2 got: ", Math::MPC::overload_string($num), "\n";
  print "not ok 2\n";
}

# checking overload_copy subroutine
$ok = '';
$ok .= 'a' if $prec[0] == 53 && $prec[1] == 53;

my $mpc1 = Math::MPC->new(12345, 67890);
Rmpc_set_default_prec2(100, 112);
my $mpc2 = $mpc1;

my @p = Rmpc_get_prec2($mpc2);

$ok .= 'b' if $p[0] == 53 && $p[1] == 53;

$mpc2++;
$ok .= 'c' if $mpc2 == $mpc1 + 1;

@p = Rmpc_get_prec2($mpc2);
$ok .= 'd' if $p[0] == 53 && $p[1] == 53;

my $mpc3 = Rmpc_init3(70, 80);
Rmpc_set_ui_ui($mpc3, 54321, 9876, MPC_RNDNN);

my $mpc4 = $mpc3;
@p = Rmpc_get_prec2($mpc4);

$ok .= 'e' if $p[0] == 70 && $p[1] == 80;

$mpc4 += 1;
$ok .= 'f' if $mpc4 == $mpc3 + 1;

@p = Rmpc_get_prec2($mpc4);
$ok .= 'g' if $p[0] == 70 && $p[1] == 80;

my $mpc5 = $mpc3;
$mpc3 += 1;
@p = Rmpc_get_prec2($mpc5);
$ok .= 'h' if $p[0] == 70 && $p[1] == 80 && $mpc5 == $mpc3 - 1;

$mpc5 -= -1;

if($mpc3 == $mpc5) {$ok .= 'i'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'j'}

if($ok eq 'abcdefghij') {print "ok 3\n"}
else {print "not ok 3 $ok\n"}

Rmpc_set_default_prec2(70, 80);
$ok = '';
$string = '(1.5 +1.5)';

## plus ##
$mpc5 += 2;
$mpc3 = $mpc3 + 2;

if($mpc3 == $mpc5) {$ok .= 'a'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'b'}

$mpc5 += 2.5;
$mpc3 = $mpc3 + 2.5;

if($mpc3 == $mpc5) {$ok .= 'c'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'd'}

$mpc5 += $string;
$mpc3 = $mpc3 + $string;

if($mpc3 == $mpc5) {$ok .= 'e'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'f'}

$mpc5 += $mpc4;
$mpc3 = $mpc3 + $mpc4;

if($mpc3 == $mpc5) {$ok .= 'g'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'h'}

## minus ##

$mpc5 -= 2;
$mpc3 = $mpc3 - 2;

if($mpc3 == $mpc5) {$ok .= 'i'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'j'}

$mpc5 -= 2.5;
$mpc3 = $mpc3 - 2.5;

if($mpc3 == $mpc5) {$ok .= 'k'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'l'}

$mpc5 -= $string;
$mpc3 = $mpc3 - $string;

if($mpc3 == $mpc5) {$ok .= 'm'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'n'}

$mpc5 -= $mpc4;
$mpc3 = $mpc3 - $mpc4;

if($mpc3 == $mpc5) {$ok .= 'o'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'p'}

## mul ##

$mpc5 *= 2;
$mpc3 = $mpc3 * 2;

if($mpc3 == $mpc5) {$ok .= 'q'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'r'}

$mpc5 *= 2.5;
$mpc3 = $mpc3 * 2.5;

if($mpc3 == $mpc5) {$ok .= 's'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 't'}

$mpc5 *= $string;
$mpc3 = $mpc3 * $string;

if($mpc3 == $mpc5) {$ok .= 'u'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'v'}

$mpc5 *= $mpc4;
$mpc3 = $mpc3 * $mpc4;

if($mpc3 == $mpc5) {$ok .= 'w'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'x'}

## div ##

$mpc5 /= 2;
$mpc3 = $mpc3 / 2;

if($mpc3 == $mpc5) {$ok .= 'y'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'z'}

$mpc5 /= 2.5;
$mpc3 = $mpc3 / 2.5;

if($mpc3 == $mpc5) {$ok .= 'A'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'B'}

$mpc5 /= $string;
$mpc3 = $mpc3 / $string;

if($mpc3 == $mpc5) {$ok .= 'C'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'D'}

$mpc5 /= $mpc4;
$mpc3 = $mpc3 / $mpc4;

if($mpc3 == $mpc5) {$ok .= 'E'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'F'}

## pow ##

$mpc5 **= 2;
$mpc3 = $mpc3 ** 2;

if($mpc3 == $mpc5) {$ok .= 'G'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'H'}

$mpc5 **= 2.5;
$mpc3 = $mpc3 ** 2.5;

if($mpc3 == $mpc5) {$ok .= 'I'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'J'}

$mpc5 **= '(1.5 +1.5)';
$mpc3 = $mpc3 ** '(1.5 +1.5)';

if($mpc3 == $mpc5) {$ok .= 'K'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'L'}

my $power = Math::MPC->new(1.5, 1.5);

$mpc5 **= $power;
$mpc3 = $mpc3 ** $power;

if($mpc3 == $mpc5) {$ok .= 'M'}
if(Math::MPC::overload_string($mpc5) eq
   Math::MPC::overload_string($mpc3)) {$ok .= 'N'}

if($ok eq 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMN') {print "ok 4\n"}
else {
  warn "$ok\n";
  print "not ok 4\n";
}

$ok = '';
my $mpc6 = Math::MPC->new(1, 2);
my $mpc7 = Math::MPC->new(3, 4);

$mpc6 = atan2($mpc6, $mpc7);
my $mpfr = Math::MPFR->new();

RMPC_RE($mpfr, $mpc6);
if($mpfr > 0.4164906 && $mpfr < 0.4164907) {$ok .= 'a'}

RMPC_IM($mpfr, $mpc6);
if($mpfr > 0.06706599 && $mpfr < 0.067066) {$ok .= 'b'}

if($ok eq 'ab') {print "ok 5\n"}
else {
  warn "$ok $mpc6\n";
  print "not ok 5\n";
}

my $nan;

if(Math::MPC::_has_longdouble()) {
 $nan = Rmpfr_get_ld(Math::MPFR->new(), GMP_RNDN);
}
else {
 $nan = Rmpfr_get_d(Math::MPFR->new(), GMP_RNDN);
}

if($nan == $nan) {
  warn "If test 6 fails, it is probably due to a bug in perl itself\n";
  print "not ok 6\n";
}
else {print "ok 6\n"}

if($mpc6 == $nan) {print "not ok 7\n"}
else {print "ok 7\n"}



