package Google::Cloud::Visionai::V1::StreamingService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LeaseType',
    as (Int | Str);

declare 'ReceiveEventsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest'];

coerce 'ReceiveEventsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest'->new($_) };

declare 'RepeatedReceiveEventsRequest',
    as ArrayRef[ReceiveEventsRequest()];

coerce 'RepeatedReceiveEventsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest'->new($_) } @$_ ] };

declare 'MapStringReceiveEventsRequest',
    as HashRef[ReceiveEventsRequest()];

declare 'SetupRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest::SetupRequest'];

coerce 'SetupRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest::SetupRequest'->new($_) };

declare 'RepeatedSetupRequest',
    as ArrayRef[SetupRequest()];

coerce 'RepeatedSetupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsRequest::SetupRequest'->new($_) } @$_ ] };

declare 'MapStringSetupRequest',
    as HashRef[SetupRequest()];

declare 'EventUpdate',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::EventUpdate'];

coerce 'EventUpdate',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::EventUpdate'->new($_) };

declare 'RepeatedEventUpdate',
    as ArrayRef[EventUpdate()];

coerce 'RepeatedEventUpdate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::EventUpdate'->new($_) } @$_ ] };

declare 'MapStringEventUpdate',
    as HashRef[EventUpdate()];

declare 'ReceiveEventsControlResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsControlResponse'];

coerce 'ReceiveEventsControlResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsControlResponse'->new($_) };

declare 'RepeatedReceiveEventsControlResponse',
    as ArrayRef[ReceiveEventsControlResponse()];

coerce 'RepeatedReceiveEventsControlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsControlResponse'->new($_) } @$_ ] };

declare 'MapStringReceiveEventsControlResponse',
    as HashRef[ReceiveEventsControlResponse()];

declare 'ReceiveEventsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse'];

coerce 'ReceiveEventsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse'->new($_) };

declare 'RepeatedReceiveEventsResponse',
    as ArrayRef[ReceiveEventsResponse()];

coerce 'RepeatedReceiveEventsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ReceiveEventsResponse'->new($_) } @$_ ] };

declare 'MapStringReceiveEventsResponse',
    as HashRef[ReceiveEventsResponse()];

declare 'Lease',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::Lease'];

coerce 'Lease',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::Lease'->new($_) };

declare 'RepeatedLease',
    as ArrayRef[Lease()];

coerce 'RepeatedLease',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::Lease'->new($_) } @$_ ] };

declare 'MapStringLease',
    as HashRef[Lease()];

declare 'AcquireLeaseRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::AcquireLeaseRequest'];

coerce 'AcquireLeaseRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::AcquireLeaseRequest'->new($_) };

declare 'RepeatedAcquireLeaseRequest',
    as ArrayRef[AcquireLeaseRequest()];

coerce 'RepeatedAcquireLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::AcquireLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringAcquireLeaseRequest',
    as HashRef[AcquireLeaseRequest()];

declare 'RenewLeaseRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::RenewLeaseRequest'];

coerce 'RenewLeaseRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::RenewLeaseRequest'->new($_) };

declare 'RepeatedRenewLeaseRequest',
    as ArrayRef[RenewLeaseRequest()];

coerce 'RepeatedRenewLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::RenewLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringRenewLeaseRequest',
    as HashRef[RenewLeaseRequest()];

declare 'ReleaseLeaseRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseRequest'];

coerce 'ReleaseLeaseRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseRequest'->new($_) };

declare 'RepeatedReleaseLeaseRequest',
    as ArrayRef[ReleaseLeaseRequest()];

coerce 'RepeatedReleaseLeaseRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseRequest'->new($_) } @$_ ] };

declare 'MapStringReleaseLeaseRequest',
    as HashRef[ReleaseLeaseRequest()];

declare 'ReleaseLeaseResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseResponse'];

coerce 'ReleaseLeaseResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseResponse'->new($_) };

declare 'RepeatedReleaseLeaseResponse',
    as ArrayRef[ReleaseLeaseResponse()];

coerce 'RepeatedReleaseLeaseResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ReleaseLeaseResponse'->new($_) } @$_ ] };

