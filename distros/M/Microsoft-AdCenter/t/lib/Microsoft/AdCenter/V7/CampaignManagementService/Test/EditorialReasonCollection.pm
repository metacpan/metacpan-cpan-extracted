package Microsoft::AdCenter::V7::CampaignManagementService::Test::EditorialReasonCollection;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::EditorialReasonCollection;

sub test_can_create_editorial_reason_collection_and_set_all_fields : Test(3) {
    my $editorial_reason_collection = Microsoft::AdCenter::V7::CampaignManagementService::EditorialReasonCollection->new
        ->AdOrKeywordId('ad or keyword id')
        ->Reasons('reasons')
    ;

    ok($editorial_reason_collection);

    is($editorial_reason_collection->AdOrKeywordId, 'ad or keyword id', 'can get ad or keyword id');
    is($editorial_reason_collection->Reasons, 'reasons', 'can get reasons');
};

1;
