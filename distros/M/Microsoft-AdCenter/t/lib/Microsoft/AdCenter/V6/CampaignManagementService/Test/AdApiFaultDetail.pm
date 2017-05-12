package Microsoft::AdCenter::V6::CampaignManagementService::Test::AdApiFaultDetail;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::AdApiFaultDetail;

sub test_can_create_ad_api_fault_detail_and_set_all_fields : Test(2) {
    my $ad_api_fault_detail = Microsoft::AdCenter::V6::CampaignManagementService::AdApiFaultDetail->new
        ->Errors('errors')
    ;

    ok($ad_api_fault_detail);

    is($ad_api_fault_detail->Errors, 'errors', 'can get errors');
};

1;
