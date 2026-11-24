package Google::Cloud::Apihub::V1::CurateService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateCurationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest'];

coerce 'CreateCurationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest'->new($_) };

declare 'RepeatedCreateCurationRequest',
    as ArrayRef[CreateCurationRequest()];

coerce 'RepeatedCreateCurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CurateService::CreateCurationRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCurationRequest',
    as HashRef[CreateCurationRequest()];

declare 'GetCurationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::CurateService::GetCurationRequest'];

coerce 'GetCurationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CurateService::GetCurationRequest'->new($_) };

declare 'RepeatedGetCurationRequest',
    as ArrayRef[GetCurationRequest()];

coerce 'RepeatedGetCurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CurateService::GetCurationRequest'->new($_) } @$_ ] };

declare 'MapStringGetCurationRequest',
    as HashRef[GetCurationRequest()];

declare 'UpdateCurationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::CurateService::UpdateCurationRequest'];

coerce 'UpdateCurationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CurateService::UpdateCurationRequest'->new($_) };

declare 'RepeatedUpdateCurationRequest',
    as ArrayRef[UpdateCurationRequest()];

coerce 'RepeatedUpdateCurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CurateService::UpdateCurationRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCurationRequest',
    as HashRef[UpdateCurationRequest()];

declare 'DeleteCurationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::CurateService::DeleteCurationRequest'];

coerce 'DeleteCurationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CurateService::DeleteCurationRequest'->new($_) };

declare 'RepeatedDeleteCurationRequest',
    as ArrayRef[DeleteCurationRequest()];

coerce 'RepeatedDeleteCurationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CurateService::DeleteCurationRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCurationRequest',
    as HashRef[DeleteCurationRequest()];

declare 'ListCurationsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::CurateService::ListCurationsRequest'];

coerce 'ListCurationsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CurateService::ListCurationsRequest'->new($_) };

declare 'RepeatedListCurationsRequest',
    as ArrayRef[ListCurationsRequest()];

coerce 'RepeatedListCurationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CurateService::ListCurationsRequest'->new($_) } @$_ ] };

declare 'MapStringListCurationsRequest',
    as HashRef[ListCurationsRequest()];

declare 'ListCurationsResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::CurateService::ListCurationsResponse'];

coerce 'ListCurationsResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CurateService::ListCurationsResponse'->new($_) };

declare 'RepeatedListCurationsResponse',
    as ArrayRef[ListCurationsResponse()];

coerce 'RepeatedListCurationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CurateService::ListCurationsResponse'->new($_) } @$_ ] };

declare 'MapStringListCurationsResponse',
    as HashRef[ListCurationsResponse()];

declare 'Curation',
    as InstanceOf['Google::Cloud::Apihub::V1::CurateService::Curation'];

coerce 'Curation',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CurateService::Curation'->new($_) };

declare 'RepeatedCuration',
    as ArrayRef[Curation()];

coerce 'RepeatedCuration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CurateService::Curation'->new($_) } @$_ ] };

declare 'MapStringCuration',
    as HashRef[Curation()];

declare 'LastExecutionState',
    as (Int | Str);

declare 'ErrorCode',
    as (Int | Str);

declare 'PluginInstanceActionID',
    as InstanceOf['Google::Cloud::Apihub::V1::CurateService::Curation::PluginInstanceActionID'];

coerce 'PluginInstanceActionID',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CurateService::Curation::PluginInstanceActionID'->new($_) };

declare 'RepeatedPluginInstanceActionID',
    as ArrayRef[PluginInstanceActionID()];

coerce 'RepeatedPluginInstanceActionID',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CurateService::Curation::PluginInstanceActionID'->new($_) } @$_ ] };

declare 'MapStringPluginInstanceActionID',
    as HashRef[PluginInstanceActionID()];

declare 'Endpoint',
    as InstanceOf['Google::Cloud::Apihub::V1::CurateService::Endpoint'];

coerce 'Endpoint',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CurateService::Endpoint'->new($_) };

declare 'RepeatedEndpoint',
    as ArrayRef[Endpoint()];

coerce 'RepeatedEndpoint',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CurateService::Endpoint'->new($_) } @$_ ] };

declare 'MapStringEndpoint',
    as HashRef[Endpoint()];

declare 'ApplicationIntegrationEndpointDetails',
    as InstanceOf['Google::Cloud::Apihub::V1::CurateService::ApplicationIntegrationEndpointDetails'];

coerce 'ApplicationIntegrationEndpointDetails',
    from HashRef, via { 'Google::Cloud::Apihub::V1::CurateService::ApplicationIntegrationEndpointDetails'->new($_) };

declare 'RepeatedApplicationIntegrationEndpointDetails',
    as ArrayRef[ApplicationIntegrationEndpointDetails()];

coerce 'RepeatedApplicationIntegrationEndpointDetails',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::CurateService::ApplicationIntegrationEndpointDetails'->new($_) } @$_ ] };

declare 'MapStringApplicationIntegrationEndpointDetails',
    as HashRef[ApplicationIntegrationEndpointDetails()];

1;

__END__

=head1 NAME

Google::Cloud::Apihub::V1::CurateService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
