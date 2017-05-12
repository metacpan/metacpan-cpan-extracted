use strict;
use warnings;
use Math::Decimal128 qw(:all);


*nnumflagl   = \&Math::Decimal128::nnumflag;
*set_nnuml   = \&Math::Decimal128::set_nnum;
*clear_nnuml = \&Math::Decimal128::clear_nnum;

my $t = 90;

print "1..$t\n";

my $rop = Math::Decimal128->new();

assignPVl($rop, 'inf');

if(is_InfD128($rop) == 1) {print "ok 1\n"}
else {
  warn "Inf: $rop\n";
  print "not ok 1\n";
}

assignPVl($rop, '-inf');

if(is_InfD128($rop) == -1) {print "ok 2\n"}
else {
  warn "-Inf: $rop\n";
  print "not ok 2\n";
}

assignPVl($rop, '+inf');

if(is_InfD128($rop) == 1) {print "ok 3\n"}
else {
  warn "+Inf: $rop\n";
  print "not ok 3\n";
}

# Space for 2 tests here.
print "ok 4\nok 5\n";

assignPVl($rop, 'nan');

if(is_NaND128($rop)) {print "ok 6\n"}
else {
  warn "NaN: $rop\n";
  print "not ok 6\n";
}

assignPVl($rop, '+nan');

if(is_NaND128($rop)) {print "ok 7\n"}
else {
  warn "+NaN: $rop\n";
  print "not ok 7\n";
}

assignPVl($rop, '-nan');

if(is_NaND128($rop)) {print "ok 8\n"}
else {
  warn "-NaN: $rop\n";
  print "not ok 8\n";
}

if($rop != NaND128()) {print "ok 9\n"}
else {
  warn "$rop == ", NaND128(), "\n";
  print "not ok 9\n";
}

warn "\nThe remaining assignPVl.t tests might take a couple of minutes\n";

my $ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..34) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    assignPVl($rop, $man . 'e' . -$exp);
    #my $check = PVtoD128($man . 'e' . -$exp);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 10\n" : print "not ok 10\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..34) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    assignPVl($rop, $man . 'E' . $exp);
    #my $check = PVtoD128($man . 'E' . $exp);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 11\n" : print "not ok 11\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..34) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    assignPVl($rop, $man . 'E' . $exp);
    #my $check = PVtoD128($man . 'E' . $exp);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 12\n" : print "not ok 12\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..34) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    assignPVl($rop, $man . 'e' . -$exp);
    #my $check = PVtoD128($man . 'e' . -$exp);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 13\n" : print "not ok 13\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..34) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    my $mod = me2pv($man, -$exp);
    assignPVl($rop, $mod);
    #my $check = PVtoD128($mod);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 14\n" : print "not ok 14\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..34) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    my $mod = me2pv($man, $exp);
    assignPVl($rop, $mod);
    #my $check = PVtoD128($mod);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 15\n" : print "not ok 15\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..34) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    my $mod = me2pv($man, $exp);
    assignPVl($rop, $mod);
    #my $check = PVtoD128($mod);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 16\n" : print "not ok 16\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..34) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    my $mod = me2pv($man, -$exp);
    assignPVl($rop, $mod);
    #my $check = PVtoD128($mod);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  \$mod: $mod\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 17\n" : print "not ok 17\n";

my $d128 = Math::Decimal128->new();

assignPVl($d128, '-0');
my $test = is_ZeroD128($d128);

if($test == -1) {print "ok 18\n"}
elsif($test == 1) {
  warn "\nThis compiler/libc doesn't honor sign of zero correctly\n";
  warn "This is not a failing of the module\n";
  print "ok 18\n";
}
else {
  warn "\nExpected -1\nGot $test\n";
  print "not ok 18\n";
}

assignPVl($d128, '0.0');
$test = is_ZeroD128($d128);

if($test == 1) {print "ok 19\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 19\n";
}

assignPVl($d128, '+inf');
$test = is_InfD128($d128);

if($test == 1) {print "ok 20\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 20\n";
}

assignPVl($d128, 'inf');
$test = is_InfD128($d128);

if($test == 1) {print "ok 21\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 21\n";
}

assignPVl($d128, '-inf');
$test = is_InfD128($d128);

if($test == -1) {print "ok 22\n"}
else {
  warn "\nExpected -1\nGot $test\n";
  print "not ok 22\n";
}

