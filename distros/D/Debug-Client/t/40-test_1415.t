use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use FindBin qw($Bin);
use lib map "$Bin/$_", 'lib', '../lib';

use t::lib::Test_1415;

# run all the test methods
Test::Class->runtests;

__END__

