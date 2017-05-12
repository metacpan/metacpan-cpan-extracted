# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MathML-Entities-Approximate.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('MathML::Entities::Approximate') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
ok(name2approximated('&aacute;') eq 'a', 'test the &aacute; approximation');
is(name2approximated('&somerandomstring;'), '', 'test that non-existant entities return empty');
isnt(name2approximated('&dotlessi;'), 'i', 'test that entities not in MathML::Entities are caught and return empty');
is(name2numbered('&aacute;'), '&#x000E1;', 'Test call to MathML::Entities methods');
ok(MathML::Entities::Approximate::getSet('aacute') eq 'a', 'test getSet for reading');
ok(MathML::Entities::Approximate::getSet('aacute', 'z') eq 'z', 'test getSet for writing');

