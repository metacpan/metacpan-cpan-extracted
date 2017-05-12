package Microsoft::AdCenter::V8::CampaignManagementService::Test::PublisherCountry;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::PublisherCountry;

sub test_can_create_publisher_country_and_set_all_fields : Test(3) {
    my $publisher_country = Microsoft::AdCenter::V8::CampaignManagementService::PublisherCountry->new
        ->Country('country')
        ->IsOptedIn('is opted in')
    ;

    ok($publisher_country);

    is($publisher_country->Country, 'country', 'can get country');
    is($publisher_country->IsOptedIn, 'is opted in', 'can get is opted in');
};

1;
