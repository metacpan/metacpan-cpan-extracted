#!/usr/bin/env perl -w

use strict;
use Test;
use FindBin qw/$RealScript/;

BEGIN { plan tests => 1 }

use FindBin::Real;

ok($RealScript, FindBin::Real::RealScript());

exit;
