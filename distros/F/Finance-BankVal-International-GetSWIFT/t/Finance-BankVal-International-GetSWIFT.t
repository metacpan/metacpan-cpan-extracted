# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-BankVal-International.t'

#########################
use Finance::BankVal::International::GetSWIFT qw(&getSWIFT);
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 20;
BEGIN { use_ok('Finance::BankVal::International::GetSWIFT') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

like ( getSWIFT('j-son','BARCGB22','abcd123','12345'),'/INVALID -.*Result Format/','2 response format validation');
like ( getSWIFT('xml','BARCGB22','abcd123','12345'),'/xml/','3 response format validation');
like ( getSWIFT('xml','BARCB22','abcd123','12345'),'/xml.*INVALID/','4 SWIFT BIC format validation');
like ( getSWIFT('xml','BARCGB22B','abcd123','12345'),'/INVALID/','5 SWIFT BIC format validation');
like ( getSWIFT('csv','BARCGB221234','abcd123','12345'),'/INVALID/','6 SWIFT BIC format validation');
like ( getSWIFT('csv','+BARCGB22','abcd123','12345'),'/INVALID/','7 SWIFT BIC format validation');
like ( getSWIFT('xml','BARCGB22123','abcd123','12345'),'/xml/','8 SWIFT BIC format validation');
like ( getSWIFT('csv','BARCGB22','cd123','12345'),'/ERROR -.*User ID/','9 User Id format validation');
like ( getSWIFT('csv','BARCGB22','abcd1234','12345'),'/ERROR -.*User ID/','10 User Id format validation');
like ( getSWIFT('csv','BARCGB22','abcd34','12345'),'/ERROR -.*User ID/','11 User Id format validation');
like ( getSWIFT('csv','BARCGB22','abcd123','2345'),'/ERROR -.*PIN/','12 PIN format validation');
like ( getSWIFT('csv','BARCGB22','abcd123','012345'),'/ERROR -.*PIN/','13 PIN format validation');
like ( getSWIFT('csv','BARCGB22','abcd123','a2345'),'/ERROR -.*PIN/','14 PIN format validation');
like ( getSWIFT('xml','BARCGB22','abcd123','12345'),'/xml/','15 valid response type');
like ( getSWIFT('json','BARCGB22','abcd123','12345'),'/result":"ERROR -/','16 valid response type');
like ( getSWIFT('csv','BARCGB22','abcd123','12345'),'/^ERROR - Invalid User ID/PIN$/','17 valid response type');
like ( getSWIFT('csv','BARCGB22'),'/unifiedsoftware/','18 config lookup fail - this test will fail if the config file is present with valid details in it, this is ok');
like ( getSWIFT('xml','BARCGB22'),'/unifiedsoftware/','19 config lookup fail - this test will fail if the config file is present with valid details in it, this is ok');
like ( getSWIFT('json','BARCGB22'),'/unifiedsoftware/','20 config lookup fail - this test will fail if the config file is present with valid details in it, this is ok');

done_testing();