package Google::Cloud::Netapp::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ServiceLevel',
    as (Int | Str);

declare 'FlexPerformance',
    as (Int | Str);

declare 'EncryptionType',
    as (Int | Str);

declare 'DirectoryServiceType',
    as (Int | Str);

declare 'StoragePoolType',
    as (Int | Str);

declare 'ScaleType',
    as (Int | Str);

declare 'HybridReplicationSchedule',
    as (Int | Str);

declare 'QosType',
    as (Int | Str);

declare 'OsType',
    as (Int | Str);

declare 'LocationMetadata',
    as InstanceOf['Google::Cloud::Netapp::V1::Common::LocationMetadata'];

coerce 'LocationMetadata',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Common::LocationMetadata'->new($_) };

declare 'RepeatedLocationMetadata',
    as ArrayRef[LocationMetadata()];

coerce 'RepeatedLocationMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Common::LocationMetadata'->new($_) } @$_ ] };

declare 'MapStringLocationMetadata',
    as HashRef[LocationMetadata()];

declare 'FlexPerformanceTier',
    as (Int | Str);

declare 'UserCommands',
    as InstanceOf['Google::Cloud::Netapp::V1::Common::UserCommands'];

coerce 'UserCommands',
    from HashRef, via { 'Google::Cloud::Netapp::V1::Common::UserCommands'->new($_) };

declare 'RepeatedUserCommands',
    as ArrayRef[UserCommands()];

coerce 'RepeatedUserCommands',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Netapp::V1::Common::UserCommands'->new($_) } @$_ ] };

declare 'MapStringUserCommands',
    as HashRef[UserCommands()];

1;

__END__

=head1 NAME

Google::Cloud::Netapp::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
