package Google::Cloud::Visionai::V1::HealthService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'HealthCheckRequest',
    as InstanceOf['Google::Cloud::Visionai::V1::HealthService::HealthCheckRequest'];

coerce 'HealthCheckRequest',
    from HashRef, via { 'Google::Cloud::Visionai::V1::HealthService::HealthCheckRequest'->new($_) };

declare 'RepeatedHealthCheckRequest',
    as ArrayRef[HealthCheckRequest()];

coerce 'RepeatedHealthCheckRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::HealthService::HealthCheckRequest'->new($_) } @$_ ] };

declare 'MapStringHealthCheckRequest',
    as HashRef[HealthCheckRequest()];

declare 'HealthCheckResponse',
    as InstanceOf['Google::Cloud::Visionai::V1::HealthService::HealthCheckResponse'];

coerce 'HealthCheckResponse',
    from HashRef, via { 'Google::Cloud::Visionai::V1::HealthService::HealthCheckResponse'->new($_) };

declare 'RepeatedHealthCheckResponse',
    as ArrayRef[HealthCheckResponse()];

coerce 'RepeatedHealthCheckResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::HealthService::HealthCheckResponse'->new($_) } @$_ ] };

declare 'MapStringHealthCheckResponse',
    as HashRef[HealthCheckResponse()];

declare 'ClusterInfo',
    as InstanceOf['Google::Cloud::Visionai::V1::HealthService::ClusterInfo'];

coerce 'ClusterInfo',
    from HashRef, via { 'Google::Cloud::Visionai::V1::HealthService::ClusterInfo'->new($_) };

declare 'RepeatedClusterInfo',
    as ArrayRef[ClusterInfo()];

coerce 'RepeatedClusterInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Visionai::V1::HealthService::ClusterInfo'->new($_) } @$_ ] };

declare 'MapStringClusterInfo',
    as HashRef[ClusterInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Visionai::V1::HealthService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
