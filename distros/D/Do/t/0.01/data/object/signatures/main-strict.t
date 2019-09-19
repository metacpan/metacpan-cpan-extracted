use Test::More;

use Data::Object::Signatures qw(:strict);
use Data::Object::Utility;

fun greeting (StrObj $name) {
  return "hello, $name";
}

fun meeting (NumObj :$epoch = Data::Object::Utility::Deduce $$) {
  return "our meeting is at $epoch";
}

is greeting(Data::Object::Utility::Deduce('martian')), 'hello, martian';
ok !eval { greeting('martian') };
ok $@;

is meeting(epoch => Data::Object::Utility::Deduce $$), 'our meeting is at ' . $$;
is meeting(epocj => Data::Object::Utility::Deduce $$), 'our meeting is at ' . $$;

ok 1 and done_testing;
