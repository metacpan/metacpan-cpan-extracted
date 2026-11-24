package Google::Cloud::Automl::V1beta1::DataItems::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Image',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataItems::Image'];

coerce 'Image',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataItems::Image'->new($_) };

declare 'RepeatedImage',
    as ArrayRef[Image()];

coerce 'RepeatedImage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataItems::Image'->new($_) } @$_ ] };

declare 'MapStringImage',
    as HashRef[Image()];

declare 'TextSnippet',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataItems::TextSnippet'];

coerce 'TextSnippet',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataItems::TextSnippet'->new($_) };

declare 'RepeatedTextSnippet',
    as ArrayRef[TextSnippet()];

coerce 'RepeatedTextSnippet',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataItems::TextSnippet'->new($_) } @$_ ] };

declare 'MapStringTextSnippet',
    as HashRef[TextSnippet()];

declare 'DocumentDimensions',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataItems::DocumentDimensions'];

coerce 'DocumentDimensions',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataItems::DocumentDimensions'->new($_) };

declare 'RepeatedDocumentDimensions',
    as ArrayRef[DocumentDimensions()];

coerce 'RepeatedDocumentDimensions',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataItems::DocumentDimensions'->new($_) } @$_ ] };

declare 'MapStringDocumentDimensions',
    as HashRef[DocumentDimensions()];

declare 'DocumentDimensionUnit',
    as (Int | Str);

declare 'Document',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataItems::Document'];

coerce 'Document',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataItems::Document'->new($_) };

declare 'RepeatedDocument',
    as ArrayRef[Document()];

coerce 'RepeatedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataItems::Document'->new($_) } @$_ ] };

declare 'MapStringDocument',
    as HashRef[Document()];

declare 'Layout',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataItems::Document::Layout'];

coerce 'Layout',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataItems::Document::Layout'->new($_) };

declare 'RepeatedLayout',
    as ArrayRef[Layout()];

coerce 'RepeatedLayout',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataItems::Document::Layout'->new($_) } @$_ ] };

declare 'MapStringLayout',
    as HashRef[Layout()];

declare 'TextSegmentType',
    as (Int | Str);

declare 'Row',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataItems::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataItems::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataItems::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

declare 'ExamplePayload',
    as InstanceOf['Google::Cloud::Automl::V1beta1::DataItems::ExamplePayload'];

coerce 'ExamplePayload',
    from HashRef, via { 'Google::Cloud::Automl::V1beta1::DataItems::ExamplePayload'->new($_) };

declare 'RepeatedExamplePayload',
    as ArrayRef[ExamplePayload()];

coerce 'RepeatedExamplePayload',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Automl::V1beta1::DataItems::ExamplePayload'->new($_) } @$_ ] };

declare 'MapStringExamplePayload',
    as HashRef[ExamplePayload()];

1;

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::DataItems::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
