
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use IPC::Session;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.


# open local sh session
my $session = new IPC::Session("/bin/sh",5);
print "ok 2\n" if $session;

eval { $session->send("sleep 3") };
print "ok 3\n" unless $@;
eval { $session->send("sleep 10") };
print "ok 4\n" if $@;

