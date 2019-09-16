use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Scalar';

# deprecated
# ok Data::Object::Scalar->does('Data::Object::Rule::Comparison');
# ok Data::Object::Scalar->does('Data::Object::Rule::Defined');
# deprecated
# ok Data::Object::Scalar->does('Data::Object::Role::Detract');
# deprecated
# ok Data::Object::Scalar->does('Data::Object::Role::Dumper');
# deprecated
# ok Data::Object::Scalar->does('Data::Object::Role::Output');
ok Data::Object::Scalar->does('Data::Object::Role::Throwable');

# no longer supported
# ok Data::Object::Scalar->does('Data::Object::Role::Value');

# deprecated
# can_ok 'Data::Object::Scalar', 'data';
# deprecated
# can_ok 'Data::Object::Scalar', 'defined';
# deprecated
# can_ok 'Data::Object::Scalar', 'detract';
# deprecated
# can_ok 'Data::Object::Scalar', 'dump';
# deprecated
# can_ok 'Data::Object::Scalar', 'eq';
# deprecated
# can_ok 'Data::Object::Scalar', 'ge';
# deprecated
# can_ok 'Data::Object::Scalar', 'gt';
# deprecated
# can_ok 'Data::Object::Scalar', 'le';
# deprecated
# can_ok 'Data::Object::Scalar', 'lt';
# deprecated
# can_ok 'Data::Object::Scalar', 'ne';
# deprecated
# can_ok 'Data::Object::Scalar', 'new';
# deprecated
# can_ok 'Data::Object::Scalar', 'print';
# deprecated
# can_ok 'Data::Object::Scalar', 'roles';
# deprecated
# can_ok 'Data::Object::Scalar', 'say';
# deprecated
# can_ok 'Data::Object::Scalar', 'throw';
# deprecated
# can_ok 'Data::Object::Scalar', 'type';

ok 1 and done_testing;
