package Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MulticloudDataTransferConfig',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferConfig'];

coerce 'MulticloudDataTransferConfig',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferConfig'->new($_) };

declare 'RepeatedMulticloudDataTransferConfig',
    as ArrayRef[MulticloudDataTransferConfig()];

coerce 'RepeatedMulticloudDataTransferConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferConfig'->new($_) } @$_ ] };

declare 'MapStringMulticloudDataTransferConfig',
    as HashRef[MulticloudDataTransferConfig()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferConfig::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferConfig::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferConfig::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ServicesEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferConfig::ServicesEntry'];

coerce 'ServicesEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferConfig::ServicesEntry'->new($_) };

declare 'RepeatedServicesEntry',
    as ArrayRef[ServicesEntry()];

coerce 'RepeatedServicesEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferConfig::ServicesEntry'->new($_) } @$_ ] };

declare 'MapStringServicesEntry',
    as HashRef[ServicesEntry()];

declare 'ListMulticloudDataTransferConfigsRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferConfigsRequest'];

coerce 'ListMulticloudDataTransferConfigsRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferConfigsRequest'->new($_) };

declare 'RepeatedListMulticloudDataTransferConfigsRequest',
    as ArrayRef[ListMulticloudDataTransferConfigsRequest()];

coerce 'RepeatedListMulticloudDataTransferConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListMulticloudDataTransferConfigsRequest',
    as HashRef[ListMulticloudDataTransferConfigsRequest()];

declare 'ListMulticloudDataTransferConfigsResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferConfigsResponse'];

coerce 'ListMulticloudDataTransferConfigsResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferConfigsResponse'->new($_) };

declare 'RepeatedListMulticloudDataTransferConfigsResponse',
    as ArrayRef[ListMulticloudDataTransferConfigsResponse()];

coerce 'RepeatedListMulticloudDataTransferConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListMulticloudDataTransferConfigsResponse',
    as HashRef[ListMulticloudDataTransferConfigsResponse()];

declare 'GetMulticloudDataTransferConfigRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::GetMulticloudDataTransferConfigRequest'];

coerce 'GetMulticloudDataTransferConfigRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::GetMulticloudDataTransferConfigRequest'->new($_) };

declare 'RepeatedGetMulticloudDataTransferConfigRequest',
    as ArrayRef[GetMulticloudDataTransferConfigRequest()];

coerce 'RepeatedGetMulticloudDataTransferConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::GetMulticloudDataTransferConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetMulticloudDataTransferConfigRequest',
    as HashRef[GetMulticloudDataTransferConfigRequest()];

declare 'CreateMulticloudDataTransferConfigRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::CreateMulticloudDataTransferConfigRequest'];

coerce 'CreateMulticloudDataTransferConfigRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::CreateMulticloudDataTransferConfigRequest'->new($_) };

declare 'RepeatedCreateMulticloudDataTransferConfigRequest',
    as ArrayRef[CreateMulticloudDataTransferConfigRequest()];

coerce 'RepeatedCreateMulticloudDataTransferConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::CreateMulticloudDataTransferConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMulticloudDataTransferConfigRequest',
    as HashRef[CreateMulticloudDataTransferConfigRequest()];

declare 'UpdateMulticloudDataTransferConfigRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::UpdateMulticloudDataTransferConfigRequest'];

coerce 'UpdateMulticloudDataTransferConfigRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::UpdateMulticloudDataTransferConfigRequest'->new($_) };

declare 'RepeatedUpdateMulticloudDataTransferConfigRequest',
    as ArrayRef[UpdateMulticloudDataTransferConfigRequest()];

coerce 'RepeatedUpdateMulticloudDataTransferConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::UpdateMulticloudDataTransferConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateMulticloudDataTransferConfigRequest',
    as HashRef[UpdateMulticloudDataTransferConfigRequest()];

declare 'DeleteMulticloudDataTransferConfigRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::DeleteMulticloudDataTransferConfigRequest'];

