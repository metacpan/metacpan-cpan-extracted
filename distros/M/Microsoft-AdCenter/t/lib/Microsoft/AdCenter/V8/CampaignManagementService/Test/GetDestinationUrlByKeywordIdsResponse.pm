package Microsoft::AdCenter::V8::CampaignManagementService::Test::GetDestinationUrlByKeywordIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::GetDestinationUrlByKeywordIdsResponse;

sub test_can_create_get_destination_url_by_keyword_ids_response_and_set_all_fields : Test(2) {
    my $get_destination_url_by_keyword_ids_response = Microsoft::AdCenter::V8::CampaignManagementService::GetDestinationUrlByKeywordIdsResponse->new
        ->DestinationUrls('destination urls')
    ;

    ok($get_destination_url_by_keyword_ids_response);

    is($get_destination_url_by_keyword_ids_response->DestinationUrls, 'destination urls', 'can get destination urls');
};

1;
