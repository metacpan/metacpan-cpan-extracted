use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Undef';

# deprecated
# ok Data::Object::Undef->does('Data::Object::Rule::Comparison');
# ok Data::Object::Undef->does('Data::Object::Rule::Defined');
ok Data::Object::Undef->does('Data::Object::Role::Detract');
ok Data::Object::Undef->does('Data::Object::Role::Dumper');
ok Data::Object::Undef->does('Data::Object::Role::Output');
ok Data::Object::Undef->does('Data::Object::Role::Throwable');

# no longer supported
# ok Data::Object::Undef->does('Data::Object::Role::Value');

# deprecated
# can_ok 'Data::Object::Undef', 'data';
# deprecated
# can_ok 'Data::Object::Undef', 'defined';
# deprecated
# can_ok 'Data::Object::Undef', 'detract';
# deprecated
# can_ok 'Data::Object::Undef', 'dump';
# deprecated
# can_ok 'Data::Object::Undef', 'eq';
# deprecated
# can_ok 'Data::Object::Undef', 'ge';
# deprecated
# can_ok 'Data::Object::Undef', 'gt';
# deprecated
# can_ok 'Data::Object::Undef', 'le';
# deprecated
# can_ok 'Data::Object::Undef', 'lt';
# deprecated
# can_ok 'Data::Object::Undef', 'ne';
# deprecated
# can_ok 'Data::Object::Undef', 'new';
# deprecated
# can_ok 'Data::Object::Undef', 'print';
# deprecated
# can_ok 'Data::Object::Undef', 'roles';
# deprecated
# can_ok 'Data::Object::Undef', 'say';
# deprecated
# can_ok 'Data::Object::Undef', 'throw';
# deprecated
# can_ok 'Data::Object::Undef', 'type';

ok 1 and done_testing;
