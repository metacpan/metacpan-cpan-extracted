
use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 1, todo => [] }
BEGIN { $| = 1 }

# load your module...
use lib './';
use Exception::Handler;

my($f) = Exception::Handler->new();

# check to see if Exception::Handler ISA [foo, etc.]
ok(UNIVERSAL::isa($f,'Exception::Handler'));

exit;