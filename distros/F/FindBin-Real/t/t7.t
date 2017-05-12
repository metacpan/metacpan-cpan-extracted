#!/usr/bin/env perl -w

use strict;
use Test;
use FindBin qw/$Dir/;

BEGIN { plan tests => 1 }

use FindBin::Real;

ok($Dir, FindBin::Real::Dir());

exit;
