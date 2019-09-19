use lib 't/0.01/lib';

use Test::More;

use Data::Object::Signatures ':strict' => qw(MyApp::Types);
use Data::Object::Utility;
use Data::Object::Registry;

fun greeting (AllCaps $name) {
  return "hello, $name";
}

fun meeting (NumObj :$epoch = $$) {
  return "our meeting is at $epoch";
}

is greeting(Data::Object::Utility::Deduce('MARTIAN')), 'hello, MARTIAN';
ok !eval { greeting(Data::Object::Utility::Deduce('martian')) };
ok $@;

is meeting(epoch => Data::Object::Utility::Deduce $$), 'our meeting is at ' . $$;
ok !eval { meeting(epocj => Data::Object::Utility::Deduce $$) };
ok $@;

ok 1 and done_testing;
