use strict;
use warnings;
use Math::MPC qw(:mpc);

print "1..30\n";

*p = \&Math::MPC::overload_string;

my @x;

$x[0] = 0;

################################
################################

$x[1] = 6;

$x[1] **= Math::MPC->new(3);

if(p($x[1]) eq '(2.16e2 0)') {print "ok 1\n"}
else {
  warn "\nExpected (2.16e2 0), got $x[1]\n";
  print "not ok 1\n";
}

$x[2] = 6 ** Math::MPC->new(3);

if(p($x[2]) eq '(2.16e2 0)') {print "ok 2\n"}
else {
  warn "\nExpected (2.16e2 0), got $x[2]\n";
  print "not ok 2\n";
}

$x[3] = 6.0;

$x[3] **= Math::MPC->new(3);

if(p($x[3]) eq '(2.16e2 0)') {print "ok 3\n"}
else {
  warn "\nExpected (2.16e2 0), got $x[3]\n";
  print "not ok 3\n";
}

$x[4] = 6.0 ** Math::MPC->new(3);

if(p($x[4]) eq '(2.16e2 0)') {print "ok 4\n"}
else {
  warn "\nExpected (2.16e2 0), got $x[4]\n";
  print "not ok 4\n";
}

$x[5] = '6.0';

$x[5] **= Math::MPC->new(3);

if(p($x[5]) eq '(2.16e2 0)') {print "ok 5\n"}
else {
  warn "\nExpected (2.16e2 0), got $x[5]\n";
  print "not ok 5\n";
}

$x[6] = '6.0' ** Math::MPC->new(3);

if(p($x[6]) eq '(2.16e2 0)') {print "ok 6\n"}
else {
  warn "\nExpected (2.16e2 0), got $x[6]\n";
  print "not ok 6\n";
}

####################################
####################################

$x[7] = 6;

$x[7] += Math::MPC->new(3);

if(p($x[7]) eq '(9 0)') {print "ok 7\n"}
else {
  warn "\nExpected (9 0), got $x[7]\n";
  print "not ok 7\n";
}

$x[8] = 6 + Math::MPC->new(3);

if(p($x[8]) eq '(9 0)') {print "ok 8\n"}
else {
  warn "\nExpected (9 0), got $x[8]\n";
  print "not ok 8\n";
}

$x[9] = 6.0;

$x[9] += Math::MPC->new(3);

if(p($x[9]) eq '(9 0)') {print "ok 9\n"}
else {
  warn "\nExpected (9 0), got $x[9]\n";
  print "not ok 9\n";
}

$x[10] = 6.0 + Math::MPC->new(3);

if(p($x[10]) eq '(9 0)') {print "ok 10\n"}
else {
  warn "\nExpected (9 0), got $x[10]\n";
  print "not ok 10\n";
}

$x[11] = '6.0';

$x[11] += Math::MPC->new(3);

if(p($x[11]) eq '(9 0)') {print "ok 11\n"}
else {
  warn "\nExpected (9 0), got $x[11]\n";
  print "not ok 11\n";
}

$x[12] = '6.0' + Math::MPC->new(3);

if(p($x[12]) eq '(9 0)') {print "ok 12\n"}
else {
  warn "\nExpected (9 0), got $x[12]\n";
  print "not ok 12\n";
}

####################################
####################################

$x[13] = 6;

$x[13] -= Math::MPC->new(3, 1);

if(p($x[13]) eq '(3 -1)') {print "ok 13\n"}
else {
  warn "\nExpected (3 -1), got $x[13]\n";
  print "not ok 13\n";
}

$x[14] = 6 - Math::MPC->new(3, 1);

if(p($x[14]) eq '(3 -1)') {print "ok 14\n"}
else {
  warn "\nExpected (3 -1), got $x[14]\n";
  print "not ok 14\n";
}

$x[15] = 6.0;

$x[15] -= Math::MPC->new(3, 1);

if(p($x[15]) eq '(3 -1)') {print "ok 15\n"}
else {
  warn "\nExpected (3 -1), got $x[15]\n";
  print "not ok 15\n";
}

