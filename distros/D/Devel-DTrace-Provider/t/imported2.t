package main;
use strict;
use warnings;
use Test::More qw/ no_plan /;

use lib 't/lib';
use TestProvider2;

probe11 { shift->fire('foo') } if probe11_enabled;
probe21 { shift->fire(1) } if probe21_enabled;
probe12 { shift->fire('foo') } if probe12_enabled;
probe22 { shift->fire(1) } if probe22_enabled;

ok($main::{'probe11'});
ok($main::{'probe11_enabled'});
ok($main::{'probe21'});
ok($main::{'probe21_enabled'});

ok($main::{'probe12'});
ok($main::{'probe12_enabled'});
ok($main::{'probe22'});
ok($main::{'probe22_enabled'});
