use strict;
use warnings;
use Test::More;
use Test::Pod::Coverage 1.08;
use Pod::Coverage 0.18;

all_pod_coverage_ok({ also_private => [ qr/^[A-Z0-9_]+$/ ], });
