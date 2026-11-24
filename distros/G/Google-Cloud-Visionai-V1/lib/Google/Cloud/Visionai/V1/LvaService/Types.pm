package Google::Cloud::Visionai::V1::LvaService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Registry',
    as (Int | Str);

declare 'ListOperatorsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::ListOperatorsRequest'];

coerce 'ListOperatorsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::ListOperatorsRequest'->new($_) };

declare 'RepeatedListOperatorsRequest',
    as ArrayRef[ListOperatorsRequest()];

coerce 'RepeatedListOperatorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::ListOperatorsRequest'->new($_) } @$_ ] };

declare 'MapStringListOperatorsRequest',
    as HashRef[ListOperatorsRequest()];

declare 'ListOperatorsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::ListOperatorsResponse'];

coerce 'ListOperatorsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::ListOperatorsResponse'->new($_) };

declare 'RepeatedListOperatorsResponse',
    as ArrayRef[ListOperatorsResponse()];

coerce 'RepeatedListOperatorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::ListOperatorsResponse'->new($_) } @$_ ] };

declare 'MapStringListOperatorsResponse',
    as HashRef[ListOperatorsResponse()];

declare 'GetOperatorRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::GetOperatorRequest'];

coerce 'GetOperatorRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::GetOperatorRequest'->new($_) };

declare 'RepeatedGetOperatorRequest',
    as ArrayRef[GetOperatorRequest()];

coerce 'RepeatedGetOperatorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::GetOperatorRequest'->new($_) } @$_ ] };

declare 'MapStringGetOperatorRequest',
    as HashRef[GetOperatorRequest()];

declare 'CreateOperatorRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::CreateOperatorRequest'];

coerce 'CreateOperatorRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::CreateOperatorRequest'->new($_) };

declare 'RepeatedCreateOperatorRequest',
    as ArrayRef[CreateOperatorRequest()];

coerce 'RepeatedCreateOperatorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::CreateOperatorRequest'->new($_) } @$_ ] };

declare 'MapStringCreateOperatorRequest',
    as HashRef[CreateOperatorRequest()];

declare 'UpdateOperatorRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::UpdateOperatorRequest'];

coerce 'UpdateOperatorRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::UpdateOperatorRequest'->new($_) };

declare 'RepeatedUpdateOperatorRequest',
    as ArrayRef[UpdateOperatorRequest()];

coerce 'RepeatedUpdateOperatorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::UpdateOperatorRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateOperatorRequest',
    as HashRef[UpdateOperatorRequest()];

declare 'DeleteOperatorRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::DeleteOperatorRequest'];

coerce 'DeleteOperatorRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::DeleteOperatorRequest'->new($_) };

declare 'RepeatedDeleteOperatorRequest',
    as ArrayRef[DeleteOperatorRequest()];

coerce 'RepeatedDeleteOperatorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::DeleteOperatorRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteOperatorRequest',
    as HashRef[DeleteOperatorRequest()];

declare 'ListAnalysesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::ListAnalysesRequest'];

coerce 'ListAnalysesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::ListAnalysesRequest'->new($_) };

declare 'RepeatedListAnalysesRequest',
    as ArrayRef[ListAnalysesRequest()];

coerce 'RepeatedListAnalysesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::ListAnalysesRequest'->new($_) } @$_ ] };

declare 'MapStringListAnalysesRequest',
    as HashRef[ListAnalysesRequest()];

declare 'ListAnalysesResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::ListAnalysesResponse'];

coerce 'ListAnalysesResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::ListAnalysesResponse'->new($_) };

declare 'RepeatedListAnalysesResponse',
    as ArrayRef[ListAnalysesResponse()];

coerce 'RepeatedListAnalysesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::ListAnalysesResponse'->new($_) } @$_ ] };

declare 'MapStringListAnalysesResponse',
    as HashRef[ListAnalysesResponse()];

declare 'GetAnalysisRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::GetAnalysisRequest'];

coerce 'GetAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::GetAnalysisRequest'->new($_) };

declare 'RepeatedGetAnalysisRequest',
    as ArrayRef[GetAnalysisRequest()];

