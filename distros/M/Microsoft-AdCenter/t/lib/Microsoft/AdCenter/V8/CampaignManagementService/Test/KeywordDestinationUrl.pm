package Microsoft::AdCenter::V8::CampaignManagementService::Test::KeywordDestinationUrl;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::KeywordDestinationUrl;

sub test_can_create_keyword_destination_url_and_set_all_fields : Test(3) {
    my $keyword_destination_url = Microsoft::AdCenter::V8::CampaignManagementService::KeywordDestinationUrl->new
        ->DestinationUrl('destination url')
        ->KeywordId('keyword id')
    ;

    ok($keyword_destination_url);

    is($keyword_destination_url->DestinationUrl, 'destination url', 'can get destination url');
    is($keyword_destination_url->KeywordId, 'keyword id', 'can get keyword id');
};

1;
