use strict;
use warnings;
use Math::Decimal64 qw(:all);

# Even on 'BID' format we can use DPDtoD128 to assign infs and nans ... so we
# might as well check that.

my $t;

if(d64_fmt() eq 'BID') {$t = 9} # Do only the inf/nan computations.
else {$t = 13}

print "1..$t\n";

my $inf = DPDtoD64('inf');

if(is_InfD64($inf) == 1) {print "ok 1\n"}
else {
  warn "Inf: $inf\n";
  print "not ok 1\n";
}

my $pinf = DPDtoD64('+inf');

if(is_InfD64($pinf) == 1) {print "ok 2\n"}
else {
  warn "+Inf: $pinf\n";
  print "not ok 2\n";
}

my $ninf = DPDtoD64('-inf');

if(is_InfD64($ninf) == -1) {print "ok 3\n"}
else {
  warn "-Inf: $ninf\n";
  print "not ok 3\n";
}

if($pinf == InfD64(1)) {print "ok 4\n"}
else {
  warn "Inf: $pinf\n";
  print "not ok 4\n";
}

if($ninf == InfD64(-1)) {print "ok 5\n"}
else {
  warn "-Inf: $ninf\n";
  print "not ok 5\n";
}

my $nan = DPDtoD64('nan');
my $pnan = DPDtoD64('+nan');
my $nnan = DPDtoD64('-nan');

if(is_NaND64($nan)) {print "ok 6\n"}
else {
  warn "NaN: $nan\n";
  print "not ok 6\n";
}

if(is_NaND64($pnan)) {print "ok 7\n"}
else {
  warn "+NaN: $pnan\n";
  print "not ok 7\n";
}

if(is_NaND64($nnan)) {print "ok 8\n"}
else {
  warn "-NaN: $nnan\n";
  print "not ok 8\n";
}

if($nan != NaND64()) {print "ok 9\n"}
else {
  warn "$nan == ", NaND64(), "\n";
  print "not ok 9\n";
}

exit 0 if d64_fmt() eq 'BID';

my $ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = '-' . random_select($digits);
    my $d64 = MEtoD64($man, -$exp);
    my $check = DPDtoD64($man, -$exp);
    if($check != $d64) {
      $ok = 0;
      warn "\n  MEtoD64: $d64\n  DPDtoD64: $check\n";
    }
  }
}

$ok ? print "ok 10\n" : print "not ok 10\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = random_select($digits);
    my $d64 = MEtoD64($man, $exp);
    my $check = DPDtoD64($man, $exp);
    if($check != $d64) {
      $ok = 0;
      warn "\n  MEtoD64: $d64\n  DPDtoD64: $check\n";
    }
  }
}

$ok ? print "ok 11\n" : print "not ok 11\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = '-' . random_select($digits);
    my $d64 = MEtoD64($man, $exp);
    my $check = DPDtoD64($man, $exp);
    if($check != $d64) {
      $ok = 0;
      warn "\n  MEtoD64: $d64\n  DPDtoD64: $check\n";
    }
  }
}

$ok ? print "ok 12\n" : print "not ok 12\n";

$ok = 1;

for my $exp(0..10, 20, 30, 350 .. 430) {
  for my $digits(1..16) {
    my $man = random_select($digits);
    my $d64 = MEtoD64($man, -$exp);
    my $check = DPDtoD64($man, -$exp);
    if($check != $d64) {
      $ok = 0;
      warn "\n  MEtoD64: $d64\n  DPDtoD64: $check\n";
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
