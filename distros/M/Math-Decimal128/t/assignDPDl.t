use strict;
use warnings;
use Math::Decimal128 qw(:all);

my $t = d128_fmt() eq 'BID' ? 9 : 17;

print "1..$t\n";

my $rop = Math::Decimal128->new();

assignDPDl($rop, 'inf');

if(is_InfD128($rop) == 1) {print "ok 1\n"}
else {
  warn "Inf: $rop\n";
  print "not ok 1\n";
}

assignDPDl($rop, '-inf');

if(is_InfD128($rop) == -1) {print "ok 2\n"}
else {
  warn "-Inf: $rop\n";
  print "not ok 2\n";
}

assignDPDl($rop, '+inf');

if(is_InfD128($rop) == 1) {print "ok 3\n"}
else {
  warn "+Inf: $rop\n";
  print "not ok 3\n";
}

# Space for 2 tests here.
print "ok 4\nok 5\n";

assignDPDl($rop, 'nan');

if(is_NaND128($rop)) {print "ok 6\n"}
else {
  warn "NaN: $rop\n";
  print "not ok 6\n";
}

assignDPDl($rop, '+nan');

if(is_NaND128($rop)) {print "ok 7\n"}
else {
  warn "+NaN: $rop\n";
  print "not ok 7\n";
}

assignDPDl($rop, '-nan');

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

exit 0 if d128_fmt eq 'BID';

my $ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300, 6150 .. 6176, 6200) {
  for my $digits(1..34) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    assignDPDl($rop, $man, -$exp);
    #my $check = PVtoD128($man . 'e' . -$exp);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 10\n" : print "not ok 10\n";

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300, 6100 .. 6111, 6200) {
  for my $digits(1..34) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    assignDPDl($rop, $man, $exp);
    #my $check = PVtoD128($man . 'E' . $exp);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 11\n" : print "not ok 11\n";

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300, 6111, 6200) {
  for my $digits(1..26) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    assignDPDl($rop, $man, $exp);
    #my $check = PVtoD128($man . 'E' . $exp);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 12\n" : print "not ok 12\n";

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300, 6176, 6200) {
  for my $digits(1..26) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    assignDPDl($rop, $man, -$exp);
    #my $check = PVtoD128($man . 'e' . -$exp);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 13\n" : print "not ok 13\n";

$ok = 1;

for my $exp(0..10, 20, 30, 6150 .. 6176, 6200) {
  for my $digits(1..34) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    #my $mod = me2pv($man, -$exp);
    assignDPDl($rop, $man, -$exp);
    #my $check = PVtoD128($mod);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 14\n" : print "not ok 14\n";

$ok = 1;

for my $exp(0..10, 20, 30, 6100 .. 6111, 6200) {
  for my $digits(1..34) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    #my $mod = me2pv($man, $exp);
    assignDPDl($rop, $man, $exp);
    #my $check = PVtoD128($mod);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 15\n" : print "not ok 15\n";

$ok = 1;

for my $exp(0..10, 20, 30, 6100 .. 6111, 6200) {
  for my $digits(1..26) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    #my $mod = me2pv($man, $exp);
    assignDPDl($rop, $man, $exp);
    #my $check = PVtoD128($mod);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
    }
  }
}

$ok ? print "ok 16\n" : print "not ok 16\n";

$ok = 1;

for my $exp(0..10, 20, 30, 6150 .. 6176, 6200) {
  for my $digits(1..26) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    #my $mod = me2pv($man, -$exp);
    assignDPDl($rop, $man, -$exp);
    #my $check = PVtoD128($mod);
    if($rop != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  PVtoD128: $rop\n";
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
