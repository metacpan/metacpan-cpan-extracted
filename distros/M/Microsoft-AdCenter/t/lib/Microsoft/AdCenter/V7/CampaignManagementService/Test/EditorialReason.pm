package Microsoft::AdCenter::V7::CampaignManagementService::Test::EditorialReason;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::EditorialReason;

sub test_can_create_editorial_reason_and_set_all_fields : Test(4) {
    my $editorial_reason = Microsoft::AdCenter::V7::CampaignManagementService::EditorialReason->new
        ->Location('location')
        ->ReasonCode('reason code')
        ->Term('term')
    ;

    ok($editorial_reason);

    is($editorial_reason->Location, 'location', 'can get location');
    is($editorial_reason->ReasonCode, 'reason code', 'can get reason code');
    is($editorial_reason->Term, 'term', 'can get term');
};

1;
