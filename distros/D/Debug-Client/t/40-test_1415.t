use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use FindBin qw($Bin);
use lib map "$Bin/$_", 'lib', '../lib';

BEGIN {
  require "./t/lib/Test_1415.pm";
  t::lib::Test_1415->import();
}

# run all the test methods
Test::Class->runtests;

__END__

