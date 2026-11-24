package Google::Cloud::Chronicle::V1::NativeDashboard::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DashboardType',
    as (Int | Str);

declare 'DashboardAccess',
    as (Int | Str);

declare 'NativeDashboardView',
    as (Int | Str);

declare 'ExportNativeDashboardsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::ExportNativeDashboardsRequest'];

coerce 'ExportNativeDashboardsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::ExportNativeDashboardsRequest'->new($_) };

declare 'RepeatedExportNativeDashboardsRequest',
    as ArrayRef[ExportNativeDashboardsRequest()];

coerce 'RepeatedExportNativeDashboardsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::ExportNativeDashboardsRequest'->new($_) } @$_ ] };

declare 'MapStringExportNativeDashboardsRequest',
    as HashRef[ExportNativeDashboardsRequest()];

declare 'ExportNativeDashboardsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::ExportNativeDashboardsResponse'];

coerce 'ExportNativeDashboardsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::ExportNativeDashboardsResponse'->new($_) };

declare 'RepeatedExportNativeDashboardsResponse',
    as ArrayRef[ExportNativeDashboardsResponse()];

coerce 'RepeatedExportNativeDashboardsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::ExportNativeDashboardsResponse'->new($_) } @$_ ] };

declare 'MapStringExportNativeDashboardsResponse',
    as HashRef[ExportNativeDashboardsResponse()];

declare 'InlineDestination',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::InlineDestination'];

coerce 'InlineDestination',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::InlineDestination'->new($_) };

declare 'RepeatedInlineDestination',
    as ArrayRef[InlineDestination()];

coerce 'RepeatedInlineDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::InlineDestination'->new($_) } @$_ ] };

declare 'MapStringInlineDestination',
    as HashRef[InlineDestination()];

declare 'NativeDashboardWithChartsAndQueries',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboardWithChartsAndQueries'];

coerce 'NativeDashboardWithChartsAndQueries',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboardWithChartsAndQueries'->new($_) };

declare 'RepeatedNativeDashboardWithChartsAndQueries',
    as ArrayRef[NativeDashboardWithChartsAndQueries()];

coerce 'RepeatedNativeDashboardWithChartsAndQueries',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboardWithChartsAndQueries'->new($_) } @$_ ] };

declare 'MapStringNativeDashboardWithChartsAndQueries',
    as HashRef[NativeDashboardWithChartsAndQueries()];

declare 'ImportNativeDashboardsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::ImportNativeDashboardsRequest'];

coerce 'ImportNativeDashboardsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::ImportNativeDashboardsRequest'->new($_) };

declare 'RepeatedImportNativeDashboardsRequest',
    as ArrayRef[ImportNativeDashboardsRequest()];

coerce 'RepeatedImportNativeDashboardsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::ImportNativeDashboardsRequest'->new($_) } @$_ ] };

declare 'MapStringImportNativeDashboardsRequest',
    as HashRef[ImportNativeDashboardsRequest()];

declare 'ImportNativeDashboardsInlineSource',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::ImportNativeDashboardsInlineSource'];

coerce 'ImportNativeDashboardsInlineSource',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::ImportNativeDashboardsInlineSource'->new($_) };

declare 'RepeatedImportNativeDashboardsInlineSource',
    as ArrayRef[ImportNativeDashboardsInlineSource()];

coerce 'RepeatedImportNativeDashboardsInlineSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::ImportNativeDashboardsInlineSource'->new($_) } @$_ ] };

declare 'MapStringImportNativeDashboardsInlineSource',
    as HashRef[ImportNativeDashboardsInlineSource()];

declare 'ImportNativeDashboardsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::ImportNativeDashboardsResponse'];

coerce 'ImportNativeDashboardsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::ImportNativeDashboardsResponse'->new($_) };

declare 'RepeatedImportNativeDashboardsResponse',
    as ArrayRef[ImportNativeDashboardsResponse()];

coerce 'RepeatedImportNativeDashboardsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::ImportNativeDashboardsResponse'->new($_) } @$_ ] };

declare 'MapStringImportNativeDashboardsResponse',
    as HashRef[ImportNativeDashboardsResponse()];

declare 'ImportExportStatus',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::ImportExportStatus'];

coerce 'ImportExportStatus',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::ImportExportStatus'->new($_) };

declare 'RepeatedImportExportStatus',
    as ArrayRef[ImportExportStatus()];

coerce 'RepeatedImportExportStatus',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::ImportExportStatus'->new($_) } @$_ ] };

declare 'MapStringImportExportStatus',
    as HashRef[ImportExportStatus()];

