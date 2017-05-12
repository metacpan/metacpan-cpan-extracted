package Microsoft::AdCenter::V8::CampaignManagementService::Test::AccountMigrationStatusesInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AccountMigrationStatusesInfo;

sub test_can_create_account_migration_statuses_info_and_set_all_fields : Test(3) {
    my $account_migration_statuses_info = Microsoft::AdCenter::V8::CampaignManagementService::AccountMigrationStatusesInfo->new
        ->AccountId('account id')
        ->MigrationStatusInfo('migration status info')
    ;

    ok($account_migration_statuses_info);

    is($account_migration_statuses_info->AccountId, 'account id', 'can get account id');
    is($account_migration_statuses_info->MigrationStatusInfo, 'migration status info', 'can get migration status info');
};

1;
