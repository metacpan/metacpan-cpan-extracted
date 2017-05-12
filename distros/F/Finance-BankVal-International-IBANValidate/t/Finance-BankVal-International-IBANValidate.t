# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-BankVal-International-IBANValidate.t'

#########################

use Finance::BankVal::International::IBANValidate qw(&ibanValidate);


# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 19;
BEGIN { use_ok('Finance::BankVal::International::IBANValidate') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

like ( ibanValidate('j-son','DE99203205004989123456','abcd123','12345'),'/INVALID -.*Result Format/','2 response format validation');
like ( ibanValidate('xml','DE99203205004989123456','abcd123','12345'),'/xml/','3 response format validation');
like ( ibanValidate('xml','DE99203205004989123456**','abcd123','12345'),'/xml.*INVALID - FORMAT/','4 IBAN format validation');
like ( ibanValidate('xml','DE99203205004~~989123456B','abcd123','12345'),'/INVALID - FORMAT/','5 IBAN format validation');
like ( ibanValidate('csv','+=DE99203205004989123456','abcd123','12345'),'/INVALID - FORMAT/','6 IBAN BIC format validation');
like ( ibanValidate('csv','+DE99203205004989123456','abcd123','12345'),'/INVALID - FORMAT/','7 IBAN BIC format validation');
like ( ibanValidate('csv','DE99203205004989123456','cd123','12345'),'/ERROR -.*User ID/','8 User Id format validation');
like ( ibanValidate('csv','DE99203205004989123456','abcd1234','12345'),'/ERROR -.*User ID/','9 User Id format validation');
like ( ibanValidate('csv','DE99203205004989123456','abcd34','12345'),'/ERROR -.*User ID/','10 User Id format validation');
like ( ibanValidate('csv','DE99203205004989123456','abcd123','2345'),'/ERROR -.*PIN/','11 PIN format validation');
like ( ibanValidate('csv','DE99203205004989123456','abcd123','012345'),'/ERROR -.*PIN/','12 PIN format validation');
like ( ibanValidate('csv','DE99203205004989123456','abcd123','a2345'),'/ERROR -.*PIN/','13 PIN format validation');
like ( ibanValidate('xml','DE99203205004989123456','abcd123','12345'),'/xml/','14 valid response type');
like ( ibanValidate('json','DE99203205004989123456','abcd123','12345'),'/result":"ERROR -/','15 valid response type');
like ( ibanValidate('csv','DE99203205004989123456','abcd123','12345'),'/^ERROR - Invalid User ID/PIN$/','16 valid response type');
like ( ibanValidate('csv','DE99203205004989123456'),'/unifiedsoftware/','17 config lookup fail - this test will fail if the config file is present with valid details in it, this is ok');
like ( ibanValidate('xml','DE99203205004989123456'),'/unifiedsoftware/','18 config lookup fail - this test will fail if the config file is present with valid details in it, this is ok');
like ( ibanValidate('json','DE99203205004989123456'),'/unifiedsoftware/','19 config lookup fail - this test will fail if the config file is present with valid details in it, this is ok');

done_testing();