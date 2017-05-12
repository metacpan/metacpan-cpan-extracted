# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use DotICD9;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $i = new DotICD9;
my $code = $i->dot( 78830, 'D' );
print $code eq '788.30' ? "ok 2" : "not ok 2",  "\n";

my $code = $i->dot( 78830, 'diag' );
print $code eq '788.30' ? "ok 3" : "not ok 3",  "\n";

my $code = $i->dot( " 0234", 'SURG' );
print $code eq '02.34' ? "ok 4" : "not ok 4",  "\n";
