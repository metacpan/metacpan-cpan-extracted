package Google::Cloud::Automl::V1beta1::Geometry::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NormalizedVertex',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Geometry::NormalizedVertex'];

coerce 'NormalizedVertex',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Geometry::NormalizedVertex'->new($_) };

declare 'RepeatedNormalizedVertex',
    as ArrayRef[NormalizedVertex()];

coerce 'RepeatedNormalizedVertex',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Geometry::NormalizedVertex'->new($_) } @$_ ] };

declare 'MapStringNormalizedVertex',
    as HashRef[NormalizedVertex()];

declare 'BoundingPoly',
    as InstanceOf['Google::Cloud::Automl::V1beta1::Geometry::BoundingPoly'];

coerce 'BoundingPoly',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::Geometry::BoundingPoly'->new($_) };

declare 'RepeatedBoundingPoly',
    as ArrayRef[BoundingPoly()];

coerce 'RepeatedBoundingPoly',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::Geometry::BoundingPoly'->new($_) } @$_ ] };

declare 'MapStringBoundingPoly',
    as HashRef[BoundingPoly()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::Geometry::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