coerce 'RepeatedGetAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::GetAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringGetAnalysisRequest',
    as HashRef[GetAnalysisRequest()];

declare 'CreateAnalysisRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::CreateAnalysisRequest'];

coerce 'CreateAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::CreateAnalysisRequest'->new($_) };

declare 'RepeatedCreateAnalysisRequest',
    as ArrayRef[CreateAnalysisRequest()];

coerce 'RepeatedCreateAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::CreateAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAnalysisRequest',
    as HashRef[CreateAnalysisRequest()];

declare 'UpdateAnalysisRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::UpdateAnalysisRequest'];

coerce 'UpdateAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::UpdateAnalysisRequest'->new($_) };

declare 'RepeatedUpdateAnalysisRequest',
    as ArrayRef[UpdateAnalysisRequest()];

coerce 'RepeatedUpdateAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::UpdateAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAnalysisRequest',
    as HashRef[UpdateAnalysisRequest()];

declare 'DeleteAnalysisRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::DeleteAnalysisRequest'];

coerce 'DeleteAnalysisRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::DeleteAnalysisRequest'->new($_) };

declare 'RepeatedDeleteAnalysisRequest',
    as ArrayRef[DeleteAnalysisRequest()];

coerce 'RepeatedDeleteAnalysisRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::DeleteAnalysisRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAnalysisRequest',
    as HashRef[DeleteAnalysisRequest()];

declare 'ListProcessesRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::ListProcessesRequest'];

coerce 'ListProcessesRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::ListProcessesRequest'->new($_) };

declare 'RepeatedListProcessesRequest',
    as ArrayRef[ListProcessesRequest()];

coerce 'RepeatedListProcessesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::ListProcessesRequest'->new($_) } @$_ ] };

declare 'MapStringListProcessesRequest',
    as HashRef[ListProcessesRequest()];

declare 'ListProcessesResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::ListProcessesResponse'];

coerce 'ListProcessesResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::ListProcessesResponse'->new($_) };

declare 'RepeatedListProcessesResponse',
    as ArrayRef[ListProcessesResponse()];

coerce 'RepeatedListProcessesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::ListProcessesResponse'->new($_) } @$_ ] };

declare 'MapStringListProcessesResponse',
    as HashRef[ListProcessesResponse()];

declare 'GetProcessRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::GetProcessRequest'];

coerce 'GetProcessRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::GetProcessRequest'->new($_) };

declare 'RepeatedGetProcessRequest',
    as ArrayRef[GetProcessRequest()];

coerce 'RepeatedGetProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::GetProcessRequest'->new($_) } @$_ ] };

declare 'MapStringGetProcessRequest',
    as HashRef[GetProcessRequest()];

declare 'CreateProcessRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::CreateProcessRequest'];

coerce 'CreateProcessRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::CreateProcessRequest'->new($_) };

declare 'RepeatedCreateProcessRequest',
    as ArrayRef[CreateProcessRequest()];

coerce 'RepeatedCreateProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::CreateProcessRequest'->new($_) } @$_ ] };

declare 'MapStringCreateProcessRequest',
    as HashRef[CreateProcessRequest()];

declare 'UpdateProcessRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::UpdateProcessRequest'];

coerce 'UpdateProcessRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::UpdateProcessRequest'->new($_) };

declare 'RepeatedUpdateProcessRequest',
    as ArrayRef[UpdateProcessRequest()];

coerce 'RepeatedUpdateProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::UpdateProcessRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateProcessRequest',
    as HashRef[UpdateProcessRequest()];

declare 'DeleteProcessRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::DeleteProcessRequest'];

coerce 'DeleteProcessRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::DeleteProcessRequest'->new($_) };

declare 'RepeatedDeleteProcessRequest',
    as ArrayRef[DeleteProcessRequest()];

coerce 'RepeatedDeleteProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::DeleteProcessRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteProcessRequest',
    as HashRef[DeleteProcessRequest()];

declare 'BatchRunProcessRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::BatchRunProcessRequest'];

coerce 'BatchRunProcessRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::BatchRunProcessRequest'->new($_) };

