package Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EmbeddingTaskType',
    as (Int | Str);

declare 'VertexEmbeddingConfig',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig::VertexEmbeddingConfig'];

coerce 'VertexEmbeddingConfig',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig::VertexEmbeddingConfig'->new($_) };

declare 'RepeatedVertexEmbeddingConfig',
    as ArrayRef[VertexEmbeddingConfig()];

coerce 'RepeatedVertexEmbeddingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig::VertexEmbeddingConfig'->new($_) } @$_ ] };

declare 'MapStringVertexEmbeddingConfig',
    as HashRef[VertexEmbeddingConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
