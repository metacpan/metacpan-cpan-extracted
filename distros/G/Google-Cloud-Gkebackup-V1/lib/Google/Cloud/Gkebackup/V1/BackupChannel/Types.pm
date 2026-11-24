package Google::Cloud::Gkebackup::V1::BackupChannel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupChannel',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel'];

coerce 'BackupChannel',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel'->new($_) };

declare 'RepeatedBackupChannel',
    as ArrayRef[BackupChannel()];

coerce 'RepeatedBackupChannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel'->new($_) } @$_ ] };

declare 'MapStringBackupChannel',
    as HashRef[BackupChannel()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::BackupChannel::BackupChannel::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::BackupChannel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
