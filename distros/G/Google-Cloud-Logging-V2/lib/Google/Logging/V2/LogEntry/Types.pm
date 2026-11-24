package Google::Logging::V2::LogEntry::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LogEntry',
    as InstanceOf['Google::Logging::V2::LogEntry::LogEntry'];

coerce 'LogEntry',
    from HashRef, via { 'Google::Logging::V2::LogEntry::LogEntry'->new($_) };

declare 'RepeatedLogEntry',
    as ArrayRef[LogEntry()];

coerce 'RepeatedLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LogEntry::LogEntry'->new($_) } @$_ ] };

declare 'MapStringLogEntry',
    as HashRef[LogEntry()];

declare 'LabelsEntry',
    as InstanceOf['Google::Logging::V2::LogEntry::LogEntry::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Logging::V2::LogEntry::LogEntry::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LogEntry::LogEntry::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'LogEntryOperation',
    as InstanceOf['Google::Logging::V2::LogEntry::LogEntryOperation'];

coerce 'LogEntryOperation',
    from HashRef, via { 'Google::Logging::V2::LogEntry::LogEntryOperation'->new($_) };

declare 'RepeatedLogEntryOperation',
    as ArrayRef[LogEntryOperation()];

coerce 'RepeatedLogEntryOperation',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LogEntry::LogEntryOperation'->new($_) } @$_ ] };

declare 'MapStringLogEntryOperation',
    as HashRef[LogEntryOperation()];

declare 'LogEntrySourceLocation',
    as InstanceOf['Google::Logging::V2::LogEntry::LogEntrySourceLocation'];

coerce 'LogEntrySourceLocation',
    from HashRef, via { 'Google::Logging::V2::LogEntry::LogEntrySourceLocation'->new($_) };

declare 'RepeatedLogEntrySourceLocation',
    as ArrayRef[LogEntrySourceLocation()];

coerce 'RepeatedLogEntrySourceLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LogEntry::LogEntrySourceLocation'->new($_) } @$_ ] };

declare 'MapStringLogEntrySourceLocation',
    as HashRef[LogEntrySourceLocation()];

declare 'LogSplit',
    as InstanceOf['Google::Logging::V2::LogEntry::LogSplit'];

coerce 'LogSplit',
    from HashRef, via { 'Google::Logging::V2::LogEntry::LogSplit'->new($_) };

declare 'RepeatedLogSplit',
    as ArrayRef[LogSplit()];

coerce 'RepeatedLogSplit',
    from ArrayRef[HashRef], via { [ map { 'Google::Logging::V2::LogEntry::LogSplit'->new($_) } @$_ ] };

declare 'MapStringLogSplit',
    as HashRef[LogSplit()];

1;

__END__

=head1 NAME

Google::Logging::V2::LogEntry::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
