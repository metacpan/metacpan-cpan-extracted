# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl FTDI-D2XX.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('FTDI::D2XX') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
require_ok('FTDI::D2XX');
$text="";
ok(FTDI::D2XX::FT_CreateDeviceInfoList($text) == FT_OK,"Dyna. lib loaded");
