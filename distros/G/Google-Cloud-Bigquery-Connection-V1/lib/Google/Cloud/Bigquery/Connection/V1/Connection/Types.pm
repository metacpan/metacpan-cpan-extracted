package Google::Cloud::Bigquery::Connection::V1::Connection::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateConnectionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::CreateConnectionRequest'];

coerce 'CreateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::CreateConnectionRequest'->new($_) };

declare 'RepeatedCreateConnectionRequest',
    as ArrayRef[CreateConnectionRequest()];

coerce 'RepeatedCreateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::CreateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateConnectionRequest',
    as HashRef[CreateConnectionRequest()];

declare 'GetConnectionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::GetConnectionRequest'];

coerce 'GetConnectionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::GetConnectionRequest'->new($_) };

declare 'RepeatedGetConnectionRequest',
    as ArrayRef[GetConnectionRequest()];

coerce 'RepeatedGetConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::GetConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetConnectionRequest',
    as HashRef[GetConnectionRequest()];

declare 'ListConnectionsRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::ListConnectionsRequest'];

coerce 'ListConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::ListConnectionsRequest'->new($_) };

declare 'RepeatedListConnectionsRequest',
    as ArrayRef[ListConnectionsRequest()];

coerce 'RepeatedListConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::ListConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListConnectionsRequest',
    as HashRef[ListConnectionsRequest()];

declare 'ListConnectionsResponse',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::ListConnectionsResponse'];

coerce 'ListConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::ListConnectionsResponse'->new($_) };

declare 'RepeatedListConnectionsResponse',
    as ArrayRef[ListConnectionsResponse()];

coerce 'RepeatedListConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::ListConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListConnectionsResponse',
    as HashRef[ListConnectionsResponse()];

declare 'UpdateConnectionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::UpdateConnectionRequest'];

coerce 'UpdateConnectionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::UpdateConnectionRequest'->new($_) };

declare 'RepeatedUpdateConnectionRequest',
    as ArrayRef[UpdateConnectionRequest()];

coerce 'RepeatedUpdateConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::UpdateConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateConnectionRequest',
    as HashRef[UpdateConnectionRequest()];

declare 'DeleteConnectionRequest',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::DeleteConnectionRequest'];

coerce 'DeleteConnectionRequest',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::DeleteConnectionRequest'->new($_) };

declare 'RepeatedDeleteConnectionRequest',
    as ArrayRef[DeleteConnectionRequest()];

coerce 'RepeatedDeleteConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::DeleteConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteConnectionRequest',
    as HashRef[DeleteConnectionRequest()];

declare 'Connection',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::Connection'];

coerce 'Connection',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::Connection'->new($_) };

declare 'RepeatedConnection',
    as ArrayRef[Connection()];

coerce 'RepeatedConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::Connection'->new($_) } @$_ ] };

declare 'MapStringConnection',
    as HashRef[Connection()];

declare 'CloudSqlProperties',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::CloudSqlProperties'];

coerce 'CloudSqlProperties',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::CloudSqlProperties'->new($_) };

declare 'RepeatedCloudSqlProperties',
    as ArrayRef[CloudSqlProperties()];

coerce 'RepeatedCloudSqlProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::CloudSqlProperties'->new($_) } @$_ ] };

declare 'MapStringCloudSqlProperties',
    as HashRef[CloudSqlProperties()];

declare 'DatabaseType',
    as (Int | Str);

declare 'CloudSqlCredential',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::CloudSqlCredential'];

coerce 'CloudSqlCredential',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::CloudSqlCredential'->new($_) };

declare 'RepeatedCloudSqlCredential',
    as ArrayRef[CloudSqlCredential()];

coerce 'RepeatedCloudSqlCredential',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::CloudSqlCredential'->new($_) } @$_ ] };

declare 'MapStringCloudSqlCredential',
    as HashRef[CloudSqlCredential()];

declare 'CloudSpannerProperties',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::CloudSpannerProperties'];

coerce 'CloudSpannerProperties',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::CloudSpannerProperties'->new($_) };

declare 'RepeatedCloudSpannerProperties',
    as ArrayRef[CloudSpannerProperties()];

coerce 'RepeatedCloudSpannerProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::CloudSpannerProperties'->new($_) } @$_ ] };

declare 'MapStringCloudSpannerProperties',
    as HashRef[CloudSpannerProperties()];

