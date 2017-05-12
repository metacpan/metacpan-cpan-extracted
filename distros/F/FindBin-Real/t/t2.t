#!/usr/bin/env perl -w

use strict;
use Test;
use FindBin qw/$Bin/;

BEGIN { plan tests => 1 }

use FindBin::Real;

ok($Bin, FindBin::Real::Bin());

exit;