$x[16] = 6.0 - Math::MPC->new(3, 1);

if(p($x[16]) eq '(3 -1)') {print "ok 16\n"}
else {
  warn "\nExpected (3 -1), got $x[16]\n";
  print "not ok 16\n";
}

$x[17] = '6.0';

$x[17] -= Math::MPC->new(3, 1);

if(p($x[17]) eq '(3 -1)') {print "ok 17\n"}
else {
  warn "\nExpected (3 -1), got $x[17]\n";
  print "not ok 17\n";
}

$x[18] = '6.0' - Math::MPC->new(3, 1);

if(p($x[18]) eq '(3 -1)') {print "ok 18\n"}
else {
  warn "\nExpected (3 -1), got $x[18]\n";
  print "not ok 18\n";
}

####################################
####################################

$x[19] = 6;

$x[19] /= Math::MPC->new(3);

if(p($x[19]) eq '(2 0)') {print "ok 19\n"}
else {
  warn "\nExpected (2 0), got $x[19]\n";
  print "not ok 19\n";
}

$x[20] = 6 / Math::MPC->new(3);

if(p($x[20]) eq '(2 0)') {print "ok 20\n"}
else {
  warn "\nExpected (2 0), got $x[20]\n";
  print "not ok 20\n";
}

$x[21] = 6.0;

$x[21] /= Math::MPC->new(3);

if(p($x[21]) eq '(2 0)') {print "ok 21\n"}
else {
  warn "\nExpected (2 0), got $x[21]\n";
  print "not ok 21\n";
}

$x[22] = 6.0 / Math::MPC->new(3);

if(p($x[22]) eq '(2 0)') {print "ok 22\n"}
else {
  warn "\nExpected (2 0), got $x[22]\n";
  print "not ok 22\n";
}

$x[23] = '6.0';

$x[23] /= Math::MPC->new(3);

if(p($x[23]) eq '(2 0)') {print "ok 23\n"}
else {
  warn "\nExpected (2 0), got $x[23]\n";
  print "not ok 23\n";
}

$x[24] = '6.0' / Math::MPC->new(3);

if(p($x[24]) eq '(2 0)') {print "ok 24\n"}
else {
  warn "\nExpected (2 0), got $x[24]\n";
  print "not ok 24\n";
}

####################################
####################################

$x[25] = 6;

$x[25] *= Math::MPC->new(3);

if(p($x[25]) eq '(1.8e1 0)') {print "ok 25\n"}
else {
  warn "\nExpected (1.8e1 0), got $x[25]\n";
  print "not ok 25\n";
}

$x[26] = 6 * Math::MPC->new(3);

if(p($x[26]) eq '(1.8e1 0)') {print "ok 26\n"}
else {
  warn "\nExpected (1.8e1 0), got $x[26]\n";
  print "not ok 26\n";
}

$x[27] = 6.0;

$x[27] *= Math::MPC->new(3);

if(p($x[27]) eq '(1.8e1 0)') {print "ok 27\n"}
else {
  warn "\nExpected (1.8e1 0), got $x[27]\n";
  print "not ok 27\n";
}

$x[28] = 6.0 * Math::MPC->new(3);

if(p($x[28]) eq '(1.8e1 0)') {print "ok 28\n"}
else {
  warn "\nExpected (1.8e1 0), got $x[28]\n";
  print "not ok 28\n";
}

$x[29] = '6.0';

$x[29] *= Math::MPC->new(3);

if(p($x[29]) eq '(1.8e1 0)') {print "ok 29\n"}
else {
  warn "\nExpected (1.8e1 0), got $x[29]\n";
  print "not ok 29\n";
}

$x[30] = '6.0' * Math::MPC->new(3);

if(p($x[30]) eq '(1.8e1 0)') {print "ok 30\n"}
else {
  warn "\nExpected (1.8e1 0), got $x[30]\n";
  print "not ok 30\n";
}

# These next 2 subs will cause failures here on perl-5.20.0
# and later if &PL_sv_yes or &PL_sv_no is encountered in the
# overload sub.

sub foo () {!0} # Breaks PL_sv_yes
sub bar () {!1} # Breaks PL_sv_no
