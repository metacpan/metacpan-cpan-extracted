#!/usr/bin/env perl -w

use strict;
use Test;
use FindBin qw/$Script/;

BEGIN { plan tests => 1 }

use FindBin::Real;

ok($Script, FindBin::Real::Script());

exit;
