# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Email-AddressParser.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('Email::AddressParser') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use Data::Dumper;

$input = "<jXhnXonX\@lXnXXc.Xdu>, <kXXXn\@hXXXraXcoXnXXXX.com>,\r\n" . 
"        \"XXXNXAN RXchXeXD\" <RXXXXe.X.XXIXMAN\@XXXe.XeXeXXr.us>,\r\n" . 
"        \"XoXXX, XXyXXr\" <taXXXraXXXds\@hXXmaXl.cXX>\r\n";

$a = new Email::AddressParser('tony', 'tkay@uoregon.edu');
ok($a->format eq '"tony" <tkay@uoregon.edu>', 'object interface');
ok($a->original eq '"tony" <tkay@uoregon.edu>', 'object interface');

@v = Email::AddressParser->parse($input);
ok(scalar(@v) == 4, 'parse returns correct number');

ok($v[2]->phrase eq 'XXXNXAN RXchXeXD', 'subphrase');
ok($v[2]->format eq '"XXXNXAN RXchXeXD" <RXXXXe.X.XXIXMAN@XXXe.XeXeXXr.us>', 'format');
ok($v[2]->address eq 'RXXXXe.X.XXIXMAN@XXXe.XeXeXXr.us', 'address');

@v = Email::AddressParser->parse('tkay@uoregon.edu, ');
ok(@v == 1, 'empty parse yields no addresses');

