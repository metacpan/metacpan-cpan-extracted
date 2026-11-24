package Google::Cloud::Servicedirectory::V1::RegistrationService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CreateNamespaceRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::CreateNamespaceRequest'];

coerce 'CreateNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::CreateNamespaceRequest'->new($_) };

declare 'RepeatedCreateNamespaceRequest',
    as ArrayRef[CreateNamespaceRequest()];

coerce 'RepeatedCreateNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::CreateNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateNamespaceRequest',
    as HashRef[CreateNamespaceRequest()];

declare 'ListNamespacesRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::ListNamespacesRequest'];

coerce 'ListNamespacesRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListNamespacesRequest'->new($_) };

declare 'RepeatedListNamespacesRequest',
    as ArrayRef[ListNamespacesRequest()];

coerce 'RepeatedListNamespacesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListNamespacesRequest'->new($_) } @$_ ] };

declare 'MapStringListNamespacesRequest',
    as HashRef[ListNamespacesRequest()];

declare 'ListNamespacesResponse',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::ListNamespacesResponse'];

coerce 'ListNamespacesResponse',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListNamespacesResponse'->new($_) };

declare 'RepeatedListNamespacesResponse',
    as ArrayRef[ListNamespacesResponse()];

coerce 'RepeatedListNamespacesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListNamespacesResponse'->new($_) } @$_ ] };

declare 'MapStringListNamespacesResponse',
    as HashRef[ListNamespacesResponse()];

declare 'GetNamespaceRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::GetNamespaceRequest'];

coerce 'GetNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::GetNamespaceRequest'->new($_) };

declare 'RepeatedGetNamespaceRequest',
    as ArrayRef[GetNamespaceRequest()];

coerce 'RepeatedGetNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::GetNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringGetNamespaceRequest',
    as HashRef[GetNamespaceRequest()];

declare 'UpdateNamespaceRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::UpdateNamespaceRequest'];

coerce 'UpdateNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::UpdateNamespaceRequest'->new($_) };

declare 'RepeatedUpdateNamespaceRequest',
    as ArrayRef[UpdateNamespaceRequest()];

coerce 'RepeatedUpdateNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::UpdateNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateNamespaceRequest',
    as HashRef[UpdateNamespaceRequest()];

declare 'DeleteNamespaceRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::DeleteNamespaceRequest'];

coerce 'DeleteNamespaceRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::DeleteNamespaceRequest'->new($_) };

declare 'RepeatedDeleteNamespaceRequest',
    as ArrayRef[DeleteNamespaceRequest()];

coerce 'RepeatedDeleteNamespaceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::DeleteNamespaceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteNamespaceRequest',
    as HashRef[DeleteNamespaceRequest()];

declare 'CreateServiceRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::CreateServiceRequest'];

coerce 'CreateServiceRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::CreateServiceRequest'->new($_) };

declare 'RepeatedCreateServiceRequest',
    as ArrayRef[CreateServiceRequest()];

coerce 'RepeatedCreateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::CreateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringCreateServiceRequest',
    as HashRef[CreateServiceRequest()];

declare 'ListServicesRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::ListServicesRequest'];

coerce 'ListServicesRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListServicesRequest'->new($_) };

declare 'RepeatedListServicesRequest',
    as ArrayRef[ListServicesRequest()];

coerce 'RepeatedListServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListServicesRequest',
    as HashRef[ListServicesRequest()];

declare 'ListServicesResponse',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::ListServicesResponse'];

coerce 'ListServicesResponse',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListServicesResponse'->new($_) };

declare 'RepeatedListServicesResponse',
    as ArrayRef[ListServicesResponse()];

coerce 'RepeatedListServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListServicesResponse',
    as HashRef[ListServicesResponse()];

declare 'GetServiceRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::GetServiceRequest'];

coerce 'GetServiceRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::GetServiceRequest'->new($_) };

declare 'RepeatedGetServiceRequest',
    as ArrayRef[GetServiceRequest()];

coerce 'RepeatedGetServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::GetServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceRequest',
    as HashRef[GetServiceRequest()];

declare 'UpdateServiceRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::UpdateServiceRequest'];

coerce 'UpdateServiceRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::UpdateServiceRequest'->new($_) };

declare 'RepeatedUpdateServiceRequest',
    as ArrayRef[UpdateServiceRequest()];

coerce 'RepeatedUpdateServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::UpdateServiceRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateServiceRequest',
    as HashRef[UpdateServiceRequest()];

declare 'DeleteServiceRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::DeleteServiceRequest'];

coerce 'DeleteServiceRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::DeleteServiceRequest'->new($_) };

declare 'RepeatedDeleteServiceRequest',
    as ArrayRef[DeleteServiceRequest()];

coerce 'RepeatedDeleteServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::DeleteServiceRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteServiceRequest',
    as HashRef[DeleteServiceRequest()];

declare 'CreateEndpointRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::CreateEndpointRequest'];

coerce 'CreateEndpointRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::CreateEndpointRequest'->new($_) };

declare 'RepeatedCreateEndpointRequest',
    as ArrayRef[CreateEndpointRequest()];

coerce 'RepeatedCreateEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::CreateEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEndpointRequest',
    as HashRef[CreateEndpointRequest()];

declare 'ListEndpointsRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::ListEndpointsRequest'];

coerce 'ListEndpointsRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListEndpointsRequest'->new($_) };

declare 'RepeatedListEndpointsRequest',
    as ArrayRef[ListEndpointsRequest()];

coerce 'RepeatedListEndpointsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListEndpointsRequest'->new($_) } @$_ ] };

declare 'MapStringListEndpointsRequest',
    as HashRef[ListEndpointsRequest()];

declare 'ListEndpointsResponse',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::ListEndpointsResponse'];

coerce 'ListEndpointsResponse',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListEndpointsResponse'->new($_) };

declare 'RepeatedListEndpointsResponse',
    as ArrayRef[ListEndpointsResponse()];

coerce 'RepeatedListEndpointsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::ListEndpointsResponse'->new($_) } @$_ ] };

declare 'MapStringListEndpointsResponse',
    as HashRef[ListEndpointsResponse()];

declare 'GetEndpointRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::GetEndpointRequest'];

coerce 'GetEndpointRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::GetEndpointRequest'->new($_) };

declare 'RepeatedGetEndpointRequest',
    as ArrayRef[GetEndpointRequest()];

coerce 'RepeatedGetEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::GetEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringGetEndpointRequest',
    as HashRef[GetEndpointRequest()];

declare 'UpdateEndpointRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::UpdateEndpointRequest'];

coerce 'UpdateEndpointRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::UpdateEndpointRequest'->new($_) };

declare 'RepeatedUpdateEndpointRequest',
    as ArrayRef[UpdateEndpointRequest()];

coerce 'RepeatedUpdateEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::UpdateEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateEndpointRequest',
    as HashRef[UpdateEndpointRequest()];

declare 'DeleteEndpointRequest',
    as InstanceOf['Google::Cloud::Servicedirectory::V1::RegistrationService::DeleteEndpointRequest'];

coerce 'DeleteEndpointRequest',
    from HashRef, via { 'Google::Cloud::Servicedirectory::V1::RegistrationService::DeleteEndpointRequest'->new($_) };

declare 'RepeatedDeleteEndpointRequest',
    as ArrayRef[DeleteEndpointRequest()];

coerce 'RepeatedDeleteEndpointRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Servicedirectory::V1::RegistrationService::DeleteEndpointRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteEndpointRequest',
    as HashRef[DeleteEndpointRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Servicedirectory::V1::RegistrationService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
