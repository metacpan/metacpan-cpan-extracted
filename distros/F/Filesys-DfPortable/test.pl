# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
require 5.006;
use Config qw(%Config);
use Filesys::DfPortable;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $dir;
($Config{osname} =~ /^MSWin/i)  and
	$dir = "C:\\" or
	$dir = "/";

my $ref = Filesys::DfPortable::dfportable($dir);

defined($ref) and
	print"ok 2\n" or
	die "not ok 2\ndfportable\(\) call failed for \"$dir\" $!\n";

print"Results for directory: \"$dir\" in bytes:\n";
print "Total: $ref->{blocks}\n";
print "Free: $ref->{bfree}\n";
print "Available: $ref->{bavail}\n";
print "Used: $ref->{bused}\n";
print "Percent Full: $ref->{per}\n";


print"All tests successful!\n\n";

