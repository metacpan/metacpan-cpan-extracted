package Microsoft::AdCenter::V8::CampaignManagementService::Test::AdRotation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AdRotation;

sub test_can_create_ad_rotation_and_set_all_fields : Test(4) {
    my $ad_rotation = Microsoft::AdCenter::V8::CampaignManagementService::AdRotation->new
        ->EndDate('2010-05-31T12:23:34')
        ->StartDate('2010-06-01T12:23:34')
        ->Type('type')
    ;

    ok($ad_rotation);

    is($ad_rotation->EndDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($ad_rotation->StartDate, '2010-06-01T12:23:34', 'can get 2010-06-01T12:23:34');
    is($ad_rotation->Type, 'type', 'can get type');
};

1;
