# 'test.pl' for MPE::CIvar

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

######################### We start with some black magic to print on failure.


BEGIN { $| = 1; print "1..17\n"; }
END {print "not ok 1\n" unless $loaded; }
use MPE::CIvar ':all';

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $i;
my $j;
my $errs;
my $total_errs=0;
my $passed=1;
my $failed=0;
my $testnum;
my $jcwname;
my $varname;
my $testval;

sub tally {
  my ($testnum, $errs) = @_;
  if ($errs) {
    $total_errs += $errs;
    ++$failed;
    print "Not ok $testnum\n";
  } else {
    print "ok $testnum\n";
    ++$passed;
  }
}

# Test 2 - setjcw/getjcw small values
$errs = 0;
$testnum = 2;
for ($i=0; $i<10; $i++) {
  setjcw($i);
  $j = MPE::CIvar::getjcw();
  if ($i != $j) {
    print STDERR "Mismatch setjcw($i) => getjcw() = $j\n";
    $errs++;
  }
}
tally($testnum, $errs);

# Test 3 - setjcw/getjcw large values
$errs = 0;
$testnum = 3;

for ($i=32760; $i<32780; $i++) {
  setjcw($i);
  # $j = MPE::CIvar::getjcw();
  $j = &getjcw;
  if ($i != $j) {
    print STDERR "Mismatch setjcw($i) => getjcw() = $j\n";
    $errs++;
  }
}
tally($testnum, $errs);

# Test 4 - putjcw/findjcw small values
$jcwname = "TESTJCW";
$errs = 0;
$testnum = 4;
for ($i=0; $i<10; $i++) {
  putjcw($jcwname, $i);
  $j = findjcw($jcwname);
  if ($i != $j) {
    print STDERR "Mismatch putjcw($jcwname, $i) => findjcw($jcwname) = $j\n";
    $errs++;
  }
}
tally($testnum, $errs);

# Test 5 - putjcw/findjcw large values
$jcwname = "TESTJCW";
$errs = 0;
$testnum = 5;

for ($i=32760; $i<32780; $i++) {
  putjcw($jcwname, $i);
  $j = findjcw($jcwname);
  if ($i != $j) {
    print STDERR "Mismatch putjcw($jcwname, $i) => findjcw($jcwname) = $j\n";
    $errs++;
  }
}
tally($testnum, $errs);

# Test 6 - findjcw bad names
$jcwname = "shouldnotbedefined";
$errs = 0;
$testnum = 6;
if (defined findjcw($jcwname)) {
    print STDERR "Failed: findjcw($jcwname) defined\n";
    $errs++;
}
tally($testnum, $errs);

# Test 7 - callci setjcw
$jcwname = "TESTJCW2";
$errs = 0;
$testnum = 7;
$testval = 432;
hpcicommand("setjcw $jcwname $testval")==0 or
                    print STDERR "Warning: system call returned error: $?\n";
$j = findjcw($jcwname);
if ($j != $testval) {
    print STDERR "Failed: findjcw($jcwname)=$j    should = $testval\n";
    print STDERR "   => value not defined\n" if not defined($j);
    $errs++;
}
tally($testnum, $errs);


# Test 8 - callci setvar integer
$varname = "TESTVAR1";
$errs = 0;
$testnum = 8;
$testval = 438;
hpcicommand("setvar $varname $testval")==0 or
                    print STDERR "Warning: system call returned error: $?\n";
$j = hpcigetvar($varname);
if ($j != $testval) {
    print STDERR "Failed: hpcigetvar($varname)=$j    should = $testval\n";
    print STDERR "   => value not defined\n" if not defined($j);
    $errs++;
}
tally($testnum, $errs);


# Test 9 - callci setvar string
$testnum = 9;
$errs = 0;
$varname = "TESTVAR2";
$testval = "howdy";
hpcicommand("setvar $varname '$testval'")==0 or
                    print STDERR "Warning: system call returned error: $?\n";
$j = hpcigetvar($varname);
if ($j ne $testval) {
    print STDERR "Failed: hpcigetvar($varname)=$j    should = $testval\n";
    print STDERR "   => value not defined\n" if not defined($j);
    $errs++;
}
tally($testnum, $errs);


# Test 10 - callci setvar boolean
$testnum = 10;
$errs = 0;
$varname = "TESTVAR3";
$testval = "TRUE";
hpcicommand("setvar $varname $testval")==0 or
                    print STDERR "Warning: system call returned error: $?\n";
$j = hpcigetvar($varname);
if (not defined($j)) {
    print "   => value not defined\n" if not defined($j);
    $errs++;
} elsif (not $j) {
    print "  value should be true; instead = $j\n";
    $errs++;
}
$testval = "FALSE";
hpcicommand("setvar $varname $testval")==0 or
                    print "Warning: system call returned error: $?\n";
$j = hpcigetvar($varname);
if (not defined($j)) {
    print STDERR "   => value not defined\n" if not defined($j);
    $errs++;
} elsif ($j) {
    print STDERR "  value should be false; instead = $j\n";
    $errs++;
}
tally($testnum, $errs);


