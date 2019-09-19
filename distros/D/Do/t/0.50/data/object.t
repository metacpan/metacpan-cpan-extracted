use strict;
use warnings;
use Test::More;

plan skip_all => 'Deprecated';

use_ok 'Data::Object';
use_ok 'Data::Object::Export';

# deprecated
# can_ok 'Data::Object', 'new';

can_ok 'Data::Object::Export', 'cast';
can_ok 'Data::Object::Export', 'class_file';
can_ok 'Data::Object::Export', 'class_name';
can_ok 'Data::Object::Export', 'class_path';
can_ok 'Data::Object::Export', 'const';
can_ok 'Data::Object::Export', 'data_array';
can_ok 'Data::Object::Export', 'data_code';
can_ok 'Data::Object::Export', 'data_float';
can_ok 'Data::Object::Export', 'data_hash';
can_ok 'Data::Object::Export', 'data_number';
can_ok 'Data::Object::Export', 'data_regexp';
can_ok 'Data::Object::Export', 'data_scalar';
can_ok 'Data::Object::Export', 'data_string';
can_ok 'Data::Object::Export', 'data_undef';
can_ok 'Data::Object::Export', 'deduce';
can_ok 'Data::Object::Export', 'deduce_deep';
can_ok 'Data::Object::Export', 'deduce_type';
can_ok 'Data::Object::Export', 'detract';
can_ok 'Data::Object::Export', 'detract_deep';
can_ok 'Data::Object::Export', 'dispatch';
can_ok 'Data::Object::Export', 'immutable';
can_ok 'Data::Object::Export', 'library';
can_ok 'Data::Object::Export', 'load';
can_ok 'Data::Object::Export', 'namespace';
can_ok 'Data::Object::Export', 'path_class';
can_ok 'Data::Object::Export', 'path_name';
can_ok 'Data::Object::Export', 'prototype';
can_ok 'Data::Object::Export', 'registry';
can_ok 'Data::Object::Export', 'reify';
can_ok 'Data::Object::Export', 'throw';

ok 1 and done_testing;
