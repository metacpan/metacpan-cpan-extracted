package Google::Cloud::Financialservices::V1::EngineConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EngineConfig',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig'];

coerce 'EngineConfig',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig'->new($_) };

declare 'RepeatedEngineConfig',
    as ArrayRef[EngineConfig()];

coerce 'RepeatedEngineConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig'->new($_) } @$_ ] };

declare 'MapStringEngineConfig',
    as HashRef[EngineConfig()];

declare 'State',
    as (Int | Str);

declare 'HyperparameterSourceType',
    as (Int | Str);

declare 'Tuning',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::Tuning'];

coerce 'Tuning',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::Tuning'->new($_) };

declare 'RepeatedTuning',
    as ArrayRef[Tuning()];

coerce 'RepeatedTuning',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::Tuning'->new($_) } @$_ ] };

declare 'MapStringTuning',
    as HashRef[Tuning()];

declare 'PerformanceTarget',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::PerformanceTarget'];

coerce 'PerformanceTarget',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::PerformanceTarget'->new($_) };

declare 'RepeatedPerformanceTarget',
    as ArrayRef[PerformanceTarget()];

coerce 'RepeatedPerformanceTarget',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::PerformanceTarget'->new($_) } @$_ ] };

declare 'MapStringPerformanceTarget',
    as HashRef[PerformanceTarget()];

declare 'HyperparameterSource',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::HyperparameterSource'];

coerce 'HyperparameterSource',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::HyperparameterSource'->new($_) };

declare 'RepeatedHyperparameterSource',
    as ArrayRef[HyperparameterSource()];

coerce 'RepeatedHyperparameterSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::HyperparameterSource'->new($_) } @$_ ] };

declare 'MapStringHyperparameterSource',
    as HashRef[HyperparameterSource()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::EngineConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListEngineConfigsRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsRequest'];

coerce 'ListEngineConfigsRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsRequest'->new($_) };

declare 'RepeatedListEngineConfigsRequest',
    as ArrayRef[ListEngineConfigsRequest()];

coerce 'RepeatedListEngineConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListEngineConfigsRequest',
    as HashRef[ListEngineConfigsRequest()];

declare 'ListEngineConfigsResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsResponse'];

coerce 'ListEngineConfigsResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsResponse'->new($_) };

declare 'RepeatedListEngineConfigsResponse',
    as ArrayRef[ListEngineConfigsResponse()];

coerce 'RepeatedListEngineConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::ListEngineConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListEngineConfigsResponse',
    as HashRef[ListEngineConfigsResponse()];

declare 'GetEngineConfigRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::GetEngineConfigRequest'];

coerce 'GetEngineConfigRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::GetEngineConfigRequest'->new($_) };

declare 'RepeatedGetEngineConfigRequest',
    as ArrayRef[GetEngineConfigRequest()];

coerce 'RepeatedGetEngineConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::GetEngineConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetEngineConfigRequest',
    as HashRef[GetEngineConfigRequest()];

declare 'CreateEngineConfigRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::CreateEngineConfigRequest'];

coerce 'CreateEngineConfigRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::CreateEngineConfigRequest'->new($_) };

declare 'RepeatedCreateEngineConfigRequest',
    as ArrayRef[CreateEngineConfigRequest()];

coerce 'RepeatedCreateEngineConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::CreateEngineConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEngineConfigRequest',
    as HashRef[CreateEngineConfigRequest()];

declare 'UpdateEngineConfigRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::UpdateEngineConfigRequest'];

coerce 'UpdateEngineConfigRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::UpdateEngineConfigRequest'->new($_) };

declare 'RepeatedUpdateEngineConfigRequest',
    as ArrayRef[UpdateEngineConfigRequest()];

coerce 'RepeatedUpdateEngineConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::UpdateEngineConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEngineConfigRequest',
    as HashRef[UpdateEngineConfigRequest()];

declare 'DeleteEngineConfigRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::DeleteEngineConfigRequest'];

coerce 'DeleteEngineConfigRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::DeleteEngineConfigRequest'->new($_) };

declare 'RepeatedDeleteEngineConfigRequest',
    as ArrayRef[DeleteEngineConfigRequest()];

coerce 'RepeatedDeleteEngineConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::DeleteEngineConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEngineConfigRequest',
    as HashRef[DeleteEngineConfigRequest()];

declare 'ExportEngineConfigMetadataRequest',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataRequest'];

coerce 'ExportEngineConfigMetadataRequest',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataRequest'->new($_) };

declare 'RepeatedExportEngineConfigMetadataRequest',
    as ArrayRef[ExportEngineConfigMetadataRequest()];

coerce 'RepeatedExportEngineConfigMetadataRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataRequest'->new($_) } @$_ ] };

declare 'MapStringExportEngineConfigMetadataRequest',
    as HashRef[ExportEngineConfigMetadataRequest()];

declare 'ExportEngineConfigMetadataResponse',
    as InstanceOf['Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataResponse'];

coerce 'ExportEngineConfigMetadataResponse',
    from HashRef, via { 'Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataResponse'->new($_) };

declare 'RepeatedExportEngineConfigMetadataResponse',
    as ArrayRef[ExportEngineConfigMetadataResponse()];

coerce 'RepeatedExportEngineConfigMetadataResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Financialservices::V1::EngineConfig::ExportEngineConfigMetadataResponse'->new($_) } @$_ ] };

declare 'MapStringExportEngineConfigMetadataResponse',
    as HashRef[ExportEngineConfigMetadataResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Financialservices::V1::EngineConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
