package main;
use strict;
use warnings;
use Test::More qw/ no_plan /;

use lib 't/lib';
use TestProvider;

probe1_start { shift->fire('foo') } if probe1_start_enabled;
probe2 { shift->fire(1) } if probe2_enabled;

ok($main::{'probe1_start'});
ok($main::{'probe1_start_enabled'});
ok($main::{'probe2'});
ok($main::{'probe2_enabled'});
