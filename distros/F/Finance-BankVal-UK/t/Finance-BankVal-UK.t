# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-BankVal-UK.t'

#########################

use Finance::BankVal::UK qw(&bankValUK);


# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Finance::BankVal::UK') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
like ( bankValUK('','BARCGB22','cd123','12345'),'/INVALID - Sortcode/','sort code validation');
done_testing();