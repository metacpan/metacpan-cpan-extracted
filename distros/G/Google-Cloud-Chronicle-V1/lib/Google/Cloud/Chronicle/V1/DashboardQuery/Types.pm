package Google::Cloud::Chronicle::V1::DashboardQuery::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LanguageFeature',
    as (Int | Str);

declare 'FilterOperator',
    as (Int | Str);

declare 'DataSource',
    as (Int | Str);

declare 'TimeUnit',
    as (Int | Str);

declare 'DashboardQuery',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery'];

coerce 'DashboardQuery',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery'->new($_) };

declare 'RepeatedDashboardQuery',
    as ArrayRef[DashboardQuery()];

coerce 'RepeatedDashboardQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery'->new($_) } @$_ ] };

declare 'MapStringDashboardQuery',
    as HashRef[DashboardQuery()];

declare 'Input',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery::Input'];

coerce 'Input',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery::Input'->new($_) };

declare 'RepeatedInput',
    as ArrayRef[Input()];

coerce 'RepeatedInput',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery::Input'->new($_) } @$_ ] };

declare 'MapStringInput',
    as HashRef[Input()];

declare 'RelativeTime',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery::Input::RelativeTime'];

coerce 'RelativeTime',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery::Input::RelativeTime'->new($_) };

declare 'RepeatedRelativeTime',
    as ArrayRef[RelativeTime()];

coerce 'RepeatedRelativeTime',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardQuery::Input::RelativeTime'->new($_) } @$_ ] };

declare 'MapStringRelativeTime',
    as HashRef[RelativeTime()];

declare 'GetDashboardQueryRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::GetDashboardQueryRequest'];

coerce 'GetDashboardQueryRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::GetDashboardQueryRequest'->new($_) };

declare 'RepeatedGetDashboardQueryRequest',
    as ArrayRef[GetDashboardQueryRequest()];

coerce 'RepeatedGetDashboardQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::GetDashboardQueryRequest'->new($_) } @$_ ] };

declare 'MapStringGetDashboardQueryRequest',
    as HashRef[GetDashboardQueryRequest()];

declare 'ExecuteDashboardQueryRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryRequest'];

coerce 'ExecuteDashboardQueryRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryRequest'->new($_) };

declare 'RepeatedExecuteDashboardQueryRequest',
    as ArrayRef[ExecuteDashboardQueryRequest()];

coerce 'RepeatedExecuteDashboardQueryRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryRequest'->new($_) } @$_ ] };

declare 'MapStringExecuteDashboardQueryRequest',
    as HashRef[ExecuteDashboardQueryRequest()];

declare 'QueryRuntimeError',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::QueryRuntimeError'];

coerce 'QueryRuntimeError',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::QueryRuntimeError'->new($_) };

declare 'RepeatedQueryRuntimeError',
    as ArrayRef[QueryRuntimeError()];

coerce 'RepeatedQueryRuntimeError',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::QueryRuntimeError'->new($_) } @$_ ] };

declare 'MapStringQueryRuntimeError',
    as HashRef[QueryRuntimeError()];

declare 'ErrorSeverity',
    as (Int | Str);

declare 'MetadataKey',
    as (Int | Str);

declare 'WarningReason',
    as (Int | Str);

declare 'QueryRuntimeErrorMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::QueryRuntimeError::QueryRuntimeErrorMetadata'];

coerce 'QueryRuntimeErrorMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::QueryRuntimeError::QueryRuntimeErrorMetadata'->new($_) };

declare 'RepeatedQueryRuntimeErrorMetadata',
    as ArrayRef[QueryRuntimeErrorMetadata()];

coerce 'RepeatedQueryRuntimeErrorMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::QueryRuntimeError::QueryRuntimeErrorMetadata'->new($_) } @$_ ] };

declare 'MapStringQueryRuntimeErrorMetadata',
    as HashRef[QueryRuntimeErrorMetadata()];

declare 'ExecuteDashboardQueryResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse'];

coerce 'ExecuteDashboardQueryResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse'->new($_) };

declare 'RepeatedExecuteDashboardQueryResponse',
    as ArrayRef[ExecuteDashboardQueryResponse()];

coerce 'RepeatedExecuteDashboardQueryResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse'->new($_) } @$_ ] };

declare 'MapStringExecuteDashboardQueryResponse',
    as HashRef[ExecuteDashboardQueryResponse()];

declare 'ColumnValue',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnValue'];

coerce 'ColumnValue',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnValue'->new($_) };

declare 'RepeatedColumnValue',
    as ArrayRef[ColumnValue()];

coerce 'RepeatedColumnValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnValue'->new($_) } @$_ ] };

declare 'MapStringColumnValue',
    as HashRef[ColumnValue()];

declare 'ValueMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnValue::ValueMetadata'];

coerce 'ValueMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnValue::ValueMetadata'->new($_) };

declare 'RepeatedValueMetadata',
    as ArrayRef[ValueMetadata()];

