package Google::Storage::Platformlogs::V1::RelocateBucketError::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RelocateBucketError',
    as InstanceOf['Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError'];

coerce 'RelocateBucketError',
    from HashRef, via { 'Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError'->new($_) };

declare 'RepeatedRelocateBucketError',
    as ArrayRef[RelocateBucketError()];

coerce 'RepeatedRelocateBucketError',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError'->new($_) } @$_ ] };

declare 'MapStringRelocateBucketError',
    as HashRef[RelocateBucketError()];

declare 'CustomPlacementConfig',
    as InstanceOf['Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError::CustomPlacementConfig'];

coerce 'CustomPlacementConfig',
    from HashRef, via { 'Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError::CustomPlacementConfig'->new($_) };

declare 'RepeatedCustomPlacementConfig',
    as ArrayRef[CustomPlacementConfig()];

coerce 'RepeatedCustomPlacementConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Storage::Platformlogs::V1::RelocateBucketError::RelocateBucketError::CustomPlacementConfig'->new($_) } @$_ ] };

declare 'MapStringCustomPlacementConfig',
    as HashRef[CustomPlacementConfig()];

1;

__END__

=head1 NAME

Google::Storage::Platformlogs::V1::RelocateBucketError::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
