use strict;
use warnings;

use Test::More tests => 1;


BEGIN {
  require Debug::Helper::Flag;                      # This is ok because we are in a BEGIN block!
  eval { Debug::Helper::Flag->import('DEBUG_FLAG') };
  ok($@, "import 'DEBUG_FLAG' while constant is not defined");
}

