# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use FirstGoodURL;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my @URLs = qw(
  http://www.pobox.com/~japhy/does_not_exist.404
  http://www.pobox.com/~japhy/index.html
  http://search.cpan.org/images/republic.gif
);


print "not " if $URLs[1] ne FirstGoodURL->in(@URLs);
print "ok 2\n";

print "not " if $URLs[2] ne FirstGoodURL->with('image/gif')->in(@URLs);
print "ok 3\n";

print "not " if $URLs[1] ne FirstGoodURL->with(qr/html/)->in(@URLs);
print "ok 4\n";

print "not " if $URLs[0] ne FirstGoodURL->with(404)->in(@URLs);
print "ok 5\n";