assignPVl($d128, 'nan');
$test = is_NaND128($d128);

if($test == 1) {print "ok 23\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 23\n";
}

assignPVl($d128, '-nan');
$test = is_NaND128($d128);

if($test == 1) {print "ok 24\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 24\n";
}

assignPVl($d128, '+nan');
$test = is_NaND128($d128);

if($test == 1) {print "ok 25\n"}
else {
  warn "\nExpected 1\nGot $test\n";
  print "not ok 25\n";
}

assignPVl($d128, '47');

if("$d128" eq '47e0') {print "ok 26\n"}
else {
  warn "\nExpected 47e0\nGot $d128\n";
  print "not ok 26\n";
}

assignPVl($d128, '-47');

if("$d128" eq '-47e0') {print "ok 27\n"}
else {
  warn "\nExpected 47e0\nGot $d128\n";
  print "not ok 27\n";
}

assignPVl($d128, '+047.0');

if("$d128" eq '47e0') {print "ok 28\n"}
else {
  warn "\nExpected 47e0\nGot $d128\n";
  print "not ok 28\n";
}

assignPVl($d128, '-47e0');

if("$d128" eq '-47e0') {print "ok 29\n"}
else {
  warn "\nExpected 47e0\nGot $d128\n";
  print "not ok 29\n";
}

assignPVl($d128, '47e-2');

if("$d128" eq '47e-2') {print "ok 30\n"}
else {
  warn "\nExpected 47e-2\nGot $d128\n";
  print "not ok 30\n";
}

assignPVl($d128, '-47e-2');

if("$d128" eq '-47e-2') {print "ok 31\n"}
else {
  warn "\nExpected -47e-2\nGot $d128\n";
  print "not ok 31\n";
}

assignPVl($d128, '47e+2');

if("$d128" eq '47e2') {print "ok 32\n"}
else {
  warn "\nExpected 47e2\nGot $d128\n";
  print "not ok 32\n";
}

assignPVl($d128, '-47e+2');

if("$d128" eq '-47e2') {print "ok 33\n"}
else {
  warn "\nExpected -47e2\nGot $d128\n";
  print "not ok 33\n";
}

assignPVl($d128, '47.116e+2');

if("$d128" eq '47116e-1') {print "ok 34\n"}
else {
  warn "\nExpected 47116e-1\nGot $d128\n";
  print "not ok 34\n";
}

assignPVl($d128, '-47.1165e+2');

if("$d128" eq '-471165e-2') {print "ok 35\n"}
else {
  warn "\nExpected -471165e-2\nGot $d128\n";
  print "not ok 35\n";
}

assignPVl($d128, '47.116');

if("$d128" eq '47116e-3') {print "ok 36\n"}
else {
  warn "\nExpected 47116e-3\nGot $d128\n";
  print "not ok 36\n";
}

assignPVl($d128, '-47.1165');

if("$d128" eq '-471165e-4') {print "ok 37\n"}
else {
  warn "\nExpected -471165e-4\nGot $d128\n";
  print "not ok 37\n";
}

assignPVl($d128, '47116.0e+2');

if("$d128" eq '47116e2') {print "ok 38\n"}
else {
  warn "\nExpected 47116e2\nGot $d128\n";
  print "not ok 38\n";
}

assignPVl($d128, '-471165.0e+2');

if("$d128" eq '-471165e2') {print "ok 39\n"}
else {
  warn "\nExpected -471165e2\nGot $d128\n";
  print "not ok 39\n";
}

assignPVl($d128, '-46e-180');

if("$d128" eq '-46e-180') {print "ok 40\n"}
else {
  warn "\nExpected -46e-180\nGot $d128\n";
  print "not ok 40\n";
}

assignPVl($d128, '46e180');

if("$d128" eq '46e180') {print "ok 41\n"}
else {
  warn "\nExpected 46e180\nGot $d128\n";
  print "not ok 41\n";
}

assignPVl($d128, '-46.98317e-180');

if("$d128" eq '-4698317e-185') {print "ok 42\n"}
else {
  warn "\nExpected -4698317e-185\nGot $d128\n";
  print "not ok 42\n";
}

assignPVl($d128, '-46.98317e180');

if("$d128" eq '-4698317e175' && nnumflagl() == 0) {print "ok 43\n"}
else {
  warn "\nExpected -4698317e175\nGot $d128\n";
  warn "nnumflagl expected 0, got ", nnumflagl(), "\n";
  print "not ok 43\n";
}

