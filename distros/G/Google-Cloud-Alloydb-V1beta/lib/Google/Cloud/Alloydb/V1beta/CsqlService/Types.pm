package Google::Cloud::Alloydb::V1beta::CsqlService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RestoreFromCloudSQLRequest',
    as InstanceOf['Google::Cloud::Alloydb::V1beta::CsqlService::RestoreFromCloudSQLRequest'];

coerce 'RestoreFromCloudSQLRequest',
    from HashRef, via { 'Google::Cloud::Alloydb::V1beta::CsqlService::RestoreFromCloudSQLRequest'->new($_) };

declare 'RepeatedRestoreFromCloudSQLRequest',
    as ArrayRef[RestoreFromCloudSQLRequest()];

coerce 'RepeatedRestoreFromCloudSQLRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Alloydb::V1beta::CsqlService::RestoreFromCloudSQLRequest'->new($_) } @$_ ] };

declare 'MapStringRestoreFromCloudSQLRequest',
    as HashRef[RestoreFromCloudSQLRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Alloydb::V1beta::CsqlService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
