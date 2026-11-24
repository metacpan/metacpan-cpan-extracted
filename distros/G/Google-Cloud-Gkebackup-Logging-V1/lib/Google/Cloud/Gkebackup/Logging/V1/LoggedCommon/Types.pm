package Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Namespaces',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::Namespaces'];

coerce 'Namespaces',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::Namespaces'->new($_) };

declare 'RepeatedNamespaces',
    as ArrayRef[Namespaces()];

coerce 'RepeatedNamespaces',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::Namespaces'->new($_) } @$_ ] };

declare 'MapStringNamespaces',
    as HashRef[Namespaces()];

declare 'NamespacedName',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedName'];

coerce 'NamespacedName',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedName'->new($_) };

declare 'RepeatedNamespacedName',
    as ArrayRef[NamespacedName()];

coerce 'RepeatedNamespacedName',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedName'->new($_) } @$_ ] };

declare 'MapStringNamespacedName',
    as HashRef[NamespacedName()];

declare 'NamespacedNames',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedNames'];

coerce 'NamespacedNames',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedNames'->new($_) };

declare 'RepeatedNamespacedNames',
    as ArrayRef[NamespacedNames()];

coerce 'RepeatedNamespacedNames',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::NamespacedNames'->new($_) } @$_ ] };

declare 'MapStringNamespacedNames',
    as HashRef[NamespacedNames()];

declare 'EncryptionKey',
    as InstanceOf['Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::EncryptionKey'];

coerce 'EncryptionKey',
    from HashRef, via { 'Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::EncryptionKey'->new($_) };

declare 'RepeatedEncryptionKey',
    as ArrayRef[EncryptionKey()];

coerce 'RepeatedEncryptionKey',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::EncryptionKey'->new($_) } @$_ ] };

declare 'MapStringEncryptionKey',
    as HashRef[EncryptionKey()];

1;

__END__

=head1 NAME

Google::Cloud::Gkebackup::Logging::V1::LoggedCommon::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
