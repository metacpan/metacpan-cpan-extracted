package Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataType',
    as (Int | Str);

declare 'ParameterDefinition',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::ParameterDefinition'];

coerce 'ParameterDefinition',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::ParameterDefinition'->new($_) };

declare 'RepeatedParameterDefinition',
    as ArrayRef[ParameterDefinition()];

coerce 'RepeatedParameterDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::ParameterDefinition'->new($_) } @$_ ] };

declare 'MapStringParameterDefinition',
    as HashRef[ParameterDefinition()];

declare 'ParameterType',
    as (Int | Str);

declare 'TypeSchema',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema'];

coerce 'TypeSchema',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema'->new($_) };

declare 'RepeatedTypeSchema',
    as ArrayRef[TypeSchema()];

coerce 'RepeatedTypeSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema'->new($_) } @$_ ] };

declare 'MapStringTypeSchema',
    as HashRef[TypeSchema()];

declare 'SchemaReference',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema::SchemaReference'];

coerce 'SchemaReference',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema::SchemaReference'->new($_) };

declare 'RepeatedSchemaReference',
    as ArrayRef[SchemaReference()];

coerce 'RepeatedSchemaReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::TypeSchema::SchemaReference'->new($_) } @$_ ] };

declare 'MapStringSchemaReference',
    as HashRef[SchemaReference()];

declare 'InlineSchema',
    as InstanceOf['Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::InlineSchema'];

coerce 'InlineSchema',
    from HashRef, via { 'Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::InlineSchema'->new($_) };

declare 'RepeatedInlineSchema',
    as ArrayRef[InlineSchema()];

coerce 'RepeatedInlineSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::InlineSchema'->new($_) } @$_ ] };

declare 'MapStringInlineSchema',
    as HashRef[InlineSchema()];

1;

__END__

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::ParameterDefinition::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
