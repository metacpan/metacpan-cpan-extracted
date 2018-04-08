#!perl
use 5.10.0;
use strict;
use warnings;
use Test::More;

use Test::Pod::Coverage;
use Pod::Coverage;

all_pod_coverage_ok( { trustme => [qr/BUILD|new/] } );
