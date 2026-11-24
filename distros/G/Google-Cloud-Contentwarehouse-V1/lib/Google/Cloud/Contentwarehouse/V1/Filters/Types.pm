package Google::Cloud::Contentwarehouse::V1::Filters::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DocumentQuery',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Filters::DocumentQuery'];

coerce 'DocumentQuery',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Filters::DocumentQuery'->new($_) };

declare 'RepeatedDocumentQuery',
    as ArrayRef[DocumentQuery()];

coerce 'RepeatedDocumentQuery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Filters::DocumentQuery'->new($_) } @$_ ] };

declare 'MapStringDocumentQuery',
    as HashRef[DocumentQuery()];

declare 'TimeFilter',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Filters::TimeFilter'];

coerce 'TimeFilter',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Filters::TimeFilter'->new($_) };

declare 'RepeatedTimeFilter',
    as ArrayRef[TimeFilter()];

coerce 'RepeatedTimeFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Filters::TimeFilter'->new($_) } @$_ ] };

declare 'MapStringTimeFilter',
    as HashRef[TimeFilter()];

declare 'TimeField',
    as (Int | Str);

declare 'PropertyFilter',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Filters::PropertyFilter'];

coerce 'PropertyFilter',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Filters::PropertyFilter'->new($_) };

declare 'RepeatedPropertyFilter',
    as ArrayRef[PropertyFilter()];

coerce 'RepeatedPropertyFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Filters::PropertyFilter'->new($_) } @$_ ] };

declare 'MapStringPropertyFilter',
    as HashRef[PropertyFilter()];

declare 'FileTypeFilter',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Filters::FileTypeFilter'];

coerce 'FileTypeFilter',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Filters::FileTypeFilter'->new($_) };

declare 'RepeatedFileTypeFilter',
    as ArrayRef[FileTypeFilter()];

coerce 'RepeatedFileTypeFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Filters::FileTypeFilter'->new($_) } @$_ ] };

declare 'MapStringFileTypeFilter',
    as HashRef[FileTypeFilter()];

declare 'FileType',
    as (Int | Str);

declare 'CustomWeightsMetadata',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Filters::CustomWeightsMetadata'];

coerce 'CustomWeightsMetadata',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Filters::CustomWeightsMetadata'->new($_) };

declare 'RepeatedCustomWeightsMetadata',
    as ArrayRef[CustomWeightsMetadata()];

coerce 'RepeatedCustomWeightsMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Filters::CustomWeightsMetadata'->new($_) } @$_ ] };

declare 'MapStringCustomWeightsMetadata',
    as HashRef[CustomWeightsMetadata()];

declare 'WeightedSchemaProperty',
    as InstanceOf['Google::Cloud::Contentwarehouse::V1::Filters::WeightedSchemaProperty'];

coerce 'WeightedSchemaProperty',
    from HashRef, via { 'Google::Cloud::Contentwarehouse::V1::Filters::WeightedSchemaProperty'->new($_) };

declare 'RepeatedWeightedSchemaProperty',
    as ArrayRef[WeightedSchemaProperty()];

coerce 'RepeatedWeightedSchemaProperty',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Contentwarehouse::V1::Filters::WeightedSchemaProperty'->new($_) } @$_ ] };

declare 'MapStringWeightedSchemaProperty',
    as HashRef[WeightedSchemaProperty()];

1;

__END__

=head1 NAME

Google::Cloud::Contentwarehouse::V1::Filters::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
