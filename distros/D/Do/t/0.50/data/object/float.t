use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Float';

# deprecated
# ok Data::Object::Float->does('Data::Object::Rule::Comparison');
# ok Data::Object::Float->does('Data::Object::Rule::Defined');
ok Data::Object::Float->does('Data::Object::Role::Detract');
ok Data::Object::Float->does('Data::Object::Role::Dumper');
# no longer supported
# ok Data::Object::Float->does('Data::Object::Role::Numeric');
ok Data::Object::Float->does('Data::Object::Role::Output');
ok Data::Object::Float->does('Data::Object::Role::Throwable');
# no longer supported
# ok Data::Object::Float->does('Data::Object::Role::Type');
# no longer supported
# ok Data::Object::Float->does('Data::Object::Role::Value');

# deprecated
# can_ok 'Data::Object::Float', 'data';
# deprecated
# can_ok 'Data::Object::Float', 'defined';
# deprecated
# can_ok 'Data::Object::Float', 'detract';
# deprecated
# can_ok 'Data::Object::Float', 'downto';
# deprecated
# can_ok 'Data::Object::Float', 'dump';
# deprecated
# can_ok 'Data::Object::Float', 'eq';
# deprecated
# can_ok 'Data::Object::Float', 'ge';
# deprecated
# can_ok 'Data::Object::Float', 'gt';
# deprecated
# can_ok 'Data::Object::Float', 'le';
# deprecated
# can_ok 'Data::Object::Float', 'lt';
# deprecated
# can_ok 'Data::Object::Float', 'ne';
# deprecated
# can_ok 'Data::Object::Float', 'new';
# deprecated
# can_ok 'Data::Object::Float', 'print';
# deprecated
# can_ok 'Data::Object::Float', 'roles';
# deprecated
# can_ok 'Data::Object::Float', 'say';
# deprecated
# can_ok 'Data::Object::Float', 'throw';
# deprecated
# can_ok 'Data::Object::Float', 'to';
# deprecated
# can_ok 'Data::Object::Float', 'type';
# deprecated
# can_ok 'Data::Object::Float', 'upto';

ok 1 and done_testing;
