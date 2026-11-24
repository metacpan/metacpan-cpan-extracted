package Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LoggedBackupPlanMetadata',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::LoggedBackupPlanMetadata'];

coerce 'LoggedBackupPlanMetadata',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::LoggedBackupPlanMetadata'->new($_) };

declare 'RepeatedLoggedBackupPlanMetadata',
    as ArrayRef[LoggedBackupPlanMetadata()];

coerce 'RepeatedLoggedBackupPlanMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::LoggedBackupPlanMetadata'->new($_) } @$_ ] };

declare 'MapStringLoggedBackupPlanMetadata',
    as HashRef[LoggedBackupPlanMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedBackupPlanMetadata::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
