package Google::Cloud::Securitycenter::V2::BackupDisasterRecovery::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BackupDisasterRecovery',
    as InstanceOf['Google::Cloud::Securitycenter::V2::BackupDisasterRecovery::BackupDisasterRecovery'];

coerce 'BackupDisasterRecovery',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::BackupDisasterRecovery::BackupDisasterRecovery'->new($_) };

declare 'RepeatedBackupDisasterRecovery',
    as ArrayRef[BackupDisasterRecovery()];

coerce 'RepeatedBackupDisasterRecovery',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::BackupDisasterRecovery::BackupDisasterRecovery'->new($_) } @$_ ] };

declare 'MapStringBackupDisasterRecovery',
    as HashRef[BackupDisasterRecovery()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::BackupDisasterRecovery::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
