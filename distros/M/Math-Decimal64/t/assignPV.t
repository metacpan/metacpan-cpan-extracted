use strict;
use warnings;
use Math::Decimal64 qw(:all);

*nnumflag   = \&Math::Decimal64::nnumflag;
*set_nnum   = \&Math::Decimal64::set_nnum;
*clear_nnum = \&Math::Decimal64::clear_nnum;

my $t = 90;
print "1..$t\n";

my $rop = Math::Decimal64->new();

assignPV($rop, 'inf');

if(is_InfD64($rop) == 1) {print "ok 1\n"}
else {
  warn "Inf: $rop\n";
  print "not ok 1\n";
}

assignPV($rop, '-inf');

if(is_InfD64($rop) == -1) {print "ok 2\n"}
else {
  warn "-Inf: $rop\n";
  print "not ok 2\n";
}

assignPV($rop, '+inf');

if(is_InfD64($rop) == 1) {print "ok 3\n"}
else {
  warn "+Inf: $rop\n";
  print "not ok 3\n";
}

# Space for 2 tests here.
print "ok 4\nok 5\n";

assignPV($rop, 'nan');

if(is_NaND64($rop)) {print "ok 6\n"}
else {
  warn "NaN: $rop\n";
  print "not ok 6\n";
}

assignPV($rop, '+nan');

if(is_NaND64($rop)) {print "ok 7\n"}
else {
  warn "+NaN: $rop\n";
  print "not ok 7\n";
}

assignPV($rop, '-nan');

if(is_NaND64($rop)) {print "ok 8\n"}
else {
  warn "-NaN: $rop\n";
  print "not ok 8\n";
}

if($rop != NaND64()) {print "ok 9\n"}
else {
  warn "$rop == ", NaND64(), "\n";
  print "not ok 9\n";
}

my $ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = '-' . random_select($digits);
    my $d64 = MEtoD64($man, -$exp);
    assignPV($rop, $man . 'e' . -$exp);
    #my $check = PVtoD64($man . 'e' . -$exp);
    if($rop != $d64) {
      $ok = 0;
      warn "\n  (man, exp): ($man, $exp)\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $rop\n";
    }
  }
}

$ok ? print "ok 10\n" : print "not ok 10\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = random_select($digits);
    my $d64 = MEtoD64($man, $exp);
    assignPV($rop, $man . 'E' . $exp);
    #my $check = PVtoD64($man . 'E' . $exp);
    if($rop != $d64) {
      $ok = 0;
      warn "\n  (man, exp): ($man, $exp)\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $rop\n";
    }
  }
}

$ok ? print "ok 11\n" : print "not ok 11\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = '-' . random_select($digits);
    my $d64 = MEtoD64($man, $exp);
    assignPV($rop, $man . 'E' . $exp);
    #my $check = PVtoD64($man . 'E' . $exp);
    if($rop != $d64) {
      $ok = 0;
      warn "\n  (man, exp): ($man, $exp)\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $rop\n";
    }
  }
}

$ok ? print "ok 12\n" : print "not ok 12\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = random_select($digits);
    my $d64 = MEtoD64($man, -$exp);
    assignPV($rop, $man . 'e' . -$exp);
    #my $check = PVtoD64($man . 'e' . -$exp);
    if($rop != $d64) {
      $ok = 0;
      warn "\n  (man, exp): ($man, $exp)\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $rop\n";
    }
  }
}

$ok ? print "ok 13\n" : print "not ok 13\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = '-' . random_select($digits);
    my $d64 = MEtoD64($man, -$exp);
    my $mod = me2pv($man, -$exp);
    assignPV($rop, $mod);
    #my $check = PVtoD64($mod);
    if($rop != $d64) {
      $ok = 0;
      warn "\n  (man, exp): ($man, $exp)\n";
      warn "  \$mod: $mod\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $rop\n";
    }
  }
}

