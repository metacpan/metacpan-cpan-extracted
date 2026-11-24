package Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListDataAgentsRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListDataAgentsRequest'];

coerce 'ListDataAgentsRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListDataAgentsRequest'->new($_) };

declare 'RepeatedListDataAgentsRequest',
    as ArrayRef[ListDataAgentsRequest()];

coerce 'RepeatedListDataAgentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListDataAgentsRequest'->new($_) } @$_ ] };

declare 'MapStringListDataAgentsRequest',
    as HashRef[ListDataAgentsRequest()];

declare 'ListDataAgentsResponse',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListDataAgentsResponse'];

coerce 'ListDataAgentsResponse',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListDataAgentsResponse'->new($_) };

declare 'RepeatedListDataAgentsResponse',
    as ArrayRef[ListDataAgentsResponse()];

coerce 'RepeatedListDataAgentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListDataAgentsResponse'->new($_) } @$_ ] };

declare 'MapStringListDataAgentsResponse',
    as HashRef[ListDataAgentsResponse()];

declare 'ListAccessibleDataAgentsRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListAccessibleDataAgentsRequest'];

coerce 'ListAccessibleDataAgentsRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListAccessibleDataAgentsRequest'->new($_) };

declare 'RepeatedListAccessibleDataAgentsRequest',
    as ArrayRef[ListAccessibleDataAgentsRequest()];

coerce 'RepeatedListAccessibleDataAgentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListAccessibleDataAgentsRequest'->new($_) } @$_ ] };

declare 'MapStringListAccessibleDataAgentsRequest',
    as HashRef[ListAccessibleDataAgentsRequest()];

declare 'CreatorFilter',
    as (Int | Str);

declare 'ListAccessibleDataAgentsResponse',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListAccessibleDataAgentsResponse'];

coerce 'ListAccessibleDataAgentsResponse',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListAccessibleDataAgentsResponse'->new($_) };

declare 'RepeatedListAccessibleDataAgentsResponse',
    as ArrayRef[ListAccessibleDataAgentsResponse()];

coerce 'RepeatedListAccessibleDataAgentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::ListAccessibleDataAgentsResponse'->new($_) } @$_ ] };

declare 'MapStringListAccessibleDataAgentsResponse',
    as HashRef[ListAccessibleDataAgentsResponse()];

declare 'GetDataAgentRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::GetDataAgentRequest'];

coerce 'GetDataAgentRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::GetDataAgentRequest'->new($_) };

declare 'RepeatedGetDataAgentRequest',
    as ArrayRef[GetDataAgentRequest()];

coerce 'RepeatedGetDataAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::GetDataAgentRequest'->new($_) } @$_ ] };

declare 'MapStringGetDataAgentRequest',
    as HashRef[GetDataAgentRequest()];

declare 'CreateDataAgentRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::CreateDataAgentRequest'];

coerce 'CreateDataAgentRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::CreateDataAgentRequest'->new($_) };

declare 'RepeatedCreateDataAgentRequest',
    as ArrayRef[CreateDataAgentRequest()];

coerce 'RepeatedCreateDataAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::CreateDataAgentRequest'->new($_) } @$_ ] };

declare 'MapStringCreateDataAgentRequest',
    as HashRef[CreateDataAgentRequest()];

declare 'UpdateDataAgentRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::UpdateDataAgentRequest'];

coerce 'UpdateDataAgentRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::UpdateDataAgentRequest'->new($_) };

declare 'RepeatedUpdateDataAgentRequest',
    as ArrayRef[UpdateDataAgentRequest()];

coerce 'RepeatedUpdateDataAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::UpdateDataAgentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateDataAgentRequest',
    as HashRef[UpdateDataAgentRequest()];

declare 'DeleteDataAgentRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::DeleteDataAgentRequest'];

coerce 'DeleteDataAgentRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::DeleteDataAgentRequest'->new($_) };

declare 'RepeatedDeleteDataAgentRequest',
    as ArrayRef[DeleteDataAgentRequest()];

coerce 'RepeatedDeleteDataAgentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::DeleteDataAgentRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteDataAgentRequest',
    as HashRef[DeleteDataAgentRequest()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'SetAgentOpsObservabilityRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::SetAgentOpsObservabilityRequest'];

coerce 'SetAgentOpsObservabilityRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::SetAgentOpsObservabilityRequest'->new($_) };

declare 'RepeatedSetAgentOpsObservabilityRequest',
    as ArrayRef[SetAgentOpsObservabilityRequest()];

coerce 'RepeatedSetAgentOpsObservabilityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::SetAgentOpsObservabilityRequest'->new($_) } @$_ ] };

declare 'MapStringSetAgentOpsObservabilityRequest',
    as HashRef[SetAgentOpsObservabilityRequest()];

declare 'SetAgentOpsObservabilityResponse',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::SetAgentOpsObservabilityResponse'];

coerce 'SetAgentOpsObservabilityResponse',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::SetAgentOpsObservabilityResponse'->new($_) };

declare 'RepeatedSetAgentOpsObservabilityResponse',
    as ArrayRef[SetAgentOpsObservabilityResponse()];

coerce 'RepeatedSetAgentOpsObservabilityResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::SetAgentOpsObservabilityResponse'->new($_) } @$_ ] };

declare 'MapStringSetAgentOpsObservabilityResponse',
    as HashRef[SetAgentOpsObservabilityResponse()];

declare 'SetAgentOpsObservabilityMetadata',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::SetAgentOpsObservabilityMetadata'];

coerce 'SetAgentOpsObservabilityMetadata',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::SetAgentOpsObservabilityMetadata'->new($_) };

declare 'RepeatedSetAgentOpsObservabilityMetadata',
    as ArrayRef[SetAgentOpsObservabilityMetadata()];

coerce 'RepeatedSetAgentOpsObservabilityMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::SetAgentOpsObservabilityMetadata'->new($_) } @$_ ] };

declare 'MapStringSetAgentOpsObservabilityMetadata',
    as HashRef[SetAgentOpsObservabilityMetadata()];

declare 'RetrieveAgentOpsObservabilityRequest',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::RetrieveAgentOpsObservabilityRequest'];

coerce 'RetrieveAgentOpsObservabilityRequest',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::RetrieveAgentOpsObservabilityRequest'->new($_) };

declare 'RepeatedRetrieveAgentOpsObservabilityRequest',
    as ArrayRef[RetrieveAgentOpsObservabilityRequest()];

coerce 'RepeatedRetrieveAgentOpsObservabilityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::RetrieveAgentOpsObservabilityRequest'->new($_) } @$_ ] };

declare 'MapStringRetrieveAgentOpsObservabilityRequest',
    as HashRef[RetrieveAgentOpsObservabilityRequest()];

declare 'RetrieveAgentOpsObservabilityResponse',
    as InstanceOf['Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::RetrieveAgentOpsObservabilityResponse'];

coerce 'RetrieveAgentOpsObservabilityResponse',
    from HashRef, via { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::RetrieveAgentOpsObservabilityResponse'->new($_) };

declare 'RepeatedRetrieveAgentOpsObservabilityResponse',
    as ArrayRef[RetrieveAgentOpsObservabilityResponse()];

coerce 'RepeatedRetrieveAgentOpsObservabilityResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::RetrieveAgentOpsObservabilityResponse'->new($_) } @$_ ] };

declare 'MapStringRetrieveAgentOpsObservabilityResponse',
    as HashRef[RetrieveAgentOpsObservabilityResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Geminidataanalytics::V1beta::DataAgentService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
