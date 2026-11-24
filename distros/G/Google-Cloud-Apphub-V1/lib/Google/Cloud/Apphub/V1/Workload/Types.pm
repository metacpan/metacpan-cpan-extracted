package Google::Cloud::Apphub::V1::Workload::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Workload',
    as InstanceOf['Google::Cloud::Apphub::V1::Workload::Workload'];

coerce 'Workload',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Workload::Workload'->new($_) };

declare 'RepeatedWorkload',
    as ArrayRef[Workload()];

coerce 'RepeatedWorkload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Workload::Workload'->new($_) } @$_ ] };

declare 'MapStringWorkload',
    as HashRef[Workload()];

declare 'State',
    as (Int | Str);

declare 'WorkloadReference',
    as InstanceOf['Google::Cloud::Apphub::V1::Workload::WorkloadReference'];

coerce 'WorkloadReference',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Workload::WorkloadReference'->new($_) };

declare 'RepeatedWorkloadReference',
    as ArrayRef[WorkloadReference()];

coerce 'RepeatedWorkloadReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Workload::WorkloadReference'->new($_) } @$_ ] };

declare 'MapStringWorkloadReference',
    as HashRef[WorkloadReference()];

declare 'WorkloadProperties',
    as InstanceOf['Google::Cloud::Apphub::V1::Workload::WorkloadProperties'];

coerce 'WorkloadProperties',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Workload::WorkloadProperties'->new($_) };

declare 'RepeatedWorkloadProperties',
    as ArrayRef[WorkloadProperties()];

coerce 'RepeatedWorkloadProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Workload::WorkloadProperties'->new($_) } @$_ ] };

declare 'MapStringWorkloadProperties',
    as HashRef[WorkloadProperties()];

declare 'ExtendedMetadataEntry',
    as InstanceOf['Google::Cloud::Apphub::V1::Workload::WorkloadProperties::ExtendedMetadataEntry'];

coerce 'ExtendedMetadataEntry',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Workload::WorkloadProperties::ExtendedMetadataEntry'->new($_) };

declare 'RepeatedExtendedMetadataEntry',
    as ArrayRef[ExtendedMetadataEntry()];

coerce 'RepeatedExtendedMetadataEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Workload::WorkloadProperties::ExtendedMetadataEntry'->new($_) } @$_ ] };

declare 'MapStringExtendedMetadataEntry',
    as HashRef[ExtendedMetadataEntry()];

declare 'DiscoveredWorkload',
    as InstanceOf['Google::Cloud::Apphub::V1::Workload::DiscoveredWorkload'];

coerce 'DiscoveredWorkload',
    from HashRef, via { 'Google::Cloud::Apphub::V1::Workload::DiscoveredWorkload'->new($_) };

declare 'RepeatedDiscoveredWorkload',
    as ArrayRef[DiscoveredWorkload()];

coerce 'RepeatedDiscoveredWorkload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Apphub::V1::Workload::DiscoveredWorkload'->new($_) } @$_ ] };

declare 'MapStringDiscoveredWorkload',
    as HashRef[DiscoveredWorkload()];

1;

__END__

=head1 NAME

Google::Cloud::Apphub::V1::Workload::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