$ok ? print "ok 14\n" : print "not ok 14\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = random_select($digits);
    my $d64 = MEtoD64($man, $exp);
    my $mod = me2pv($man, $exp);
    assignPV($rop, $mod);
    #my $check = PVtoD64($mod);
    if($rop != $d64) {
      $ok = 0;
      warn "\n  (man, exp): ($man, $exp)\n";
      warn "\$mod: $mod\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $rop\n";
    }
  }
}

$ok ? print "ok 15\n" : print "not ok 15\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = '-' . random_select($digits);
    my $d64 = MEtoD64($man, $exp);
    my $mod = me2pv($man, $exp);
    assignPV($rop, $mod);
    #my $check = PVtoD64($mod);
    if($rop != $d64) {
      $ok = 0;
      warn "\n  (man, exp): ($man, $exp)\n";
      warn "\$mod: $mod\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $rop\n";
    }
  }
}

$ok ? print "ok 16\n" : print "not ok 16\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = random_select($digits);
    my $d64 = MEtoD64($man, -$exp);
    my $mod = me2pv($man, -$exp);
    assignPV($rop, $mod);
    #my $check = PVtoD64($mod);
    if($rop != $d64) {
      $ok = 0;
      warn "\n  (man, exp): ($man, $exp)\n";
      warn "  MEtoD64: $d64\n  PVtoD64: $rop\n";
    }
  }
}

$ok ? print "ok 17\n" : print "not ok 17\n";

my $d64 = Math::Decimal64->new();

# Testing some specific inputs - many of which failed at
# various times as I was sorting out _atodecimal()

assignPV($d64, '-0');
my $test = is_ZeroD64($d64);

if($test == -1) {print "ok 18\n"}
elsif($test == 1){
  warn "\nThis compiler/libc doesn't honor sign of zero correctly\n";
  warn "This is not a failing of the module\n";
  print "ok 18\n";
}
else {
  warn "\nExpected -1\nGot $test\n";
  print "not ok 18\n";
}

assignPV($d64, '0.0');
$test = is_ZeroD64($d64);

if($test == 1) {print "ok 19\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 19\n";
}

assignPV($d64, '+inf');
$test = is_InfD64($d64);

if($test == 1) {print "ok 20\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 20\n";
}

assignPV($d64, 'inf');
$test = is_InfD64($d64);

if($test == 1) {print "ok 21\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 21\n";
}

assignPV($d64, '-inf');
$test = is_InfD64($d64);

if($test == -1) {print "ok 22\n"}
else {
  warn "\nExpected -1\nGot $test\n";
  print "not ok 22\n";
}

assignPV($d64, 'nan');
$test = is_NaND64($d64);

if($test == 1) {print "ok 23\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 23\n";
}

assignPV($d64, '-nan');
$test = is_NaND64($d64);

if($test == 1) {print "ok 24\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 24\n";
}

assignPV($d64, '+nan');
$test = is_NaND64($d64);

if($test == 1) {print "ok 25\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 25\n";
}

assignPV($d64, '47');

if("$d64" eq '47e0') {print "ok 26\n"}
else {
  warn "\nExpected 47e0\nGot $d64\n";
  print "not ok 26\n";
}

assignPV($d64, '-47');

if("$d64" eq '-47e0') {print "ok 27\n"}
else {
  warn "\nExpected 47e0\nGot $d64\n";
  print "not ok 27\n";
}

assignPV($d64, '+047.0');

if("$d64" eq '47e0') {print "ok 28\n"}
else {
  warn "\nExpected 47e0\nGot $d64\n";
  print "not ok 28\n";
}

assignPV($d64, '-47e0');

if("$d64" eq '-47e0') {print "ok 29\n"}
else {
  warn "\nExpected 47e0\nGot $d64\n";
  print "not ok 29\n";
}

assignPV($d64, '47e-2');

if("$d64" eq '47e-2') {print "ok 30\n"}
else {
  warn "\nExpected 47e-2\nGot $d64\n";
  print "not ok 30\n";
}

assignPV($d64, '-47e-2');

if("$d64" eq '-47e-2') {print "ok 31\n"}
else {
  warn "\nExpected -47e-2\nGot $d64\n";
  print "not ok 31\n";
}

