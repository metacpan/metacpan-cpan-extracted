package Microsoft::AdCenter::V7::CampaignManagementService::Test::MigrationStatusInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::MigrationStatusInfo;

sub test_can_create_migration_status_info_and_set_all_fields : Test(4) {
    my $migration_status_info = Microsoft::AdCenter::V7::CampaignManagementService::MigrationStatusInfo->new
        ->MigrationType('migration type')
        ->StartTimeInUtc('2010-05-31T12:23:34')
        ->Status('status')
    ;

    ok($migration_status_info);

    is($migration_status_info->MigrationType, 'migration type', 'can get migration type');
    is($migration_status_info->StartTimeInUtc, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($migration_status_info->Status, 'status', 'can get status');
};

1;
