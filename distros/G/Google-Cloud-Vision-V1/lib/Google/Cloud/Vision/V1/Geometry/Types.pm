package Google::Cloud::Vision::V1::Geometry::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Vertex',
    as InstanceOf['Google::Cloud::Vision::V1::Geometry::Vertex'];

coerce 'Vertex',
    from HashRef, via { 'Google::Cloud::Vision::V1::Geometry::Vertex'->new($_) };

declare 'RepeatedVertex',
    as ArrayRef[Vertex()];

coerce 'RepeatedVertex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::Geometry::Vertex'->new($_) } @$_ ] };

declare 'MapStringVertex',
    as HashRef[Vertex()];

declare 'NormalizedVertex',
    as InstanceOf['Google::Cloud::Vision::V1::Geometry::NormalizedVertex'];

coerce 'NormalizedVertex',
    from HashRef, via { 'Google::Cloud::Vision::V1::Geometry::NormalizedVertex'->new($_) };

declare 'RepeatedNormalizedVertex',
    as ArrayRef[NormalizedVertex()];

coerce 'RepeatedNormalizedVertex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::Geometry::NormalizedVertex'->new($_) } @$_ ] };

declare 'MapStringNormalizedVertex',
    as HashRef[NormalizedVertex()];

declare 'BoundingPoly',
    as InstanceOf['Google::Cloud::Vision::V1::Geometry::BoundingPoly'];

coerce 'BoundingPoly',
    from HashRef, via { 'Google::Cloud::Vision::V1::Geometry::BoundingPoly'->new($_) };

declare 'RepeatedBoundingPoly',
    as ArrayRef[BoundingPoly()];

coerce 'RepeatedBoundingPoly',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::Geometry::BoundingPoly'->new($_) } @$_ ] };

declare 'MapStringBoundingPoly',
    as HashRef[BoundingPoly()];

declare 'Position',
    as InstanceOf['Google::Cloud::Vision::V1::Geometry::Position'];

coerce 'Position',
    from HashRef, via { 'Google::Cloud::Vision::V1::Geometry::Position'->new($_) };

declare 'RepeatedPosition',
    as ArrayRef[Position()];

coerce 'RepeatedPosition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::Geometry::Position'->new($_) } @$_ ] };

declare 'MapStringPosition',
    as HashRef[Position()];

1;

__END__

=head1 NAME

Google::Cloud::Vision::V1::Geometry::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