assignPV($d64, '47e+2');

if("$d64" eq '47e2') {print "ok 32\n"}
else {
  warn "\nExpected 47e2\nGot $d64\n";
  print "not ok 32\n";
}

assignPV($d64, '-47e+2');

if("$d64" eq '-47e2') {print "ok 33\n"}
else {
  warn "\nExpected -47e2\nGot $d64\n";
  print "not ok 33\n";
}

assignPV($d64, '47.116e+2');

if("$d64" eq '47116e-1') {print "ok 34\n"}
else {
  warn "\nExpected 47116e-1\nGot $d64\n";
  print "not ok 34\n";
}

assignPV($d64, '-47.1165e+2');

if("$d64" eq '-471165e-2') {print "ok 35\n"}
else {
  warn "\nExpected -471165e-2\nGot $d64\n";
  print "not ok 35\n";
}

assignPV($d64, '47.116');

if("$d64" eq '47116e-3') {print "ok 36\n"}
else {
  warn "\nExpected 47116e-3\nGot $d64\n";
  print "not ok 36\n";
}

assignPV($d64, '-47.1165');

if("$d64" eq '-471165e-4') {print "ok 37\n"}
else {
  warn "\nExpected -471165e-4\nGot $d64\n";
  print "not ok 37\n";
}

assignPV($d64, '47116.0e+2');

if("$d64" eq '47116e2') {print "ok 38\n"}
else {
  warn "\nExpected 47116e2\nGot $d64\n";
  print "not ok 38\n";
}

assignPV($d64, '-471165.0e+2');

if("$d64" eq '-471165e2') {print "ok 39\n"}
else {
  warn "\nExpected -471165e2\nGot $d64\n";
  print "not ok 39\n";
}

assignPV($d64, '-46e-180');

if("$d64" eq '-46e-180') {print "ok 40\n"}
else {
  warn "\nExpected -46e-180\nGot $d64\n";
  print "not ok 40\n";
}

assignPV($d64, '46e180');

if("$d64" eq '46e180') {print "ok 41\n"}
else {
  warn "\nExpected 46e180\nGot $d64\n";
  print "not ok 41\n";
}

assignPV($d64, '-46.98317e-180');

if("$d64" eq '-4698317e-185') {print "ok 42\n"}
else {
  warn "\nExpected -4698317e-185\nGot $d64\n";
  print "not ok 42\n";
}

assignPV($d64, '-46.98317e180');

if("$d64" eq '-4698317e175' && nnumflag() == 0) {print "ok 43\n"}
else {
  warn "\nExpected -4698317e175\nGot $d64\n";
  warn "nnumflag expected 0, got ", nnumflag(), "\n";
  print "not ok 43\n";
}

assignPV($d64, '-46.98317e180z1');

if("$d64" eq '-4698317e175' && nnumflag() == 1) {print "ok 44\n"}
else {
  warn "\nExpected -4698317e175\nGot $d64\n";
  warn "nnumflag expected 1, got ", nnumflag(), "\n";
  print "not ok 44\n";
}

assignPV($d64, '-51e383');

if("$d64" eq '-51e383') {print "ok 45\n"}
else {
  warn "\nExpected -51e383\nGot $d64\n";
  print "not ok 45\n";
}

assignPV($d64, '-0e410');

if("$d64" eq '-0') {print "ok 46\n"}
elsif("$d64" eq '0'){
  warn "\nThis compiler/libc doesn't honor sign of zero correctly\n";
  warn "This is not a failing of the module\n";
  print "ok 46\n";
}
else {
  warn "\nExpected -0\nGot $d64\n";
  print "not ok 46\n";
}

assignPV($d64, '-2372646073611e353');
if("$d64" eq '-2372646073611e353') {print "ok 47\n"}
else {
  warn "\nExpected -2372646073611e353\nGot $d64\n";
  print "not ok 47\n";
}

assignPV($d64, '623537214927823e-409');

