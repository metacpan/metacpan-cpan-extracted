use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::String';

# deprecated
# ok Data::Object::String->does('Data::Object::Rule::Comparison');
# ok Data::Object::String->does('Data::Object::Rule::Defined');
ok Data::Object::String->does('Data::Object::Role::Detract');
ok Data::Object::String->does('Data::Object::Role::Dumper');
ok Data::Object::String->does('Data::Object::Role::Output');
ok Data::Object::String->does('Data::Object::Role::Throwable');

# no longer supported
# ok Data::Object::String->does('Data::Object::Role::Value');

# deprecated
# can_ok 'Data::Object::String', 'append';
# deprecated
# can_ok 'Data::Object::String', 'camelcase';
# deprecated
# can_ok 'Data::Object::String', 'chomp';
# deprecated
# can_ok 'Data::Object::String', 'chop';
# deprecated
# can_ok 'Data::Object::String', 'concat';
# deprecated
# can_ok 'Data::Object::String', 'contains';
# deprecated
# can_ok 'Data::Object::String', 'data';
# deprecated
# can_ok 'Data::Object::String', 'defined';
# deprecated
# can_ok 'Data::Object::String', 'detract';
# deprecated
# can_ok 'Data::Object::String', 'dump';
# deprecated
# can_ok 'Data::Object::String', 'eq';
# deprecated
# can_ok 'Data::Object::String', 'ge';
# deprecated
# can_ok 'Data::Object::String', 'gt';
# deprecated
# can_ok 'Data::Object::String', 'hex';
# deprecated
# can_ok 'Data::Object::String', 'index';
# deprecated
# can_ok 'Data::Object::String', 'lc';
# deprecated
# can_ok 'Data::Object::String', 'lcfirst';
# deprecated
# can_ok 'Data::Object::String', 'le';
# deprecated
# can_ok 'Data::Object::String', 'length';
# deprecated
# can_ok 'Data::Object::String', 'lines';
# deprecated
# can_ok 'Data::Object::String', 'lowercase';
# deprecated
# can_ok 'Data::Object::String', 'lt';
# deprecated
# can_ok 'Data::Object::String', 'ne';
# deprecated
# can_ok 'Data::Object::String', 'new';
# deprecated
# can_ok 'Data::Object::String', 'print';
# deprecated
# can_ok 'Data::Object::String', 'replace';
# deprecated
# can_ok 'Data::Object::String', 'reverse';
# deprecated
# can_ok 'Data::Object::String', 'rindex';
# deprecated
# can_ok 'Data::Object::String', 'roles';
# deprecated
# can_ok 'Data::Object::String', 'say';
# deprecated
# can_ok 'Data::Object::String', 'snakecase';
# deprecated
# can_ok 'Data::Object::String', 'split';
# deprecated
# can_ok 'Data::Object::String', 'strip';
# deprecated
# can_ok 'Data::Object::String', 'throw';
# deprecated
# can_ok 'Data::Object::String', 'titlecase';
# deprecated
# can_ok 'Data::Object::String', 'trim';
# deprecated
# can_ok 'Data::Object::String', 'type';
# deprecated
# can_ok 'Data::Object::String', 'uc';
# deprecated
# can_ok 'Data::Object::String', 'ucfirst';
# deprecated
# can_ok 'Data::Object::String', 'uppercase';
# deprecated
# can_ok 'Data::Object::String', 'words';

ok 1 and done_testing;
