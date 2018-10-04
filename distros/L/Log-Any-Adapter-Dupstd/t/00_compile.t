use strict;
use warnings;

use Test::More 0.98;

use_ok $_ for qw(
    Log::Any::Adapter::Dupstd
    Log::Any::Adapter::Duperr
    Log::Any::Adapter::Dupout
);

done_testing;
