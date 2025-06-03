use strict;
use warnings;

use Test::More tests => 1;


BEGIN {
  local $ENV{PERL_DEBUG_HELPER_FLAG_STRICT} = 1;
  require Debug::Helper::Flag;                      # This is ok because we are in a BEGIN block!
  eval { Debug::Helper::Flag->import('DEBUG_FLAG') };
  ok($@, "import 'DEBUG_FLAG' while constant is not defined");
}

