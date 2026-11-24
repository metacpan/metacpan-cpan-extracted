package Google::Cloud::Discoveryengine::V1alpha::EvaluationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetEvaluationRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest'];

coerce 'GetEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest'->new($_) };

declare 'RepeatedGetEvaluationRequest',
    as ArrayRef[GetEvaluationRequest()];

coerce 'RepeatedGetEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::GetEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringGetEvaluationRequest',
    as HashRef[GetEvaluationRequest()];

declare 'ListEvaluationsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsRequest'];

coerce 'ListEvaluationsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsRequest'->new($_) };

declare 'RepeatedListEvaluationsRequest',
    as ArrayRef[ListEvaluationsRequest()];

coerce 'RepeatedListEvaluationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsRequest'->new($_) } @$_ ] };

declare 'MapStringListEvaluationsRequest',
    as HashRef[ListEvaluationsRequest()];

declare 'ListEvaluationsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsResponse'];

coerce 'ListEvaluationsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsResponse'->new($_) };

declare 'RepeatedListEvaluationsResponse',
    as ArrayRef[ListEvaluationsResponse()];

coerce 'RepeatedListEvaluationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationsResponse'->new($_) } @$_ ] };

declare 'MapStringListEvaluationsResponse',
    as HashRef[ListEvaluationsResponse()];

declare 'CreateEvaluationRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationRequest'];

coerce 'CreateEvaluationRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationRequest'->new($_) };

declare 'RepeatedCreateEvaluationRequest',
    as ArrayRef[CreateEvaluationRequest()];

coerce 'RepeatedCreateEvaluationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEvaluationRequest',
    as HashRef[CreateEvaluationRequest()];

declare 'CreateEvaluationMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationMetadata'];

coerce 'CreateEvaluationMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationMetadata'->new($_) };

declare 'RepeatedCreateEvaluationMetadata',
    as ArrayRef[CreateEvaluationMetadata()];

coerce 'RepeatedCreateEvaluationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::CreateEvaluationMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateEvaluationMetadata',
    as HashRef[CreateEvaluationMetadata()];

declare 'ListEvaluationResultsRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsRequest'];

coerce 'ListEvaluationResultsRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsRequest'->new($_) };

declare 'RepeatedListEvaluationResultsRequest',
    as ArrayRef[ListEvaluationResultsRequest()];

coerce 'RepeatedListEvaluationResultsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsRequest'->new($_) } @$_ ] };

declare 'MapStringListEvaluationResultsRequest',
    as HashRef[ListEvaluationResultsRequest()];

declare 'ListEvaluationResultsResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsResponse'];

coerce 'ListEvaluationResultsResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsResponse'->new($_) };

declare 'RepeatedListEvaluationResultsResponse',
    as ArrayRef[ListEvaluationResultsResponse()];

coerce 'RepeatedListEvaluationResultsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsResponse'->new($_) } @$_ ] };

declare 'MapStringListEvaluationResultsResponse',
    as HashRef[ListEvaluationResultsResponse()];

declare 'EvaluationResult',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsResponse::EvaluationResult'];

coerce 'EvaluationResult',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsResponse::EvaluationResult'->new($_) };

declare 'RepeatedEvaluationResult',
    as ArrayRef[EvaluationResult()];

coerce 'RepeatedEvaluationResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::EvaluationService::ListEvaluationResultsResponse::EvaluationResult'->new($_) } @$_ ] };

declare 'MapStringEvaluationResult',
    as HashRef[EvaluationResult()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::EvaluationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
