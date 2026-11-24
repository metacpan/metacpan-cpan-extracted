package Google::Cloud::Vectorsearch::V1beta::DataObject::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataObject',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject'];

coerce 'DataObject',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject'->new($_) };

declare 'RepeatedDataObject',
    as ArrayRef[DataObject()];

coerce 'RepeatedDataObject',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject'->new($_) } @$_ ] };

declare 'MapStringDataObject',
    as HashRef[DataObject()];

declare 'VectorsEntry',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject::VectorsEntry'];

coerce 'VectorsEntry',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject::VectorsEntry'->new($_) };

declare 'RepeatedVectorsEntry',
    as ArrayRef[VectorsEntry()];

coerce 'RepeatedVectorsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObject::DataObject::VectorsEntry'->new($_) } @$_ ] };

declare 'MapStringVectorsEntry',
    as HashRef[VectorsEntry()];

declare 'Vector',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObject::Vector'];

coerce 'Vector',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObject::Vector'->new($_) };

declare 'RepeatedVector',
    as ArrayRef[Vector()];

coerce 'RepeatedVector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObject::Vector'->new($_) } @$_ ] };

declare 'MapStringVector',
    as HashRef[Vector()];

declare 'DenseVector',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObject::DenseVector'];

coerce 'DenseVector',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObject::DenseVector'->new($_) };

declare 'RepeatedDenseVector',
    as ArrayRef[DenseVector()];

coerce 'RepeatedDenseVector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObject::DenseVector'->new($_) } @$_ ] };

declare 'MapStringDenseVector',
    as HashRef[DenseVector()];

declare 'SparseVector',
    as InstanceOf['Google::Cloud::Vectorsearch::V1beta::DataObject::SparseVector'];

coerce 'SparseVector',
    from HashRef, via { 'Google::Cloud::Vectorsearch::V1beta::DataObject::SparseVector'->new($_) };

declare 'RepeatedSparseVector',
    as ArrayRef[SparseVector()];

coerce 'RepeatedSparseVector',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vectorsearch::V1beta::DataObject::SparseVector'->new($_) } @$_ ] };

declare 'MapStringSparseVector',
    as HashRef[SparseVector()];

1;

__END__

=head1 NAME

Google::Cloud::Vectorsearch::V1beta::DataObject::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
