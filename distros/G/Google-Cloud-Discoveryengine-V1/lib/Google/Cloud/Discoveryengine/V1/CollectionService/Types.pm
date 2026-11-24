package Google::Cloud::Discoveryengine::V1::CollectionService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DeleteCollectionRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest'];

coerce 'DeleteCollectionRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest'->new($_) };

declare 'RepeatedDeleteCollectionRequest',
    as ArrayRef[DeleteCollectionRequest()];

coerce 'RepeatedDeleteCollectionRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCollectionRequest',
    as HashRef[DeleteCollectionRequest()];

declare 'DeleteCollectionMetadata',
    as InstanceOf['Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionMetadata'];

coerce 'DeleteCollectionMetadata',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionMetadata'->new($_) };

declare 'RepeatedDeleteCollectionMetadata',
    as ArrayRef[DeleteCollectionMetadata()];

coerce 'RepeatedDeleteCollectionMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1::CollectionService::DeleteCollectionMetadata'->new($_) } @$_ ] };

declare 'MapStringDeleteCollectionMetadata',
    as HashRef[DeleteCollectionMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1::CollectionService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
