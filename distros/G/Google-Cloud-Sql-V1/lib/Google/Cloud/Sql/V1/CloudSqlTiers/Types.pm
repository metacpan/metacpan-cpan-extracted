package Google::Cloud::Sql::V1::CloudSqlTiers::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlTiersListRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlTiers::SqlTiersListRequest'];

coerce 'SqlTiersListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlTiers::SqlTiersListRequest'->new($_) };

declare 'RepeatedSqlTiersListRequest',
    as ArrayRef[SqlTiersListRequest()];

coerce 'RepeatedSqlTiersListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlTiers::SqlTiersListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlTiersListRequest',
    as HashRef[SqlTiersListRequest()];

declare 'TiersListResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlTiers::TiersListResponse'];

coerce 'TiersListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlTiers::TiersListResponse'->new($_) };

declare 'RepeatedTiersListResponse',
    as ArrayRef[TiersListResponse()];

coerce 'RepeatedTiersListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlTiers::TiersListResponse'->new($_) } @$_ ] };

declare 'MapStringTiersListResponse',
    as HashRef[TiersListResponse()];

declare 'Tier',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlTiers::Tier'];

coerce 'Tier',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlTiers::Tier'->new($_) };

declare 'RepeatedTier',
    as ArrayRef[Tier()];

coerce 'RepeatedTier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlTiers::Tier'->new($_) } @$_ ] };

declare 'MapStringTier',
    as HashRef[Tier()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlTiers::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
