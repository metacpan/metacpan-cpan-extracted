use Math::MPFI qw(:mpfi);
use Math::MPFR qw(:mpfr);
use warnings;
use strict;

print "1..5\n";

my $set;

Rmpfi_reset_error();

unless (Rmpfi_is_error()) {print "ok 1\n"}
else {
  warn "1: Error number is set\n";
  print "not ok 1\n";
}

Rmpfi_set_error(1);

if (Rmpfi_is_error()) {
  $set = 1;
  print "ok 2\n";
}
else {
  warn "2: Error is not set\n";
  $set = 0;
  print "not ok 2\n";
}

if($set) {
  Rmpfi_reset_error();
  unless (Rmpfi_is_error()) {print "ok 3\n"}
  else {
    warn "3: Error number is set\n";
    print "not ok 3\n";
  }
}
else {
  warn "Skipping test 3 - error was not set at test 2\n";
  print "ok 3\n";
}

RMPFI_ERROR("This is an expected test message ... please ignore\n");

if (Rmpfi_is_error()) {
  $set = 1;
  print "ok 4\n";
}
else {
  warn "4: Error is not set\n";
  $set = 0;
  print "not ok 4\n";
}

if($set) {
  Rmpfi_reset_error();
  unless (Rmpfi_is_error()) {print "ok 5\n"}
  else {
    warn "5: Error number is set\n";
    print "not ok 5\n";
  }
}
else {
  warn "Skipping test 5 - error was not set at test 4\n";
  print "ok 5\n";
}
