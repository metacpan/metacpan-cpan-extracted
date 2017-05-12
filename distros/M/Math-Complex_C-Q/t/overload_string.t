use strict;
use warnings;
use Math::Complex_C::Q qw(:all);

print "1..7\n";

my $c1 = MCQ(2.1,-5.1);

if(sprintf("%s", $c1) eq Math::Complex_C::Q::_overload_string($c1, 0, 0)) {print "ok 1\n"}
else {
  warn "\n$c1 ne ", Math::Complex_C::Q::_overload_string($c1, 0, 0), "\n";
  print "not ok 1\n";
}

my $ret = q_to_str($c1);
my $check = sprintf("%s", $c1);

# Remove trailing zeroes from $ret and $check.

$ret =~ s/0+e/e/gi;
$check =~ s/0+e/e/gi;

if("($ret)" eq $check) {print "ok 2\n"}
else {
  warn "\n($ret) ne $check\n";
  print "not ok 2\n";
}

my $str1 = q_to_str(MCQ());
my $str2 = q_to_strp(MCQ(), 2 + q_get_prec());

if($str1 eq $str2 && $str1 eq 'nan nan') {print "ok 3\n"}
else {
  warn "\nExpected 'nan nan'\nGot '$str1' and '$str2'\n";
  print "not ok 3\n";
}

my $cinf = (MCQ(1, 1) / MCQ(0, 0));

$str1 = q_to_str($cinf);
$str2 = q_to_strp($cinf, 2 + q_get_prec());

if($str1 eq $str2 && $str1 eq 'inf inf') {print "ok 4\n"}
else {
  warn "\nExpected 'inf inf'\nGot '$str1' and '$str2'\n";
  print "not ok 4\n";
}

$cinf *= MCQ(-1, 0);

$str1 = q_to_str($cinf);
$str2 = q_to_strp($cinf, 2 + q_get_prec());

if($str1 eq $str2 && $str1 eq '-inf -inf') {print "ok 5\n"}
else {
  warn "\nExpected '-inf -inf'\nGot '$str1' and '$str2'\n";
  print "not ok 5\n";
}

$check = MCQ('-3.1', '119e-4');
$str1 = q_to_str($check);
my $check2 = str_to_q($str1);
if($check == $check2) {print "ok 6\n"}
else {
  warn "\n$check != $check2\n";
  print "not ok 6\n";
}

my $ap_tester = MCQ('2.13', '2.12');

my $ap_str = q_to_str($ap_tester);

if($ap_str =~ /2\.1/) {print "ok 7\n"}
else {
  warn "\nExpected something that matches /2.1/\nGot $ap_str\n";
  print "not ok 7\n";
}