if("$d64" eq '6235e-398') {print "ok 48\n"}
else {
  warn "\nExpected 6235e-398\nGot $d64\n";
  print "not ok 48\n";
}

assignPV($d64, '-623537214927823e-409');

if("$d64" eq '-6235e-398') {print "ok 49\n"}
else {
  warn "\nExpected -6235e-398\nGot $d64\n";
  print "not ok 49\n";
}

assignPV($d64, '623557214927823e-409');

if("$d64" eq '6236e-398') {print "ok 50\n"}
else {
  warn "\nExpected 6236e-398\nGot $d64\n";
  print "not ok 50\n";
}

assignPV($d64, '-623557214927823e-409');

if("$d64" eq '-6236e-398') {print "ok 51\n"}
else {
  warn "\nExpected -6236e-398\nGot $d64\n";
  print "not ok 51\n";
}

assignPV($d64, '62355e-399');

if("$d64" eq '6236e-398') {print "ok 52\n"}
else {
  warn "\nExpected 6236e-398\nGot $d64\n";
  print "not ok 52\n";
}

assignPV($d64, '-62355e-399');

if("$d64" eq '-6236e-398') {print "ok 53\n"}
else {
  warn "\nExpected -6236e-398\nGot $d64\n";
  print "not ok 53\n";
}

assignPV($d64, '62345e-399');

if("$d64" eq '6234e-398') {print "ok 54\n"}
else {
  warn "\nExpected 6234e-398\nGot $d64\n";
  print "not ok 54\n";
}

assignPV($d64, '-62345e-399');

if("$d64" eq '-6234e-398') {print "ok 55\n"}
else {
  warn "\nExpected -6234e-398\nGot $d64\n";
  print "not ok 55\n";
}

assignPV($d64, '5371185275501e-397');

if("$d64" eq '5371185275501e-397') {print "ok 56\n"}
else {
  warn "\nExpected 5371185275501e-397\nGot $d64\n";
  print "not ok 56\n";
}

assignPV($d64 , '-3.090145872714666e15');

if("$d64" eq '-3090145872714666e0') {print "ok 57\n"}
else {
  warn "\nExpected -3090145872714666e0\nGot $d64\n";
  print "not ok 57\n";
}

assignPV($d64, '0.0062e385');

if("$d64" eq '62e381') {print "ok 58\n"}
else {
  warn "\nExpected 62e381\nGot $d64\n";
  print "not ok 58\n";
}

assignPV($d64, '.0062e385');

if("$d64" eq '62e381') {print "ok 59\n"}
else {
  warn "\nExpected 62e381\nGot $d64\n";
  print "not ok 59\n";
}

assignPV($d64, '-0.6e385');

if("$d64" eq '-6e384' && nnumflag() == 1) {print "ok 60\n"}
else {
  warn "\nExpected -6e384\nGot $d64\n";
  warn "nnumflag expected 1, got ", nnumflag(), "\n";
  print "not ok 60\n";
}

assignPV($d64, '');

if("$d64" eq '0') {print "ok 61\n"}
else {
  warn "\nExpected 0\nGot $d64\n";
  print "not ok 61\n";
}

assignPV($d64, '+');

if("$d64" eq '0') {print "ok 62\n"}
else {
  warn "\nExpected 0\nGot $d64\n";
  print "not ok 62\n";
}

assignPV($d64, '-');

if("$d64" eq '-0') {print "ok 63\n"}
elsif("$d64" eq '0'){
  warn "\nThis compiler/libc doesn't honor sign of zero correctly\n";
  warn "This is not a failing of the module\n";
  print "ok 63\n";
}
else {
  warn "\nExpected -0\nGot $d64\n";
  print "not ok 63\n";
}

assignPV($d64, ' ');

if("$d64" eq '0' && nnumflag() == 5) {print "ok 64\n"}
else {
  warn "\nExpected 0\nGot $d64\n";
  warn "nnumflag expected 5, got ", nnumflag(), "\n";
  print "not ok 64\n";
}

#############################
# Do some checks for spaces #
#############################

assignPV($d64, '- 23');

