package Google::Spanner::V1::ChangeStream::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ChangeStreamRecord',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord'];

coerce 'ChangeStreamRecord',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord'->new($_) };

declare 'RepeatedChangeStreamRecord',
    as ArrayRef[ChangeStreamRecord()];

coerce 'RepeatedChangeStreamRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord'->new($_) } @$_ ] };

declare 'MapStringChangeStreamRecord',
    as HashRef[ChangeStreamRecord()];

declare 'DataChangeRecord',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord'];

coerce 'DataChangeRecord',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord'->new($_) };

declare 'RepeatedDataChangeRecord',
    as ArrayRef[DataChangeRecord()];

coerce 'RepeatedDataChangeRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord'->new($_) } @$_ ] };

declare 'MapStringDataChangeRecord',
    as HashRef[DataChangeRecord()];

declare 'ModType',
    as (Int | Str);

declare 'ValueCaptureType',
    as (Int | Str);

declare 'ColumnMetadata',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord::ColumnMetadata'];

coerce 'ColumnMetadata',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord::ColumnMetadata'->new($_) };

declare 'RepeatedColumnMetadata',
    as ArrayRef[ColumnMetadata()];

coerce 'RepeatedColumnMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord::ColumnMetadata'->new($_) } @$_ ] };

declare 'MapStringColumnMetadata',
    as HashRef[ColumnMetadata()];

declare 'ModValue',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord::ModValue'];

coerce 'ModValue',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord::ModValue'->new($_) };

declare 'RepeatedModValue',
    as ArrayRef[ModValue()];

coerce 'RepeatedModValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord::ModValue'->new($_) } @$_ ] };

declare 'MapStringModValue',
    as HashRef[ModValue()];

declare 'Mod',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord::Mod'];

coerce 'Mod',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord::Mod'->new($_) };

declare 'RepeatedMod',
    as ArrayRef[Mod()];

coerce 'RepeatedMod',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::DataChangeRecord::Mod'->new($_) } @$_ ] };

declare 'MapStringMod',
    as HashRef[Mod()];

declare 'HeartbeatRecord',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord::HeartbeatRecord'];

coerce 'HeartbeatRecord',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::HeartbeatRecord'->new($_) };

declare 'RepeatedHeartbeatRecord',
    as ArrayRef[HeartbeatRecord()];

coerce 'RepeatedHeartbeatRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::HeartbeatRecord'->new($_) } @$_ ] };

declare 'MapStringHeartbeatRecord',
    as HashRef[HeartbeatRecord()];

declare 'PartitionStartRecord',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionStartRecord'];

coerce 'PartitionStartRecord',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionStartRecord'->new($_) };

declare 'RepeatedPartitionStartRecord',
    as ArrayRef[PartitionStartRecord()];

coerce 'RepeatedPartitionStartRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionStartRecord'->new($_) } @$_ ] };

declare 'MapStringPartitionStartRecord',
    as HashRef[PartitionStartRecord()];

declare 'PartitionEndRecord',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEndRecord'];

coerce 'PartitionEndRecord',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEndRecord'->new($_) };

declare 'RepeatedPartitionEndRecord',
    as ArrayRef[PartitionEndRecord()];

coerce 'RepeatedPartitionEndRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEndRecord'->new($_) } @$_ ] };

declare 'MapStringPartitionEndRecord',
    as HashRef[PartitionEndRecord()];

declare 'PartitionEventRecord',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEventRecord'];

coerce 'PartitionEventRecord',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEventRecord'->new($_) };

declare 'RepeatedPartitionEventRecord',
    as ArrayRef[PartitionEventRecord()];

coerce 'RepeatedPartitionEventRecord',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEventRecord'->new($_) } @$_ ] };

declare 'MapStringPartitionEventRecord',
    as HashRef[PartitionEventRecord()];

declare 'MoveInEvent',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEventRecord::MoveInEvent'];

coerce 'MoveInEvent',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEventRecord::MoveInEvent'->new($_) };

declare 'RepeatedMoveInEvent',
    as ArrayRef[MoveInEvent()];

coerce 'RepeatedMoveInEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEventRecord::MoveInEvent'->new($_) } @$_ ] };

declare 'MapStringMoveInEvent',
    as HashRef[MoveInEvent()];

declare 'MoveOutEvent',
    as InstanceOf['Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEventRecord::MoveOutEvent'];

coerce 'MoveOutEvent',
    from HashRef, via { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEventRecord::MoveOutEvent'->new($_) };

declare 'RepeatedMoveOutEvent',
    as ArrayRef[MoveOutEvent()];

coerce 'RepeatedMoveOutEvent',
    from ArrayRef[HashRef], via { [ map { 'Google::Spanner::V1::ChangeStream::ChangeStreamRecord::PartitionEventRecord::MoveOutEvent'->new($_) } @$_ ] };

declare 'MapStringMoveOutEvent',
    as HashRef[MoveOutEvent()];

1;

__END__

=head1 NAME

Google::Spanner::V1::ChangeStream::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
