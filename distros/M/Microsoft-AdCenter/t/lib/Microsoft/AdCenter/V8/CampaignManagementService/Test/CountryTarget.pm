package Microsoft::AdCenter::V8::CampaignManagementService::Test::CountryTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::CountryTarget;

sub test_can_create_country_target_and_set_all_fields : Test(2) {
    my $country_target = Microsoft::AdCenter::V8::CampaignManagementService::CountryTarget->new
        ->Bids('bids')
    ;

    ok($country_target);

    is($country_target->Bids, 'bids', 'can get bids');
};

1;
