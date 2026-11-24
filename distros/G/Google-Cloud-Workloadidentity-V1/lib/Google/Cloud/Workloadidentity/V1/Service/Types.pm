package Google::Cloud::Workloadidentity::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServiceAgent',
    as InstanceOf['Google::Cloud::Workloadidentity::V1::Service::ServiceAgent'];

coerce 'ServiceAgent',
    from HashRef, via { 'Google::Cloud::Workloadidentity::V1::Service::ServiceAgent'->new($_) };

declare 'RepeatedServiceAgent',
    as ArrayRef[ServiceAgent()];

coerce 'RepeatedServiceAgent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadidentity::V1::Service::ServiceAgent'->new($_) } @$_ ] };

declare 'MapStringServiceAgent',
    as HashRef[ServiceAgent()];

declare 'State',
    as (Int | Str);

declare 'GenerateServiceAgentsRequest',
    as InstanceOf['Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsRequest'];

coerce 'GenerateServiceAgentsRequest',
    from HashRef, via { 'Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsRequest'->new($_) };

declare 'RepeatedGenerateServiceAgentsRequest',
    as ArrayRef[GenerateServiceAgentsRequest()];

coerce 'RepeatedGenerateServiceAgentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsRequest'->new($_) } @$_ ] };

declare 'MapStringGenerateServiceAgentsRequest',
    as HashRef[GenerateServiceAgentsRequest()];

declare 'GenerateServiceAgentsResponse',
    as InstanceOf['Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsResponse'];

coerce 'GenerateServiceAgentsResponse',
    from HashRef, via { 'Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsResponse'->new($_) };

declare 'RepeatedGenerateServiceAgentsResponse',
    as ArrayRef[GenerateServiceAgentsResponse()];

coerce 'RepeatedGenerateServiceAgentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadidentity::V1::Service::GenerateServiceAgentsResponse'->new($_) } @$_ ] };

declare 'MapStringGenerateServiceAgentsResponse',
    as HashRef[GenerateServiceAgentsResponse()];

declare 'OperationMetadata',
    as InstanceOf['Google::Cloud::Workloadidentity::V1::Service::OperationMetadata'];

coerce 'OperationMetadata',
    from HashRef, via { 'Google::Cloud::Workloadidentity::V1::Service::OperationMetadata'->new($_) };

declare 'RepeatedOperationMetadata',
    as ArrayRef[OperationMetadata()];

coerce 'RepeatedOperationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Workloadidentity::V1::Service::OperationMetadata'->new($_) } @$_ ] };

declare 'MapStringOperationMetadata',
    as HashRef[OperationMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Workloadidentity::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
