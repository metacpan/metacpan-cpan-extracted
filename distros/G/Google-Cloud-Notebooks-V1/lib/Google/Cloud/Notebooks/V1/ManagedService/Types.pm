package Google::Cloud::Notebooks::V1::ManagedService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListRuntimesRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesRequest'];

coerce 'ListRuntimesRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesRequest'->new($_) };

declare 'RepeatedListRuntimesRequest',
    as ArrayRef[ListRuntimesRequest()];

coerce 'RepeatedListRuntimesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesRequest'->new($_) } @$_ ] };

declare 'MapStringListRuntimesRequest',
    as HashRef[ListRuntimesRequest()];

declare 'ListRuntimesResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesResponse'];

coerce 'ListRuntimesResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesResponse'->new($_) };

declare 'RepeatedListRuntimesResponse',
    as ArrayRef[ListRuntimesResponse()];

coerce 'RepeatedListRuntimesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::ListRuntimesResponse'->new($_) } @$_ ] };

declare 'MapStringListRuntimesResponse',
    as HashRef[ListRuntimesResponse()];

declare 'GetRuntimeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::GetRuntimeRequest'];

coerce 'GetRuntimeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::GetRuntimeRequest'->new($_) };

declare 'RepeatedGetRuntimeRequest',
    as ArrayRef[GetRuntimeRequest()];

coerce 'RepeatedGetRuntimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::GetRuntimeRequest'->new($_) } @$_ ] };

declare 'MapStringGetRuntimeRequest',
    as HashRef[GetRuntimeRequest()];

declare 'CreateRuntimeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::CreateRuntimeRequest'];

coerce 'CreateRuntimeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::CreateRuntimeRequest'->new($_) };

declare 'RepeatedCreateRuntimeRequest',
    as ArrayRef[CreateRuntimeRequest()];

coerce 'RepeatedCreateRuntimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::CreateRuntimeRequest'->new($_) } @$_ ] };

declare 'MapStringCreateRuntimeRequest',
    as HashRef[CreateRuntimeRequest()];

declare 'DeleteRuntimeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::DeleteRuntimeRequest'];

coerce 'DeleteRuntimeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::DeleteRuntimeRequest'->new($_) };

declare 'RepeatedDeleteRuntimeRequest',
    as ArrayRef[DeleteRuntimeRequest()];

coerce 'RepeatedDeleteRuntimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::DeleteRuntimeRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteRuntimeRequest',
    as HashRef[DeleteRuntimeRequest()];

declare 'StartRuntimeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::StartRuntimeRequest'];

coerce 'StartRuntimeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::StartRuntimeRequest'->new($_) };

declare 'RepeatedStartRuntimeRequest',
    as ArrayRef[StartRuntimeRequest()];

coerce 'RepeatedStartRuntimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::StartRuntimeRequest'->new($_) } @$_ ] };

declare 'MapStringStartRuntimeRequest',
    as HashRef[StartRuntimeRequest()];

declare 'StopRuntimeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::StopRuntimeRequest'];

coerce 'StopRuntimeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::StopRuntimeRequest'->new($_) };

declare 'RepeatedStopRuntimeRequest',
    as ArrayRef[StopRuntimeRequest()];

coerce 'RepeatedStopRuntimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::StopRuntimeRequest'->new($_) } @$_ ] };

declare 'MapStringStopRuntimeRequest',
    as HashRef[StopRuntimeRequest()];

declare 'SwitchRuntimeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::SwitchRuntimeRequest'];

coerce 'SwitchRuntimeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::SwitchRuntimeRequest'->new($_) };

declare 'RepeatedSwitchRuntimeRequest',
    as ArrayRef[SwitchRuntimeRequest()];

coerce 'RepeatedSwitchRuntimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::SwitchRuntimeRequest'->new($_) } @$_ ] };

declare 'MapStringSwitchRuntimeRequest',
    as HashRef[SwitchRuntimeRequest()];

declare 'ResetRuntimeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::ResetRuntimeRequest'];

coerce 'ResetRuntimeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::ResetRuntimeRequest'->new($_) };

declare 'RepeatedResetRuntimeRequest',
    as ArrayRef[ResetRuntimeRequest()];

coerce 'RepeatedResetRuntimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::ResetRuntimeRequest'->new($_) } @$_ ] };

declare 'MapStringResetRuntimeRequest',
    as HashRef[ResetRuntimeRequest()];

declare 'UpgradeRuntimeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::UpgradeRuntimeRequest'];

coerce 'UpgradeRuntimeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::UpgradeRuntimeRequest'->new($_) };

declare 'RepeatedUpgradeRuntimeRequest',
    as ArrayRef[UpgradeRuntimeRequest()];

coerce 'RepeatedUpgradeRuntimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::UpgradeRuntimeRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeRuntimeRequest',
    as HashRef[UpgradeRuntimeRequest()];

declare 'ReportRuntimeEventRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::ReportRuntimeEventRequest'];

coerce 'ReportRuntimeEventRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::ReportRuntimeEventRequest'->new($_) };

declare 'RepeatedReportRuntimeEventRequest',
    as ArrayRef[ReportRuntimeEventRequest()];

coerce 'RepeatedReportRuntimeEventRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::ReportRuntimeEventRequest'->new($_) } @$_ ] };

declare 'MapStringReportRuntimeEventRequest',
    as HashRef[ReportRuntimeEventRequest()];

declare 'UpdateRuntimeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::UpdateRuntimeRequest'];

coerce 'UpdateRuntimeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::UpdateRuntimeRequest'->new($_) };

declare 'RepeatedUpdateRuntimeRequest',
    as ArrayRef[UpdateRuntimeRequest()];

coerce 'RepeatedUpdateRuntimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::UpdateRuntimeRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateRuntimeRequest',
    as HashRef[UpdateRuntimeRequest()];

declare 'RefreshRuntimeTokenInternalRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalRequest'];

coerce 'RefreshRuntimeTokenInternalRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalRequest'->new($_) };

declare 'RepeatedRefreshRuntimeTokenInternalRequest',
    as ArrayRef[RefreshRuntimeTokenInternalRequest()];

coerce 'RepeatedRefreshRuntimeTokenInternalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalRequest'->new($_) } @$_ ] };

declare 'MapStringRefreshRuntimeTokenInternalRequest',
    as HashRef[RefreshRuntimeTokenInternalRequest()];

declare 'RefreshRuntimeTokenInternalResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalResponse'];

coerce 'RefreshRuntimeTokenInternalResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalResponse'->new($_) };

declare 'RepeatedRefreshRuntimeTokenInternalResponse',
    as ArrayRef[RefreshRuntimeTokenInternalResponse()];

coerce 'RepeatedRefreshRuntimeTokenInternalResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::RefreshRuntimeTokenInternalResponse'->new($_) } @$_ ] };

declare 'MapStringRefreshRuntimeTokenInternalResponse',
    as HashRef[RefreshRuntimeTokenInternalResponse()];

declare 'DiagnoseRuntimeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1::ManagedService::DiagnoseRuntimeRequest'];

coerce 'DiagnoseRuntimeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1::ManagedService::DiagnoseRuntimeRequest'->new($_) };

declare 'RepeatedDiagnoseRuntimeRequest',
    as ArrayRef[DiagnoseRuntimeRequest()];

coerce 'RepeatedDiagnoseRuntimeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1::ManagedService::DiagnoseRuntimeRequest'->new($_) } @$_ ] };

declare 'MapStringDiagnoseRuntimeRequest',
    as HashRef[DiagnoseRuntimeRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V1::ManagedService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
