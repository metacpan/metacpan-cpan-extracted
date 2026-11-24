package Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoggedBackupChannel',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel'];

coerce 'LoggedBackupChannel',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel'->new($_) };

declare 'RepeatedLoggedBackupChannel',
    as ArrayRef[LoggedBackupChannel()];

coerce 'RepeatedLoggedBackupChannel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel'->new($_) } @$_ ] };

declare 'MapStringLoggedBackupChannel',
    as HashRef[LoggedBackupChannel()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::LoggedBackupChannel::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedBackupChannel::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
