# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Config qw(%Config);
use Filesys::Statvfs;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $dir = "/";

my($bsize, $frsize, $blocks, $bfree, $bavail,
   $files, $ffree, $favail, $flag, $namemax)  = Filesys::Statvfs::statvfs($dir);

defined($bsize) and
	print"ok 2\n" or
	die "not ok 2\nstatvfs\(\) call failed for \"$dir\" $!\n";

print"Results for statvfs on \"$dir\"\n";
print "bsize: $bsize\n";
print "frsize: $frsize\n";
print "blocks: $blocks\n";
print "bfree: $bfree\n";
print "bavail: $bavail\n";
print "files: $files\n";
print "ffree: $ffree\n";
print "favail: $favail\n";
print "flag: $flag\n";
print "namemax: $namemax\n";

open(FILE, "./test.pl") or die "$! ./test.pl\n";
($bsize, $frsize, $blocks, $bfree, $bavail,
 $files, $ffree, $favail, $flag, $namemax) = Filesys::Statvfs::fstatvfs(fileno(FILE));
close(FILE);

defined($bsize) and
	print"\nok 3\n\n" or
	die "not ok 3\nfstatvfs\(\) call failed for \"test.pl\" $!\n";

print"Results for fstatvfs:\n";
print "bsize: $bsize\n";
print "frsize: $frsize\n";
print "blocks: $blocks\n";
print "bfree: $bfree\n";
print "bavail: $bavail\n";
print "files: $files\n";
print "ffree: $ffree\n";
print "favail: $favail\n";
print "flag: $flag\n";
print "namemax: $namemax\n";


print"All tests successful!\n\n";

