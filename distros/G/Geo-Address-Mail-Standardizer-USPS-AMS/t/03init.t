use Test::More;

use strict;
use warnings;

use_ok('Geo::Address::Mail::Standardizer::USPS::AMS');

my $ms = new Geo::Address::Mail::Standardizer::USPS::AMS;

$ms->init;

done_testing;

