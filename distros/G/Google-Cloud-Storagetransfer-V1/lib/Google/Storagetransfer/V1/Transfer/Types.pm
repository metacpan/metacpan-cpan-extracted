package Google::Storagetransfer::V1::Transfer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetGoogleServiceAccountRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest'];

coerce 'GetGoogleServiceAccountRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest'->new($_) };

declare 'RepeatedGetGoogleServiceAccountRequest',
    as ArrayRef[GetGoogleServiceAccountRequest()];

coerce 'RepeatedGetGoogleServiceAccountRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::GetGoogleServiceAccountRequest'->new($_) } @$_ ] };

declare 'MapStringGetGoogleServiceAccountRequest',
    as HashRef[GetGoogleServiceAccountRequest()];

declare 'CreateTransferJobRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::CreateTransferJobRequest'];

coerce 'CreateTransferJobRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::CreateTransferJobRequest'->new($_) };

declare 'RepeatedCreateTransferJobRequest',
    as ArrayRef[CreateTransferJobRequest()];

coerce 'RepeatedCreateTransferJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::CreateTransferJobRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTransferJobRequest',
    as HashRef[CreateTransferJobRequest()];

declare 'UpdateTransferJobRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::UpdateTransferJobRequest'];

coerce 'UpdateTransferJobRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::UpdateTransferJobRequest'->new($_) };

declare 'RepeatedUpdateTransferJobRequest',
    as ArrayRef[UpdateTransferJobRequest()];

coerce 'RepeatedUpdateTransferJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::UpdateTransferJobRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTransferJobRequest',
    as HashRef[UpdateTransferJobRequest()];

declare 'GetTransferJobRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::GetTransferJobRequest'];

coerce 'GetTransferJobRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::GetTransferJobRequest'->new($_) };

declare 'RepeatedGetTransferJobRequest',
    as ArrayRef[GetTransferJobRequest()];

coerce 'RepeatedGetTransferJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::GetTransferJobRequest'->new($_) } @$_ ] };

declare 'MapStringGetTransferJobRequest',
    as HashRef[GetTransferJobRequest()];

declare 'DeleteTransferJobRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::DeleteTransferJobRequest'];

coerce 'DeleteTransferJobRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::DeleteTransferJobRequest'->new($_) };

declare 'RepeatedDeleteTransferJobRequest',
    as ArrayRef[DeleteTransferJobRequest()];

coerce 'RepeatedDeleteTransferJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::DeleteTransferJobRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTransferJobRequest',
    as HashRef[DeleteTransferJobRequest()];

declare 'ListTransferJobsRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::ListTransferJobsRequest'];

coerce 'ListTransferJobsRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::ListTransferJobsRequest'->new($_) };

declare 'RepeatedListTransferJobsRequest',
    as ArrayRef[ListTransferJobsRequest()];

coerce 'RepeatedListTransferJobsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::ListTransferJobsRequest'->new($_) } @$_ ] };

declare 'MapStringListTransferJobsRequest',
    as HashRef[ListTransferJobsRequest()];

declare 'ListTransferJobsResponse',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::ListTransferJobsResponse'];

coerce 'ListTransferJobsResponse',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::ListTransferJobsResponse'->new($_) };

declare 'RepeatedListTransferJobsResponse',
    as ArrayRef[ListTransferJobsResponse()];

coerce 'RepeatedListTransferJobsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::ListTransferJobsResponse'->new($_) } @$_ ] };

declare 'MapStringListTransferJobsResponse',
    as HashRef[ListTransferJobsResponse()];

declare 'PauseTransferOperationRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::PauseTransferOperationRequest'];

coerce 'PauseTransferOperationRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::PauseTransferOperationRequest'->new($_) };

declare 'RepeatedPauseTransferOperationRequest',
    as ArrayRef[PauseTransferOperationRequest()];

coerce 'RepeatedPauseTransferOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::PauseTransferOperationRequest'->new($_) } @$_ ] };

declare 'MapStringPauseTransferOperationRequest',
    as HashRef[PauseTransferOperationRequest()];

declare 'ResumeTransferOperationRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::ResumeTransferOperationRequest'];