coerce 'DeleteMulticloudDataTransferConfigRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::DeleteMulticloudDataTransferConfigRequest'->new($_) };

declare 'RepeatedDeleteMulticloudDataTransferConfigRequest',
    as ArrayRef[DeleteMulticloudDataTransferConfigRequest()];

coerce 'RepeatedDeleteMulticloudDataTransferConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::DeleteMulticloudDataTransferConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMulticloudDataTransferConfigRequest',
    as HashRef[DeleteMulticloudDataTransferConfigRequest()];

declare 'Destination',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Destination'];

coerce 'Destination',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Destination'->new($_) };

declare 'RepeatedDestination',
    as ArrayRef[Destination()];

coerce 'RepeatedDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Destination'->new($_) } @$_ ] };

declare 'MapStringDestination',
    as HashRef[Destination()];

declare 'DestinationEndpoint',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Destination::DestinationEndpoint'];

coerce 'DestinationEndpoint',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Destination::DestinationEndpoint'->new($_) };

declare 'RepeatedDestinationEndpoint',
    as ArrayRef[DestinationEndpoint()];

coerce 'RepeatedDestinationEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Destination::DestinationEndpoint'->new($_) } @$_ ] };

declare 'MapStringDestinationEndpoint',
    as HashRef[DestinationEndpoint()];

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Destination::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Destination::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Destination::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListDestinationsRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListDestinationsRequest'];

coerce 'ListDestinationsRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListDestinationsRequest'->new($_) };

declare 'RepeatedListDestinationsRequest',
    as ArrayRef[ListDestinationsRequest()];

coerce 'RepeatedListDestinationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListDestinationsRequest'->new($_) } @$_ ] };

declare 'MapStringListDestinationsRequest',
    as HashRef[ListDestinationsRequest()];

declare 'ListDestinationsResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListDestinationsResponse'];

coerce 'ListDestinationsResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListDestinationsResponse'->new($_) };

declare 'RepeatedListDestinationsResponse',
    as ArrayRef[ListDestinationsResponse()];

coerce 'RepeatedListDestinationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListDestinationsResponse'->new($_) } @$_ ] };

declare 'MapStringListDestinationsResponse',
    as HashRef[ListDestinationsResponse()];

declare 'GetDestinationRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::GetDestinationRequest'];

coerce 'GetDestinationRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::GetDestinationRequest'->new($_) };

declare 'RepeatedGetDestinationRequest',
    as ArrayRef[GetDestinationRequest()];

coerce 'RepeatedGetDestinationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::GetDestinationRequest'->new($_) } @$_ ] };

declare 'MapStringGetDestinationRequest',
    as HashRef[GetDestinationRequest()];

declare 'CreateDestinationRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::CreateDestinationRequest'];

coerce 'CreateDestinationRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::CreateDestinationRequest'->new($_) };

declare 'RepeatedCreateDestinationRequest',
    as ArrayRef[CreateDestinationRequest()];

coerce 'RepeatedCreateDestinationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::CreateDestinationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDestinationRequest',
    as HashRef[CreateDestinationRequest()];

declare 'UpdateDestinationRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::UpdateDestinationRequest'];

coerce 'UpdateDestinationRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::UpdateDestinationRequest'->new($_) };

declare 'RepeatedUpdateDestinationRequest',
    as ArrayRef[UpdateDestinationRequest()];

coerce 'RepeatedUpdateDestinationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::UpdateDestinationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDestinationRequest',
    as HashRef[UpdateDestinationRequest()];

declare 'DeleteDestinationRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::DeleteDestinationRequest'];

coerce 'DeleteDestinationRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::DeleteDestinationRequest'->new($_) };

declare 'RepeatedDeleteDestinationRequest',
    as ArrayRef[DeleteDestinationRequest()];

coerce 'RepeatedDeleteDestinationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::DeleteDestinationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDestinationRequest',
    as HashRef[DeleteDestinationRequest()];

