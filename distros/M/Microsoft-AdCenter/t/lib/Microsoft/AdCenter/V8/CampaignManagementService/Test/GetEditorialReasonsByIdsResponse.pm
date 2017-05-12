package Microsoft::AdCenter::V8::CampaignManagementService::Test::GetEditorialReasonsByIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::GetEditorialReasonsByIdsResponse;

sub test_can_create_get_editorial_reasons_by_ids_response_and_set_all_fields : Test(2) {
    my $get_editorial_reasons_by_ids_response = Microsoft::AdCenter::V8::CampaignManagementService::GetEditorialReasonsByIdsResponse->new
        ->EditorialReasons('editorial reasons')
    ;

    ok($get_editorial_reasons_by_ids_response);

    is($get_editorial_reasons_by_ids_response->EditorialReasons, 'editorial reasons', 'can get editorial reasons');
};

1;
