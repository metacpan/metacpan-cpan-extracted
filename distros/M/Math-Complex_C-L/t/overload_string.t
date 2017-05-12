use strict;
use warnings;
use Math::Complex_C::L qw(:all);

print "1..6\n";

my $c1 = MCL(2.1,-5.1);

if(sprintf("%s", $c1) eq Math::Complex_C::L::_overload_string($c1, 0, 0)) {print "ok 1\n"}
else {
  warn "\n$c1 ne ", Math::Complex_C::L::_overload_string($c1, 0, 0), "\n";
  print "not ok 1\n";
}

my $ret = l_to_str($c1);
my $check = sprintf("%s", $c1);

# Remove trailing zeroes from $ret and $check.

$ret =~ s/0+e/e/gi;
$check =~ s/0+e/e/gi;

if("($ret)" eq $check) {print "ok 2\n"}
else {
  warn "\n($ret) ne $check\n";
  print "not ok 2\n";
}

my $str1 = l_to_str(MCL());
my $str2 = l_to_strp(MCL(), 2 + l_get_prec());

if($str1 eq $str2 && $str1 eq 'nan nan') {print "ok 3\n"}
else {
  warn "\nExpected 'nan nan'\nGot '$str1' and '$str2'\n";
  print "not ok 3\n";
}

my $cinf = (MCL(1, 1) / MCL(0, 0));

$str1 = l_to_str($cinf);
$str2 = l_to_strp($cinf, 2 + l_get_prec());

my $div_zero_bug = 0;

if($str1 eq $str2 && $str1 eq 'inf inf') {print "ok 4\n"}
elsif($str1 eq 'nan nan' && $str2 eq $str1) {
  warn "\n  You have a buggy libc that's assigning 'nan' instead of 'inf'\n",
         "  for division by zero - not registering a fail for this as the\n",
         "  module is behaving correctly. The problem is your libc.\n",
         "  Test 5 should also experience the same bug.\n";
  $div_zero_bug = 1;
  print "ok 4\n";
}
else {
  warn "\nExpected 'inf inf'\nGot '$str1' and '$str2'\n";
  print "not ok 4\n";
}

$cinf *= MCL(-1, 0);

$str1 = l_to_str($cinf);
$str2 = l_to_strp($cinf, 2 + l_get_prec());

if($str1 eq $str2 && $str1 eq '-inf -inf') {print "ok 5\n"}
elsif($str1 eq 'nan nan' && $str2 eq $str1 && $div_zero_bug) {
  warn "\n  Same division by zero bug at work here - again not registering\n",
         "  a fail\n";
  print "ok 5\n";
}
else {
  warn "\nExpected '-inf -inf'\nGot '$str1' and '$str2'\n";
  print "not ok 5\n";
}

$check = MCL('-3.1', '119e-4');
$str1 = l_to_str($check);
my $check2 = str_to_l($str1);
if($check == $check2) {print "ok 6\n"}
else {
  warn "\n$check != $check2\n";
  print "not ok 6\n";
}
