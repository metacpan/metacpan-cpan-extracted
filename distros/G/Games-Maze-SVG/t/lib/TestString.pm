#
# Wrapper to handle the Test::LongString problem.
#

use Test::More;

use strict;
use warnings;

BEGIN {
   eval "use Test::LongString;";
   *::is_string = \&Test::More::is if $@;
}

1;
