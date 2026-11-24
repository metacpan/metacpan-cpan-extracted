package Google::Monitoring::Dashboard::V1::Layouts::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GridLayout',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Layouts::GridLayout'];

coerce 'GridLayout',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Layouts::GridLayout'->new($_) };

declare 'RepeatedGridLayout',
    as ArrayRef[GridLayout()];

coerce 'RepeatedGridLayout',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Layouts::GridLayout'->new($_) } @$_ ] };

declare 'MapStringGridLayout',
    as HashRef[GridLayout()];

declare 'MosaicLayout',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Layouts::MosaicLayout'];

coerce 'MosaicLayout',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Layouts::MosaicLayout'->new($_) };

declare 'RepeatedMosaicLayout',
    as ArrayRef[MosaicLayout()];

coerce 'RepeatedMosaicLayout',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Layouts::MosaicLayout'->new($_) } @$_ ] };

declare 'MapStringMosaicLayout',
    as HashRef[MosaicLayout()];

declare 'Tile',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Layouts::MosaicLayout::Tile'];

coerce 'Tile',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Layouts::MosaicLayout::Tile'->new($_) };

declare 'RepeatedTile',
    as ArrayRef[Tile()];

coerce 'RepeatedTile',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Layouts::MosaicLayout::Tile'->new($_) } @$_ ] };

declare 'MapStringTile',
    as HashRef[Tile()];

declare 'RowLayout',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Layouts::RowLayout'];

coerce 'RowLayout',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Layouts::RowLayout'->new($_) };

declare 'RepeatedRowLayout',
    as ArrayRef[RowLayout()];

coerce 'RepeatedRowLayout',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Layouts::RowLayout'->new($_) } @$_ ] };

declare 'MapStringRowLayout',
    as HashRef[RowLayout()];

declare 'Row',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Layouts::RowLayout::Row'];

coerce 'Row',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Layouts::RowLayout::Row'->new($_) };

declare 'RepeatedRow',
    as ArrayRef[Row()];

coerce 'RepeatedRow',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Layouts::RowLayout::Row'->new($_) } @$_ ] };

declare 'MapStringRow',
    as HashRef[Row()];

declare 'ColumnLayout',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Layouts::ColumnLayout'];

coerce 'ColumnLayout',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Layouts::ColumnLayout'->new($_) };

declare 'RepeatedColumnLayout',
    as ArrayRef[ColumnLayout()];

coerce 'RepeatedColumnLayout',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Layouts::ColumnLayout'->new($_) } @$_ ] };

declare 'MapStringColumnLayout',
    as HashRef[ColumnLayout()];

declare 'Column',
    as InstanceOf['Google::Monitoring::Dashboard::V1::Layouts::ColumnLayout::Column'];

coerce 'Column',
    from HashRef, via { 'Google::Monitoring::Dashboard::V1::Layouts::ColumnLayout::Column'->new($_) };

declare 'RepeatedColumn',
    as ArrayRef[Column()];

coerce 'RepeatedColumn',
    from ArrayRef[HashRef], via { [ map { 'Google::Monitoring::Dashboard::V1::Layouts::ColumnLayout::Column'->new($_) } @$_ ] };

declare 'MapStringColumn',
    as HashRef[Column()];

1;

__END__

=head1 NAME

Google::Monitoring::Dashboard::V1::Layouts::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
