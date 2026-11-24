package Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'AutonomousDatabaseBackup',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup'];

coerce 'AutonomousDatabaseBackup',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup'->new($_) };

declare 'RepeatedAutonomousDatabaseBackup',
    as ArrayRef[AutonomousDatabaseBackup()];

coerce 'RepeatedAutonomousDatabaseBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabaseBackup',
    as HashRef[AutonomousDatabaseBackup()];

declare 'LabelsEntry',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup::LabelsEntry'];

coerce 'LabelsEntry',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup::LabelsEntry'->new($_) };

declare 'RepeatedLabelsEntry',
    as ArrayRef[LabelsEntry()];

coerce 'RepeatedLabelsEntry',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackup::LabelsEntry'->new($_) } @$_ ] };

declare 'MapStringLabelsEntry',
    as HashRef[LabelsEntry()];

declare 'AutonomousDatabaseBackupProperties',
    as InstanceOf['Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackupProperties'];

coerce 'AutonomousDatabaseBackupProperties',
    from HashRef, via { 'Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackupProperties'->new($_) };

declare 'RepeatedAutonomousDatabaseBackupProperties',
    as ArrayRef[AutonomousDatabaseBackupProperties()];

coerce 'RepeatedAutonomousDatabaseBackupProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::AutonomousDatabaseBackupProperties'->new($_) } @$_ ] };

declare 'MapStringAutonomousDatabaseBackupProperties',
    as HashRef[AutonomousDatabaseBackupProperties()];

declare 'State',
    as (Int | Str);

declare 'Type',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1::AutonomousDbBackup::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
