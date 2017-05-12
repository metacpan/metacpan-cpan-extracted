# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Data::Dumper;

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
	system('perl pl2modinfo -c -i ex/MyModule.pm -o ex/MyModule.test');
	open(COMP, "ex/MyModule.commented") or die "Missing kit component.  Couldn't located comparison file ex/MyModule.commented";
	open(TEST, "ex/MyModule.commented") or return 0;
	while(my $comp = <COMP>) {
		my $test = <TEST>;
		$comp eq $test || return 0;
	}
	return 1;
}
