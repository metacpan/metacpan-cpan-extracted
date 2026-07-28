package Google::Cloud::Networkservices::V1::Extensibility::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WasmPluginView',
    as (Int | Str);

declare 'WasmPlugin',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin'];

coerce 'WasmPlugin',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin'->new($_) };

declare 'RepeatedWasmPlugin',
    as ArrayRef[WasmPlugin()];

coerce 'RepeatedWasmPlugin',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin'->new($_) } @$_ ] };

declare 'MapStringWasmPlugin',
    as HashRef[WasmPlugin()];

declare 'VersionDetails',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::VersionDetails'];

coerce 'VersionDetails',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::VersionDetails'->new($_) };

declare 'RepeatedVersionDetails',
    as ArrayRef[VersionDetails()];

coerce 'RepeatedVersionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::VersionDetails'->new($_) } @$_ ] };

declare 'MapStringVersionDetails',
    as HashRef[VersionDetails()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::VersionDetails::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::VersionDetails::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::VersionDetails::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'LogConfig',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::LogConfig'];

coerce 'LogConfig',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::LogConfig'->new($_) };

declare 'RepeatedLogConfig',
    as ArrayRef[LogConfig()];

coerce 'RepeatedLogConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::LogConfig'->new($_) } @$_ ] };

declare 'MapStringLogConfig',
    as HashRef[LogConfig()];

declare 'LogLevel',
    as (Int | Str);

declare 'UsedBy',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::UsedBy'];

coerce 'UsedBy',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::UsedBy'->new($_) };

declare 'RepeatedUsedBy',
    as ArrayRef[UsedBy()];

coerce 'RepeatedUsedBy',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::UsedBy'->new($_) } @$_ ] };

declare 'MapStringUsedBy',
    as HashRef[UsedBy()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'VersionsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::VersionsEntry'];

coerce 'VersionsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::VersionsEntry'->new($_) };

declare 'RepeatedVersionsEntry',
    as ArrayRef[VersionsEntry()];

coerce 'RepeatedVersionsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPlugin::VersionsEntry'->new($_) } @$_ ] };

declare 'MapStringVersionsEntry',
    as HashRef[VersionsEntry()];

declare 'WasmPluginVersion',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::WasmPluginVersion'];

coerce 'WasmPluginVersion',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPluginVersion'->new($_) };

declare 'RepeatedWasmPluginVersion',
    as ArrayRef[WasmPluginVersion()];

coerce 'RepeatedWasmPluginVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPluginVersion'->new($_) } @$_ ] };

declare 'MapStringWasmPluginVersion',
    as HashRef[WasmPluginVersion()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::WasmPluginVersion::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPluginVersion::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::WasmPluginVersion::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListWasmPluginsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginsRequest'];

coerce 'ListWasmPluginsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginsRequest'->new($_) };

declare 'RepeatedListWasmPluginsRequest',
    as ArrayRef[ListWasmPluginsRequest()];

coerce 'RepeatedListWasmPluginsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginsRequest'->new($_) } @$_ ] };

declare 'MapStringListWasmPluginsRequest',
    as HashRef[ListWasmPluginsRequest()];

declare 'ListWasmPluginsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginsResponse'];

coerce 'ListWasmPluginsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginsResponse'->new($_) };

declare 'RepeatedListWasmPluginsResponse',
    as ArrayRef[ListWasmPluginsResponse()];

coerce 'RepeatedListWasmPluginsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginsResponse'->new($_) } @$_ ] };

declare 'MapStringListWasmPluginsResponse',
    as HashRef[ListWasmPluginsResponse()];

declare 'GetWasmPluginRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::GetWasmPluginRequest'];

coerce 'GetWasmPluginRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::GetWasmPluginRequest'->new($_) };

declare 'RepeatedGetWasmPluginRequest',
    as ArrayRef[GetWasmPluginRequest()];

coerce 'RepeatedGetWasmPluginRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::GetWasmPluginRequest'->new($_) } @$_ ] };

declare 'MapStringGetWasmPluginRequest',
    as HashRef[GetWasmPluginRequest()];

declare 'CreateWasmPluginRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::CreateWasmPluginRequest'];

