# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Devel::ModInfo;
$loaded = 1;
print "ok 1\n";
print "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

test_convert() ? print "ok 2\n" : print "not ok 2\n";


sub test_convert {
	system('perl modinfo2xml -i ex/MyModule.commented -o ex/MyModule.mfo.test');
	open(COMP, "ex/MyModule.mfo") or die "Missing kit component.  Couldn't located comparison file ex/MyModule.mfo";
	open(TEST, "ex/MyModule.mfo.test") or return 0;
	while(my $comp = <COMP>) {
		my $test = <TEST>;
		if ($comp ne $test) {
			warn "Compare file line mismatch:\nCompare: $comp\nTest: $test\n";
			return 0;
		}
	}
	return 1;
}