coerce 'RepeatedValueMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnValue::ValueMetadata'->new($_) } @$_ ] };

declare 'MapStringValueMetadata',
    as HashRef[ValueMetadata()];

declare 'ColumnType',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnType'];

coerce 'ColumnType',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnType'->new($_) };

declare 'RepeatedColumnType',
    as ArrayRef[ColumnType()];

coerce 'RepeatedColumnType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnType'->new($_) } @$_ ] };

declare 'MapStringColumnType',
    as HashRef[ColumnType()];

declare 'List',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnType::List'];

coerce 'List',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnType::List'->new($_) };

declare 'RepeatedList',
    as ArrayRef[List()];

coerce 'RepeatedList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnType::List'->new($_) } @$_ ] };

declare 'MapStringList',
    as HashRef[List()];

declare 'ColumnData',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnData'];

coerce 'ColumnData',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnData'->new($_) };

declare 'RepeatedColumnData',
    as ArrayRef[ColumnData()];

coerce 'RepeatedColumnData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::ExecuteDashboardQueryResponse::ColumnData'->new($_) } @$_ ] };

declare 'MapStringColumnData',
    as HashRef[ColumnData()];

declare 'DashboardFilter',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::DashboardFilter'];

coerce 'DashboardFilter',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardFilter'->new($_) };

declare 'RepeatedDashboardFilter',
    as ArrayRef[DashboardFilter()];

coerce 'RepeatedDashboardFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::DashboardFilter'->new($_) } @$_ ] };

declare 'MapStringDashboardFilter',
    as HashRef[DashboardFilter()];

declare 'FilterOperatorAndValues',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::FilterOperatorAndValues'];

coerce 'FilterOperatorAndValues',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::FilterOperatorAndValues'->new($_) };

declare 'RepeatedFilterOperatorAndValues',
    as ArrayRef[FilterOperatorAndValues()];

coerce 'RepeatedFilterOperatorAndValues',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::FilterOperatorAndValues'->new($_) } @$_ ] };

declare 'MapStringFilterOperatorAndValues',
    as HashRef[FilterOperatorAndValues()];

declare 'AdvancedFilterConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig'];

coerce 'AdvancedFilterConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig'->new($_) };

declare 'RepeatedAdvancedFilterConfig',
    as ArrayRef[AdvancedFilterConfig()];

coerce 'RepeatedAdvancedFilterConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig'->new($_) } @$_ ] };

declare 'MapStringAdvancedFilterConfig',
    as HashRef[AdvancedFilterConfig()];

declare 'ValueSource',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig::ValueSource'];

coerce 'ValueSource',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig::ValueSource'->new($_) };

declare 'RepeatedValueSource',
    as ArrayRef[ValueSource()];

coerce 'RepeatedValueSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig::ValueSource'->new($_) } @$_ ] };

declare 'MapStringValueSource',
    as HashRef[ValueSource()];

declare 'ManualOptions',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig::ManualOptions'];

coerce 'ManualOptions',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig::ManualOptions'->new($_) };

declare 'RepeatedManualOptions',
    as ArrayRef[ManualOptions()];

coerce 'RepeatedManualOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig::ManualOptions'->new($_) } @$_ ] };

declare 'MapStringManualOptions',
    as HashRef[ManualOptions()];

declare 'QueryOptions',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig::QueryOptions'];

coerce 'QueryOptions',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig::QueryOptions'->new($_) };

declare 'RepeatedQueryOptions',
    as ArrayRef[QueryOptions()];

coerce 'RepeatedQueryOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::AdvancedFilterConfig::QueryOptions'->new($_) } @$_ ] };

declare 'MapStringQueryOptions',
    as HashRef[QueryOptions()];

declare 'InAppLink',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::InAppLink'];

coerce 'InAppLink',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::InAppLink'->new($_) };

declare 'RepeatedInAppLink',
    as ArrayRef[InAppLink()];

coerce 'RepeatedInAppLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::InAppLink'->new($_) } @$_ ] };

declare 'MapStringInAppLink',
    as HashRef[InAppLink()];

declare 'ColumnMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::ColumnMetadata'];

coerce 'ColumnMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::ColumnMetadata'->new($_) };

declare 'RepeatedColumnMetadata',
    as ArrayRef[ColumnMetadata()];

coerce 'RepeatedColumnMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::ColumnMetadata'->new($_) } @$_ ] };

declare 'MapStringColumnMetadata',
    as HashRef[ColumnMetadata()];

declare 'TimestampMetadata',
    as InstanceOf['Google::Cloud::Chronicle::V1::DashboardQuery::TimestampMetadata'];

coerce 'TimestampMetadata',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::DashboardQuery::TimestampMetadata'->new($_) };

declare 'RepeatedTimestampMetadata',
    as ArrayRef[TimestampMetadata()];

coerce 'RepeatedTimestampMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::DashboardQuery::TimestampMetadata'->new($_) } @$_ ] };

declare 'MapStringTimestampMetadata',
    as HashRef[TimestampMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::DashboardQuery::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
