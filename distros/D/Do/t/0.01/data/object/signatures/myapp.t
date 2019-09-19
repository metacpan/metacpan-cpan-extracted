use lib 't/0.01/lib';

use Test::More;

use Data::Object::Signatures qw(MyApp::Types);
use Data::Object::Utility;

fun greeting (AllCaps $name) {
  return "hello, $name";
}

fun meeting (NumberObj :$epoch = Data::Object::Utility::Deduce $$) {
  return "our meeting is at $epoch";
}

is greeting(Data::Object::Utility::Deduce('MARTIAN')), 'hello, MARTIAN';
ok !eval { greeting(Data::Object::Utility::Deduce('martian')) };
ok $@;

is meeting(epoch => Data::Object::Utility::Deduce $$), 'our meeting is at ' . $$;
is meeting(epocj => Data::Object::Utility::Deduce $$), 'our meeting is at ' . $$;

ok 1 and done_testing;
