package Microsoft::AdCenter::V8::CampaignManagementService::Test::DeleteTargetResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::DeleteTargetResponse;

sub test_can_create_delete_target_response_and_set_all_fields : Test(1) {
    my $delete_target_response = Microsoft::AdCenter::V8::CampaignManagementService::DeleteTargetResponse->new
    ;

    ok($delete_target_response);

};

1;
