# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math-MultiplicationTable.t'

#########################

use Test::More tests => 6;
BEGIN { use_ok('Math::MultiplicationTable') };

#########################

ok(not defined Math::MultiplicationTable::generate(-1));
ok(Math::MultiplicationTable::generate());
ok(Math::MultiplicationTable::generate(0) eq '');
ok(Math::MultiplicationTable::generate(1) eq " 1\n");
ok(Math::MultiplicationTable::generate(99));
