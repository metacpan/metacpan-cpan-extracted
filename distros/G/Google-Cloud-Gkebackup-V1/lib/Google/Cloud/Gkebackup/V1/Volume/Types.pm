package Google::Cloud::Gkebackup::V1::Volume::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'VolumeBackup',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Volume::VolumeBackup'];

coerce 'VolumeBackup',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Volume::VolumeBackup'->new($_) };

declare 'RepeatedVolumeBackup',
    as ArrayRef[VolumeBackup()];

coerce 'RepeatedVolumeBackup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Volume::VolumeBackup'->new($_) } @$_ ] };

declare 'MapStringVolumeBackup',
    as HashRef[VolumeBackup()];

declare 'VolumeBackupFormat',
    as (Int | Str);

declare 'State',
    as (Int | Str);

declare 'VolumeRestore',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Volume::VolumeRestore'];

coerce 'VolumeRestore',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Volume::VolumeRestore'->new($_) };

declare 'RepeatedVolumeRestore',
    as ArrayRef[VolumeRestore()];

coerce 'RepeatedVolumeRestore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Volume::VolumeRestore'->new($_) } @$_ ] };

declare 'MapStringVolumeRestore',
    as HashRef[VolumeRestore()];

declare 'VolumeType',
    as (Int | Str);

declare 'State',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::Volume::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
