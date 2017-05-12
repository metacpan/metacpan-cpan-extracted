# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use MPE::Suprtool;
$loaded = 1;
print "ok 1\n";


######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# Unfortunately, you need to be in an MPE group for the
# suprtool2 call to work (as of SUPRTOOL 4.3)
# Hopefully Robelle will fix this in a later version
#
chdir("/$ENV{HPACCOUNT}/PUB") or die "Cannot chdir: $!\n";

my $supr = MPE::Suprtool->new(printstate =>'ER');

if (defined $supr) {
  print "ok 2\n";
} else {
  print "not ok 2\n";
  exit 1;
}

@cmd1 = (
 "PURGE SUCHECK1",
 "BUILD SUCHECK1;REC=-80,,F,ASCII",
 "EXIT"
);

$supr->cmd(@cmd1) or die "not ok 3\n";
print "ok 3\n";

open SUCHECK1, ">SUCHECK1" or die "Error opening SUCHECK1: $!\n";
my $i;
for ($i=1; $i <=100; $i++) {
  printf SUCHECK1 "%c   %06d\n", 65+($i % 5), $i
    or die "Error writing SUCHECK1: $!\n";
}
close SUCHECK1;

$supr->cmd(
 "in sucheck1",
 "def a,1,4; def b,5,6,display",
 "ext a, b",
 "total b",
 "out sucheck2,link",
 "purge sucheck2",
 "exit") or die "not ok 4\n";

print "ok 4\n";

if ($supr->count == 100) {
  print "ok 5\n";
} else {
  print "not ok 5\n";
  print STDERR "count is ", $supr->count, " should be 100\n";
}

my @tot = $supr->totals();


if ($#tot == 0 && $tot[0] == 5050) {
  print "ok 6\n";
} else {
  print "not ok 6\n";
  print STDERR "totals are ", join(', ', @tot), " should be 5050\n";
}

$supr->cmd(
 "in sucheck2",
 "sor a",
 "ext a",
 "dup n k count",
 "purge sucheck3",
 "out sucheck3,link",
 "exit") or die "not ok 7\n";

print "ok 7\n";

if ($supr->count == 5) {
  print "ok 8\n";
} else {
  print "not ok 8\n";
  print STDERR "count is ", $supr->count, " should be 5\n";
}

$supr->cmd(
 "in sucheck3",
 "list sta",
 "xeq",
 "in sucheck3",
 "total st-count",
 "out \$NULL",
 "exit") or die "not ok 9\n";

print "ok 9\n";

if ($supr->count == 5) {
  print "ok 10\n";
} else {
  print "not ok 10\n";
  print STDERR "count is ", $supr->count, " should be 5\n";
}

@tot = $supr->totals();


if ($#tot == 0 && $tot[0] == 100) {
  print "ok 11\n";
} else {
  print "not ok 11\n";
  print STDERR "totals are ", join(', ', @tot), " should be 100\n";
}

