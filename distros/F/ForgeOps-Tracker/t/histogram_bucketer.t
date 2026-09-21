use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use ForgeOps::Tracker::HistogramBucketer;

sub bucket_for { ForgeOps::Tracker::HistogramBucketer::bucket_for(@_) }

subtest 'returns the smallest boundary a duration fits under, as a string' => sub {
    is(bucket_for(10), '50');
    is(bucket_for(50), '50');
    is(bucket_for(50.5), '100');
    is(bucket_for(4999), '5000');
};

subtest 'returns inf for anything larger than the largest boundary' => sub {
    is(bucket_for(10001), 'inf');
    is(bucket_for(1000000), 'inf');
};

subtest 'puts a duration exactly on a boundary into that boundary\'s own bucket' => sub {
    is(bucket_for($_), "$_") for ForgeOps::Tracker::HistogramBucketer::BOUNDARIES_MS;
};

subtest 'boundaries match the server\'s HistogramPercentile' => sub {
    # app/services/histogram_percentile.rb and every other SDK must agree on this exact list.
    is_deeply([ForgeOps::Tracker::HistogramBucketer::BOUNDARIES_MS], [50, 100, 250, 500, 1000, 2500, 5000, 10000]);
};

done_testing;
