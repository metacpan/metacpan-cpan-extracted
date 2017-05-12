# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Mail::MXplus') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok (mxplus("mxplus.org", "64.71.139.107") eq "pass");
ok (mxplus("mxplus.org", "10.1.2.3") eq "fail");
