package Microsoft::AdCenter::V8::CampaignManagementService::Test::CountryTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::CountryTargetBid;

sub test_can_create_country_target_bid_and_set_all_fields : Test(3) {
    my $country_target_bid = Microsoft::AdCenter::V8::CampaignManagementService::CountryTargetBid->new
        ->CountryAndRegion('country and region')
        ->IncrementalBid('incremental bid')
    ;

    ok($country_target_bid);

    is($country_target_bid->CountryAndRegion, 'country and region', 'can get country and region');
    is($country_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
};

1;