declare 'AwsProperties',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::AwsProperties'];

coerce 'AwsProperties',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::AwsProperties'->new($_) };

declare 'RepeatedAwsProperties',
    as ArrayRef[AwsProperties()];

coerce 'RepeatedAwsProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::AwsProperties'->new($_) } @$_ ] };

declare 'MapStringAwsProperties',
    as HashRef[AwsProperties()];

declare 'AwsCrossAccountRole',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::AwsCrossAccountRole'];

coerce 'AwsCrossAccountRole',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::AwsCrossAccountRole'->new($_) };

declare 'RepeatedAwsCrossAccountRole',
    as ArrayRef[AwsCrossAccountRole()];

coerce 'RepeatedAwsCrossAccountRole',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::AwsCrossAccountRole'->new($_) } @$_ ] };

declare 'MapStringAwsCrossAccountRole',
    as HashRef[AwsCrossAccountRole()];

declare 'AwsAccessRole',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::AwsAccessRole'];

coerce 'AwsAccessRole',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::AwsAccessRole'->new($_) };

declare 'RepeatedAwsAccessRole',
    as ArrayRef[AwsAccessRole()];

coerce 'RepeatedAwsAccessRole',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::AwsAccessRole'->new($_) } @$_ ] };

declare 'MapStringAwsAccessRole',
    as HashRef[AwsAccessRole()];

declare 'AzureProperties',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::AzureProperties'];

coerce 'AzureProperties',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::AzureProperties'->new($_) };

declare 'RepeatedAzureProperties',
    as ArrayRef[AzureProperties()];

coerce 'RepeatedAzureProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::AzureProperties'->new($_) } @$_ ] };

declare 'MapStringAzureProperties',
    as HashRef[AzureProperties()];

declare 'CloudResourceProperties',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::CloudResourceProperties'];

coerce 'CloudResourceProperties',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::CloudResourceProperties'->new($_) };

declare 'RepeatedCloudResourceProperties',
    as ArrayRef[CloudResourceProperties()];

coerce 'RepeatedCloudResourceProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::CloudResourceProperties'->new($_) } @$_ ] };

declare 'MapStringCloudResourceProperties',
    as HashRef[CloudResourceProperties()];

declare 'MetastoreServiceConfig',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::MetastoreServiceConfig'];

coerce 'MetastoreServiceConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::MetastoreServiceConfig'->new($_) };

declare 'RepeatedMetastoreServiceConfig',
    as ArrayRef[MetastoreServiceConfig()];

coerce 'RepeatedMetastoreServiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::MetastoreServiceConfig'->new($_) } @$_ ] };

declare 'MapStringMetastoreServiceConfig',
    as HashRef[MetastoreServiceConfig()];

declare 'SparkHistoryServerConfig',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::SparkHistoryServerConfig'];

coerce 'SparkHistoryServerConfig',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::SparkHistoryServerConfig'->new($_) };

declare 'RepeatedSparkHistoryServerConfig',
    as ArrayRef[SparkHistoryServerConfig()];

coerce 'RepeatedSparkHistoryServerConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::SparkHistoryServerConfig'->new($_) } @$_ ] };

declare 'MapStringSparkHistoryServerConfig',
    as HashRef[SparkHistoryServerConfig()];

declare 'SparkProperties',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::SparkProperties'];

coerce 'SparkProperties',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::SparkProperties'->new($_) };

declare 'RepeatedSparkProperties',
    as ArrayRef[SparkProperties()];

coerce 'RepeatedSparkProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::SparkProperties'->new($_) } @$_ ] };

declare 'MapStringSparkProperties',
    as HashRef[SparkProperties()];

declare 'SalesforceDataCloudProperties',
    as InstanceOf['Google::Cloud::Bigquery::Connection::V1::Connection::SalesforceDataCloudProperties'];

coerce 'SalesforceDataCloudProperties',
    from HashRef, via { 'Google::Cloud::Bigquery::Connection::V1::Connection::SalesforceDataCloudProperties'->new($_) };

declare 'RepeatedSalesforceDataCloudProperties',
    as ArrayRef[SalesforceDataCloudProperties()];

coerce 'RepeatedSalesforceDataCloudProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Connection::V1::Connection::SalesforceDataCloudProperties'->new($_) } @$_ ] };

declare 'MapStringSalesforceDataCloudProperties',
    as HashRef[SalesforceDataCloudProperties()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Connection::V1::Connection::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
