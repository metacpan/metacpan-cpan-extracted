use strict;
use warnings;
use Lingua::JA::Expand::DataSource::YahooSearch;
use Test::More tests => 1;

my %config = (
    yahoo_api_appid => 'dummy'
);

my $datasource = Lingua::JA::Expand::DataSource::YahooSearch->new(\%config);

isa_ok($datasource, 'Lingua::JA::Expand::DataSource::YahooSearch');


