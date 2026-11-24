package Google::Cloud::Vision::V1::ProductSearch::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProductSearchParams',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearch::ProductSearchParams'];

coerce 'ProductSearchParams',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearch::ProductSearchParams'->new($_) };

declare 'RepeatedProductSearchParams',
    as ArrayRef[ProductSearchParams()];

coerce 'RepeatedProductSearchParams',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearch::ProductSearchParams'->new($_) } @$_ ] };

declare 'MapStringProductSearchParams',
    as HashRef[ProductSearchParams()];

declare 'ProductSearchResults',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults'];

coerce 'ProductSearchResults',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults'->new($_) };

declare 'RepeatedProductSearchResults',
    as ArrayRef[ProductSearchResults()];

coerce 'RepeatedProductSearchResults',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults'->new($_) } @$_ ] };

declare 'MapStringProductSearchResults',
    as HashRef[ProductSearchResults()];

declare 'Result',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::Result'];

coerce 'Result',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::Result'->new($_) };

declare 'RepeatedResult',
    as ArrayRef[Result()];

coerce 'RepeatedResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::Result'->new($_) } @$_ ] };

declare 'MapStringResult',
    as HashRef[Result()];

declare 'ObjectAnnotation',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::ObjectAnnotation'];

coerce 'ObjectAnnotation',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::ObjectAnnotation'->new($_) };

declare 'RepeatedObjectAnnotation',
    as ArrayRef[ObjectAnnotation()];

coerce 'RepeatedObjectAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::ObjectAnnotation'->new($_) } @$_ ] };

declare 'MapStringObjectAnnotation',
    as HashRef[ObjectAnnotation()];

declare 'GroupedResult',
    as InstanceOf['Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::GroupedResult'];

coerce 'GroupedResult',
    from HashRef, via { 'Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::GroupedResult'->new($_) };

declare 'RepeatedGroupedResult',
    as ArrayRef[GroupedResult()];

coerce 'RepeatedGroupedResult',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Vision::V1::ProductSearch::ProductSearchResults::GroupedResult'->new($_) } @$_ ] };

declare 'MapStringGroupedResult',
    as HashRef[GroupedResult()];

1;

__END__

=head1 NAME

Google::Cloud::Vision::V1::ProductSearch::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
