use strict;
use warnings;

use Test::More tests => 1;

my $stderr;
BEGIN {
  $stderr = '';
  local *STDERR;
  open STDERR, '>', \$stderr;
  require Debug::Helper::Flag;                      # This is ok because we are in a BEGIN block!
  Debug::Helper::Flag->import('DEBUG_FLAG');
}
like($stderr, qr/Attempt to export while constant is not yet defined/,
     "import 'DEBUG_FLAG' while constant is not defined (warning))");

