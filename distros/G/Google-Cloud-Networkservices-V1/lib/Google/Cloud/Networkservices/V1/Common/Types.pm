package Google::Cloud::Networkservices::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EnvoyHeaders',
    as (Int | Str);

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Networkservices::V1::Common::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Common::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Common::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

declare 'TrafficPortSelector',
    as InstanceOf['Google::Cloud::Networkservices::V1::Common::TrafficPortSelector'];

coerce 'TrafficPortSelector',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Common::TrafficPortSelector'->new($_) };

declare 'RepeatedTrafficPortSelector',
    as ArrayRef[TrafficPortSelector()];

coerce 'RepeatedTrafficPortSelector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Common::TrafficPortSelector'->new($_) } @$_ ] };

declare 'MapStringTrafficPortSelector',
    as HashRef[TrafficPortSelector()];

declare 'EndpointMatcher',
    as InstanceOf['Google::Cloud::Networkservices::V1::Common::EndpointMatcher'];

coerce 'EndpointMatcher',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Common::EndpointMatcher'->new($_) };

declare 'RepeatedEndpointMatcher',
    as ArrayRef[EndpointMatcher()];

coerce 'RepeatedEndpointMatcher',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Common::EndpointMatcher'->new($_) } @$_ ] };

declare 'MapStringEndpointMatcher',
    as HashRef[EndpointMatcher()];

declare 'MetadataLabelMatcher',
    as InstanceOf['Google::Cloud::Networkservices::V1::Common::EndpointMatcher::MetadataLabelMatcher'];

coerce 'MetadataLabelMatcher',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Common::EndpointMatcher::MetadataLabelMatcher'->new($_) };

declare 'RepeatedMetadataLabelMatcher',
    as ArrayRef[MetadataLabelMatcher()];

coerce 'RepeatedMetadataLabelMatcher',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Common::EndpointMatcher::MetadataLabelMatcher'->new($_) } @$_ ] };

declare 'MapStringMetadataLabelMatcher',
    as HashRef[MetadataLabelMatcher()];

declare 'MetadataLabelMatchCriteria',
    as (Int | Str);

declare 'MetadataLabels',
    as InstanceOf['Google::Cloud::Networkservices::V1::Common::EndpointMatcher::MetadataLabelMatcher::MetadataLabels'];

coerce 'MetadataLabels',
    from HashRef, via { 'Google::Cloud::Networkservices::V1::Common::EndpointMatcher::MetadataLabelMatcher::MetadataLabels'->new($_) };

declare 'RepeatedMetadataLabels',
    as ArrayRef[MetadataLabels()];

coerce 'RepeatedMetadataLabels',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Networkservices::V1::Common::EndpointMatcher::MetadataLabelMatcher::MetadataLabels'->new($_) } @$_ ] };

declare 'MapStringMetadataLabels',
    as HashRef[MetadataLabels()];

1;

__END__

=head1 NAME

Google::Cloud::Networkservices::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
