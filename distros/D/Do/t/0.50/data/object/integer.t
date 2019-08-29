use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Integer';

# deprecated
# ok Data::Object::Integer->does('Data::Object::Rule::Comparison');
# ok Data::Object::Integer->does('Data::Object::Rule::Defined');
ok Data::Object::Integer->does('Data::Object::Role::Detract');
ok Data::Object::Integer->does('Data::Object::Role::Dumper');
ok Data::Object::Integer->does('Data::Object::Role::Output');
ok Data::Object::Integer->does('Data::Object::Role::Throwable');

# no longer supported
# ok Data::Object::Integer->does('Data::Object::Role::Value');

# deprecated
# can_ok 'Data::Object::Integer', 'data';
# deprecated
# can_ok 'Data::Object::Integer', 'defined';
# deprecated
# can_ok 'Data::Object::Integer', 'detract';
# deprecated
# can_ok 'Data::Object::Integer', 'downto';
# deprecated
# can_ok 'Data::Object::Integer', 'dump';
# deprecated
# can_ok 'Data::Object::Integer', 'eq';
# deprecated
# can_ok 'Data::Object::Integer', 'ge';
# deprecated
# can_ok 'Data::Object::Integer', 'gt';
# deprecated
# can_ok 'Data::Object::Integer', 'le';
# deprecated
# can_ok 'Data::Object::Integer', 'lt';
# deprecated
# can_ok 'Data::Object::Integer', 'ne';
# deprecated
# can_ok 'Data::Object::Integer', 'new';
# deprecated
# can_ok 'Data::Object::Integer', 'print';
# deprecated
# can_ok 'Data::Object::Integer', 'roles';
# deprecated
# can_ok 'Data::Object::Integer', 'say';
# deprecated
# can_ok 'Data::Object::Integer', 'throw';
# deprecated
# can_ok 'Data::Object::Integer', 'to';
# deprecated
# can_ok 'Data::Object::Integer', 'type';
# deprecated
# can_ok 'Data::Object::Integer', 'upto';

ok 1 and done_testing;
