package Google::Cloud::Oracledatabase::V1::PluggableDatabase::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PluggableDatabase',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabase'];

coerce 'PluggableDatabase',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabase'->new($_) };

declare 'RepeatedPluggableDatabase',
    as ArrayRef[PluggableDatabase()];

coerce 'RepeatedPluggableDatabase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabase'->new($_) } @$_ ] };

declare 'MapStringPluggableDatabase',
    as HashRef[PluggableDatabase()];

declare 'PluggableDatabaseProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties'];

coerce 'PluggableDatabaseProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties'->new($_) };

declare 'RepeatedPluggableDatabaseProperties',
    as ArrayRef[PluggableDatabaseProperties()];

coerce 'RepeatedPluggableDatabaseProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties'->new($_) } @$_ ] };

declare 'MapStringPluggableDatabaseProperties',
    as HashRef[PluggableDatabaseProperties()];

declare 'PluggableDatabaseLifecycleState',
    as (Int | Str);

declare 'OperationsInsightsState',
    as (Int | Str);

declare 'DefinedTagValue',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::DefinedTagValue'];

coerce 'DefinedTagValue',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::DefinedTagValue'->new($_) };

declare 'RepeatedDefinedTagValue',
    as ArrayRef[DefinedTagValue()];

coerce 'RepeatedDefinedTagValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::DefinedTagValue'->new($_) } @$_ ] };

declare 'MapStringDefinedTagValue',
    as HashRef[DefinedTagValue()];

declare 'TagsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::DefinedTagValue::TagsEntry'];

coerce 'TagsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::DefinedTagValue::TagsEntry'->new($_) };

declare 'RepeatedTagsEntry',
    as ArrayRef[TagsEntry()];

coerce 'RepeatedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::DefinedTagValue::TagsEntry'->new($_) } @$_ ] };

declare 'MapStringTagsEntry',
    as HashRef[TagsEntry()];

declare 'DefinedTagsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::DefinedTagsEntry'];

coerce 'DefinedTagsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::DefinedTagsEntry'->new($_) };

declare 'RepeatedDefinedTagsEntry',
    as ArrayRef[DefinedTagsEntry()];

coerce 'RepeatedDefinedTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::DefinedTagsEntry'->new($_) } @$_ ] };

declare 'MapStringDefinedTagsEntry',
    as HashRef[DefinedTagsEntry()];

declare 'FreeformTagsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::FreeformTagsEntry'];

coerce 'FreeformTagsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::FreeformTagsEntry'->new($_) };

declare 'RepeatedFreeformTagsEntry',
    as ArrayRef[FreeformTagsEntry()];

coerce 'RepeatedFreeformTagsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseProperties::FreeformTagsEntry'->new($_) } @$_ ] };

declare 'MapStringFreeformTagsEntry',
    as HashRef[FreeformTagsEntry()];

declare 'PluggableDatabaseConnectionStrings',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseConnectionStrings'];

coerce 'PluggableDatabaseConnectionStrings',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseConnectionStrings'->new($_) };

declare 'RepeatedPluggableDatabaseConnectionStrings',
    as ArrayRef[PluggableDatabaseConnectionStrings()];

coerce 'RepeatedPluggableDatabaseConnectionStrings',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseConnectionStrings'->new($_) } @$_ ] };

declare 'MapStringPluggableDatabaseConnectionStrings',
    as HashRef[PluggableDatabaseConnectionStrings()];

declare 'AllConnectionStringsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseConnectionStrings::AllConnectionStringsEntry'];

coerce 'AllConnectionStringsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseConnectionStrings::AllConnectionStringsEntry'->new($_) };

declare 'RepeatedAllConnectionStringsEntry',
    as ArrayRef[AllConnectionStringsEntry()];

coerce 'RepeatedAllConnectionStringsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseConnectionStrings::AllConnectionStringsEntry'->new($_) } @$_ ] };

declare 'MapStringAllConnectionStringsEntry',
    as HashRef[AllConnectionStringsEntry()];

declare 'PluggableDatabaseNodeLevelDetails',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseNodeLevelDetails'];

coerce 'PluggableDatabaseNodeLevelDetails',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseNodeLevelDetails'->new($_) };

declare 'RepeatedPluggableDatabaseNodeLevelDetails',
    as ArrayRef[PluggableDatabaseNodeLevelDetails()];

coerce 'RepeatedPluggableDatabaseNodeLevelDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::PluggableDatabaseNodeLevelDetails'->new($_) } @$_ ] };

declare 'MapStringPluggableDatabaseNodeLevelDetails',
    as HashRef[PluggableDatabaseNodeLevelDetails()];

declare 'PluggableDatabaseOpenMode',
    as (Int | Str);

declare 'DatabaseManagementConfig',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::DatabaseManagementConfig'];

coerce 'DatabaseManagementConfig',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::DatabaseManagementConfig'->new($_) };

declare 'RepeatedDatabaseManagementConfig',
    as ArrayRef[DatabaseManagementConfig()];

coerce 'RepeatedDatabaseManagementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::DatabaseManagementConfig'->new($_) } @$_ ] };

declare 'MapStringDatabaseManagementConfig',
    as HashRef[DatabaseManagementConfig()];

declare 'ManagementState',
    as (Int | Str);

declare 'ManagementType',
    as (Int | Str);

declare 'GetPluggableDatabaseRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::GetPluggableDatabaseRequest'];

coerce 'GetPluggableDatabaseRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::GetPluggableDatabaseRequest'->new($_) };

declare 'RepeatedGetPluggableDatabaseRequest',
    as ArrayRef[GetPluggableDatabaseRequest()];

coerce 'RepeatedGetPluggableDatabaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::GetPluggableDatabaseRequest'->new($_) } @$_ ] };

declare 'MapStringGetPluggableDatabaseRequest',
    as HashRef[GetPluggableDatabaseRequest()];

declare 'ListPluggableDatabasesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::ListPluggableDatabasesRequest'];

coerce 'ListPluggableDatabasesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::ListPluggableDatabasesRequest'->new($_) };

declare 'RepeatedListPluggableDatabasesRequest',
    as ArrayRef[ListPluggableDatabasesRequest()];

coerce 'RepeatedListPluggableDatabasesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::ListPluggableDatabasesRequest'->new($_) } @$_ ] };

declare 'MapStringListPluggableDatabasesRequest',
    as HashRef[ListPluggableDatabasesRequest()];

declare 'ListPluggableDatabasesResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::PluggableDatabase::ListPluggableDatabasesResponse'];

coerce 'ListPluggableDatabasesResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::ListPluggableDatabasesResponse'->new($_) };

declare 'RepeatedListPluggableDatabasesResponse',
    as ArrayRef[ListPluggableDatabasesResponse()];

coerce 'RepeatedListPluggableDatabasesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::PluggableDatabase::ListPluggableDatabasesResponse'->new($_) } @$_ ] };

declare 'MapStringListPluggableDatabasesResponse',
    as HashRef[ListPluggableDatabasesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::PluggableDatabase::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
