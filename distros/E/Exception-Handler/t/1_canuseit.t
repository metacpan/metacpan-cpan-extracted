
use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 1, todo => [] }

# load your module...
use lib './';
use Exception::Handler;

# check object constructor
ok(ref(Exception::Handler->new()),'Exception::Handler');

exit;