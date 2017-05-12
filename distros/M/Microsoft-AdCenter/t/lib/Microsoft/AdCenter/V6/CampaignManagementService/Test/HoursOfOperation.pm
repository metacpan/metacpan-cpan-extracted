package Microsoft::AdCenter::V6::CampaignManagementService::Test::HoursOfOperation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::HoursOfOperation;

sub test_can_create_hours_of_operation_and_set_all_fields : Test(4) {
    my $hours_of_operation = Microsoft::AdCenter::V6::CampaignManagementService::HoursOfOperation->new
        ->Day('day')
        ->openTime1('open time1')
        ->openTime2('open time2')
    ;

    ok($hours_of_operation);

    is($hours_of_operation->Day, 'day', 'can get day');
    is($hours_of_operation->openTime1, 'open time1', 'can get open time1');
    is($hours_of_operation->openTime2, 'open time2', 'can get open time2');
};

1;
