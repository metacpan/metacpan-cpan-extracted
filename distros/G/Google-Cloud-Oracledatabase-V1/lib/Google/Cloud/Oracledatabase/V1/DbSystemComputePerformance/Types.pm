package Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DbSystemComputePerformance',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::DbSystemComputePerformance'];

coerce 'DbSystemComputePerformance',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::DbSystemComputePerformance'->new($_) };

declare 'RepeatedDbSystemComputePerformance',
    as ArrayRef[DbSystemComputePerformance()];

coerce 'RepeatedDbSystemComputePerformance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::DbSystemComputePerformance'->new($_) } @$_ ] };

declare 'MapStringDbSystemComputePerformance',
    as HashRef[DbSystemComputePerformance()];

declare 'ComputePerformance',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ComputePerformance'];

coerce 'ComputePerformance',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ComputePerformance'->new($_) };

declare 'RepeatedComputePerformance',
    as ArrayRef[ComputePerformance()];

coerce 'RepeatedComputePerformance',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ComputePerformance'->new($_) } @$_ ] };

declare 'MapStringComputePerformance',
    as HashRef[ComputePerformance()];

declare 'ListDbSystemComputePerformancesRequest',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ListDbSystemComputePerformancesRequest'];

coerce 'ListDbSystemComputePerformancesRequest',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ListDbSystemComputePerformancesRequest'->new($_) };

declare 'RepeatedListDbSystemComputePerformancesRequest',
    as ArrayRef[ListDbSystemComputePerformancesRequest()];

coerce 'RepeatedListDbSystemComputePerformancesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ListDbSystemComputePerformancesRequest'->new($_) } @$_ ] };

declare 'MapStringListDbSystemComputePerformancesRequest',
    as HashRef[ListDbSystemComputePerformancesRequest()];

declare 'ListDbSystemComputePerformancesResponse',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ListDbSystemComputePerformancesResponse'];

coerce 'ListDbSystemComputePerformancesResponse',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ListDbSystemComputePerformancesResponse'->new($_) };

declare 'RepeatedListDbSystemComputePerformancesResponse',
    as ArrayRef[ListDbSystemComputePerformancesResponse()];

coerce 'RepeatedListDbSystemComputePerformancesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::ListDbSystemComputePerformancesResponse'->new($_) } @$_ ] };

declare 'MapStringListDbSystemComputePerformancesResponse',
    as HashRef[ListDbSystemComputePerformancesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
