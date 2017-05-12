use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use PackageChanger;

::is __PACKAGE__, 'Moo::Kooh';

::done_testing;
