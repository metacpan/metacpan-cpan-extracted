######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use Geo::Coordinates::UTM;
my ($zone,$east,$north);
$loaded = 1;
print "ok 1\n";

if (($zone,$east,$north)=latlon_to_utm(5,57.833055556,-2.788951667)) {
    $loaded = 1;
    print "ok 2\n";
} else {
    $loaded = 0;
    print "not ok 2\n";
}

if (my($x,$y)=utm_to_latlon(5,$zone,$east,$north)) {
    $loaded = 1;
    print "ok 3\n";
} else {
    $loaded = 0;
    print "not ok 3\n";
}

