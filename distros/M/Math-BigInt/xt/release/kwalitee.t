# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More 0.88;

eval "use Test::Kwalitee 1.21 'kwalitee_ok'";
plan skip_all => 'Test::Kwalitee required for testing kwalitee' if $@;

kwalitee_ok();

done_testing;
