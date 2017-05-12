# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

use Graphics::Libplot ':ALL';
#use POSIX;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub deb {
    print STDERR "$_[0]\n";
}


$i = 2;

foreach 
    $test ( qw ( spiralbox ccurve rothello spiraltext movingeye ) ) {
	print "trying $test\n";
	pl_parampl ("VANISH_ON_DELETE", "no");  # reset this each time
	require "examples/$test";
        print "ok $i\n";
	$i++;
    }








