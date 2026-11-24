package Google::Cloud::Notebooks::V1beta1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'ListInstancesRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::ListInstancesRequest'];

coerce 'ListInstancesRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::ListInstancesRequest'->new($_) };

declare 'RepeatedListInstancesRequest',
    as ArrayRef[ListInstancesRequest()];

coerce 'RepeatedListInstancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::ListInstancesRequest'->new($_) } @$_ ] };

declare 'MapStringListInstancesRequest',
    as HashRef[ListInstancesRequest()];

declare 'ListInstancesResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::ListInstancesResponse'];

coerce 'ListInstancesResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::ListInstancesResponse'->new($_) };

declare 'RepeatedListInstancesResponse',
    as ArrayRef[ListInstancesResponse()];

coerce 'RepeatedListInstancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::ListInstancesResponse'->new($_) } @$_ ] };

declare 'MapStringListInstancesResponse',
    as HashRef[ListInstancesResponse()];

declare 'GetInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::GetInstanceRequest'];

coerce 'GetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::GetInstanceRequest'->new($_) };

declare 'RepeatedGetInstanceRequest',
    as ArrayRef[GetInstanceRequest()];

coerce 'RepeatedGetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::GetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringGetInstanceRequest',
    as HashRef[GetInstanceRequest()];

declare 'CreateInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::CreateInstanceRequest'];

coerce 'CreateInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::CreateInstanceRequest'->new($_) };

declare 'RepeatedCreateInstanceRequest',
    as ArrayRef[CreateInstanceRequest()];

coerce 'RepeatedCreateInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::CreateInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateInstanceRequest',
    as HashRef[CreateInstanceRequest()];

declare 'RegisterInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::RegisterInstanceRequest'];

coerce 'RegisterInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::RegisterInstanceRequest'->new($_) };

declare 'RepeatedRegisterInstanceRequest',
    as ArrayRef[RegisterInstanceRequest()];

coerce 'RepeatedRegisterInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::RegisterInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringRegisterInstanceRequest',
    as HashRef[RegisterInstanceRequest()];

declare 'SetInstanceAcceleratorRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::SetInstanceAcceleratorRequest'];

coerce 'SetInstanceAcceleratorRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::SetInstanceAcceleratorRequest'->new($_) };

declare 'RepeatedSetInstanceAcceleratorRequest',
    as ArrayRef[SetInstanceAcceleratorRequest()];

coerce 'RepeatedSetInstanceAcceleratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::SetInstanceAcceleratorRequest'->new($_) } @$_ ] };

declare 'MapStringSetInstanceAcceleratorRequest',
    as HashRef[SetInstanceAcceleratorRequest()];

declare 'SetInstanceMachineTypeRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::SetInstanceMachineTypeRequest'];

coerce 'SetInstanceMachineTypeRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::SetInstanceMachineTypeRequest'->new($_) };

declare 'RepeatedSetInstanceMachineTypeRequest',
    as ArrayRef[SetInstanceMachineTypeRequest()];

coerce 'RepeatedSetInstanceMachineTypeRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::SetInstanceMachineTypeRequest'->new($_) } @$_ ] };

declare 'MapStringSetInstanceMachineTypeRequest',
    as HashRef[SetInstanceMachineTypeRequest()];

declare 'SetInstanceLabelsRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::SetInstanceLabelsRequest'];

coerce 'SetInstanceLabelsRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::SetInstanceLabelsRequest'->new($_) };

declare 'RepeatedSetInstanceLabelsRequest',
    as ArrayRef[SetInstanceLabelsRequest()];

coerce 'RepeatedSetInstanceLabelsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::SetInstanceLabelsRequest'->new($_) } @$_ ] };

declare 'MapStringSetInstanceLabelsRequest',
    as HashRef[SetInstanceLabelsRequest()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::SetInstanceLabelsRequest::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::SetInstanceLabelsRequest::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::SetInstanceLabelsRequest::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'DeleteInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::DeleteInstanceRequest'];

coerce 'DeleteInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::DeleteInstanceRequest'->new($_) };

declare 'RepeatedDeleteInstanceRequest',
    as ArrayRef[DeleteInstanceRequest()];

coerce 'RepeatedDeleteInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::DeleteInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteInstanceRequest',
    as HashRef[DeleteInstanceRequest()];

declare 'StartInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::StartInstanceRequest'];

coerce 'StartInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::StartInstanceRequest'->new($_) };

declare 'RepeatedStartInstanceRequest',
    as ArrayRef[StartInstanceRequest()];

coerce 'RepeatedStartInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::StartInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringStartInstanceRequest',
    as HashRef[StartInstanceRequest()];

declare 'StopInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::StopInstanceRequest'];

coerce 'StopInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::StopInstanceRequest'->new($_) };

declare 'RepeatedStopInstanceRequest',
    as ArrayRef[StopInstanceRequest()];

coerce 'RepeatedStopInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::StopInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringStopInstanceRequest',
    as HashRef[StopInstanceRequest()];

declare 'ResetInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::ResetInstanceRequest'];

coerce 'ResetInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::ResetInstanceRequest'->new($_) };

declare 'RepeatedResetInstanceRequest',
    as ArrayRef[ResetInstanceRequest()];

coerce 'RepeatedResetInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::ResetInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringResetInstanceRequest',
    as HashRef[ResetInstanceRequest()];

declare 'ReportInstanceInfoRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::ReportInstanceInfoRequest'];

coerce 'ReportInstanceInfoRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::ReportInstanceInfoRequest'->new($_) };