declare 'RepeatedBatchRunProcessRequest',
    as ArrayRef[BatchRunProcessRequest()];

coerce 'RepeatedBatchRunProcessRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::BatchRunProcessRequest'->new($_) } @$_ ] };

declare 'MapStringBatchRunProcessRequest',
    as HashRef[BatchRunProcessRequest()];

declare 'BatchRunProcessOptions',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::BatchRunProcessRequest::BatchRunProcessOptions'];

coerce 'BatchRunProcessOptions',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::BatchRunProcessRequest::BatchRunProcessOptions'->new($_) };

declare 'RepeatedBatchRunProcessOptions',
    as ArrayRef[BatchRunProcessOptions()];

coerce 'RepeatedBatchRunProcessOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::BatchRunProcessRequest::BatchRunProcessOptions'->new($_) } @$_ ] };

declare 'MapStringBatchRunProcessOptions',
    as HashRef[BatchRunProcessOptions()];

declare 'BatchRunProcessResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::BatchRunProcessResponse'];

coerce 'BatchRunProcessResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::BatchRunProcessResponse'->new($_) };

declare 'RepeatedBatchRunProcessResponse',
    as ArrayRef[BatchRunProcessResponse()];

coerce 'RepeatedBatchRunProcessResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::BatchRunProcessResponse'->new($_) } @$_ ] };

declare 'MapStringBatchRunProcessResponse',
    as HashRef[BatchRunProcessResponse()];

declare 'ResolveOperatorInfoRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::ResolveOperatorInfoRequest'];

coerce 'ResolveOperatorInfoRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::ResolveOperatorInfoRequest'->new($_) };

declare 'RepeatedResolveOperatorInfoRequest',
    as ArrayRef[ResolveOperatorInfoRequest()];

coerce 'RepeatedResolveOperatorInfoRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::ResolveOperatorInfoRequest'->new($_) } @$_ ] };

declare 'MapStringResolveOperatorInfoRequest',
    as HashRef[ResolveOperatorInfoRequest()];

declare 'OperatorQuery',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::OperatorQuery'];

coerce 'OperatorQuery',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::OperatorQuery'->new($_) };

declare 'RepeatedOperatorQuery',
    as ArrayRef[OperatorQuery()];

coerce 'RepeatedOperatorQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::OperatorQuery'->new($_) } @$_ ] };

declare 'MapStringOperatorQuery',
    as HashRef[OperatorQuery()];

declare 'ResolveOperatorInfoResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::ResolveOperatorInfoResponse'];

coerce 'ResolveOperatorInfoResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::ResolveOperatorInfoResponse'->new($_) };

declare 'RepeatedResolveOperatorInfoResponse',
    as ArrayRef[ResolveOperatorInfoResponse()];

coerce 'RepeatedResolveOperatorInfoResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::ResolveOperatorInfoResponse'->new($_) } @$_ ] };

declare 'MapStringResolveOperatorInfoResponse',
    as HashRef[ResolveOperatorInfoResponse()];

declare 'ListPublicOperatorsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::ListPublicOperatorsRequest'];

coerce 'ListPublicOperatorsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::ListPublicOperatorsRequest'->new($_) };

declare 'RepeatedListPublicOperatorsRequest',
    as ArrayRef[ListPublicOperatorsRequest()];

coerce 'RepeatedListPublicOperatorsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::ListPublicOperatorsRequest'->new($_) } @$_ ] };

declare 'MapStringListPublicOperatorsRequest',
    as HashRef[ListPublicOperatorsRequest()];

declare 'ListPublicOperatorsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::LvaService::ListPublicOperatorsResponse'];

coerce 'ListPublicOperatorsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::LvaService::ListPublicOperatorsResponse'->new($_) };

declare 'RepeatedListPublicOperatorsResponse',
    as ArrayRef[ListPublicOperatorsResponse()];

coerce 'RepeatedListPublicOperatorsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::LvaService::ListPublicOperatorsResponse'->new($_) } @$_ ] };

declare 'MapStringListPublicOperatorsResponse',
    as HashRef[ListPublicOperatorsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1::LvaService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
