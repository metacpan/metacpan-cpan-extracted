package Google::Cloud::Discoveryengine::V1alpha::ChunkService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GetChunkRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest'];

coerce 'GetChunkRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest'->new($_) };

declare 'RepeatedGetChunkRequest',
    as ArrayRef[GetChunkRequest()];

coerce 'RepeatedGetChunkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ChunkService::GetChunkRequest'->new($_) } @$_ ] };

declare 'MapStringGetChunkRequest',
    as HashRef[GetChunkRequest()];

declare 'ListChunksRequest',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksRequest'];

coerce 'ListChunksRequest',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksRequest'->new($_) };

declare 'RepeatedListChunksRequest',
    as ArrayRef[ListChunksRequest()];

coerce 'RepeatedListChunksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksRequest'->new($_) } @$_ ] };

declare 'MapStringListChunksRequest',
    as HashRef[ListChunksRequest()];

declare 'ListChunksResponse',
    as InstanceOf['Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksResponse'];

coerce 'ListChunksResponse',
    from HashRef, via { 'Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksResponse'->new($_) };

declare 'RepeatedListChunksResponse',
    as ArrayRef[ListChunksResponse()];

coerce 'RepeatedListChunksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Discoveryengine::V1alpha::ChunkService::ListChunksResponse'->new($_) } @$_ ] };

declare 'MapStringListChunksResponse',
    as HashRef[ListChunksResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::ChunkService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
