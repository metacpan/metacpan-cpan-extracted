package Google::Cloud::Ces::V1::WidgetTool::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'WidgetTool',
    as InstanceOf['Google::Cloud::Ces::V1::WidgetTool::WidgetTool'];

coerce 'WidgetTool',
    from HashRef, via { 'Google::Cloud::Ces::V1::WidgetTool::WidgetTool'->new($_) };

declare 'RepeatedWidgetTool',
    as ArrayRef[WidgetTool()];

coerce 'RepeatedWidgetTool',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::WidgetTool::WidgetTool'->new($_) } @$_ ] };

declare 'MapStringWidgetTool',
    as HashRef[WidgetTool()];

declare 'WidgetType',
    as (Int | Str);

declare 'TextResponseConfig',
    as InstanceOf['Google::Cloud::Ces::V1::WidgetTool::WidgetTool::TextResponseConfig'];

coerce 'TextResponseConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::WidgetTool::WidgetTool::TextResponseConfig'->new($_) };

declare 'RepeatedTextResponseConfig',
    as ArrayRef[TextResponseConfig()];

coerce 'RepeatedTextResponseConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::WidgetTool::WidgetTool::TextResponseConfig'->new($_) } @$_ ] };

declare 'MapStringTextResponseConfig',
    as HashRef[TextResponseConfig()];

declare 'Type',
    as (Int | Str);

declare 'DataMapping',
    as InstanceOf['Google::Cloud::Ces::V1::WidgetTool::WidgetTool::DataMapping'];

coerce 'DataMapping',
    from HashRef, via { 'Google::Cloud::Ces::V1::WidgetTool::WidgetTool::DataMapping'->new($_) };

declare 'RepeatedDataMapping',
    as ArrayRef[DataMapping()];

coerce 'RepeatedDataMapping',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::WidgetTool::WidgetTool::DataMapping'->new($_) } @$_ ] };

declare 'MapStringDataMapping',
    as HashRef[DataMapping()];

declare 'Mode',
    as (Int | Str);

declare 'FieldMappingsEntry',
    as InstanceOf['Google::Cloud::Ces::V1::WidgetTool::WidgetTool::DataMapping::FieldMappingsEntry'];

coerce 'FieldMappingsEntry',
    from HashRef, via { 'Google::Cloud::Ces::V1::WidgetTool::WidgetTool::DataMapping::FieldMappingsEntry'->new($_) };

declare 'RepeatedFieldMappingsEntry',
    as ArrayRef[FieldMappingsEntry()];

coerce 'RepeatedFieldMappingsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::WidgetTool::WidgetTool::DataMapping::FieldMappingsEntry'->new($_) } @$_ ] };

declare 'MapStringFieldMappingsEntry',
    as HashRef[FieldMappingsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::WidgetTool::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
