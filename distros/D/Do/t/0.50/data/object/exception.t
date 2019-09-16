use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Exception';

# deprecated
# can_ok 'Data::Object::Exception', 'data';

can_ok 'Data::Object::Exception', 'explain';

# deprecated
# can_ok 'Data::Object::Exception', 'dump';

can_ok 'Data::Object::Exception', 'throw';

ok 1 and done_testing;
