package Google::Cloud::Backupdr::V1beta::BackupvaultBa::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupApplianceBackupProperties',
    as InstanceOf['Google::Cloud::Backupdr::V1beta::BackupvaultBa::BackupApplianceBackupProperties'];

coerce 'BackupApplianceBackupProperties',
    from HashRef, via { 'Google::Cloud::Backupdr::V1beta::BackupvaultBa::BackupApplianceBackupProperties'->new($_) };

declare 'RepeatedBackupApplianceBackupProperties',
    as ArrayRef[BackupApplianceBackupProperties()];

coerce 'RepeatedBackupApplianceBackupProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Backupdr::V1beta::BackupvaultBa::BackupApplianceBackupProperties'->new($_) } @$_ ] };

declare 'MapStringBackupApplianceBackupProperties',
    as HashRef[BackupApplianceBackupProperties()];

1;

__END__

=head1 NAME

Google::Cloud::Backupdr::V1beta::BackupvaultBa::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
