# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; print "ok 1\n"; }
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}
use Devel::SawAmpersand qw(sawampersand);
use strict;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

BEGIN { print Devel::SawAmpersand::sawampersand == 0 ? "ok 2\n" : "not ok 2\n"; }

BEGIN { # emulate English.pm
        *MATCH                                  = *&    ;
        print sawampersand >= 1 ? "ok 3\n" : "not ok 3\n"; }

