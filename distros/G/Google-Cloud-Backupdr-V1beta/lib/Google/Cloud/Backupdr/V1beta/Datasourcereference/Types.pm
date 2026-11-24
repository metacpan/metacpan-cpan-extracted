package Google::Cloud::Backupdr::V1beta::Datasourcereference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataSourceReference',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceReference'];

coerce 'DataSourceReference',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceReference'->new($_) };

declare 'RepeatedDataSourceReference',
    as ArrayRef[DataSourceReference()];

coerce 'RepeatedDataSourceReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceReference'->new($_) } @$_ ] };

declare 'MapStringDataSourceReference',
    as HashRef[DataSourceReference()];

declare 'DataSourceBackupConfigInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceBackupConfigInfo'];

coerce 'DataSourceBackupConfigInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceBackupConfigInfo'->new($_) };

declare 'RepeatedDataSourceBackupConfigInfo',
    as ArrayRef[DataSourceBackupConfigInfo()];

coerce 'RepeatedDataSourceBackupConfigInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceBackupConfigInfo'->new($_) } @$_ ] };

declare 'MapStringDataSourceBackupConfigInfo',
    as HashRef[DataSourceBackupConfigInfo()];

declare 'DataSourceGcpResourceInfo',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceGcpResourceInfo'];

coerce 'DataSourceGcpResourceInfo',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceGcpResourceInfo'->new($_) };

declare 'RepeatedDataSourceGcpResourceInfo',
    as ArrayRef[DataSourceGcpResourceInfo()];

coerce 'RepeatedDataSourceGcpResourceInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::DataSourceGcpResourceInfo'->new($_) } @$_ ] };

declare 'MapStringDataSourceGcpResourceInfo',
    as HashRef[DataSourceGcpResourceInfo()];

declare 'GetDataSourceReferenceRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Datasourcereference::GetDataSourceReferenceRequest'];

coerce 'GetDataSourceReferenceRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::GetDataSourceReferenceRequest'->new($_) };

declare 'RepeatedGetDataSourceReferenceRequest',
    as ArrayRef[GetDataSourceReferenceRequest()];

coerce 'RepeatedGetDataSourceReferenceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::GetDataSourceReferenceRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataSourceReferenceRequest',
    as HashRef[GetDataSourceReferenceRequest()];

declare 'ListDataSourceReferencesRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Datasourcereference::ListDataSourceReferencesRequest'];

coerce 'ListDataSourceReferencesRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::ListDataSourceReferencesRequest'->new($_) };

declare 'RepeatedListDataSourceReferencesRequest',
    as ArrayRef[ListDataSourceReferencesRequest()];

coerce 'RepeatedListDataSourceReferencesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::ListDataSourceReferencesRequest'->new($_) } @$_ ] };

declare 'MapStringListDataSourceReferencesRequest',
    as HashRef[ListDataSourceReferencesRequest()];

declare 'ListDataSourceReferencesResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Datasourcereference::ListDataSourceReferencesResponse'];

coerce 'ListDataSourceReferencesResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::ListDataSourceReferencesResponse'->new($_) };

declare 'RepeatedListDataSourceReferencesResponse',
    as ArrayRef[ListDataSourceReferencesResponse()];

coerce 'RepeatedListDataSourceReferencesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::ListDataSourceReferencesResponse'->new($_) } @$_ ] };

declare 'MapStringListDataSourceReferencesResponse',
    as HashRef[ListDataSourceReferencesResponse()];

declare 'FetchDataSourceReferencesForResourceTypeRequest',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Datasourcereference::FetchDataSourceReferencesForResourceTypeRequest'];

coerce 'FetchDataSourceReferencesForResourceTypeRequest',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::FetchDataSourceReferencesForResourceTypeRequest'->new($_) };

declare 'RepeatedFetchDataSourceReferencesForResourceTypeRequest',
    as ArrayRef[FetchDataSourceReferencesForResourceTypeRequest()];

coerce 'RepeatedFetchDataSourceReferencesForResourceTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::FetchDataSourceReferencesForResourceTypeRequest'->new($_) } @$_ ] };

declare 'MapStringFetchDataSourceReferencesForResourceTypeRequest',
    as HashRef[FetchDataSourceReferencesForResourceTypeRequest()];

declare 'FetchDataSourceReferencesForResourceTypeResponse',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::Datasourcereference::FetchDataSourceReferencesForResourceTypeResponse'];

coerce 'FetchDataSourceReferencesForResourceTypeResponse',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::FetchDataSourceReferencesForResourceTypeResponse'->new($_) };

declare 'RepeatedFetchDataSourceReferencesForResourceTypeResponse',
    as ArrayRef[FetchDataSourceReferencesForResourceTypeResponse()];

coerce 'RepeatedFetchDataSourceReferencesForResourceTypeResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::Datasourcereference::FetchDataSourceReferencesForResourceTypeResponse'->new($_) } @$_ ] };

declare 'MapStringFetchDataSourceReferencesForResourceTypeResponse',
    as HashRef[FetchDataSourceReferencesForResourceTypeResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta::Datasourcereference::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
