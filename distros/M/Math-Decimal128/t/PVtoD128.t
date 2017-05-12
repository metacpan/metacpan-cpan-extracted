use strict;
use warnings;
use Math::Decimal128 qw(:all);

my $t = 17;

print "1..$t\n";

my $inf = PVtoD128('inf');

if(is_InfD128($inf) == 1) {print "ok 1\n"}
else {
  warn "Inf: $inf\n";
  print "not ok 1\n";
}

my $pinf = PVtoD128('+inf');

if(is_InfD128($pinf) == 1) {print "ok 2\n"}
else {
  warn "+Inf: $pinf\n";
  print "not ok 2\n";
}

my $ninf = PVtoD128('-inf');

if(is_InfD128($ninf) == -1) {print "ok 3\n"}
else {
  warn "-Inf: $ninf\n";
  print "not ok 3\n";
}

if($pinf == InfD128(1)) {print "ok 4\n"}
else {
  warn "Inf: $pinf\n";
  print "not ok 4\n";
}

if($ninf == InfD128(-1)) {print "ok 5\n"}
else {
  warn "-Inf: $ninf\n";
  print "not ok 5\n";
}

my $nan = PVtoD128('nan');
my $pnan = PVtoD128('+nan');
my $nnan = PVtoD128('-nan');

if(is_NaND128($nan)) {print "ok 6\n"}
else {
  warn "NaN: $nan\n";
  print "not ok 6\n";
}

if(is_NaND128($pnan)) {print "ok 7\n"}
else {
  warn "+NaN: $pnan\n";
  print "not ok 7\n";
}

if(is_NaND128($nnan)) {print "ok 8\n"}
else {
  warn "-NaN: $nnan\n";
  print "not ok 8\n";
}

if($nan != NaND128()) {print "ok 9\n"}
else {
  warn "$nan == ", NaND128(), "\n";
  print "not ok 9\n";
}

my $ok = 1;

warn "\nThe remaining PVtoD128.t tests might take a couple of minutes\n";

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..34) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    my $check = PVtoD128($man . 'e' . -$exp);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $check\n";
    }
  }
}

$ok ? print "ok 10\n" : print "not ok 10\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..34) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    my $check = PVtoD128($man . 'E' . $exp);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $check\n";
    }
  }
}

$ok ? print "ok 11\n" : print "not ok 11\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..26) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    my $check = PVtoD128($man . 'E' . $exp);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $check\n";
    }
  }
}

$ok ? print "ok 12\n" : print "not ok 12\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..26) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    my $check = PVtoD128($man . 'e' . -$exp);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $check\n";
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
    my $check = PVtoD128($mod);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $check\n";
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
    my $check = PVtoD128($mod);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $check\n";
    }
  }
}

$ok ? print "ok 15\n" : print "not ok 15\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..26) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    my $mod = me2pv($man, $exp);
    my $check = PVtoD128($mod);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $check\n";
    }
  }
}

$ok ? print "ok 16\n" : print "not ok 16\n";

$ok = 1;

for my $exp(0..10, 6140 .. 6220) {
  for my $digits(1..26) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    my $mod = me2pv($man, -$exp);
    my $check = PVtoD128($mod);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $check\n";
    }
  }
}

$ok ? print "ok 17\n" : print "not ok 17\n";

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
