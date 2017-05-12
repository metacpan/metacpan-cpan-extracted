#!/usr/bin/perl

use strict;
use warnings;

use Test::More no_plan => 1;
use EO::System;

ok(1, "loaded");
ok(my $os = EO::System->os);
ok($os->osname);

1;
