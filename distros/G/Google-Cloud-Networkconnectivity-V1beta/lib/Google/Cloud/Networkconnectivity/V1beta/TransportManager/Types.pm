package Google::Cloud::Networkconnectivity::V1beta::TransportManager::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RemoteTransportProfile',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::RemoteTransportProfile'];

coerce 'RemoteTransportProfile',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::RemoteTransportProfile'->new($_) };

declare 'RepeatedRemoteTransportProfile',
    as ArrayRef[RemoteTransportProfile()];

coerce 'RepeatedRemoteTransportProfile',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::RemoteTransportProfile'->new($_) } @$_ ] };

declare 'MapStringRemoteTransportProfile',
    as HashRef[RemoteTransportProfile()];

declare 'Bandwidth',
    as (Int | Str);

declare 'ServiceLevelAvailability',
    as (Int | Str);

declare 'KeyProvisioningFlow',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'ProviderType',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::RemoteTransportProfile::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::RemoteTransportProfile::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::RemoteTransportProfile::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListRemoteTransportProfilesRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListRemoteTransportProfilesRequest'];

coerce 'ListRemoteTransportProfilesRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListRemoteTransportProfilesRequest'->new($_) };

declare 'RepeatedListRemoteTransportProfilesRequest',
    as ArrayRef[ListRemoteTransportProfilesRequest()];

coerce 'RepeatedListRemoteTransportProfilesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListRemoteTransportProfilesRequest'->new($_) } @$_ ] };

declare 'MapStringListRemoteTransportProfilesRequest',
    as HashRef[ListRemoteTransportProfilesRequest()];

declare 'ListRemoteTransportProfilesResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListRemoteTransportProfilesResponse'];

coerce 'ListRemoteTransportProfilesResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListRemoteTransportProfilesResponse'->new($_) };

declare 'RepeatedListRemoteTransportProfilesResponse',
    as ArrayRef[ListRemoteTransportProfilesResponse()];

coerce 'RepeatedListRemoteTransportProfilesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListRemoteTransportProfilesResponse'->new($_) } @$_ ] };

declare 'MapStringListRemoteTransportProfilesResponse',
    as HashRef[ListRemoteTransportProfilesResponse()];

declare 'GetRemoteTransportProfileRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetRemoteTransportProfileRequest'];

coerce 'GetRemoteTransportProfileRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetRemoteTransportProfileRequest'->new($_) };

declare 'RepeatedGetRemoteTransportProfileRequest',
    as ArrayRef[GetRemoteTransportProfileRequest()];

coerce 'RepeatedGetRemoteTransportProfileRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetRemoteTransportProfileRequest'->new($_) } @$_ ] };

declare 'MapStringGetRemoteTransportProfileRequest',
    as HashRef[GetRemoteTransportProfileRequest()];

declare 'ParseFromActivationKeyRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::ParseFromActivationKeyRequest'];

coerce 'ParseFromActivationKeyRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ParseFromActivationKeyRequest'->new($_) };

declare 'RepeatedParseFromActivationKeyRequest',
    as ArrayRef[ParseFromActivationKeyRequest()];

coerce 'RepeatedParseFromActivationKeyRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ParseFromActivationKeyRequest'->new($_) } @$_ ] };

declare 'MapStringParseFromActivationKeyRequest',
    as HashRef[ParseFromActivationKeyRequest()];

declare 'ParseFromActivationKeyResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::ParseFromActivationKeyResponse'];

coerce 'ParseFromActivationKeyResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ParseFromActivationKeyResponse'->new($_) };

declare 'RepeatedParseFromActivationKeyResponse',
    as ArrayRef[ParseFromActivationKeyResponse()];

coerce 'RepeatedParseFromActivationKeyResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ParseFromActivationKeyResponse'->new($_) } @$_ ] };

declare 'MapStringParseFromActivationKeyResponse',
    as HashRef[ParseFromActivationKeyResponse()];

declare 'Transport',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::Transport'];

coerce 'Transport',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::Transport'->new($_) };

declare 'RepeatedTransport',
    as ArrayRef[Transport()];

