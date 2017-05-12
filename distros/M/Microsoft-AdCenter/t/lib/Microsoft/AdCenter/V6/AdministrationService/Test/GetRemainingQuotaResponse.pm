package Microsoft::AdCenter::V6::AdministrationService::Test::GetRemainingQuotaResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::AdministrationService;
use Microsoft::AdCenter::V6::AdministrationService::GetRemainingQuotaResponse;

sub test_can_create_get_remaining_quota_response_and_set_all_fields : Test(2) {
    my $get_remaining_quota_response = Microsoft::AdCenter::V6::AdministrationService::GetRemainingQuotaResponse->new
        ->RemainingQuota('remaining quota')
    ;

    ok($get_remaining_quota_response);

    is($get_remaining_quota_response->RemainingQuota, 'remaining quota', 'can get remaining quota');
};

1;