declare 'NativeDashboard',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboard'];

coerce 'NativeDashboard',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboard'->new($_) };

declare 'RepeatedNativeDashboard',
    as ArrayRef[NativeDashboard()];

coerce 'RepeatedNativeDashboard',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::NativeDashboard'->new($_) } @$_ ] };

declare 'MapStringNativeDashboard',
    as HashRef[NativeDashboard()];

declare 'CreateNativeDashboardRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::CreateNativeDashboardRequest'];

coerce 'CreateNativeDashboardRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::CreateNativeDashboardRequest'->new($_) };

declare 'RepeatedCreateNativeDashboardRequest',
    as ArrayRef[CreateNativeDashboardRequest()];

coerce 'RepeatedCreateNativeDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::CreateNativeDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNativeDashboardRequest',
    as HashRef[CreateNativeDashboardRequest()];

declare 'GetNativeDashboardRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::GetNativeDashboardRequest'];

coerce 'GetNativeDashboardRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::GetNativeDashboardRequest'->new($_) };

declare 'RepeatedGetNativeDashboardRequest',
    as ArrayRef[GetNativeDashboardRequest()];

coerce 'RepeatedGetNativeDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::GetNativeDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringGetNativeDashboardRequest',
    as HashRef[GetNativeDashboardRequest()];

declare 'ListNativeDashboardsRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::ListNativeDashboardsRequest'];

coerce 'ListNativeDashboardsRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::ListNativeDashboardsRequest'->new($_) };

declare 'RepeatedListNativeDashboardsRequest',
    as ArrayRef[ListNativeDashboardsRequest()];

coerce 'RepeatedListNativeDashboardsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::ListNativeDashboardsRequest'->new($_) } @$_ ] };

declare 'MapStringListNativeDashboardsRequest',
    as HashRef[ListNativeDashboardsRequest()];

declare 'ListNativeDashboardsResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::ListNativeDashboardsResponse'];

coerce 'ListNativeDashboardsResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::ListNativeDashboardsResponse'->new($_) };

declare 'RepeatedListNativeDashboardsResponse',
    as ArrayRef[ListNativeDashboardsResponse()];

coerce 'RepeatedListNativeDashboardsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::ListNativeDashboardsResponse'->new($_) } @$_ ] };

declare 'MapStringListNativeDashboardsResponse',
    as HashRef[ListNativeDashboardsResponse()];

declare 'UpdateNativeDashboardRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::UpdateNativeDashboardRequest'];

coerce 'UpdateNativeDashboardRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::UpdateNativeDashboardRequest'->new($_) };

declare 'RepeatedUpdateNativeDashboardRequest',
    as ArrayRef[UpdateNativeDashboardRequest()];

coerce 'RepeatedUpdateNativeDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::UpdateNativeDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNativeDashboardRequest',
    as HashRef[UpdateNativeDashboardRequest()];

declare 'DuplicateNativeDashboardRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::DuplicateNativeDashboardRequest'];

coerce 'DuplicateNativeDashboardRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::DuplicateNativeDashboardRequest'->new($_) };

declare 'RepeatedDuplicateNativeDashboardRequest',
    as ArrayRef[DuplicateNativeDashboardRequest()];

coerce 'RepeatedDuplicateNativeDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::DuplicateNativeDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringDuplicateNativeDashboardRequest',
    as HashRef[DuplicateNativeDashboardRequest()];

declare 'DeleteNativeDashboardRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::DeleteNativeDashboardRequest'];

coerce 'DeleteNativeDashboardRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::DeleteNativeDashboardRequest'->new($_) };

declare 'RepeatedDeleteNativeDashboardRequest',
    as ArrayRef[DeleteNativeDashboardRequest()];

coerce 'RepeatedDeleteNativeDashboardRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::DeleteNativeDashboardRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNativeDashboardRequest',
    as HashRef[DeleteNativeDashboardRequest()];

declare 'AddChartRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::AddChartRequest'];

coerce 'AddChartRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::AddChartRequest'->new($_) };

declare 'RepeatedAddChartRequest',
    as ArrayRef[AddChartRequest()];

coerce 'RepeatedAddChartRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::AddChartRequest'->new($_) } @$_ ] };

declare 'MapStringAddChartRequest',
    as HashRef[AddChartRequest()];

declare 'AddChartResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::AddChartResponse'];

coerce 'AddChartResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::AddChartResponse'->new($_) };

declare 'RepeatedAddChartResponse',
    as ArrayRef[AddChartResponse()];

