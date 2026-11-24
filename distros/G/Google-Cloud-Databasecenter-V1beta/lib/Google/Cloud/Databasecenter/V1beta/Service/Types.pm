package Google::Cloud::Databasecenter::V1beta::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Edition',
    as (Int | Str);

declare 'SubResourceType',
    as (Int | Str);

declare 'ManagementType',
    as (Int | Str);

declare 'ResourceCategory',
    as (Int | Str);

declare 'QueryProductsRequest',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::QueryProductsRequest'];

coerce 'QueryProductsRequest',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::QueryProductsRequest'->new($_) };

declare 'RepeatedQueryProductsRequest',
    as ArrayRef[QueryProductsRequest()];

coerce 'RepeatedQueryProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::QueryProductsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryProductsRequest',
    as HashRef[QueryProductsRequest()];

declare 'QueryProductsResponse',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::QueryProductsResponse'];

coerce 'QueryProductsResponse',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::QueryProductsResponse'->new($_) };

declare 'RepeatedQueryProductsResponse',
    as ArrayRef[QueryProductsResponse()];

coerce 'RepeatedQueryProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::QueryProductsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryProductsResponse',
    as HashRef[QueryProductsResponse()];

declare 'QueryDatabaseResourceGroupsRequest',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsRequest'];

coerce 'QueryDatabaseResourceGroupsRequest',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsRequest'->new($_) };

declare 'RepeatedQueryDatabaseResourceGroupsRequest',
    as ArrayRef[QueryDatabaseResourceGroupsRequest()];

coerce 'RepeatedQueryDatabaseResourceGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryDatabaseResourceGroupsRequest',
    as HashRef[QueryDatabaseResourceGroupsRequest()];

declare 'QueryDatabaseResourceGroupsResponse',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsResponse'];

coerce 'QueryDatabaseResourceGroupsResponse',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsResponse'->new($_) };

declare 'RepeatedQueryDatabaseResourceGroupsResponse',
    as ArrayRef[QueryDatabaseResourceGroupsResponse()];

coerce 'RepeatedQueryDatabaseResourceGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::QueryDatabaseResourceGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryDatabaseResourceGroupsResponse',
    as HashRef[QueryDatabaseResourceGroupsResponse()];

declare 'DatabaseResourceGroup',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::DatabaseResourceGroup'];

coerce 'DatabaseResourceGroup',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::DatabaseResourceGroup'->new($_) };

declare 'RepeatedDatabaseResourceGroup',
    as ArrayRef[DatabaseResourceGroup()];

coerce 'RepeatedDatabaseResourceGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::DatabaseResourceGroup'->new($_) } @$_ ] };

declare 'MapStringDatabaseResourceGroup',
    as HashRef[DatabaseResourceGroup()];

declare 'DatabaseResource',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::DatabaseResource'];

coerce 'DatabaseResource',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::DatabaseResource'->new($_) };

declare 'RepeatedDatabaseResource',
    as ArrayRef[DatabaseResource()];

coerce 'RepeatedDatabaseResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::DatabaseResource'->new($_) } @$_ ] };

declare 'MapStringDatabaseResource',
    as HashRef[DatabaseResource()];

declare 'AggregateIssueStatsRequest',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsRequest'];

coerce 'AggregateIssueStatsRequest',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsRequest'->new($_) };

declare 'RepeatedAggregateIssueStatsRequest',
    as ArrayRef[AggregateIssueStatsRequest()];

coerce 'RepeatedAggregateIssueStatsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsRequest'->new($_) } @$_ ] };

declare 'MapStringAggregateIssueStatsRequest',
    as HashRef[AggregateIssueStatsRequest()];

declare 'AggregateQueryStatsRequest',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsRequest'];

coerce 'AggregateQueryStatsRequest',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsRequest'->new($_) };

declare 'RepeatedAggregateQueryStatsRequest',
    as ArrayRef[AggregateQueryStatsRequest()];

coerce 'RepeatedAggregateQueryStatsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsRequest'->new($_) } @$_ ] };

declare 'MapStringAggregateQueryStatsRequest',
    as HashRef[AggregateQueryStatsRequest()];

declare 'AggregateQueryStatsResponse',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsResponse'];

coerce 'AggregateQueryStatsResponse',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsResponse'->new($_) };