assignPVl($d128, '-46.98317e180z1');

if("$d128" eq '-4698317e175' && nnumflagl() == 1) {print "ok 44\n"}
else {
  warn "\nExpected -4698317e175\nGot $d128\n";
  warn "nnumflagl expected 1, got ", nnumflagl(), "\n";
  print "not ok 44\n";
}

assignPVl($d128, '-51e383');

if("$d128" eq '-51e383') {print "ok 45\n"}
else {
  warn "\nExpected -51e383\nGot $d128\n";
  print "not ok 45\n";
}

assignPVl($d128, '-0e410');

if("$d128" eq '-0') {print "ok 46\n"}
elsif("$d128" eq '0') {
  warn "\nThis compiler/libc doesn't honor sign of zero correctly\n";
  warn "This is not a failing of the module\n";
  print "ok 46\n";
}
else {
  warn "\nExpected -0\nGot $d128\n";
  print "not ok 46\n";
}

assignPVl($d128, '-2372646073611e353');
if("$d128" eq '-2372646073611e353') {print "ok 47\n"}
else {
  warn "\nExpected -2372646073611e353\nGot $d128\n";
  print "not ok 47\n";
}

assignPVl($d128, '623537214927823e-409');

if("$d128" eq '623537214927823e-409') {print "ok 48\n"}
else {
  warn "\nExpected 623537214927823e-409\nGot $d128\n";
  print "not ok 48\n";
}

assignPVl($d128, '-623537214927823e-409');

if("$d128" eq '-623537214927823e-409') {print "ok 49\n"}
else {
  warn "\nExpected -623537214927823e-409\nGot $d128\n";
  print "not ok 49n";
}

assignPVl($d128, '6235572149278230000e-413');

if("$d128" eq '623557214927823e-409') {print "ok 50\n"}
else {
  warn "\nExpected 623557214927823e-409\nGot $d128\n";
  print "not ok 50\n";
}

assignPVl($d128, '-623557.214927823e-400');

if("$d128" eq '-623557214927823e-409') {print "ok 51\n"}
else {
  warn "\nExpected -623557214927823e-409\nGot $d128\n";
  print "not ok 51\n";
}

assignPVl($d128, '62355e-399');

if("$d128" eq '62355e-399') {print "ok 52\n"}
else {
  warn "\nExpected 62355e-399\nGot $d128\n";
  print "not ok 52\n";
}

assignPVl($d128, '-6.2355e-395');

if("$d128" eq '-62355e-399') {print "ok 53\n"}
else {
  warn "\nExpected -62355e-399\nGot $d128\n";
  print "not ok 53\n";
}

assignPVl($d128, '6234500e-401');

if("$d128" eq '62345e-399') {print "ok 54\n"}
else {
  warn "\nExpected 62345e-399\nGot $d128\n";
  print "not ok 54\n";
}

assignPVl($d128, '-623.45e-397');

if("$d128" eq '-62345e-399') {print "ok 55\n"}
else {
  warn "\nExpected -62345e-399\nGot $d128\n";
  print "not ok 55\n";
}

assignPVl($d128, '5371185275501e-397');

if("$d128" eq '5371185275501e-397') {print "ok 56\n"}
else {
  warn "\nExpected 5371185275501e-397\nGot $d128\n";
  print "not ok 56\n";
}

assignPVl($d128 , '-3.090145872714666e15');

if("$d128" eq '-3090145872714666e0') {print "ok 57\n"}
else {
  warn "\nExpected -3090145872714666e0\nGot $d128\n";
  print "not ok 57\n";
}

assignPVl($d128, '0.0062e385');

if("$d128" eq '62e381') {print "ok 58\n"}
else {
  warn "\nExpected 62e381\nGot $d128\n";
  print "not ok 58\n";
}

assignPVl($d128, '.0062e385');

if("$d128" eq '62e381') {print "ok 59\n"}
else {
  warn "\nExpected 62e381\nGot $d128\n";
  print "not ok 59\n";
}

assignPVl($d128, '-0.6e385');

if("$d128" eq '-6e384') {print "ok 60\n"}
else {
  warn "\nExpected -6e384\nGot $d128\n";
  print "not ok 60\n";
}

assignPVl($d128, '131e-6176');