coerce 'ResumeTransferOperationRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::ResumeTransferOperationRequest'->new($_) };

declare 'RepeatedResumeTransferOperationRequest',
    as ArrayRef[ResumeTransferOperationRequest()];

coerce 'RepeatedResumeTransferOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::ResumeTransferOperationRequest'->new($_) } @$_ ] };

declare 'MapStringResumeTransferOperationRequest',
    as HashRef[ResumeTransferOperationRequest()];

declare 'RunTransferJobRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::RunTransferJobRequest'];

coerce 'RunTransferJobRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::RunTransferJobRequest'->new($_) };

declare 'RepeatedRunTransferJobRequest',
    as ArrayRef[RunTransferJobRequest()];

coerce 'RepeatedRunTransferJobRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::RunTransferJobRequest'->new($_) } @$_ ] };

declare 'MapStringRunTransferJobRequest',
    as HashRef[RunTransferJobRequest()];

declare 'CreateAgentPoolRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::CreateAgentPoolRequest'];

coerce 'CreateAgentPoolRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::CreateAgentPoolRequest'->new($_) };

declare 'RepeatedCreateAgentPoolRequest',
    as ArrayRef[CreateAgentPoolRequest()];

coerce 'RepeatedCreateAgentPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::CreateAgentPoolRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAgentPoolRequest',
    as HashRef[CreateAgentPoolRequest()];

declare 'UpdateAgentPoolRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::UpdateAgentPoolRequest'];

coerce 'UpdateAgentPoolRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::UpdateAgentPoolRequest'->new($_) };

declare 'RepeatedUpdateAgentPoolRequest',
    as ArrayRef[UpdateAgentPoolRequest()];

coerce 'RepeatedUpdateAgentPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::UpdateAgentPoolRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAgentPoolRequest',
    as HashRef[UpdateAgentPoolRequest()];

declare 'GetAgentPoolRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::GetAgentPoolRequest'];

coerce 'GetAgentPoolRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::GetAgentPoolRequest'->new($_) };

declare 'RepeatedGetAgentPoolRequest',
    as ArrayRef[GetAgentPoolRequest()];

coerce 'RepeatedGetAgentPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::GetAgentPoolRequest'->new($_) } @$_ ] };

declare 'MapStringGetAgentPoolRequest',
    as HashRef[GetAgentPoolRequest()];

declare 'DeleteAgentPoolRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::DeleteAgentPoolRequest'];

coerce 'DeleteAgentPoolRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::DeleteAgentPoolRequest'->new($_) };

declare 'RepeatedDeleteAgentPoolRequest',
    as ArrayRef[DeleteAgentPoolRequest()];

coerce 'RepeatedDeleteAgentPoolRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::DeleteAgentPoolRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAgentPoolRequest',
    as HashRef[DeleteAgentPoolRequest()];

declare 'ListAgentPoolsRequest',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::ListAgentPoolsRequest'];

coerce 'ListAgentPoolsRequest',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::ListAgentPoolsRequest'->new($_) };

declare 'RepeatedListAgentPoolsRequest',
    as ArrayRef[ListAgentPoolsRequest()];

coerce 'RepeatedListAgentPoolsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::ListAgentPoolsRequest'->new($_) } @$_ ] };

declare 'MapStringListAgentPoolsRequest',
    as HashRef[ListAgentPoolsRequest()];

declare 'ListAgentPoolsResponse',
    as InstanceOf['Google::Storagetransfer::V1::Transfer::ListAgentPoolsResponse'];

coerce 'ListAgentPoolsResponse',
    from HashRef, via { 'Google::Storagetransfer::V1::Transfer::ListAgentPoolsResponse'->new($_) };

declare 'RepeatedListAgentPoolsResponse',
    as ArrayRef[ListAgentPoolsResponse()];

coerce 'RepeatedListAgentPoolsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Storagetransfer::V1::Transfer::ListAgentPoolsResponse'->new($_) } @$_ ] };

declare 'MapStringListAgentPoolsResponse',
    as HashRef[ListAgentPoolsResponse()];

1;

__END__

=head1 NAME

Google::Storagetransfer::V1::Transfer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