declare 'RepeatedReportInstanceInfoRequest',
    as ArrayRef[ReportInstanceInfoRequest()];

coerce 'RepeatedReportInstanceInfoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::ReportInstanceInfoRequest'->new($_) } @$_ ] };

declare 'MapStringReportInstanceInfoRequest',
    as HashRef[ReportInstanceInfoRequest()];

declare 'MetadataEntry',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::ReportInstanceInfoRequest::MetadataEntry'];

coerce 'MetadataEntry',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::ReportInstanceInfoRequest::MetadataEntry'->new($_) };

declare 'RepeatedMetadataEntry',
    as ArrayRef[MetadataEntry()];

coerce 'RepeatedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::ReportInstanceInfoRequest::MetadataEntry'->new($_) } @$_ ] };

declare 'MapStringMetadataEntry',
    as HashRef[MetadataEntry()];

declare 'IsInstanceUpgradeableRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::IsInstanceUpgradeableRequest'];

coerce 'IsInstanceUpgradeableRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::IsInstanceUpgradeableRequest'->new($_) };

declare 'RepeatedIsInstanceUpgradeableRequest',
    as ArrayRef[IsInstanceUpgradeableRequest()];

coerce 'RepeatedIsInstanceUpgradeableRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::IsInstanceUpgradeableRequest'->new($_) } @$_ ] };

declare 'MapStringIsInstanceUpgradeableRequest',
    as HashRef[IsInstanceUpgradeableRequest()];

declare 'IsInstanceUpgradeableResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::IsInstanceUpgradeableResponse'];

coerce 'IsInstanceUpgradeableResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::IsInstanceUpgradeableResponse'->new($_) };

declare 'RepeatedIsInstanceUpgradeableResponse',
    as ArrayRef[IsInstanceUpgradeableResponse()];

coerce 'RepeatedIsInstanceUpgradeableResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::IsInstanceUpgradeableResponse'->new($_) } @$_ ] };

declare 'MapStringIsInstanceUpgradeableResponse',
    as HashRef[IsInstanceUpgradeableResponse()];

declare 'UpgradeInstanceRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::UpgradeInstanceRequest'];

coerce 'UpgradeInstanceRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::UpgradeInstanceRequest'->new($_) };

declare 'RepeatedUpgradeInstanceRequest',
    as ArrayRef[UpgradeInstanceRequest()];

coerce 'RepeatedUpgradeInstanceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::UpgradeInstanceRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeInstanceRequest',
    as HashRef[UpgradeInstanceRequest()];

declare 'UpgradeInstanceInternalRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::UpgradeInstanceInternalRequest'];

coerce 'UpgradeInstanceInternalRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::UpgradeInstanceInternalRequest'->new($_) };

declare 'RepeatedUpgradeInstanceInternalRequest',
    as ArrayRef[UpgradeInstanceInternalRequest()];

coerce 'RepeatedUpgradeInstanceInternalRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::UpgradeInstanceInternalRequest'->new($_) } @$_ ] };

declare 'MapStringUpgradeInstanceInternalRequest',
    as HashRef[UpgradeInstanceInternalRequest()];

declare 'ListEnvironmentsRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::ListEnvironmentsRequest'];

coerce 'ListEnvironmentsRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::ListEnvironmentsRequest'->new($_) };

declare 'RepeatedListEnvironmentsRequest',
    as ArrayRef[ListEnvironmentsRequest()];

coerce 'RepeatedListEnvironmentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::ListEnvironmentsRequest'->new($_) } @$_ ] };

declare 'MapStringListEnvironmentsRequest',
    as HashRef[ListEnvironmentsRequest()];

declare 'ListEnvironmentsResponse',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::ListEnvironmentsResponse'];

coerce 'ListEnvironmentsResponse',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::ListEnvironmentsResponse'->new($_) };

declare 'RepeatedListEnvironmentsResponse',
    as ArrayRef[ListEnvironmentsResponse()];

coerce 'RepeatedListEnvironmentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::ListEnvironmentsResponse'->new($_) } @$_ ] };

declare 'MapStringListEnvironmentsResponse',
    as HashRef[ListEnvironmentsResponse()];

declare 'GetEnvironmentRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::GetEnvironmentRequest'];

coerce 'GetEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::GetEnvironmentRequest'->new($_) };

declare 'RepeatedGetEnvironmentRequest',
    as ArrayRef[GetEnvironmentRequest()];

coerce 'RepeatedGetEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::GetEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringGetEnvironmentRequest',
    as HashRef[GetEnvironmentRequest()];

declare 'CreateEnvironmentRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::CreateEnvironmentRequest'];

coerce 'CreateEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::CreateEnvironmentRequest'->new($_) };

declare 'RepeatedCreateEnvironmentRequest',
    as ArrayRef[CreateEnvironmentRequest()];

coerce 'RepeatedCreateEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::CreateEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEnvironmentRequest',
    as HashRef[CreateEnvironmentRequest()];

declare 'DeleteEnvironmentRequest',
    as InstanceOf['Google::Cloud::Notebooks::V1beta1::Service::DeleteEnvironmentRequest'];

coerce 'DeleteEnvironmentRequest',
    from HashRef, via { 'Google::Cloud::Notebooks::V1beta1::Service::DeleteEnvironmentRequest'->new($_) };

declare 'RepeatedDeleteEnvironmentRequest',
    as ArrayRef[DeleteEnvironmentRequest()];

coerce 'RepeatedDeleteEnvironmentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Notebooks::V1beta1::Service::DeleteEnvironmentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEnvironmentRequest',
    as HashRef[DeleteEnvironmentRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Notebooks::V1beta1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
