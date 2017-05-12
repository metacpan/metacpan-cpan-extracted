package Microsoft::AdCenter::V8::CampaignManagementService::Test::SiteLink;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::SiteLink;

sub test_can_create_site_link_and_set_all_fields : Test(3) {
    my $site_link = Microsoft::AdCenter::V8::CampaignManagementService::SiteLink->new
        ->DestinationUrl('destination url')
        ->DisplayText('display text')
    ;

    ok($site_link);

    is($site_link->DestinationUrl, 'destination url', 'can get destination url');
    is($site_link->DisplayText, 'display text', 'can get display text');
};

1;