declare 'RepeatedAggregateQueryStatsResponse',
    as ArrayRef[AggregateQueryStatsResponse()];

coerce 'RepeatedAggregateQueryStatsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateQueryStatsResponse'->new($_) } @$_ ] };

declare 'MapStringAggregateQueryStatsResponse',
    as HashRef[AggregateQueryStatsResponse()];

declare 'AggregateIssueStatsResponse',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsResponse'];

coerce 'AggregateIssueStatsResponse',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsResponse'->new($_) };

declare 'RepeatedAggregateIssueStatsResponse',
    as ArrayRef[AggregateIssueStatsResponse()];

coerce 'RepeatedAggregateIssueStatsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateIssueStatsResponse'->new($_) } @$_ ] };

declare 'MapStringAggregateIssueStatsResponse',
    as HashRef[AggregateIssueStatsResponse()];

declare 'IssueGroupStats',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::IssueGroupStats'];

coerce 'IssueGroupStats',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::IssueGroupStats'->new($_) };

declare 'RepeatedIssueGroupStats',
    as ArrayRef[IssueGroupStats()];

coerce 'RepeatedIssueGroupStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::IssueGroupStats'->new($_) } @$_ ] };

declare 'MapStringIssueGroupStats',
    as HashRef[IssueGroupStats()];

declare 'IssueStats',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::IssueStats'];

coerce 'IssueStats',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::IssueStats'->new($_) };

declare 'RepeatedIssueStats',
    as ArrayRef[IssueStats()];

coerce 'RepeatedIssueStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::IssueStats'->new($_) } @$_ ] };

declare 'MapStringIssueStats',
    as HashRef[IssueStats()];

declare 'Label',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::Label'];

coerce 'Label',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::Label'->new($_) };

declare 'RepeatedLabel',
    as ArrayRef[Label()];

coerce 'RepeatedLabel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::Label'->new($_) } @$_ ] };

declare 'MapStringLabel',
    as HashRef[Label()];

declare 'AggregateFleetRequest',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetRequest'];

coerce 'AggregateFleetRequest',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetRequest'->new($_) };

declare 'RepeatedAggregateFleetRequest',
    as ArrayRef[AggregateFleetRequest()];

coerce 'RepeatedAggregateFleetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetRequest'->new($_) } @$_ ] };

declare 'MapStringAggregateFleetRequest',
    as HashRef[AggregateFleetRequest()];

declare 'QueryStatsInfo',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::QueryStatsInfo'];

coerce 'QueryStatsInfo',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::QueryStatsInfo'->new($_) };

declare 'RepeatedQueryStatsInfo',
    as ArrayRef[QueryStatsInfo()];

coerce 'RepeatedQueryStatsInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::QueryStatsInfo'->new($_) } @$_ ] };

declare 'MapStringQueryStatsInfo',
    as HashRef[QueryStatsInfo()];

declare 'ResourceId',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::ResourceId'];

coerce 'ResourceId',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::ResourceId'->new($_) };

declare 'RepeatedResourceId',
    as ArrayRef[ResourceId()];

coerce 'RepeatedResourceId',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::ResourceId'->new($_) } @$_ ] };

declare 'MapStringResourceId',
    as HashRef[ResourceId()];

declare 'QueryStats',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::QueryStats'];

coerce 'QueryStats',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::QueryStats'->new($_) };

declare 'RepeatedQueryStats',
    as ArrayRef[QueryStats()];

coerce 'RepeatedQueryStats',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::QueryStats'->new($_) } @$_ ] };

declare 'MapStringQueryStats',
    as HashRef[QueryStats()];

declare 'QueryMetrics',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::QueryMetrics'];

coerce 'QueryMetrics',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::QueryMetrics'->new($_) };

declare 'RepeatedQueryMetrics',
    as ArrayRef[QueryMetrics()];

coerce 'RepeatedQueryMetrics',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::QueryMetrics'->new($_) } @$_ ] };

declare 'MapStringQueryMetrics',
    as HashRef[QueryMetrics()];

declare 'MetricsWindow',
    as (Int | Str);

declare 'AggregateFleetResponse',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetResponse'];

coerce 'AggregateFleetResponse',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetResponse'->new($_) };

declare 'RepeatedAggregateFleetResponse',
    as ArrayRef[AggregateFleetResponse()];

coerce 'RepeatedAggregateFleetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetResponse'->new($_) } @$_ ] };