coerce 'RepeatedAddChartResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::AddChartResponse'->new($_) } @$_ ] };

declare 'MapStringAddChartResponse',
    as HashRef[AddChartResponse()];

declare 'EditChartRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::EditChartRequest'];

coerce 'EditChartRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::EditChartRequest'->new($_) };

declare 'RepeatedEditChartRequest',
    as ArrayRef[EditChartRequest()];

coerce 'RepeatedEditChartRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::EditChartRequest'->new($_) } @$_ ] };

declare 'MapStringEditChartRequest',
    as HashRef[EditChartRequest()];

declare 'EditChartResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::EditChartResponse'];

coerce 'EditChartResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::EditChartResponse'->new($_) };

declare 'RepeatedEditChartResponse',
    as ArrayRef[EditChartResponse()];

coerce 'RepeatedEditChartResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::EditChartResponse'->new($_) } @$_ ] };

declare 'MapStringEditChartResponse',
    as HashRef[EditChartResponse()];

declare 'RemoveChartRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::RemoveChartRequest'];

coerce 'RemoveChartRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::RemoveChartRequest'->new($_) };

declare 'RepeatedRemoveChartRequest',
    as ArrayRef[RemoveChartRequest()];

coerce 'RepeatedRemoveChartRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::RemoveChartRequest'->new($_) } @$_ ] };

declare 'MapStringRemoveChartRequest',
    as HashRef[RemoveChartRequest()];

declare 'DuplicateChartRequest',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::DuplicateChartRequest'];

coerce 'DuplicateChartRequest',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::DuplicateChartRequest'->new($_) };

declare 'RepeatedDuplicateChartRequest',
    as ArrayRef[DuplicateChartRequest()];

coerce 'RepeatedDuplicateChartRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::DuplicateChartRequest'->new($_) } @$_ ] };

declare 'MapStringDuplicateChartRequest',
    as HashRef[DuplicateChartRequest()];

declare 'DuplicateChartResponse',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::DuplicateChartResponse'];

coerce 'DuplicateChartResponse',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::DuplicateChartResponse'->new($_) };

declare 'RepeatedDuplicateChartResponse',
    as ArrayRef[DuplicateChartResponse()];

coerce 'RepeatedDuplicateChartResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::DuplicateChartResponse'->new($_) } @$_ ] };

declare 'MapStringDuplicateChartResponse',
    as HashRef[DuplicateChartResponse()];

declare 'DashboardUserData',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::DashboardUserData'];

coerce 'DashboardUserData',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::DashboardUserData'->new($_) };

declare 'RepeatedDashboardUserData',
    as ArrayRef[DashboardUserData()];

coerce 'RepeatedDashboardUserData',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::DashboardUserData'->new($_) } @$_ ] };

declare 'MapStringDashboardUserData',
    as HashRef[DashboardUserData()];

declare 'DashboardDefinition',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::DashboardDefinition'];

coerce 'DashboardDefinition',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::DashboardDefinition'->new($_) };

declare 'RepeatedDashboardDefinition',
    as ArrayRef[DashboardDefinition()];

coerce 'RepeatedDashboardDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::DashboardDefinition'->new($_) } @$_ ] };

declare 'MapStringDashboardDefinition',
    as HashRef[DashboardDefinition()];

declare 'ChartConfig',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::DashboardDefinition::ChartConfig'];

coerce 'ChartConfig',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::DashboardDefinition::ChartConfig'->new($_) };

declare 'RepeatedChartConfig',
    as ArrayRef[ChartConfig()];

coerce 'RepeatedChartConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::DashboardDefinition::ChartConfig'->new($_) } @$_ ] };

declare 'MapStringChartConfig',
    as HashRef[ChartConfig()];

declare 'ChartLayout',
    as InstanceOf['Google::Cloud::Chronicle::V1::NativeDashboard::DashboardDefinition::ChartConfig::ChartLayout'];

coerce 'ChartLayout',
    from HashRef, via { 'Google::Cloud::Chronicle::V1::NativeDashboard::DashboardDefinition::ChartConfig::ChartLayout'->new($_) };

declare 'RepeatedChartLayout',
    as ArrayRef[ChartLayout()];

coerce 'RepeatedChartLayout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Chronicle::V1::NativeDashboard::DashboardDefinition::ChartConfig::ChartLayout'->new($_) } @$_ ] };

declare 'MapStringChartLayout',
    as HashRef[ChartLayout()];

1;

__END__

=head1 NAME

Google::Cloud::Chronicle::V1::NativeDashboard::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
