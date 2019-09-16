use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Code';

# deprecated
# ok Data::Object::Code->does('Data::Object::Rule::Defined');
# deprecated
# ok Data::Object::Code->does('Data::Object::Role::Detract');
# deprecated
# ok Data::Object::Code->does('Data::Object::Role::Dumper');
ok Data::Object::Code->does('Data::Object::Role::Throwable');

# deprecated
# can_ok 'Data::Object::Code', 'call';
# deprecated
# can_ok 'Data::Object::Code', 'compose';
# deprecated
# can_ok 'Data::Object::Code', 'conjoin';
# deprecated
# can_ok 'Data::Object::Code', 'curry';
# deprecated
# can_ok 'Data::Object::Code', 'data';
# deprecated
# can_ok 'Data::Object::Code', 'defined';
# deprecated
# can_ok 'Data::Object::Code', 'detract';
# deprecated
# can_ok 'Data::Object::Code', 'disjoin';
# deprecated
# can_ok 'Data::Object::Code', 'dump';
# deprecated
# can_ok 'Data::Object::Code', 'new';
# deprecated
# can_ok 'Data::Object::Code', 'next';
# deprecated
# can_ok 'Data::Object::Code', 'rcurry';
# deprecated
# can_ok 'Data::Object::Code', 'roles';
# deprecated
# can_ok 'Data::Object::Code', 'throw';
# deprecated
# can_ok 'Data::Object::Code', 'type';

ok 1 and done_testing;
