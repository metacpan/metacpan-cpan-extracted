package Microsoft::AdCenter::V8::CampaignManagementService::Test::SiteLinksAdExtension;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::SiteLinksAdExtension;

sub test_can_create_site_links_ad_extension_and_set_all_fields : Test(2) {
    my $site_links_ad_extension = Microsoft::AdCenter::V8::CampaignManagementService::SiteLinksAdExtension->new
        ->SiteLinks('site links')
    ;

    ok($site_links_ad_extension);

    is($site_links_ad_extension->SiteLinks, 'site links', 'can get site links');
};

1;
