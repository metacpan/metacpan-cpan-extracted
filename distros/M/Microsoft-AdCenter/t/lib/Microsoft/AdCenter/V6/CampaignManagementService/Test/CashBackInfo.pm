package Microsoft::AdCenter::V6::CampaignManagementService::Test::CashBackInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::CashBackInfo;

sub test_can_create_cash_back_info_and_set_all_fields : Test(4) {
    my $cash_back_info = Microsoft::AdCenter::V6::CampaignManagementService::CashBackInfo->new
        ->CashBackAmount('cash back amount')
        ->CashBackStatus('cash back status')
        ->CashBackText('cash back text')
    ;

    ok($cash_back_info);

    is($cash_back_info->CashBackAmount, 'cash back amount', 'can get cash back amount');
    is($cash_back_info->CashBackStatus, 'cash back status', 'can get cash back status');
    is($cash_back_info->CashBackText, 'cash back text', 'can get cash back text');
};

1;
