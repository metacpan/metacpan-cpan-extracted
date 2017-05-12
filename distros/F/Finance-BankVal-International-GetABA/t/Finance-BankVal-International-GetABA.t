# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-BankVal-International-GetABA.t'

#########################

use Finance::BankVal::International::GetABA qw(&getABA);

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 20;
BEGIN { use_ok('Finance::BankVal::International::GetABA') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

like ( getABA ('x-ml','011001276','abcd123','12345'),'/INVALID - Result Format/','2 response format validation');
like ( getABA('xml','011001276','abcd123','12345'),'/xml/','3 response format validation');
like ( getABA('xml','f11001276','abcd123','12345'),'/INVALID/','4 ABA format validation');
like ( getABA('xml','01100127f','abcd123','12345'),'/INVALID/','5 ABA format validation');
like ( getABA('csv','0110f1276','abcd123','12345'),'/INVALID/','6 ABA format validation');
like ( getABA('csv','+011001276','abcd123','12345'),'/INVALID/','7 ABA format validation');
like ( getABA('xml','01100126','abcd123','12345'),'/INVALID/','8 ABA format validation');
like ( getABA('csv','011001276','cd123','12345'),'/ERROR -.*User ID/','9 User Id format validation');
like ( getABA('csv','011001276','abcd1234','12345'),'/ERROR -.*User ID/','10 User Id format validation');
like ( getABA('csv','011001276','abcd34','12345'),'/ERROR -.*User ID/','11 User Id format validation');
like ( getABA('csv','011001276','abcd123','2345'),'/ERROR -.*PIN/','12 PIN format validation');
like ( getABA('csv','011001276','abcd123','012345'),'/ERROR -.*PIN/','13 PIN format validation');
like ( getABA('csv','011001276','abcd123','a2345'),'/ERROR -.*PIN/','14 PIN format validation');
like ( getABA('xml','011001276','abcd123','12345'),'/xml/','15 valid response type');
like ( getABA('json','911001276','abcd123','12345'),'/result":"ERROR -/','16 valid response type');
like ( getABA('csv','011001276','abcd123','12345'),'/^ERROR - Invalid User ID/PIN$/','17 valid response type');
like ( getABA('csv','011001276'),'/unifiedsoftware/','18 config lookup fail - this test will fail if the config file is present with valid details in it, this is ok');
like ( getABA('xml','011001276'),'/unifiedsoftware/','19 config lookup fail - this test will fail if the config file is present with valid details in it, this is ok');
like ( getABA('json','011001276'),'/unifiedsoftware/','20 config lookup fail - this test will fail if the config file is present with valid details in it, this is ok');

done_testing();