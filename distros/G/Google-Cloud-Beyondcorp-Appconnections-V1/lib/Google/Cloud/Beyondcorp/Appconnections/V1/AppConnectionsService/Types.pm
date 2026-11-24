package Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListAppConnectionsRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ListAppConnectionsRequest'];

coerce 'ListAppConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ListAppConnectionsRequest'->new($_) };

declare 'RepeatedListAppConnectionsRequest',
    as ArrayRef[ListAppConnectionsRequest()];

coerce 'RepeatedListAppConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ListAppConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringListAppConnectionsRequest',
    as HashRef[ListAppConnectionsRequest()];

declare 'ListAppConnectionsResponse',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ListAppConnectionsResponse'];

coerce 'ListAppConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ListAppConnectionsResponse'->new($_) };

declare 'RepeatedListAppConnectionsResponse',
    as ArrayRef[ListAppConnectionsResponse()];

coerce 'RepeatedListAppConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ListAppConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringListAppConnectionsResponse',
    as HashRef[ListAppConnectionsResponse()];

declare 'GetAppConnectionRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::GetAppConnectionRequest'];

coerce 'GetAppConnectionRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::GetAppConnectionRequest'->new($_) };

declare 'RepeatedGetAppConnectionRequest',
    as ArrayRef[GetAppConnectionRequest()];

coerce 'RepeatedGetAppConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::GetAppConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringGetAppConnectionRequest',
    as HashRef[GetAppConnectionRequest()];

declare 'CreateAppConnectionRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::CreateAppConnectionRequest'];

coerce 'CreateAppConnectionRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::CreateAppConnectionRequest'->new($_) };

declare 'RepeatedCreateAppConnectionRequest',
    as ArrayRef[CreateAppConnectionRequest()];

coerce 'RepeatedCreateAppConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::CreateAppConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringCreateAppConnectionRequest',
    as HashRef[CreateAppConnectionRequest()];

declare 'UpdateAppConnectionRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::UpdateAppConnectionRequest'];

coerce 'UpdateAppConnectionRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::UpdateAppConnectionRequest'->new($_) };

declare 'RepeatedUpdateAppConnectionRequest',
    as ArrayRef[UpdateAppConnectionRequest()];

coerce 'RepeatedUpdateAppConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::UpdateAppConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateAppConnectionRequest',
    as HashRef[UpdateAppConnectionRequest()];

declare 'DeleteAppConnectionRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::DeleteAppConnectionRequest'];

coerce 'DeleteAppConnectionRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::DeleteAppConnectionRequest'->new($_) };

declare 'RepeatedDeleteAppConnectionRequest',
    as ArrayRef[DeleteAppConnectionRequest()];

coerce 'RepeatedDeleteAppConnectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::DeleteAppConnectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteAppConnectionRequest',
    as HashRef[DeleteAppConnectionRequest()];

declare 'ResolveAppConnectionsRequest',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ResolveAppConnectionsRequest'];

coerce 'ResolveAppConnectionsRequest',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ResolveAppConnectionsRequest'->new($_) };

declare 'RepeatedResolveAppConnectionsRequest',
    as ArrayRef[ResolveAppConnectionsRequest()];

coerce 'RepeatedResolveAppConnectionsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ResolveAppConnectionsRequest'->new($_) } @$_ ] };

declare 'MapStringResolveAppConnectionsRequest',
    as HashRef[ResolveAppConnectionsRequest()];

declare 'ResolveAppConnectionsResponse',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ResolveAppConnectionsResponse'];

coerce 'ResolveAppConnectionsResponse',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ResolveAppConnectionsResponse'->new($_) };

declare 'RepeatedResolveAppConnectionsResponse',
    as ArrayRef[ResolveAppConnectionsResponse()];

coerce 'RepeatedResolveAppConnectionsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ResolveAppConnectionsResponse'->new($_) } @$_ ] };

declare 'MapStringResolveAppConnectionsResponse',
    as HashRef[ResolveAppConnectionsResponse()];

declare 'AppConnectionDetails',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ResolveAppConnectionsResponse::AppConnectionDetails'];

coerce 'AppConnectionDetails',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ResolveAppConnectionsResponse::AppConnectionDetails'->new($_) };

declare 'RepeatedAppConnectionDetails',
    as ArrayRef[AppConnectionDetails()];

coerce 'RepeatedAppConnectionDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::ResolveAppConnectionsResponse::AppConnectionDetails'->new($_) } @$_ ] };

declare 'MapStringAppConnectionDetails',
    as HashRef[AppConnectionDetails()];

declare 'AppConnection',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection'];

coerce 'AppConnection',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection'->new($_) };

declare 'RepeatedAppConnection',
    as ArrayRef[AppConnection()];

coerce 'RepeatedAppConnection',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection'->new($_) } @$_ ] };

declare 'MapStringAppConnection',
    as HashRef[AppConnection()];

declare 'Type',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'ApplicationEndpoint',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection::ApplicationEndpoint'];

coerce 'ApplicationEndpoint',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection::ApplicationEndpoint'->new($_) };

declare 'RepeatedApplicationEndpoint',
    as ArrayRef[ApplicationEndpoint()];

coerce 'RepeatedApplicationEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection::ApplicationEndpoint'->new($_) } @$_ ] };

declare 'MapStringApplicationEndpoint',
    as HashRef[ApplicationEndpoint()];

declare 'Gateway',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection::Gateway'];

coerce 'Gateway',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection::Gateway'->new($_) };

declare 'RepeatedGateway',
    as ArrayRef[Gateway()];

coerce 'RepeatedGateway',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection::Gateway'->new($_) } @$_ ] };

declare 'MapStringGateway',
    as HashRef[Gateway()];

declare 'Type',
    as (Int | Str);

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnection::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AppConnectionOperationMetadata',
    as InstanceOf['Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnectionOperationMetadata'];

coerce 'AppConnectionOperationMetadata',
    from HashRef, via { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnectionOperationMetadata'->new($_) };

declare 'RepeatedAppConnectionOperationMetadata',
    as ArrayRef[AppConnectionOperationMetadata()];

coerce 'RepeatedAppConnectionOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::AppConnectionOperationMetadata'->new($_) } @$_ ] };

declare 'MapStringAppConnectionOperationMetadata',
    as HashRef[AppConnectionOperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Beyondcorp::Appconnections::V1::AppConnectionsService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
