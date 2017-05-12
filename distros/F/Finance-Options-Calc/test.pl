# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Finance::Options::Calc;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

print (b_s_call(90,80,20,30,4.5) eq "10.30083" ? "ok 2\n" : "not ok 2\n");
print (b_s_put(90,80,20,30,4.5) eq "0.10382" ? "ok 3\n" : "not ok 3\n");
print (call_delta(90,80,20,30,4.5) eq "0.95994" ? "ok 4\n" : "not ok 4\n");
print (put_delta(90,80,20,30,4.5) eq "-0.04006" ? "ok 5\n" : "not ok 5\n");
print (call_theta(90,80,20,30,4.5) eq "-0.02307"? "ok 6\n" : "not ok 6\n");
print (put_theta(90,80,20,30,4.5) eq "-0.01324"? "ok 7\n" : "not ok 7\n");
print (call_rho(90,80,20,30,4.5) eq "0.04170"? "ok 8\n" : "not ok 8\n");
print (put_rho(90,80,20,30,4.5) eq "-0.00203"? "ok 9\n" : "not ok 9\n");
print (gamma(90,80,20,30,4.5) eq "0.01371"? "ok 10\n" : "not ok 10\n");
print (vega(90,80,20,30,4.5) eq "0.01826"? "ok 11\n" : "not ok 11\n");


