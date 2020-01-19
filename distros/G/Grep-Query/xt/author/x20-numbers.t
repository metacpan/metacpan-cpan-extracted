use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/../../t/lib";
use lib "$Bin/../lib";

use XTestUtils;

XTestUtils::runAsNonFieldedDbTests('numbers');
