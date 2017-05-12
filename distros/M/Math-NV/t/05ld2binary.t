use strict;
use warnings;
use Math::NV qw(:all);

print "1..7\n";

my($man1, $exp1, $prec1) = ld2binary(-1023.75);
my($man2, $exp2, $prec2) = ld_str2binary('-10237500e-4');

if($man1 eq $man2) {print "ok 1\n"}
else {
  warn "\n\$man1: $man1\n\$man2: $man2\n";
  print "not ok 1\n";
}

if($exp1 eq $exp2) {print "ok 2\n"}
else {
  warn "\n\$exp1: $exp1\n\$exp2: $exp2\n";
  print "not ok 2\n";
}


if($prec1 eq $prec2) {print "ok 3\n"}
else {
  warn "\n\$prec1: $prec1\n\$prec2: $prec2\n";
  print "not ok 3\n";
}

if($man1 eq '-0.111111111111') {print "ok 4\n"}
else {
  warn "\nExpected '-0.111111111111'\nGot '$man1'\n";
  print "not ok 4\n";
}

if($exp1 eq '10') {print "ok 5\n"}
else {
  warn "\nExpected '10'\nGot '$exp1'\n";
  print "not ok 5\n";
}

if($prec1 eq '12') {print "ok 6\n"}
else {
  warn "\nExpected '12'\nGot '$prec1'\n";
  print "not ok 6\n";
}

my $nv_check = bin2val($man1, $exp1, $prec1);

if($nv_check == -1023.75) {print "ok 7\n"}
else {
  warn "\nExpected -1.023.75\nGot $nv_check\n";
  print "not ok 7\n";
}
