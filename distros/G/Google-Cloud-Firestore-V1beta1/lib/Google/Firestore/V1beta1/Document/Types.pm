package Google::Firestore::V1beta1::Document::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Document',
    as InstanceOf['Google::Firestore::V1beta1::Document::Document'];

coerce 'Document',
    from HashRef, via { 'Google::Firestore::V1beta1::Document::Document'->new($_) };

declare 'RepeatedDocument',
    as ArrayRef[Document()];

coerce 'RepeatedDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Document::Document'->new($_) } @$_ ] };

declare 'MapStringDocument',
    as HashRef[Document()];

declare 'FieldsEntry',
    as InstanceOf['Google::Firestore::V1beta1::Document::Document::FieldsEntry'];

coerce 'FieldsEntry',
    from HashRef, via { 'Google::Firestore::V1beta1::Document::Document::FieldsEntry'->new($_) };

declare 'RepeatedFieldsEntry',
    as ArrayRef[FieldsEntry()];

coerce 'RepeatedFieldsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Document::Document::FieldsEntry'->new($_) } @$_ ] };

declare 'MapStringFieldsEntry',
    as HashRef[FieldsEntry()];

declare 'Value',
    as InstanceOf['Google::Firestore::V1beta1::Document::Value'];

coerce 'Value',
    from HashRef, via { 'Google::Firestore::V1beta1::Document::Value'->new($_) };

declare 'RepeatedValue',
    as ArrayRef[Value()];

coerce 'RepeatedValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Document::Value'->new($_) } @$_ ] };

declare 'MapStringValue',
    as HashRef[Value()];

declare 'ArrayValue',
    as InstanceOf['Google::Firestore::V1beta1::Document::ArrayValue'];

coerce 'ArrayValue',
    from HashRef, via { 'Google::Firestore::V1beta1::Document::ArrayValue'->new($_) };

declare 'RepeatedArrayValue',
    as ArrayRef[ArrayValue()];

coerce 'RepeatedArrayValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Document::ArrayValue'->new($_) } @$_ ] };

declare 'MapStringArrayValue',
    as HashRef[ArrayValue()];

declare 'MapValue',
    as InstanceOf['Google::Firestore::V1beta1::Document::MapValue'];

coerce 'MapValue',
    from HashRef, via { 'Google::Firestore::V1beta1::Document::MapValue'->new($_) };

declare 'RepeatedMapValue',
    as ArrayRef[MapValue()];

coerce 'RepeatedMapValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Document::MapValue'->new($_) } @$_ ] };

declare 'MapStringMapValue',
    as HashRef[MapValue()];

declare 'FieldsEntry',
    as InstanceOf['Google::Firestore::V1beta1::Document::MapValue::FieldsEntry'];

coerce 'FieldsEntry',
    from HashRef, via { 'Google::Firestore::V1beta1::Document::MapValue::FieldsEntry'->new($_) };

declare 'RepeatedFieldsEntry',
    as ArrayRef[FieldsEntry()];

coerce 'RepeatedFieldsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Firestore::V1beta1::Document::MapValue::FieldsEntry'->new($_) } @$_ ] };

declare 'MapStringFieldsEntry',
    as HashRef[FieldsEntry()];

1;

__END__

=head1 NAME

Google::Firestore::V1beta1::Document::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
