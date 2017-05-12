package Microsoft::AdCenter::V6::CampaignManagementService::Test::MobileAd;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::MobileAd;

sub test_can_create_mobile_ad_and_set_all_fields : Test(7) {
    my $mobile_ad = Microsoft::AdCenter::V6::CampaignManagementService::MobileAd->new
        ->BusinessName('business name')
        ->DestinationUrl('destination url')
        ->DisplayUrl('display url')
        ->PhoneNumber('phone number')
        ->Text('text')
        ->Title('title')
    ;

    ok($mobile_ad);

    is($mobile_ad->BusinessName, 'business name', 'can get business name');
    is($mobile_ad->DestinationUrl, 'destination url', 'can get destination url');
    is($mobile_ad->DisplayUrl, 'display url', 'can get display url');
    is($mobile_ad->PhoneNumber, 'phone number', 'can get phone number');
    is($mobile_ad->Text, 'text', 'can get text');
    is($mobile_ad->Title, 'title', 'can get title');
};

1;