if("$d64" eq '-0' && nnumflag() == 6) {print "ok 65\n"}
elsif("$d64" eq '0' && nnumflag() == 6){
  warn "\nThis compiler/libc doesn't honor sign of zero correctly\n";
  warn "This is not a failing of the module\n";
  print "ok 65\n";
}
else {
  warn "\nExpected -0\nGot $d64\n";
  warn "nnumflag expected 6, got ", nnumflag(), "\n";
  print "not ok 65\n";
}

assignPV($d64, " \r \n \t \f -23e-2");

if("$d64" eq '-23e-2') {print "ok 66\n"}
else {
  warn "\nExpected -23e-2\nGot $d64\n";
  print "not ok 66\n";
}

assignPV($d64, " \r \n \t \f -23 e-2");

if("$d64" eq '-23e0' && nnumflag() == 7) {print "ok 67\n"}
else {
  warn "\nExpected -23e0\nGot $d64\n";
  warn "nnumflag expected 7, got ", nnumflag(), "\n";
  print "not ok 67\n";
}

assignPV($d64, " -23e -2");

if("$d64" eq '-23e0') {print "ok 68\n"}
else {
  warn "\nExpected -23e0\nGot $d64\n";
  print "not ok 68\n";
}

assignPV($d64, "2 3e-2");

if("$d64" eq '2e0' && nnumflag() == 9) {print "ok 69\n"}
else {
  warn "\nExpected 2e0\nGot $d64\n";
  warn "nnumflag expected 9, got ", nnumflag(), "\n";
  print "not ok 69\n";
}

assignPV($d64, ' inf  ');

if(is_InfD64($d64) == 1) {print "ok 70\n"}
else {
  warn "Inf: $d64\n";
  print "not ok 70\n";
}

assignPV($d64, ' +inf  ');

if(is_InfD64($d64) == 1) {print "ok 71\n"}
else {
  warn "Inf: $d64\n";
  print "not ok 71\n";
}

assignPV($d64, ' -0.162.235');

# Allow for known brokenness of 5.21.x (for x < 9) builds of perl.
if($] lt '5.021009' && $] ge '5.021001') {set_nnum(10)}

if("$d64" eq '-162e-3' && nnumflag() == 10) {print "ok 72\n"}
else {
  warn "\nExpected -162e-3\nGot $d64\n";
  warn "nnumflag expected 10, got ", nnumflag(), "\n";
  print "not ok 72\n";
}

###################################
# Do some checks for non-numerics #
###################################

assignPV($d64, '-a23');

if("$d64" eq '-0' && nnumflag() == 11) {print "ok 73\n"}
elsif("$d64" eq '0' && nnumflag() == 11){
  warn "\nThis compiler/libc doesn't honor sign of zero correctly\n";
  warn "This is not a failing of the module\n";
  print "ok 73\n";
}
else {
  warn "\nExpected -0\nGot $d64\n";
  warn "nnumflag expected 11, got ", nnumflag(), "\n";
  print "not ok 73\n";
}

assignPV($d64, " \r \n \t \f -23e-2.");

if("$d64" eq '-23e-2' && nnumflag() == 12) {print "ok 74\n"}
else {
  warn "\nExpected -23e-2\nGot $d64\n";
  warn "nnumflag expected 12, got ", nnumflag(), "\n";
  print "not ok 74\n";
}

assignPV($d64, " \r \n \t \f -23ae-2");

if("$d64" eq '-23e0' && nnumflag() == 13) {print "ok 75\n"}
else {
  warn "\nExpected -23e0\nGot $d64\n";
  warn "nnumflag expected 13, got ", nnumflag(), "\n";
  print "not ok 75\n";
}

assignPV($d64, " -23ea-2");

if("$d64" eq '-23e0') {print "ok 76\n"}
else {
  warn "\nExpected -23e0\nGot $d64\n";
  print "not ok 76\n";
}

assignPV($d64, "2a3e-2");

if("$d64" eq '2e0') {print "ok 77\n"}
else {
  warn "\nExpected 2e0\nGot $d64\n";
  print "not ok 77\n";
}

