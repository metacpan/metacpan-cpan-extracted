#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Maplat::Array::Unique') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @testarray = qw[one two one three];

unique(\@testarray);

if($testarray[0] ne 'one') {
    fail("Element 0 not 'one'");
} elsif($testarray[1] ne 'three') {
    fail("Element 1 not 'three'");
} elsif($testarray[2] ne 'two') {
    fail("Element 2 not 'two'");
} elsif(defined($testarray[3])) {
    fail("Returned more than 3 elements");
} else {
    pass("unique() works");
}
