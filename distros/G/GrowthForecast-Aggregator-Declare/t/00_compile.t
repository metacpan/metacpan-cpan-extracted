use strict;
use Test::More;

use_ok $_ for qw(
    GrowthForecast::Aggregator::Declare
    GrowthForecast::Aggregator::DB
    GrowthForecast::Aggregator::DBMulti
    GrowthForecast::Aggregator::Callback
);
done_testing;
