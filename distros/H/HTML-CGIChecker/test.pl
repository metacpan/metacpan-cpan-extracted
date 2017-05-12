
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..last_test_to_print\n"; }
END { print "not ok 1\n" unless $loaded; }

##############################################################################

chdir "test";

opendir(DIR, ".");
@tests = sort(grep (/\.pl$/, readdir(DIR)));
closedir DIR;

$i = 2;
foreach $test (@tests) {
    print "$i..";
    if (system("perl", $test) != 0) {
        print " $i\n";
        exit 1;
    }
    print " $i\n";
    $i++;
}

##############################################################################

$loaded = 1;
print "ok 1\n";
