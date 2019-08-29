use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Regexp';

# deprecated
# ok Data::Object::Regexp->does('Data::Object::Rule::Defined');
ok Data::Object::Regexp->does('Data::Object::Role::Detract');
ok Data::Object::Regexp->does('Data::Object::Role::Dumper');
ok Data::Object::Regexp->does('Data::Object::Role::Output');
ok Data::Object::Regexp->does('Data::Object::Role::Throwable');

# deprecated
# can_ok 'Data::Object::Regexp', 'data';
# deprecated
# can_ok 'Data::Object::Regexp', 'defined';
# deprecated
# can_ok 'Data::Object::Regexp', 'detract';
# deprecated
# can_ok 'Data::Object::Regexp', 'dump';
# deprecated
# can_ok 'Data::Object::Regexp', 'new';
# deprecated
# can_ok 'Data::Object::Regexp', 'print';
# deprecated
# can_ok 'Data::Object::Regexp', 'replace';
# deprecated
# can_ok 'Data::Object::Regexp', 'roles';
# deprecated
# can_ok 'Data::Object::Regexp', 'say';
# deprecated
# can_ok 'Data::Object::Regexp', 'search';
# deprecated
# can_ok 'Data::Object::Regexp', 'throw';
# deprecated
# can_ok 'Data::Object::Regexp', 'type';

ok 1 and done_testing;