declare 'MapStringAggregateFleetResponse',
    as HashRef[AggregateFleetResponse()];

declare 'AggregateFleetRow',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetRow'];

coerce 'AggregateFleetRow',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetRow'->new($_) };

declare 'RepeatedAggregateFleetRow',
    as ArrayRef[AggregateFleetRow()];

coerce 'RepeatedAggregateFleetRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::AggregateFleetRow'->new($_) } @$_ ] };

declare 'MapStringAggregateFleetRow',
    as HashRef[AggregateFleetRow()];

declare 'Dimension',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::Dimension'];

coerce 'Dimension',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::Dimension'->new($_) };

declare 'RepeatedDimension',
    as ArrayRef[Dimension()];

coerce 'RepeatedDimension',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::Dimension'->new($_) } @$_ ] };

declare 'MapStringDimension',
    as HashRef[Dimension()];

declare 'BackupDRConfig',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::BackupDRConfig'];

coerce 'BackupDRConfig',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::BackupDRConfig'->new($_) };

declare 'RepeatedBackupDRConfig',
    as ArrayRef[BackupDRConfig()];

coerce 'RepeatedBackupDRConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::BackupDRConfig'->new($_) } @$_ ] };

declare 'MapStringBackupDRConfig',
    as HashRef[BackupDRConfig()];

declare 'QueryIssuesRequest',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesRequest'];

coerce 'QueryIssuesRequest',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesRequest'->new($_) };

declare 'RepeatedQueryIssuesRequest',
    as ArrayRef[QueryIssuesRequest()];

coerce 'RepeatedQueryIssuesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesRequest'->new($_) } @$_ ] };

declare 'MapStringQueryIssuesRequest',
    as HashRef[QueryIssuesRequest()];

declare 'SignalProductsFilters',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::SignalProductsFilters'];

coerce 'SignalProductsFilters',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::SignalProductsFilters'->new($_) };

declare 'RepeatedSignalProductsFilters',
    as ArrayRef[SignalProductsFilters()];

coerce 'RepeatedSignalProductsFilters',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::SignalProductsFilters'->new($_) } @$_ ] };

declare 'MapStringSignalProductsFilters',
    as HashRef[SignalProductsFilters()];

declare 'QueryIssuesResponse',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesResponse'];

coerce 'QueryIssuesResponse',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesResponse'->new($_) };

declare 'RepeatedQueryIssuesResponse',
    as ArrayRef[QueryIssuesResponse()];

coerce 'RepeatedQueryIssuesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::QueryIssuesResponse'->new($_) } @$_ ] };

declare 'MapStringQueryIssuesResponse',
    as HashRef[QueryIssuesResponse()];

declare 'DatabaseResourceIssue',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::DatabaseResourceIssue'];

coerce 'DatabaseResourceIssue',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::DatabaseResourceIssue'->new($_) };

declare 'RepeatedDatabaseResourceIssue',
    as ArrayRef[DatabaseResourceIssue()];

coerce 'RepeatedDatabaseResourceIssue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::DatabaseResourceIssue'->new($_) } @$_ ] };

declare 'MapStringDatabaseResourceIssue',
    as HashRef[DatabaseResourceIssue()];

declare 'Tag',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::Tag'];

coerce 'Tag',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::Tag'->new($_) };

declare 'RepeatedTag',
    as ArrayRef[Tag()];

coerce 'RepeatedTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::Tag'->new($_) } @$_ ] };

declare 'MapStringTag',
    as HashRef[Tag()];

declare 'ResourceDetails',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::ResourceDetails'];

coerce 'ResourceDetails',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::ResourceDetails'->new($_) };

declare 'RepeatedResourceDetails',
    as ArrayRef[ResourceDetails()];

coerce 'RepeatedResourceDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::ResourceDetails'->new($_) } @$_ ] };

declare 'MapStringResourceDetails',
    as HashRef[ResourceDetails()];

declare 'DeltaDetails',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Service::DeltaDetails'];

coerce 'DeltaDetails',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Service::DeltaDetails'->new($_) };

declare 'RepeatedDeltaDetails',
    as ArrayRef[DeltaDetails()];

coerce 'RepeatedDeltaDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Service::DeltaDetails'->new($_) } @$_ ] };

declare 'MapStringDeltaDetails',
    as HashRef[DeltaDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Databasecenter::V1beta::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
