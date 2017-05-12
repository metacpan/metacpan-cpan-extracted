use warnings;
use strict;
use Math::Complex_C qw(:all);

print "1..14\n";

my $eps = 1e-12;

my $rop = Math::Complex_C->new();
my $op = Math::Complex_C->new(4.3, -5.7);

conj_c($rop, $op);

if(approx(real_c($rop), 4.3, $eps)) {print "ok 1\n"}
else {
  warn "\nExpected approx 4.3\nGot ", real_c($rop), "\n";
  print "not ok 1\n";
}

if(approx(imag_c($rop), 5.7, $eps)) {print "ok 2\n"}
else {
  warn "\nExpected approx 5.7\nGot ", imag_c($rop), "\n";;
  print "not ok 2\n";
}

proj_c($rop, $op);

# For some versions of glibc (pre 2.12.0), cprojl will incorrectly
# return (0.165448249326664 -0.219315121200462)

if(approx(real_c($rop), 4.3, $eps)) {print "ok 3\n"}
elsif(approx(real_c($rop), 0.165448249326664, $eps) &&
      approx(imag_c($rop), -0.219315121200462, $eps)) {
  warn "\nSkipping tests 3 & 4 - your glibc contains a bug that breaks cprojl()\n",
       "Updating your glibc to version 2.12.0 or later should fix the problem\n";
  print "ok 3\n";
}
else {
  warn "\nExpected approx 4.3\nGot ", real_c($rop), "\n";
  print "not ok 3\n";
}

if(approx(imag_c($rop), -5.7, $eps)) {print "ok 4\n"}
elsif(approx(real_c($rop), 0.165448249326664, $eps) &&
      approx(imag_c($rop), -0.219315121200462, $eps)) {print "ok 4\n"}
else {
  warn "\nExpected approx -5.7\nGot ", imag_c($rop), "\n";
  print "not ok 4\n";
}

##############################
##############################
my $nan = get_nan();
my $inf = get_inf();

assign_c($op, $inf, 1);

proj_c($rop, $op);

if(is_inf(real_c($rop))) {print "ok 5\n"}
else {
  warn "\nExpected infinity\nGot ", real_c($rop), "\n";
  print "not ok 5\n";
}

my $sz = imag_c($rop);

if("$sz" eq "0") {print "ok 6\n"}
else {
  warn "\nExpected 0\nGot ", imag_c($rop), "\n";
  print "not ok 6\n";
}

##############################
##############################

assign_c($op, $inf, -1);

proj_c($rop, $op);

if(is_inf(real_c($rop))) {print "ok 7\n"}
else {
  warn "\nExpected infinity\nGot ", real_c($rop), "\n";
  print "not ok 7\n";
}

$sz = imag_c($rop);

if($sz == 0) {print "ok 8\n"}
else {
  warn "\nExpected 0\nGot ", imag_c($rop), "\n";
  print "not ok 8\n";
}

##############################
##############################

assign_c($op, $inf, $nan);

proj_c($rop, $op);

if(is_inf(real_c($rop))) {print "ok 9\n"}
else {
  warn "\nExpected infinity\nGot ", real_c($rop), "\n";
  print "not ok 9\n";
}

$sz = imag_c($rop);

# The sign of $sz should be the same as the sign of $op's imaginary part, but $op's imaginary
# part is NaN ... so we can probably accept either '0' or '-0' here, especially given that we
# don't support signed NaN. (Recent perl's variously return 0 or -0.)

if("$sz" eq "0" || "$sz" eq "-0") {print "ok 10\n"}
else {
  warn "\nExpected 0\nGot ", imag_c($rop), "\n";
  print "not ok 10\n";
}


##############################
##############################

assign_c($op, $nan, $inf);

proj_c($rop, $op);

if(is_inf(real_c($rop))) {print "ok 11\n"}
else {
  warn "\nExpected infinity\nGot ", real_c($rop), "\n";
  print "not ok 11\n";
}

$sz = imag_c($rop);

if("$sz" eq "0") {print "ok 12\n"}
else {
  warn "\nExpected 0\nGot ", imag_c($rop), "\n";
  print "not ok 12\n";
}

##############################
##############################

assign_c($op, $nan, $inf * -1);

proj_c($rop, $op);

if(is_inf(real_c($rop))) {print "ok 13\n"}
else {
  warn "\nExpected infinity\nGot ", real_c($rop), "\n";
  print "not ok 13\n";
}

$sz = imag_c($rop);

if($sz == 0) {print "ok 14\n"}
else {
  warn "\nExpected 0\nGot ", imag_c($rop), "\n";
  print "not ok 14\n";
}

##############################
##############################

sub approx {
    if(($_[0] > ($_[1] - $_[2])) && ($_[0] < ($_[1] + $_[2]))) {return 1}
    return 0;
}

