# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Error::Unhandled;
use Error qw(:try);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

package Error::Unhandled::Test;

@Error::Unhandled::Test::ISA = ('Error::Unhandled');

sub unhandled {
  print "ok 5\n";
  exit;
}

package main;



try {
  &foo;
  print "not ok 2\n";
} otherwise {
  my $E = shift;
  print "ok 2\n";
};

eval {&foo;};
defined $@ or print "not ok 3\n";

try {
  &bar;
  print "not ok 4\n";
} otherwise {
  my $E = shift;
  print "ok 4\n";
};

&bar;
print "not ok 5\n";




sub foo {
  throw Error::Unhandled(unhandled => sub {print "ok 3\n"});
}

sub bar {
  throw Error::Unhandled::Test;
}