if("$d128" eq '131e-6176') {print "ok 61\n"}
else {
  warn "\nExpected 131e-6176\nGot $d128\n";
  print "not ok 61\n";
}

assignPVl($d128, '1312.67366122681036974666750688613e-6177');

if("$d128" eq '131e-6176' && nnumflagl() == 1) {print "ok 62\n"}
else {
  warn "\nExpected 131e-6176\nGot $d128\n";
  warn "nnumflagl expected 1, got ", nnumflagl(), "\n";
  print "not ok 62\n";
}

assignPVl($d128, '-');

if("$d128" eq '-0') {print "ok 63\n"}
elsif("$d128" eq '0') {
  warn "\nThis compiler/libc doesn't honor sign of zero correctly\n";
  warn "This is not a failing of the module\n";
  print "ok 63\n";
}
else {
  warn "\nExpected -0\nGot $d128\n";
  print "not ok 63\n";
}

assignPVl($d128, ' ');

if("$d128" eq '0' && nnumflagl() == 3) {print "ok 64\n"}
else {
  warn "\nExpected 0\nGot $d128\n";
  warn "nnumflagl expected 3, got ", nnumflagl(), "\n";
  print "not ok 64\n";
}

#############################
# Do some checks for spaces #
#############################

assignPVl($d128, '- 23');

if("$d128" eq '-0' && nnumflagl() == 4) {print "ok 65\n"}
elsif("$d128" eq '0' && nnumflagl() == 4) {
  warn "\nThis compiler/libc doesn't honor sign of zero correctly\n";
  warn "This is not a failing of the module\n";
  print "ok 65\n";
}
else {
  warn "\nExpected -0\nGot $d128\n";
  warn "nnumflagl expected 4, got ", nnumflagl(), "\n";
  print "not ok 65\n";
}

assignPVl($d128, " \r \n \t \f -23e-2");

if("$d128" eq '-23e-2') {print "ok 66\n"}
else {
  warn "\nExpected -23e-2\nGot $d128\n";
  print "not ok 66\n";
}

assignPVl($d128, " \r \n \t \f -23 e-2");

if("$d128" eq '-23e0' && nnumflagl() == 5) {print "ok 67\n"}
else {
  warn "\nExpected -23e0\nGot $d128\n";
  warn "nnumflagl expected 5, got ", nnumflagl(), "\n";
  print "not ok 67\n";
}

assignPVl($d128, " -23e -2");

if("$d128" eq '-23e0') {print "ok 68\n"}
else {
  warn "\nExpected -23e0\nGot $d128\n";
  print "not ok 68\n";
}

assignPVl($d128, "2 3e-2");

if("$d128" eq '2e0' && nnumflagl() == 7) {print "ok 69\n"}
else {
  warn "\nExpected 2e0\nGot $d128\n";
  warn "nnumflagl expected 7, got ", nnumflagl(), "\n";
  print "not ok 69\n";
}

assignPVl($d128, ' inf  ');

if(is_InfD128($d128) == 1) {print "ok 70\n"}
else {
  warn "Inf: $d128\n";
  print "not ok 70\n";
}

assignPVl($d128, ' +inf  ');

if(is_InfD128($d128) == 1) {print "ok 71\n"}
else {
  warn "Inf: $d128\n";
  print "not ok 71\n";
}

assignPVl($d128, ' -0.162.235');

# Allow for known brokenness of 5.21.x (for x < 9) builds of perl.
if($] lt '5.021009' && $] ge '5.021001') {set_nnuml(8)}

if("$d128" eq '-162e-3' && nnumflagl() == 8) {print "ok 72\n"}
else {
  warn "\nExpected -162e-3\nGot $d128\n";
  warn "nnumflagl expected 8, got ", nnumflagl(), "\n";
  print "not ok 72\n";
}

###################################
# Do some checks for non-numerics #
###################################

assignPVl($d128, '-a23');

if("$d128" eq '-0' && nnumflagl() == 9) {print "ok 73\n"}
elsif("$d128" eq '0' && nnumflagl() == 9) {
  warn "\nThis compiler/libc doesn't honor sign of zero correctly\n";
  warn "This is not a failing of the module\n";
  print "ok 73\n";
}
else {
  warn "\nExpected -0\nGot $d128\n";
  warn "nnumflagl expected 9, got ", nnumflagl(), "\n";
  print "not ok 73\n";
}

