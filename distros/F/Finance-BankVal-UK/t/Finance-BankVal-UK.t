# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-BankVal-UK.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Finance::BankVal::UK qw(&bankValUK);
use Test::More tests => 7;
BEGIN { use_ok('Finance::BankVal::UK') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

like( bankValUK('j-son','09-01-26','12345678','abcd123','12345'),'/INVALID -.*Result Format/','format validation');
like( bankValUK('json','09012','12345678','abcd123','12345'),'/INVALID - Sortcode/','sort code validation');
like( bankValUK('json','090126','12345','abcd123','12345'),'/INVALID - Account/','account validation');
like( bankValUK('json','090126','12345678','abcd','12345'),'/ERROR - Invalid User/','user id validation');
like( bankValUK('json','090126','12345678','abcd123','1234'),'/ERROR - Invalid User/','PIN validation');
like( bankValUK('json','090126','12345678','abcd123','12345'),'/ERROR - Invalid User/','PIN validation');
done_testing();