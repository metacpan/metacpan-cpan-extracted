package Google::Cloud::Sql::V1::CloudSqlSslCerts::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SqlSslCertsDeleteRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest'];

coerce 'SqlSslCertsDeleteRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest'->new($_) };

declare 'RepeatedSqlSslCertsDeleteRequest',
    as ArrayRef[SqlSslCertsDeleteRequest()];

coerce 'RepeatedSqlSslCertsDeleteRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsDeleteRequest'->new($_) } @$_ ] };

declare 'MapStringSqlSslCertsDeleteRequest',
    as HashRef[SqlSslCertsDeleteRequest()];

declare 'SqlSslCertsGetRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest'];

coerce 'SqlSslCertsGetRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest'->new($_) };

declare 'RepeatedSqlSslCertsGetRequest',
    as ArrayRef[SqlSslCertsGetRequest()];

coerce 'RepeatedSqlSslCertsGetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsGetRequest'->new($_) } @$_ ] };

declare 'MapStringSqlSslCertsGetRequest',
    as HashRef[SqlSslCertsGetRequest()];

declare 'SqlSslCertsInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest'];

coerce 'SqlSslCertsInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest'->new($_) };

declare 'RepeatedSqlSslCertsInsertRequest',
    as ArrayRef[SqlSslCertsInsertRequest()];

coerce 'RepeatedSqlSslCertsInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSqlSslCertsInsertRequest',
    as HashRef[SqlSslCertsInsertRequest()];

declare 'SqlSslCertsListRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest'];

coerce 'SqlSslCertsListRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest'->new($_) };

declare 'RepeatedSqlSslCertsListRequest',
    as ArrayRef[SqlSslCertsListRequest()];

coerce 'RepeatedSqlSslCertsListRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SqlSslCertsListRequest'->new($_) } @$_ ] };

declare 'MapStringSqlSslCertsListRequest',
    as HashRef[SqlSslCertsListRequest()];

declare 'SslCertsInsertRequest',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertRequest'];

coerce 'SslCertsInsertRequest',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertRequest'->new($_) };

declare 'RepeatedSslCertsInsertRequest',
    as ArrayRef[SslCertsInsertRequest()];

coerce 'RepeatedSslCertsInsertRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertRequest'->new($_) } @$_ ] };

declare 'MapStringSslCertsInsertRequest',
    as HashRef[SslCertsInsertRequest()];

declare 'SslCertsInsertResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse'];

coerce 'SslCertsInsertResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse'->new($_) };

declare 'RepeatedSslCertsInsertResponse',
    as ArrayRef[SslCertsInsertResponse()];

coerce 'RepeatedSslCertsInsertResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsInsertResponse'->new($_) } @$_ ] };

declare 'MapStringSslCertsInsertResponse',
    as HashRef[SslCertsInsertResponse()];

declare 'SslCertsListResponse',
    as InstanceOf['Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse'];

coerce 'SslCertsListResponse',
    from HashRef, via { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse'->new($_) };

declare 'RepeatedSslCertsListResponse',
    as ArrayRef[SslCertsListResponse()];

coerce 'RepeatedSslCertsListResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Sql::V1::CloudSqlSslCerts::SslCertsListResponse'->new($_) } @$_ ] };

declare 'MapStringSslCertsListResponse',
    as HashRef[SslCertsListResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlSslCerts::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
