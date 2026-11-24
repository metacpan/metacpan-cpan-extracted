package Google::Cloud::Datacatalog::V1::Bigquery::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BigQueryConnectionSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Bigquery::BigQueryConnectionSpec'];

coerce 'BigQueryConnectionSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Bigquery::BigQueryConnectionSpec'->new($_) };

declare 'RepeatedBigQueryConnectionSpec',
    as ArrayRef[BigQueryConnectionSpec()];

coerce 'RepeatedBigQueryConnectionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Bigquery::BigQueryConnectionSpec'->new($_) } @$_ ] };

declare 'MapStringBigQueryConnectionSpec',
    as HashRef[BigQueryConnectionSpec()];

declare 'ConnectionType',
    as (Int | Str);

declare 'CloudSqlBigQueryConnectionSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Bigquery::CloudSqlBigQueryConnectionSpec'];

coerce 'CloudSqlBigQueryConnectionSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Bigquery::CloudSqlBigQueryConnectionSpec'->new($_) };

declare 'RepeatedCloudSqlBigQueryConnectionSpec',
    as ArrayRef[CloudSqlBigQueryConnectionSpec()];

coerce 'RepeatedCloudSqlBigQueryConnectionSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Bigquery::CloudSqlBigQueryConnectionSpec'->new($_) } @$_ ] };

declare 'MapStringCloudSqlBigQueryConnectionSpec',
    as HashRef[CloudSqlBigQueryConnectionSpec()];

declare 'DatabaseType',
    as (Int | Str);

declare 'BigQueryRoutineSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::Bigquery::BigQueryRoutineSpec'];

coerce 'BigQueryRoutineSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::Bigquery::BigQueryRoutineSpec'->new($_) };

declare 'RepeatedBigQueryRoutineSpec',
    as ArrayRef[BigQueryRoutineSpec()];

coerce 'RepeatedBigQueryRoutineSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::Bigquery::BigQueryRoutineSpec'->new($_) } @$_ ] };

declare 'MapStringBigQueryRoutineSpec',
    as HashRef[BigQueryRoutineSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::Bigquery::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
