# @(#)test.pl	1.1    03/07/09
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use MVS::JESFTP;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


# modify these variables for your installation; also modify TEST.SEQ
# as needed.

my($host, $logonid, $password, $job, $jobname) =
    ('nmgsdisd.state.nm.us', 'DPMIKE', 'JTREE', './TEST.SEQ', 'DPMIKE1');

$jes = MVS::JESFTP->open($host, $logonid, $password) or die "not ok 2\n";
print "ok 2\n";

$jes->submit($job)                                   or die "not ok 3\n";
print "ok 3\n";

$aref = $jes->wait_for_results($jobname)             or die "not ok 4\n";
print "ok 4\n";

$fails = $jes->get_results($aref)                    and die "not ok 5\n";
print "ok 5\n";

$fails = $jes->delete_results($aref)                 and die "not ok 6\n";
print "ok 6\n";

$jes->quit                                           or die "not ok 7\n";
print "ok 7\n";
