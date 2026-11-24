package Google::Cloud::Datacatalog::V1beta1::Tags::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Tag',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Tags::Tag'];

coerce 'Tag',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Tags::Tag'->new($_) };

declare 'RepeatedTag',
    as ArrayRef[Tag()];

coerce 'RepeatedTag',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Tags::Tag'->new($_) } @$_ ] };

declare 'MapStringTag',
    as HashRef[Tag()];

declare 'FieldsEntry',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Tags::Tag::FieldsEntry'];

coerce 'FieldsEntry',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Tags::Tag::FieldsEntry'->new($_) };

declare 'RepeatedFieldsEntry',
    as ArrayRef[FieldsEntry()];

coerce 'RepeatedFieldsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Tags::Tag::FieldsEntry'->new($_) } @$_ ] };

declare 'MapStringFieldsEntry',
    as HashRef[FieldsEntry()];

declare 'TagField',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Tags::TagField'];

coerce 'TagField',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Tags::TagField'->new($_) };

declare 'RepeatedTagField',
    as ArrayRef[TagField()];

coerce 'RepeatedTagField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Tags::TagField'->new($_) } @$_ ] };

declare 'MapStringTagField',
    as HashRef[TagField()];

declare 'EnumValue',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Tags::TagField::EnumValue'];

coerce 'EnumValue',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Tags::TagField::EnumValue'->new($_) };

declare 'RepeatedEnumValue',
    as ArrayRef[EnumValue()];

coerce 'RepeatedEnumValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Tags::TagField::EnumValue'->new($_) } @$_ ] };

declare 'MapStringEnumValue',
    as HashRef[EnumValue()];

declare 'TagTemplate',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplate'];

coerce 'TagTemplate',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplate'->new($_) };

declare 'RepeatedTagTemplate',
    as ArrayRef[TagTemplate()];

coerce 'RepeatedTagTemplate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplate'->new($_) } @$_ ] };

declare 'MapStringTagTemplate',
    as HashRef[TagTemplate()];

declare 'DataplexTransferStatus',
    as (Int | Str);

declare 'FieldsEntry',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplate::FieldsEntry'];

coerce 'FieldsEntry',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplate::FieldsEntry'->new($_) };

declare 'RepeatedFieldsEntry',
    as ArrayRef[FieldsEntry()];

coerce 'RepeatedFieldsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplate::FieldsEntry'->new($_) } @$_ ] };

declare 'MapStringFieldsEntry',
    as HashRef[FieldsEntry()];

declare 'TagTemplateField',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplateField'];

coerce 'TagTemplateField',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplateField'->new($_) };

declare 'RepeatedTagTemplateField',
    as ArrayRef[TagTemplateField()];

coerce 'RepeatedTagTemplateField',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Tags::TagTemplateField'->new($_) } @$_ ] };

declare 'MapStringTagTemplateField',
    as HashRef[TagTemplateField()];

declare 'FieldType',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Tags::FieldType'];

coerce 'FieldType',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Tags::FieldType'->new($_) };

declare 'RepeatedFieldType',
    as ArrayRef[FieldType()];

coerce 'RepeatedFieldType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Tags::FieldType'->new($_) } @$_ ] };

declare 'MapStringFieldType',
    as HashRef[FieldType()];

declare 'PrimitiveType',
    as (Int | Str);

declare 'EnumType',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Tags::FieldType::EnumType'];

coerce 'EnumType',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Tags::FieldType::EnumType'->new($_) };

declare 'RepeatedEnumType',
    as ArrayRef[EnumType()];

coerce 'RepeatedEnumType',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Tags::FieldType::EnumType'->new($_) } @$_ ] };

declare 'MapStringEnumType',
    as HashRef[EnumType()];

declare 'EnumValue',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Tags::FieldType::EnumType::EnumValue'];

coerce 'EnumValue',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Tags::FieldType::EnumType::EnumValue'->new($_) };

declare 'RepeatedEnumValue',
    as ArrayRef[EnumValue()];

coerce 'RepeatedEnumValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Tags::FieldType::EnumType::EnumValue'->new($_) } @$_ ] };

declare 'MapStringEnumValue',
    as HashRef[EnumValue()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Tags::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
