package Microsoft::AdCenter::V6::AdministrationService::Test::GetAssignedQuotaResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::AdministrationService;
use Microsoft::AdCenter::V6::AdministrationService::GetAssignedQuotaResponse;

sub test_can_create_get_assigned_quota_response_and_set_all_fields : Test(2) {
    my $get_assigned_quota_response = Microsoft::AdCenter::V6::AdministrationService::GetAssignedQuotaResponse->new
        ->AssignedQuota('assigned quota')
    ;

    ok($get_assigned_quota_response);

    is($get_assigned_quota_response->AssignedQuota, 'assigned quota', 'can get assigned quota');
};

1;
