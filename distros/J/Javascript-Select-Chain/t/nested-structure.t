# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Javascript-Select-Chain.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw/no_plan/;

use Javascript::Select::Chain::Nested qw/selectchain/;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use lib '.';

use_ok('Car2');

use Data::Dumper;

selectchain(  Car2->model , { js => 'sample-nested.js' });
