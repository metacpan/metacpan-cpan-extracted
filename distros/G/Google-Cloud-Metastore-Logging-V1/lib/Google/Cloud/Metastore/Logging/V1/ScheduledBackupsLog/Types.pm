package Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ScheduledBackupLogEntry',
    as InstanceOf['Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog::ScheduledBackupLogEntry'];

coerce 'ScheduledBackupLogEntry',
    from HashRef, via { 'Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog::ScheduledBackupLogEntry'->new($_) };

declare 'RepeatedScheduledBackupLogEntry',
    as ArrayRef[ScheduledBackupLogEntry()];

coerce 'RepeatedScheduledBackupLogEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog::ScheduledBackupLogEntry'->new($_) } @$_ ] };

declare 'MapStringScheduledBackupLogEntry',
    as HashRef[ScheduledBackupLogEntry()];

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Metastore::Logging::V1::ScheduledBackupsLog::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