# Test 11 - hpciputvar/hpcigetvar int test
$testnum = 11;
$errs = 0;
$varname = "TESTVAR4";
for $testval (qw/-3 -2 -1 0 1 2 3 32000 -32000 330000 34234235 -32768/) {
  hpciputvar($varname, $testval);
  $j = hpcigetvar($varname);
  if ($j != $testval) {
      print STDERR "Failed: hpcigetvar($varname)=$j    should = $testval\n";
      print STDERR "   => value not defined\n" if not defined($j);
      $errs++;
  }
}
tally($testnum, $errs);


# Test 12 - hpciputvar/hpcigetvar int test
$testnum = 12;
$errs = 0;
$varname = "TESTVAR4";
for $testval (qw/-3 -2 -1 0 1 2 3 32000 -32000 330000 34234235 -32768/) {
  hpciputvar($varname, $testval);
  $j = hpcigetvar($varname);
  if ($j != $testval) {
      print STDERR "Failed: hpcigetvar($varname)=$j    should = $testval\n";
      print STDERR "   => value not defined\n" if not defined($j);
      $errs++;
  }
}
tally($testnum, $errs);


# Test 13 - hpciputvar/hpcigetvar string test
$testnum = 13;
$errs = 0;
$varname = "TESTVAR4";
for $testval (qw/asdfasdfasdfasdfasf SDF(dfasdf j99 99+9)/, "now is") {
  hpciputvar($varname, $testval);
  $j = hpcigetvar($varname);
  if ($j ne $testval) {
      print STDERR "Failed: hpcigetvar($varname)=$j    should = $testval\n";
      print STDERR "   => value not defined\n" if not defined($j);
      $errs++;
  }
}
tally($testnum, $errs);


# Test 14 - hpciputvar/hpcigetvar boolean test
$testnum = 14;
$errs = 0;
$varname = "TESTVAR4";
$testval = "TRUE";
hpciputvar($varname, $testval);
$j = hpcigetvar($varname);
if (not defined($j)) {
    print STDERR "   => value not defined\n" if not defined($j);
    $errs++;
} elsif (not $j) {
    print STDERR "  value should be true; instead = $j\n";
    $errs++;
}
$testval = "FALSE";
hpciputvar($varname, $testval);
$j = hpcigetvar($varname);
if (not defined($j)) {
    print STDERR "   => value not defined\n" if not defined($j);
    $errs++;
} elsif ($j) {
    print STDERR "  value should be false; instead = $j\n";
    $errs++;
}
tally($testnum, $errs);


# Test 15 - hpcideletevar test;
$testnum = 15;
$errs = 0;
$varname = "TESTVAR4";
$testval = "TRUE";
hpciputvar($varname, $testval);
$j = hpcigetvar($varname);
if (not defined($j)) {
    print STDERR "   => value not defined\n" if not defined($j);
    $errs++;
} elsif (not $j) {
    print STDERR "  value should be true; instead = $j\n";
    $errs++;
}
hpcideletevar($varname);
if (defined hpcigetvar($varname)) {
    print STDERR "Failed: hpcigetvar($varname) defined\n";
    $errs++;
}
tally($testnum, $errs);

# Test 16 -  %CIvar test A
$testnum = 16;
$errs = 0;
my $varname1 = "TESTVAR1";
my $varname2 = "TESTVAR2";
for $testval (qw/asdfasdfasdfasdfasf 123 SDF(dfasdf j99 99+9)/, "now is") {
  hpciputvar($varname1, $testval);
  $CIVAR{$varname2} = $testval;
  $j = hpcigetvar($varname2);
  if ($j ne $testval) {
      print STDERR "Failed: hpcigetvar($varname2)=$j    should = $testval\n";
      print STDERR "   => value not defined\n" if not defined($j);
      $errs++;
  }
  $j = $CIVAR{$varname1};
  if ($j ne $testval) {
      print STDERR "Failed: \$CIVAR{$varname1}=$j    should = $testval\n";
      print STDERR "   => value not defined\n" if not defined($j);
      $errs++;
  }
  $j = $CIVAR{$varname2};
  if ($j ne $testval) {
      print STDERR "Failed: \$CIVAR{$varname2}=$j    should = $testval\n";
      print STDERR "   => value not defined\n" if not defined($j);
      $errs++;
  }
}
tally($testnum, $errs);


# Test 17 -  %CIvar test B
$testnum = 17;
$errs = 0;
hpcideletevar($varname1);
delete $CIVAR{$varname2};
if (defined hpcigetvar($varname1)) {
    print STDERR "Failed: hpcigetvar($varname1) defined\n";
    $errs++;
}
if (defined hpcigetvar($varname2)) {
    print STDERR "Failed: hpcigetvar($varname2) defined\n";
    $errs++;
}
if (defined $CIVAR{$varname1}) {
    print STDERR "Failed: \$CIVAR{$varname1} defined\n";
    $errs++;
}
if (defined $CIVAR{$varname2}) {
    print STDERR "Failed: \$CIVAR{$varname2} defined\n";
    $errs++;
}
tally($testnum, $errs);



print "\n\n========================\n";
print "Tests passed: $passed\n";
print "Tests failed: $failed\n";

die "Some tests failed" if $failed;
