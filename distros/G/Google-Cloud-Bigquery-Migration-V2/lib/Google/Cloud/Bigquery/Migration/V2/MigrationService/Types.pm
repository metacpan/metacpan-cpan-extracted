package Google::Cloud::Bigquery::Migration::V2::MigrationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateMigrationWorkflowRequest',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationService::CreateMigrationWorkflowRequest'];

coerce 'CreateMigrationWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::CreateMigrationWorkflowRequest'->new($_) };

declare 'RepeatedCreateMigrationWorkflowRequest',
    as ArrayRef[CreateMigrationWorkflowRequest()];

coerce 'RepeatedCreateMigrationWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::CreateMigrationWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMigrationWorkflowRequest',
    as HashRef[CreateMigrationWorkflowRequest()];

declare 'GetMigrationWorkflowRequest',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationWorkflowRequest'];

coerce 'GetMigrationWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationWorkflowRequest'->new($_) };

declare 'RepeatedGetMigrationWorkflowRequest',
    as ArrayRef[GetMigrationWorkflowRequest()];

coerce 'RepeatedGetMigrationWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringGetMigrationWorkflowRequest',
    as HashRef[GetMigrationWorkflowRequest()];

declare 'ListMigrationWorkflowsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsRequest'];

coerce 'ListMigrationWorkflowsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsRequest'->new($_) };

declare 'RepeatedListMigrationWorkflowsRequest',
    as ArrayRef[ListMigrationWorkflowsRequest()];

coerce 'RepeatedListMigrationWorkflowsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsRequest'->new($_) } @$_ ] };

declare 'MapStringListMigrationWorkflowsRequest',
    as HashRef[ListMigrationWorkflowsRequest()];

declare 'ListMigrationWorkflowsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsResponse'];

coerce 'ListMigrationWorkflowsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsResponse'->new($_) };

declare 'RepeatedListMigrationWorkflowsResponse',
    as ArrayRef[ListMigrationWorkflowsResponse()];

coerce 'RepeatedListMigrationWorkflowsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationWorkflowsResponse'->new($_) } @$_ ] };

declare 'MapStringListMigrationWorkflowsResponse',
    as HashRef[ListMigrationWorkflowsResponse()];

declare 'DeleteMigrationWorkflowRequest',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationService::DeleteMigrationWorkflowRequest'];

coerce 'DeleteMigrationWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::DeleteMigrationWorkflowRequest'->new($_) };

declare 'RepeatedDeleteMigrationWorkflowRequest',
    as ArrayRef[DeleteMigrationWorkflowRequest()];

coerce 'RepeatedDeleteMigrationWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::DeleteMigrationWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMigrationWorkflowRequest',
    as HashRef[DeleteMigrationWorkflowRequest()];

declare 'StartMigrationWorkflowRequest',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationService::StartMigrationWorkflowRequest'];

coerce 'StartMigrationWorkflowRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::StartMigrationWorkflowRequest'->new($_) };

declare 'RepeatedStartMigrationWorkflowRequest',
    as ArrayRef[StartMigrationWorkflowRequest()];

coerce 'RepeatedStartMigrationWorkflowRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::StartMigrationWorkflowRequest'->new($_) } @$_ ] };

declare 'MapStringStartMigrationWorkflowRequest',
    as HashRef[StartMigrationWorkflowRequest()];

declare 'GetMigrationSubtaskRequest',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationSubtaskRequest'];

coerce 'GetMigrationSubtaskRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationSubtaskRequest'->new($_) };

declare 'RepeatedGetMigrationSubtaskRequest',
    as ArrayRef[GetMigrationSubtaskRequest()];

coerce 'RepeatedGetMigrationSubtaskRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::GetMigrationSubtaskRequest'->new($_) } @$_ ] };

declare 'MapStringGetMigrationSubtaskRequest',
    as HashRef[GetMigrationSubtaskRequest()];

declare 'ListMigrationSubtasksRequest',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksRequest'];

coerce 'ListMigrationSubtasksRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksRequest'->new($_) };

declare 'RepeatedListMigrationSubtasksRequest',
    as ArrayRef[ListMigrationSubtasksRequest()];

coerce 'RepeatedListMigrationSubtasksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksRequest'->new($_) } @$_ ] };

declare 'MapStringListMigrationSubtasksRequest',
    as HashRef[ListMigrationSubtasksRequest()];

declare 'ListMigrationSubtasksResponse',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksResponse'];

coerce 'ListMigrationSubtasksResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksResponse'->new($_) };

declare 'RepeatedListMigrationSubtasksResponse',
    as ArrayRef[ListMigrationSubtasksResponse()];

coerce 'RepeatedListMigrationSubtasksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2::MigrationService::ListMigrationSubtasksResponse'->new($_) } @$_ ] };

declare 'MapStringListMigrationSubtasksResponse',
    as HashRef[ListMigrationSubtasksResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::MigrationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
