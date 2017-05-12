package Microsoft::AdCenter::V8::CampaignManagementService::Test::AdExtensionEditorialReason;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AdExtensionEditorialReason;

sub test_can_create_ad_extension_editorial_reason_and_set_all_fields : Test(5) {
    my $ad_extension_editorial_reason = Microsoft::AdCenter::V8::CampaignManagementService::AdExtensionEditorialReason->new
        ->Location('location')
        ->PublisherCountries('publisher countries')
        ->ReasonCode('reason code')
        ->Term('term')
    ;

    ok($ad_extension_editorial_reason);

    is($ad_extension_editorial_reason->Location, 'location', 'can get location');
    is($ad_extension_editorial_reason->PublisherCountries, 'publisher countries', 'can get publisher countries');
    is($ad_extension_editorial_reason->ReasonCode, 'reason code', 'can get reason code');
    is($ad_extension_editorial_reason->Term, 'term', 'can get term');
};

1;
