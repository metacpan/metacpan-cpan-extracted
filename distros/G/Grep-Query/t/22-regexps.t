use strict;
use warnings;

use FindBin qw($Bin);

use lib "$Bin/lib";

use TestUtils;

TestUtils::runAsNonFieldedTests('regexps');
