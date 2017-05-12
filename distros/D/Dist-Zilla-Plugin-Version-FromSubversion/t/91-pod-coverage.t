#!perl
use strict;
use warnings;
use Test::More skip_all => 'only for raising Kwalitee';

use Test::Pod::Coverage;
all_pod_coverage_ok();
