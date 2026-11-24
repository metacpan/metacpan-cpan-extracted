package Google::Cloud::Apihub::V1::DiscoveryService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListDiscoveredApiObservationsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest'];

coerce 'ListDiscoveredApiObservationsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest'->new($_) };

declare 'RepeatedListDiscoveredApiObservationsRequest',
    as ArrayRef[ListDiscoveredApiObservationsRequest()];

coerce 'RepeatedListDiscoveredApiObservationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsRequest'->new($_) } @$_ ] };

declare 'MapStringListDiscoveredApiObservationsRequest',
    as HashRef[ListDiscoveredApiObservationsRequest()];

declare 'ListDiscoveredApiObservationsResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse'];

coerce 'ListDiscoveredApiObservationsResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse'->new($_) };

declare 'RepeatedListDiscoveredApiObservationsResponse',
    as ArrayRef[ListDiscoveredApiObservationsResponse()];

coerce 'RepeatedListDiscoveredApiObservationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiObservationsResponse'->new($_) } @$_ ] };

declare 'MapStringListDiscoveredApiObservationsResponse',
    as HashRef[ListDiscoveredApiObservationsResponse()];

declare 'ListDiscoveredApiOperationsRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsRequest'];

coerce 'ListDiscoveredApiOperationsRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsRequest'->new($_) };

declare 'RepeatedListDiscoveredApiOperationsRequest',
    as ArrayRef[ListDiscoveredApiOperationsRequest()];

coerce 'RepeatedListDiscoveredApiOperationsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsRequest'->new($_) } @$_ ] };

declare 'MapStringListDiscoveredApiOperationsRequest',
    as HashRef[ListDiscoveredApiOperationsRequest()];

declare 'ListDiscoveredApiOperationsResponse',
    as InstanceOf['Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsResponse'];

coerce 'ListDiscoveredApiOperationsResponse',
    from HashRef, via { 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsResponse'->new($_) };

declare 'RepeatedListDiscoveredApiOperationsResponse',
    as ArrayRef[ListDiscoveredApiOperationsResponse()];

coerce 'RepeatedListDiscoveredApiOperationsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::DiscoveryService::ListDiscoveredApiOperationsResponse'->new($_) } @$_ ] };

declare 'MapStringListDiscoveredApiOperationsResponse',
    as HashRef[ListDiscoveredApiOperationsResponse()];

declare 'GetDiscoveredApiObservationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiObservationRequest'];

coerce 'GetDiscoveredApiObservationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiObservationRequest'->new($_) };

declare 'RepeatedGetDiscoveredApiObservationRequest',
    as ArrayRef[GetDiscoveredApiObservationRequest()];

coerce 'RepeatedGetDiscoveredApiObservationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiObservationRequest'->new($_) } @$_ ] };

declare 'MapStringGetDiscoveredApiObservationRequest',
    as HashRef[GetDiscoveredApiObservationRequest()];

declare 'GetDiscoveredApiOperationRequest',
    as InstanceOf['Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiOperationRequest'];

coerce 'GetDiscoveredApiOperationRequest',
    from HashRef, via { 'Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiOperationRequest'->new($_) };

declare 'RepeatedGetDiscoveredApiOperationRequest',
    as ArrayRef[GetDiscoveredApiOperationRequest()];

coerce 'RepeatedGetDiscoveredApiOperationRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apihub::V1::DiscoveryService::GetDiscoveredApiOperationRequest'->new($_) } @$_ ] };

declare 'MapStringGetDiscoveredApiOperationRequest',
    as HashRef[GetDiscoveredApiOperationRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Apihub::V1::DiscoveryService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
