use strict;
use warnings;
use Test::More;

BEGIN {
  plan skip_all => 'Regexp-Result no longer supported';
}

use_ok 'Data::Object::RegexpResult';

can_ok 'Data::Object::RegexpResult', 'captures';
can_ok 'Data::Object::RegexpResult', 'count';
can_ok 'Data::Object::RegexpResult', 'initial';
can_ok 'Data::Object::RegexpResult', 'last_match_end';
can_ok 'Data::Object::RegexpResult', 'last_match_start';
can_ok 'Data::Object::RegexpResult', 'matched';
can_ok 'Data::Object::RegexpResult', 'named_captures';
can_ok 'Data::Object::RegexpResult', 'postmatched';
can_ok 'Data::Object::RegexpResult', 'prematched';
can_ok 'Data::Object::RegexpResult', 'regexp';
can_ok 'Data::Object::RegexpResult', 'string';

ok 1 and done_testing;
