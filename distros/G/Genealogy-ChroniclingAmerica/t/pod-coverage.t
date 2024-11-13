use strict;
use warnings;
use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::Pod::Coverage' => '1.08', 'Pod::Coverage' => 0.18 };

Test::Pod::Coverage->import();
Pod::Coverage->import();

all_pod_coverage_ok();
