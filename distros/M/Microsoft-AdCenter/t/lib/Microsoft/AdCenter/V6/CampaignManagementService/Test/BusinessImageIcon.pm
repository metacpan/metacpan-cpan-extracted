package Microsoft::AdCenter::V6::CampaignManagementService::Test::BusinessImageIcon;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::BusinessImageIcon;

sub test_can_create_business_image_icon_and_set_all_fields : Test(3) {
    my $business_image_icon = Microsoft::AdCenter::V6::CampaignManagementService::BusinessImageIcon->new
        ->CustomIconAssetId('custom icon asset id')
        ->StandardBusinessIcon('standard business icon')
    ;

    ok($business_image_icon);

    is($business_image_icon->CustomIconAssetId, 'custom icon asset id', 'can get custom icon asset id');
    is($business_image_icon->StandardBusinessIcon, 'standard business icon', 'can get standard business icon');
};

1;
