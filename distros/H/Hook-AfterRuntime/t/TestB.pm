package TestB;
use strict;
use warnings;

use Test::More;

use TestA;

ok( !$main::TRIGGERED, "Not triggered yet." );

1;