declare 'MapStringReleaseLeaseResponse',
    as HashRef[ReleaseLeaseResponse()];

declare 'RequestMetadata',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::RequestMetadata'];

coerce 'RequestMetadata',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::RequestMetadata'->new($_) };

declare 'RepeatedRequestMetadata',
    as ArrayRef[RequestMetadata()];

coerce 'RepeatedRequestMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::RequestMetadata'->new($_) } @$_ ] };

declare 'MapStringRequestMetadata',
    as HashRef[RequestMetadata()];

declare 'SendPacketsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::SendPacketsRequest'];

coerce 'SendPacketsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::SendPacketsRequest'->new($_) };

declare 'RepeatedSendPacketsRequest',
    as ArrayRef[SendPacketsRequest()];

coerce 'RepeatedSendPacketsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::SendPacketsRequest'->new($_) } @$_ ] };

declare 'MapStringSendPacketsRequest',
    as HashRef[SendPacketsRequest()];

declare 'SendPacketsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse'];

coerce 'SendPacketsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse'->new($_) };

declare 'RepeatedSendPacketsResponse',
    as ArrayRef[SendPacketsResponse()];

coerce 'RepeatedSendPacketsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::SendPacketsResponse'->new($_) } @$_ ] };

declare 'MapStringSendPacketsResponse',
    as HashRef[SendPacketsResponse()];

declare 'ReceivePacketsRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest'];

coerce 'ReceivePacketsRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest'->new($_) };

declare 'RepeatedReceivePacketsRequest',
    as ArrayRef[ReceivePacketsRequest()];

coerce 'RepeatedReceivePacketsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest'->new($_) } @$_ ] };

declare 'MapStringReceivePacketsRequest',
    as HashRef[ReceivePacketsRequest()];

declare 'SetupRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest::SetupRequest'];

coerce 'SetupRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest::SetupRequest'->new($_) };

declare 'RepeatedSetupRequest',
    as ArrayRef[SetupRequest()];

coerce 'RepeatedSetupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsRequest::SetupRequest'->new($_) } @$_ ] };

declare 'MapStringSetupRequest',
    as HashRef[SetupRequest()];

declare 'ReceivePacketsControlResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsControlResponse'];

coerce 'ReceivePacketsControlResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsControlResponse'->new($_) };

declare 'RepeatedReceivePacketsControlResponse',
    as ArrayRef[ReceivePacketsControlResponse()];

coerce 'RepeatedReceivePacketsControlResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsControlResponse'->new($_) } @$_ ] };

declare 'MapStringReceivePacketsControlResponse',
    as HashRef[ReceivePacketsControlResponse()];

declare 'ReceivePacketsResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse'];

coerce 'ReceivePacketsResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse'->new($_) };

declare 'RepeatedReceivePacketsResponse',
    as ArrayRef[ReceivePacketsResponse()];

coerce 'RepeatedReceivePacketsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ReceivePacketsResponse'->new($_) } @$_ ] };

declare 'MapStringReceivePacketsResponse',
    as HashRef[ReceivePacketsResponse()];

declare 'EagerMode',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::EagerMode'];

coerce 'EagerMode',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::EagerMode'->new($_) };

declare 'RepeatedEagerMode',
    as ArrayRef[EagerMode()];

coerce 'RepeatedEagerMode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::EagerMode'->new($_) } @$_ ] };

declare 'MapStringEagerMode',
    as HashRef[EagerMode()];

declare 'ControlledMode',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::ControlledMode'];

coerce 'ControlledMode',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::ControlledMode'->new($_) };

declare 'RepeatedControlledMode',
    as ArrayRef[ControlledMode()];

coerce 'RepeatedControlledMode',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::ControlledMode'->new($_) } @$_ ] };

declare 'MapStringControlledMode',
    as HashRef[ControlledMode()];

declare 'CommitRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::StreamingService::CommitRequest'];

coerce 'CommitRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::StreamingService::CommitRequest'->new($_) };

declare 'RepeatedCommitRequest',
    as ArrayRef[CommitRequest()];

coerce 'RepeatedCommitRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::StreamingService::CommitRequest'->new($_) } @$_ ] };

declare 'MapStringCommitRequest',
    as HashRef[CommitRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1::StreamingService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