declare 'StateTimeline',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::StateTimeline'];

coerce 'StateTimeline',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::StateTimeline'->new($_) };

declare 'RepeatedStateTimeline',
    as ArrayRef[StateTimeline()];

coerce 'RepeatedStateTimeline',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::StateTimeline'->new($_) } @$_ ] };

declare 'MapStringStateTimeline',
    as HashRef[StateTimeline()];

declare 'StateMetadata',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::StateTimeline::StateMetadata'];

coerce 'StateMetadata',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::StateTimeline::StateMetadata'->new($_) };

declare 'RepeatedStateMetadata',
    as ArrayRef[StateMetadata()];

coerce 'RepeatedStateMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::StateTimeline::StateMetadata'->new($_) } @$_ ] };

declare 'MapStringStateMetadata',
    as HashRef[StateMetadata()];

declare 'State',
    as (Int | Str);

declare 'MulticloudDataTransferSupportedService',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferSupportedService'];

coerce 'MulticloudDataTransferSupportedService',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferSupportedService'->new($_) };

declare 'RepeatedMulticloudDataTransferSupportedService',
    as ArrayRef[MulticloudDataTransferSupportedService()];

coerce 'RepeatedMulticloudDataTransferSupportedService',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::MulticloudDataTransferSupportedService'->new($_) } @$_ ] };

declare 'MapStringMulticloudDataTransferSupportedService',
    as HashRef[MulticloudDataTransferSupportedService()];

declare 'ServiceConfig',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ServiceConfig'];

coerce 'ServiceConfig',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ServiceConfig'->new($_) };

declare 'RepeatedServiceConfig',
    as ArrayRef[ServiceConfig()];

coerce 'RepeatedServiceConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ServiceConfig'->new($_) } @$_ ] };

declare 'MapStringServiceConfig',
    as HashRef[ServiceConfig()];

declare 'EligibilityCriteria',
    as (Int | Str);

declare 'GetMulticloudDataTransferSupportedServiceRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::GetMulticloudDataTransferSupportedServiceRequest'];

coerce 'GetMulticloudDataTransferSupportedServiceRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::GetMulticloudDataTransferSupportedServiceRequest'->new($_) };

declare 'RepeatedGetMulticloudDataTransferSupportedServiceRequest',
    as ArrayRef[GetMulticloudDataTransferSupportedServiceRequest()];

coerce 'RepeatedGetMulticloudDataTransferSupportedServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::GetMulticloudDataTransferSupportedServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetMulticloudDataTransferSupportedServiceRequest',
    as HashRef[GetMulticloudDataTransferSupportedServiceRequest()];

declare 'ListMulticloudDataTransferSupportedServicesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferSupportedServicesRequest'];

coerce 'ListMulticloudDataTransferSupportedServicesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferSupportedServicesRequest'->new($_) };

declare 'RepeatedListMulticloudDataTransferSupportedServicesRequest',
    as ArrayRef[ListMulticloudDataTransferSupportedServicesRequest()];

coerce 'RepeatedListMulticloudDataTransferSupportedServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferSupportedServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListMulticloudDataTransferSupportedServicesRequest',
    as HashRef[ListMulticloudDataTransferSupportedServicesRequest()];

declare 'ListMulticloudDataTransferSupportedServicesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferSupportedServicesResponse'];

coerce 'ListMulticloudDataTransferSupportedServicesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferSupportedServicesResponse'->new($_) };

declare 'RepeatedListMulticloudDataTransferSupportedServicesResponse',
    as ArrayRef[ListMulticloudDataTransferSupportedServicesResponse()];

coerce 'RepeatedListMulticloudDataTransferSupportedServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::DataTransfer::ListMulticloudDataTransferSupportedServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListMulticloudDataTransferSupportedServicesResponse',
    as HashRef[ListMulticloudDataTransferSupportedServicesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Networkconnectivity::V1beta::DataTransfer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
