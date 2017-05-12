# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Devel::AutoProfiler;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):




sub wait_1
{
  print "wait_1\n";
  sleep 1;
}


sub wait_2
{
  print "wait_2\n";
  sleep 2;
}

sub wait_3
{
  print "wait_3\n";
  wait_2;
  wait_1;
}

sub wait_4
{
  print "wait_4\n";
  wait_3;
  wait_1;
}

sub call_waits
{
  wait_2;
  wait_3;

  wait_4;

  wait_1;
}


eval {
call_waits;
};

call_waits;


print "ok 2\n";