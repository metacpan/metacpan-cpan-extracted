
use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 6, todo => [] }
BEGIN { $| = 1 }

# load your module...
use lib './';
use Exception::Handler;

my($f) = Exception::Handler->new();

# check to see if non-autoloaded Exception::Handler methods are can-able ;O)
map { ok(ref(UNIVERSAL::can($f,$_)),'CODE') } qw
   (
      new
      fail
      trace

      VERSION
      DESTROY
      AUTOLOAD
   );

exit;