coerce 'RepeatedTransport',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::Transport'->new($_) } @$_ ] };

declare 'MapStringTransport',
    as HashRef[Transport()];

declare 'Bandwidth',
    as (Int | Str);

declare 'StackType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::Transport::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::Transport::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::Transport::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'ListTransportsRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListTransportsRequest'];

coerce 'ListTransportsRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListTransportsRequest'->new($_) };

declare 'RepeatedListTransportsRequest',
    as ArrayRef[ListTransportsRequest()];

coerce 'RepeatedListTransportsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListTransportsRequest'->new($_) } @$_ ] };

declare 'MapStringListTransportsRequest',
    as HashRef[ListTransportsRequest()];

declare 'ListTransportsResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListTransportsResponse'];

coerce 'ListTransportsResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListTransportsResponse'->new($_) };

declare 'RepeatedListTransportsResponse',
    as ArrayRef[ListTransportsResponse()];

coerce 'RepeatedListTransportsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::ListTransportsResponse'->new($_) } @$_ ] };

declare 'MapStringListTransportsResponse',
    as HashRef[ListTransportsResponse()];

declare 'GetTransportRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetTransportRequest'];

coerce 'GetTransportRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetTransportRequest'->new($_) };

declare 'RepeatedGetTransportRequest',
    as ArrayRef[GetTransportRequest()];

coerce 'RepeatedGetTransportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetTransportRequest'->new($_) } @$_ ] };

declare 'MapStringGetTransportRequest',
    as HashRef[GetTransportRequest()];

declare 'GetStatusRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetStatusRequest'];

coerce 'GetStatusRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetStatusRequest'->new($_) };

declare 'RepeatedGetStatusRequest',
    as ArrayRef[GetStatusRequest()];

coerce 'RepeatedGetStatusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetStatusRequest'->new($_) } @$_ ] };

declare 'MapStringGetStatusRequest',
    as HashRef[GetStatusRequest()];

declare 'GetStatusResponse',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetStatusResponse'];

coerce 'GetStatusResponse',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetStatusResponse'->new($_) };

declare 'RepeatedGetStatusResponse',
    as ArrayRef[GetStatusResponse()];

coerce 'RepeatedGetStatusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::GetStatusResponse'->new($_) } @$_ ] };

declare 'MapStringGetStatusResponse',
    as HashRef[GetStatusResponse()];

declare 'OverallStatus',
    as (Int | Str);

declare 'OperationalStatus',
    as (Int | Str);

declare 'ConnectivityStatus',
    as (Int | Str);

declare 'MacSecStatus',
    as (Int | Str);

declare 'CreateTransportRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::CreateTransportRequest'];

coerce 'CreateTransportRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::CreateTransportRequest'->new($_) };

declare 'RepeatedCreateTransportRequest',
    as ArrayRef[CreateTransportRequest()];

coerce 'RepeatedCreateTransportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::CreateTransportRequest'->new($_) } @$_ ] };

declare 'MapStringCreateTransportRequest',
    as HashRef[CreateTransportRequest()];

declare 'UpdateTransportRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::UpdateTransportRequest'];

coerce 'UpdateTransportRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::UpdateTransportRequest'->new($_) };

declare 'RepeatedUpdateTransportRequest',
    as ArrayRef[UpdateTransportRequest()];

coerce 'RepeatedUpdateTransportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::UpdateTransportRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateTransportRequest',
    as HashRef[UpdateTransportRequest()];

declare 'DeleteTransportRequest',
    as InstanceOf['Google::Cloud::Networkconnectivity::V1beta::TransportManager::DeleteTransportRequest'];

coerce 'DeleteTransportRequest',
    from HashRef, via { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::DeleteTransportRequest'->new($_) };

declare 'RepeatedDeleteTransportRequest',
    as ArrayRef[DeleteTransportRequest()];

coerce 'RepeatedDeleteTransportRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkconnectivity::V1beta::TransportManager::DeleteTransportRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteTransportRequest',
    as HashRef[DeleteTransportRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Networkconnectivity::V1beta::TransportManager::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
