#!/usr/bin/env perl -w

use strict;
use Test;
use FindBin qw/$RealDir/;

BEGIN { plan tests => 1 }

use FindBin::Real;

ok($RealDir, FindBin::Real::RealDir());

exit;
