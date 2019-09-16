use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Number';

# deprecated
# ok Data::Object::Number->does('Data::Object::Rule::Comparison');
# ok Data::Object::Number->does('Data::Object::Rule::Defined');
# deprecated
# ok Data::Object::Number->does('Data::Object::Role::Detract');
# deprecated
# ok Data::Object::Number->does('Data::Object::Role::Dumper');
# deprecated
# ok Data::Object::Number->does('Data::Object::Role::Output');
ok Data::Object::Number->does('Data::Object::Role::Throwable');

# no longer supported
# ok Data::Object::Number->does('Data::Object::Role::Value');

# deprecated
# can_ok 'Data::Object::Number', 'abs';
# deprecated
# can_ok 'Data::Object::Number', 'atan2';
# deprecated
# can_ok 'Data::Object::Number', 'cos';
# deprecated
# can_ok 'Data::Object::Number', 'data';
# deprecated
# can_ok 'Data::Object::Number', 'decr';
# deprecated
# can_ok 'Data::Object::Number', 'defined';
# deprecated
# can_ok 'Data::Object::Number', 'detract';
# deprecated
# can_ok 'Data::Object::Number', 'downto';
# deprecated
# can_ok 'Data::Object::Number', 'dump';
# deprecated
# can_ok 'Data::Object::Number', 'eq';
# deprecated
# can_ok 'Data::Object::Number', 'exp';
# deprecated
# can_ok 'Data::Object::Number', 'ge';
# deprecated
# can_ok 'Data::Object::Number', 'gt';
# deprecated
# can_ok 'Data::Object::Number', 'hex';
# deprecated
# can_ok 'Data::Object::Number', 'incr';
# deprecated
# can_ok 'Data::Object::Number', 'int';
# deprecated
# can_ok 'Data::Object::Number', 'le';
# deprecated
# can_ok 'Data::Object::Number', 'log';
# deprecated
# can_ok 'Data::Object::Number', 'lt';
# deprecated
# can_ok 'Data::Object::Number', 'mod';
# deprecated
# can_ok 'Data::Object::Number', 'ne';
# deprecated
# can_ok 'Data::Object::Number', 'neg';
# deprecated
# can_ok 'Data::Object::Number', 'new';
# deprecated
# can_ok 'Data::Object::Number', 'pow';
# deprecated
# can_ok 'Data::Object::Number', 'print';
# deprecated
# can_ok 'Data::Object::Number', 'roles';
# deprecated
# can_ok 'Data::Object::Number', 'say';
# deprecated
# can_ok 'Data::Object::Number', 'sin';
# deprecated
# can_ok 'Data::Object::Number', 'sqrt';
# deprecated
# can_ok 'Data::Object::Number', 'throw';
# deprecated
# can_ok 'Data::Object::Number', 'to';
# deprecated
# can_ok 'Data::Object::Number', 'type';
# deprecated
# can_ok 'Data::Object::Number', 'upto';

ok 1 and done_testing;
