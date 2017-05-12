package Microsoft::AdCenter::V8::CampaignManagementService::Test::AdExtensionEditorialReasonCollection;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AdExtensionEditorialReasonCollection;

sub test_can_create_ad_extension_editorial_reason_collection_and_set_all_fields : Test(3) {
    my $ad_extension_editorial_reason_collection = Microsoft::AdCenter::V8::CampaignManagementService::AdExtensionEditorialReasonCollection->new
        ->AdExtensionId('ad extension id')
        ->Reasons('reasons')
    ;

    ok($ad_extension_editorial_reason_collection);

    is($ad_extension_editorial_reason_collection->AdExtensionId, 'ad extension id', 'can get ad extension id');
    is($ad_extension_editorial_reason_collection->Reasons, 'reasons', 'can get reasons');
};

1;
