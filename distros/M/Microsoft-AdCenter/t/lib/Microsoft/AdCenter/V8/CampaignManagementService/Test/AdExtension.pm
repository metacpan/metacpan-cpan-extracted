package Microsoft::AdCenter::V8::CampaignManagementService::Test::AdExtension;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AdExtension;

sub test_can_create_ad_extension_and_set_all_fields : Test(4) {
    my $ad_extension = Microsoft::AdCenter::V8::CampaignManagementService::AdExtension->new
        ->CampaignId('campaign id')
        ->EnableLocationExtension('enable location extension')
        ->PhoneExtension('phone extension')
    ;

    ok($ad_extension);

    is($ad_extension->CampaignId, 'campaign id', 'can get campaign id');
    is($ad_extension->EnableLocationExtension, 'enable location extension', 'can get enable location extension');
    is($ad_extension->PhoneExtension, 'phone extension', 'can get phone extension');
};

1;
