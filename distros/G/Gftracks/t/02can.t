# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Gftracks.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;

use Gftracks qw /sec/;
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok("Gftracks","sec");
can_ok("Gftracks","init");
can_ok("Gftracks","instime");
can_ok("Gftracks","deltrack");
can_ok("Gftracks","printtracks");