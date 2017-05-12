# Check that all .pm files have a $VERSION.

use strict;
use warnings;

use Test::HasVersion;
all_pm_version_ok();
