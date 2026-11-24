package Google::Cloud::Oracledatabase::V1::DatabaseConnection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatabaseConnection',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection'];

coerce 'DatabaseConnection',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection'->new($_) };

declare 'RepeatedDatabaseConnection',
    as ArrayRef[DatabaseConnection()];

coerce 'RepeatedDatabaseConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection'->new($_) } @$_ ] };

declare 'MapStringDatabaseConnection',
    as HashRef[DatabaseConnection()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::DatabaseConnection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'CreateDatabaseConnectionRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseConnection::CreateDatabaseConnectionRequest'];

coerce 'CreateDatabaseConnectionRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::CreateDatabaseConnectionRequest'->new($_) };

declare 'RepeatedCreateDatabaseConnectionRequest',
    as ArrayRef[CreateDatabaseConnectionRequest()];

coerce 'RepeatedCreateDatabaseConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::CreateDatabaseConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDatabaseConnectionRequest',
    as HashRef[CreateDatabaseConnectionRequest()];

declare 'DeleteDatabaseConnectionRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseConnection::DeleteDatabaseConnectionRequest'];

coerce 'DeleteDatabaseConnectionRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::DeleteDatabaseConnectionRequest'->new($_) };

declare 'RepeatedDeleteDatabaseConnectionRequest',
    as ArrayRef[DeleteDatabaseConnectionRequest()];

coerce 'RepeatedDeleteDatabaseConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::DeleteDatabaseConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDatabaseConnectionRequest',
    as HashRef[DeleteDatabaseConnectionRequest()];

declare 'ListDatabaseConnectionsRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseConnection::ListDatabaseConnectionsRequest'];

coerce 'ListDatabaseConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::ListDatabaseConnectionsRequest'->new($_) };

declare 'RepeatedListDatabaseConnectionsRequest',
    as ArrayRef[ListDatabaseConnectionsRequest()];

coerce 'RepeatedListDatabaseConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::ListDatabaseConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListDatabaseConnectionsRequest',
    as HashRef[ListDatabaseConnectionsRequest()];

declare 'ListDatabaseConnectionsResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseConnection::ListDatabaseConnectionsResponse'];

coerce 'ListDatabaseConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::ListDatabaseConnectionsResponse'->new($_) };

declare 'RepeatedListDatabaseConnectionsResponse',
    as ArrayRef[ListDatabaseConnectionsResponse()];

coerce 'RepeatedListDatabaseConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::ListDatabaseConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListDatabaseConnectionsResponse',
    as HashRef[ListDatabaseConnectionsResponse()];

declare 'GetDatabaseConnectionRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseConnection::GetDatabaseConnectionRequest'];

coerce 'GetDatabaseConnectionRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::GetDatabaseConnectionRequest'->new($_) };

declare 'RepeatedGetDatabaseConnectionRequest',
    as ArrayRef[GetDatabaseConnectionRequest()];

coerce 'RepeatedGetDatabaseConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::GetDatabaseConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetDatabaseConnectionRequest',
    as HashRef[GetDatabaseConnectionRequest()];

declare 'UpdateDatabaseConnectionRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseConnection::UpdateDatabaseConnectionRequest'];

coerce 'UpdateDatabaseConnectionRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::UpdateDatabaseConnectionRequest'->new($_) };

declare 'RepeatedUpdateDatabaseConnectionRequest',
    as ArrayRef[UpdateDatabaseConnectionRequest()];

coerce 'RepeatedUpdateDatabaseConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::UpdateDatabaseConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDatabaseConnectionRequest',
    as HashRef[UpdateDatabaseConnectionRequest()];

declare 'TestDatabaseConnectionRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseConnection::TestDatabaseConnectionRequest'];

coerce 'TestDatabaseConnectionRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::TestDatabaseConnectionRequest'->new($_) };

declare 'RepeatedTestDatabaseConnectionRequest',
    as ArrayRef[TestDatabaseConnectionRequest()];

coerce 'RepeatedTestDatabaseConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::TestDatabaseConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringTestDatabaseConnectionRequest',
    as HashRef[TestDatabaseConnectionRequest()];

declare 'TestDatabaseConnectionResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DatabaseConnection::TestDatabaseConnectionResponse'];

coerce 'TestDatabaseConnectionResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::TestDatabaseConnectionResponse'->new($_) };

declare 'RepeatedTestDatabaseConnectionResponse',
    as ArrayRef[TestDatabaseConnectionResponse()];

coerce 'RepeatedTestDatabaseConnectionResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DatabaseConnection::TestDatabaseConnectionResponse'->new($_) } @$_ ] };

declare 'MapStringTestDatabaseConnectionResponse',
    as HashRef[TestDatabaseConnectionResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::DatabaseConnection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
