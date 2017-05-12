use strict;
use warnings;
use Math::Decimal128 qw(:all);

# Even on 'BID' format we can use DPDtoD128 to assign infs and nans ... so we
# might as well check that.

my $t;

if(d128_fmt() eq 'BID') {$t = 9} # Do only the inf/nan computations.
else {$t = 13}

print "1..$t\n";

my $inf = DPDtoD128('inf');

if(is_InfD128($inf) == 1) {print "ok 1\n"}
else {
  warn "Inf: $inf\n";
  print "not ok 1\n";
}

my $pinf = DPDtoD128('+inf');

if(is_InfD128($pinf) == 1) {print "ok 2\n"}
else {
  warn "+Inf: $pinf\n";
  print "not ok 2\n";
}

my $ninf = DPDtoD128('-inf');

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

my $nan = DPDtoD128('nan');
my $pnan = DPDtoD128('+nan');
my $nnan = DPDtoD128('-nan');

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

exit 0 if d128_fmt() eq 'BID';

my $ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300, 6090..6100) {
  for my $digits(1..34) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    my $check = DPDtoD128($man, -$exp);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  DPDtoD128: $check\n";
    }
  }
}

$ok ? print "ok 10\n" : print "not ok 10\n";

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300, 6090..6100) {
  for my $digits(1..34) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    my $check = DPDtoD128($man, $exp);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  DPDtoD128: $check\n";
    }
  }
}

$ok ? print "ok 11\n" : print "not ok 11\n";

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300,) {
  for my $digits(1..26) {
    my $man = '-' . random_select($digits);
    my $d128 = MEtoD128($man, $exp);
    my $check = DPDtoD128($man, $exp);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  DPDtoD128: $check\n";
    }
  }
}

$ok ? print "ok 12\n" : print "not ok 12\n";

$ok = 1;

for my $exp(0..10, 20, 30, 280 .. 300,) {
  for my $digits(1..26) {
    my $man = random_select($digits);
    my $d128 = MEtoD128($man, -$exp);
    my $check = DPDtoD128($man, -$exp);
    if($check != $d128) {
      $ok = 0;
      warn "\n  MEtoD128: $d128\n  DPDtoD128: $check\n";
    }
  }
}

$ok ? print "ok 13\n" : print "not ok 13\n";

sub random_select {
  my $ret = '';
  for(1 .. $_[0]) {
    $ret .= int(rand(10));
  }
  return "$ret";
}
