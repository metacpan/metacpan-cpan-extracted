package Google::Cloud::Datacatalog::V1::TableSpec::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'TableSourceType',
    as (Int | Str);

declare 'BigQueryTableSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::TableSpec::BigQueryTableSpec'];

coerce 'BigQueryTableSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::TableSpec::BigQueryTableSpec'->new($_) };

declare 'RepeatedBigQueryTableSpec',
    as ArrayRef[BigQueryTableSpec()];

coerce 'RepeatedBigQueryTableSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::TableSpec::BigQueryTableSpec'->new($_) } @$_ ] };

declare 'MapStringBigQueryTableSpec',
    as HashRef[BigQueryTableSpec()];

declare 'ViewSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::TableSpec::ViewSpec'];

coerce 'ViewSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::TableSpec::ViewSpec'->new($_) };

declare 'RepeatedViewSpec',
    as ArrayRef[ViewSpec()];

coerce 'RepeatedViewSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::TableSpec::ViewSpec'->new($_) } @$_ ] };

declare 'MapStringViewSpec',
    as HashRef[ViewSpec()];

declare 'TableSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::TableSpec::TableSpec'];

coerce 'TableSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::TableSpec::TableSpec'->new($_) };

declare 'RepeatedTableSpec',
    as ArrayRef[TableSpec()];

coerce 'RepeatedTableSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::TableSpec::TableSpec'->new($_) } @$_ ] };

declare 'MapStringTableSpec',
    as HashRef[TableSpec()];

declare 'BigQueryDateShardedSpec',
    as InstanceOf['Google::Cloud::Datacatalog::V1::TableSpec::BigQueryDateShardedSpec'];

coerce 'BigQueryDateShardedSpec',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::TableSpec::BigQueryDateShardedSpec'->new($_) };

declare 'RepeatedBigQueryDateShardedSpec',
    as ArrayRef[BigQueryDateShardedSpec()];

coerce 'RepeatedBigQueryDateShardedSpec',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::TableSpec::BigQueryDateShardedSpec'->new($_) } @$_ ] };

declare 'MapStringBigQueryDateShardedSpec',
    as HashRef[BigQueryDateShardedSpec()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::TableSpec::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
