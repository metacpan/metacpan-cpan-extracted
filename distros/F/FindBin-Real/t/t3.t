#!/usr/bin/env perl -w

use strict;
use Test;
use FindBin qw/$RealBin/;

BEGIN { plan tests => 1 }

use FindBin::Real;

ok($RealBin, FindBin::Real::RealBin());

exit;