assignPVl($d128, " \r \n \t \f -23e-2.");

if("$d128" eq '-23e-2') {print "ok 74\n"}
else {
  warn "\nExpected -23e-2\nGot $d128\n";
  print "not ok 74\n";
}

assignPVl($d128, " \r \n \t \f -23ae-2");

if("$d128" eq '-23e0' && nnumflagl() == 11) {print "ok 75\n"}
else {
  warn "\nExpected -23e0\nGot $d128\n";
  warn "nnumflagl expected 11, got ", nnumflagl(), "\n";
  print "not ok 75\n";
}

assignPVl($d128, " -23ea-2");

if("$d128" eq '-23e0') {print "ok 76\n"}
else {
  warn "\nExpected -23e0\nGot $d128\n";
  print "not ok 76\n";
}

assignPVl($d128, "2a3e-2");

if("$d128" eq '2e0') {print "ok 77\n"}
else {
  warn "\nExpected 2e0\nGot $d128\n";
  print "not ok 77\n";
}

assignPVl($d128, ' infa ');

if(is_InfD128($d128) == 1) {print "ok 78\n"}
else {
  warn "Inf: $d128\n";
  print "not ok 78\n";
}

assignPVl($d128, ' +infa  ');

if(is_InfD128($d128) == 1) {print "ok 79\n"}
else {
  warn "Inf: $d128\n";
  print "not ok 79\n";
}

assignPVl($d128, ' -0.162.a235');

if("$d128" eq '-162e-3') {print "ok 80\n"}
else {
  warn "\nExpected -162e-3\nGot $d128\n";
  print "not ok 80\n";
}

assignPVl($d128, 'a23');

if("$d128" eq '0') {print "ok 81\n"}
else {
  warn "\nExpected 0\nGot $d128\n";
  print "not ok 81\n";
}

assignPVl($d128, 'ae23');

if("$d128" eq '0') {print "ok 82\n"}
else {
  warn "\nExpected 0\nGot $d128\n";
  print "not ok 82\n";
}

assignPVl($d128, 'a.23');

if("$d128" eq '0' && nnumflagl() == 19) {print "ok 83\n"}
else {
  warn "\nExpected 0\nGot $d128\n";
  warn "nnumflagl expected 19, got ", nnumflagl(), "\n";
  print "not ok 83\n";
}

set_nnuml(5);

if(nnumflagl() == 5) {print "ok 84\n"}
else {
  warn "\nnnumflagl expected 5, got ", nnumflagl(), "\n";
  print "not ok 84\n";
}

clear_nnuml();

if(nnumflagl() == 0) {print "ok 85\n"}
else {
  warn "\nnnumflagl expected 0, got ", nnumflagl(), "\n";
  print "not ok 85\n";
}

assignPVl($d128, '0 but true');

if("$d128" eq '0' && nnumflagl() == 0) {print "ok 86\n"}
else {
  warn "\nExpected 0\nGot $d128\n";
  warn "nnumflagl expected 0, got ", nnumflagl(), "\n";
  print "not ok 86\n";
}

assignPVl($d128, '0 But true');

if("$d128" eq '0' && nnumflagl() == 1) {print "ok 87\n"}
else {
  warn "\nExpected 0\nGot $d128\n";
  warn "nnumflagl expected 1, got ", nnumflagl(), "\n";
  print "not ok 87\n";
}


assignPVl($d128, 'InfiniTy');

if(is_InfD128($d128) && nnumflagl() == 1) {print "ok 88\n"}
else {
  warn "\nExpected inf\nGot $d128\n";
  warn "nnumflag expected 1, got ", nnumflagl(), "\n";
  print "not ok 88\n";
}

assignPVl($d128, 'infinit');

if(is_InfD128($d128) && nnumflagl() == 2) {print "ok 89\n"}
else {
  warn "\nExpected inf\nGot $d128\n";
  warn "nnumflag expected 2, got ", nnumflagl(), "\n";
  print "not ok 89\n";
}

assignPVl($d128, 'infinitys');

if(is_InfD128($d128) && nnumflagl() == 3) {print "ok 90\n"}
else {
  warn "\nExpected inf\nGot $d128\n";
  warn "nnumflag expected 3, got ", nnumflagl(), "\n";
  print "not ok 90\n";
}

#################################
#################################

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

###################################
###################################
