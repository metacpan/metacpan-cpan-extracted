package Google::Cloud::Gkebackup::V1::Common::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Namespaces',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Common::Namespaces'];

coerce 'Namespaces',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Common::Namespaces'->new($_) };

declare 'RepeatedNamespaces',
    as ArrayRef[Namespaces()];

coerce 'RepeatedNamespaces',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Common::Namespaces'->new($_) } @$_ ] };

declare 'MapStringNamespaces',
    as HashRef[Namespaces()];

declare 'NamespacedName',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Common::NamespacedName'];

coerce 'NamespacedName',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Common::NamespacedName'->new($_) };

declare 'RepeatedNamespacedName',
    as ArrayRef[NamespacedName()];

coerce 'RepeatedNamespacedName',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Common::NamespacedName'->new($_) } @$_ ] };

declare 'MapStringNamespacedName',
    as HashRef[NamespacedName()];

declare 'NamespacedNames',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Common::NamespacedNames'];

coerce 'NamespacedNames',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Common::NamespacedNames'->new($_) };

declare 'RepeatedNamespacedNames',
    as ArrayRef[NamespacedNames()];

coerce 'RepeatedNamespacedNames',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Common::NamespacedNames'->new($_) } @$_ ] };

declare 'MapStringNamespacedNames',
    as HashRef[NamespacedNames()];

declare 'EncryptionKey',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Common::EncryptionKey'];

coerce 'EncryptionKey',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Common::EncryptionKey'->new($_) };

declare 'RepeatedEncryptionKey',
    as ArrayRef[EncryptionKey()];

coerce 'RepeatedEncryptionKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Common::EncryptionKey'->new($_) } @$_ ] };

declare 'MapStringEncryptionKey',
    as HashRef[EncryptionKey()];

declare 'VolumeTypeEnum',
    as InstanceOf['Google::Cloud::Gkebackup::V1::Common::VolumeTypeEnum'];

coerce 'VolumeTypeEnum',
    from HashRef, via { 'Google::Cloud::Gkebackup::V1::Common::VolumeTypeEnum'->new($_) };

declare 'RepeatedVolumeTypeEnum',
    as ArrayRef[VolumeTypeEnum()];

coerce 'RepeatedVolumeTypeEnum',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::V1::Common::VolumeTypeEnum'->new($_) } @$_ ] };

declare 'MapStringVolumeTypeEnum',
    as HashRef[VolumeTypeEnum()];

declare 'VolumeType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::V1::Common::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
