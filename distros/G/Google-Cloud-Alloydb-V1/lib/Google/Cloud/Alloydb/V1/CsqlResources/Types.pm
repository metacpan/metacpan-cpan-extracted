package Google::Cloud::Alloydb::V1::CsqlResources::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CloudSQLBackupRunSource',
    as InstanceOf['Google::Cloud::Alloydb::V1::CsqlResources::CloudSQLBackupRunSource'];

coerce 'CloudSQLBackupRunSource',
    from HashRef, via { 'Google::Cloud::Alloydb::V1::CsqlResources::CloudSQLBackupRunSource'->new($_) };

declare 'RepeatedCloudSQLBackupRunSource',
    as ArrayRef[CloudSQLBackupRunSource()];

coerce 'RepeatedCloudSQLBackupRunSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1::CsqlResources::CloudSQLBackupRunSource'->new($_) } @$_ ] };

declare 'MapStringCloudSQLBackupRunSource',
    as HashRef[CloudSQLBackupRunSource()];

1;

__END__

=head1 NAME

Google::Cloud::Alloydb::V1::CsqlResources::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