coerce 'CreateWasmPluginRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::CreateWasmPluginRequest'->new($_) };

declare 'RepeatedCreateWasmPluginRequest',
    as ArrayRef[CreateWasmPluginRequest()];

coerce 'RepeatedCreateWasmPluginRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::CreateWasmPluginRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWasmPluginRequest',
    as HashRef[CreateWasmPluginRequest()];

declare 'UpdateWasmPluginRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::UpdateWasmPluginRequest'];

coerce 'UpdateWasmPluginRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::UpdateWasmPluginRequest'->new($_) };

declare 'RepeatedUpdateWasmPluginRequest',
    as ArrayRef[UpdateWasmPluginRequest()];

coerce 'RepeatedUpdateWasmPluginRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::UpdateWasmPluginRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateWasmPluginRequest',
    as HashRef[UpdateWasmPluginRequest()];

declare 'DeleteWasmPluginRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::DeleteWasmPluginRequest'];

coerce 'DeleteWasmPluginRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::DeleteWasmPluginRequest'->new($_) };

declare 'RepeatedDeleteWasmPluginRequest',
    as ArrayRef[DeleteWasmPluginRequest()];

coerce 'RepeatedDeleteWasmPluginRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::DeleteWasmPluginRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWasmPluginRequest',
    as HashRef[DeleteWasmPluginRequest()];

declare 'ListWasmPluginVersionsRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginVersionsRequest'];

coerce 'ListWasmPluginVersionsRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginVersionsRequest'->new($_) };

declare 'RepeatedListWasmPluginVersionsRequest',
    as ArrayRef[ListWasmPluginVersionsRequest()];

coerce 'RepeatedListWasmPluginVersionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginVersionsRequest'->new($_) } @$_ ] };

declare 'MapStringListWasmPluginVersionsRequest',
    as HashRef[ListWasmPluginVersionsRequest()];

declare 'ListWasmPluginVersionsResponse',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginVersionsResponse'];

coerce 'ListWasmPluginVersionsResponse',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginVersionsResponse'->new($_) };

declare 'RepeatedListWasmPluginVersionsResponse',
    as ArrayRef[ListWasmPluginVersionsResponse()];

coerce 'RepeatedListWasmPluginVersionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::ListWasmPluginVersionsResponse'->new($_) } @$_ ] };

declare 'MapStringListWasmPluginVersionsResponse',
    as HashRef[ListWasmPluginVersionsResponse()];

declare 'GetWasmPluginVersionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::GetWasmPluginVersionRequest'];

coerce 'GetWasmPluginVersionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::GetWasmPluginVersionRequest'->new($_) };

declare 'RepeatedGetWasmPluginVersionRequest',
    as ArrayRef[GetWasmPluginVersionRequest()];

coerce 'RepeatedGetWasmPluginVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::GetWasmPluginVersionRequest'->new($_) } @$_ ] };

declare 'MapStringGetWasmPluginVersionRequest',
    as HashRef[GetWasmPluginVersionRequest()];

declare 'CreateWasmPluginVersionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::CreateWasmPluginVersionRequest'];

coerce 'CreateWasmPluginVersionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::CreateWasmPluginVersionRequest'->new($_) };

declare 'RepeatedCreateWasmPluginVersionRequest',
    as ArrayRef[CreateWasmPluginVersionRequest()];

coerce 'RepeatedCreateWasmPluginVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::CreateWasmPluginVersionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateWasmPluginVersionRequest',
    as HashRef[CreateWasmPluginVersionRequest()];

declare 'DeleteWasmPluginVersionRequest',
    as InstanceOf['Google::Cloud::Networkservices::V1::Extensibility::DeleteWasmPluginVersionRequest'];

coerce 'DeleteWasmPluginVersionRequest',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Extensibility::DeleteWasmPluginVersionRequest'->new($_) };

declare 'RepeatedDeleteWasmPluginVersionRequest',
    as ArrayRef[DeleteWasmPluginVersionRequest()];

coerce 'RepeatedDeleteWasmPluginVersionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Extensibility::DeleteWasmPluginVersionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteWasmPluginVersionRequest',
    as HashRef[DeleteWasmPluginVersionRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::Extensibility::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
