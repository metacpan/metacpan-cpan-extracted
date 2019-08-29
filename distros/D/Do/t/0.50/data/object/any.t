use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Any';

# deprecated
# ok Data::Object::Any->does('Data::Object::Rule::Comparison');
# ok Data::Object::Any->does('Data::Object::Rule::Defined');
ok Data::Object::Any->does('Data::Object::Role::Detract');
ok Data::Object::Any->does('Data::Object::Role::Dumper');
ok Data::Object::Any->does('Data::Object::Role::Output');
ok Data::Object::Any->does('Data::Object::Role::Throwable');

# no longer supported
# ok Data::Object::Any->does('Data::Object::Role::Value');

# deprecated
# can_ok 'Data::Object::Any', 'data';
# deprecated
# can_ok 'Data::Object::Any', 'defined';
# deprecated
# can_ok 'Data::Object::Any', 'detract';
# deprecated
# can_ok 'Data::Object::Any', 'dump';
# deprecated
# can_ok 'Data::Object::Any', 'eq';
# deprecated
# can_ok 'Data::Object::Any', 'ge';
# deprecated
# can_ok 'Data::Object::Any', 'gt';
# deprecated
# can_ok 'Data::Object::Any', 'le';
# deprecated
# can_ok 'Data::Object::Any', 'lt';
# deprecated
# can_ok 'Data::Object::Any', 'ne';
# deprecated
# can_ok 'Data::Object::Any', 'new';
# deprecated
# can_ok 'Data::Object::Any', 'print';
# deprecated
# can_ok 'Data::Object::Any', 'roles';
# deprecated
# can_ok 'Data::Object::Any', 'say';
# deprecated
# can_ok 'Data::Object::Any', 'throw';
# deprecated
# can_ok 'Data::Object::Any', 'type';

ok 1 and done_testing;
