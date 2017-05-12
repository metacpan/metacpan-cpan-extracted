# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1--MARC::Errochecks not loaded\n" unless $loaded;}
use MARC::Errorchecks;
$loaded = 1;
print "ok 1--MARC::Errorchecks loaded\n";

######################### End of black magic.

print "Please run: t/008errorchecks.t.pl, t/check_010.t, and t/Errorchecks.t\n";

#print "Press Enter to quit";
#<>;