assignPV($d64, ' infa ');

if(is_InfD64($d64) == 1) {print "ok 78\n"}
else {
  warn "Inf: $d64\n";
  print "not ok 78\n";
}

assignPV($d64, ' +infa  ');

if(is_InfD64($d64) == 1) {print "ok 79\n"}
else {
  warn "Inf: $d64\n";
  print "not ok 79\n";
}

assignPV($d64, ' -0.162.a235');

if("$d64" eq '-162e-3') {print "ok 80\n"}
else {
  warn "\nExpected -162e-3\nGot $d64\n";
  print "not ok 80\n";
}

assignPV($d64, 'a23');

if("$d64" eq '0') {print "ok 81\n"}
else {
  warn "\nExpected 0\nGot $d64\n";
  print "not ok 81\n";
}

assignPV($d64, 'ae23');

if("$d64" eq '0') {print "ok 82\n"}
else {
  warn "\nExpected 0\nGot $d64\n";
  print "not ok 82\n";
}

assignPV($d64, 'a.23');

if("$d64" eq '0' && nnumflag() == 21) {print "ok 83\n"}
else {
  warn "\nExpected 0\nGot $d64\n";
  warn "nnumflag expected 21, got ", nnumflag(), "\n";
  print "not ok 83\n";
}

set_nnum(5);

if(nnumflag() == 5) {print "ok 84\n"}
else {
  warn "\nnnumflag expected 5, got ", nnumflag(), "\n";
  print "not ok 84\n";
}

clear_nnum();

if(nnumflag() == 0) {print "ok 85\n"}
else {
  warn "\nnnumflag expected 0, got ", nnumflag(), "\n";
  print "not ok 85\n";
}

assignPV($d64, '0 but true');

if("$d64" eq '0' && nnumflag() == 0) {print "ok 86\n"}
else {
  warn "\nExpected 0\nGot $d64\n";
  warn "nnumflag expected 0, got ", nnumflag(), "\n";
  print "not ok 86\n";
}

assignPV($d64, '0 But true');

if("$d64" eq '0' && nnumflag() == 1) {print "ok 87\n"}
else {
  warn "\nExpected 0\nGot $d64\n";
  warn "nnumflag expected 1, got ", nnumflag(), "\n";
  print "not ok 87\n";
}

assignPV($d64, 'InfiniTy');

if(is_InfD64($d64) && nnumflag() == 1) {print "ok 88\n"}
else {
  warn "\nExpected inf\nGot $d64\n";
  warn "nnumflag expected 1, got ", nnumflag(), "\n";
  print "not ok 88\n";
}

assignPV($d64, 'infinit');

if(is_InfD64($d64) && nnumflag() == 2) {print "ok 89\n"}
else {
  warn "\nExpected inf\nGot $d64\n";
  warn "nnumflag expected 2, got ", nnumflag(), "\n";
  print "not ok 89\n";
}

assignPV($d64, 'infinity 0');

if(is_InfD64($d64) && nnumflag() == 3) {print "ok 90\n"}
else {
  warn "\nExpected inf\nGot $d64\n";
  warn "nnumflag expected 3, got ", nnumflag(), "\n";
  print "not ok 90\n";
}


sub random_select {
  my $ret = '';
  for(1 .. $_[0]) {
    $ret .= int(rand(10));
  }
  return "$ret";
}

sub me2pv {
  my($man, $exp) = (shift, shift);
  my $sign = '';
  if($man =~ /[^0-9]/) {
    $sign = substr($man, 0, 1);
    $man = substr($man, 1);
  }
  my $len = length($man);
  my $pos = int(rand($len + 1));
  my $insert;
  if($pos == $len) {$insert = '.0'}
  elsif($pos == 0 && $len % 2) {$insert = '0.'}
  else {$insert = '.'}
  substr($man, $pos, 0, $insert);
  $exp += $len - $pos;
  my $ret = $sign . $man . 'e' . $exp;
  #print "$ret\n";
  return $ret;
}
