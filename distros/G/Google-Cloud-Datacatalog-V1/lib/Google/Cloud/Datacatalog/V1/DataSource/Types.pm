package Google::Cloud::Datacatalog::V1::DataSource::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataSource',
    as InstanceOf['Google::Cloud::Datacatalog::V1::DataSource::DataSource'];

coerce 'DataSource',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::DataSource::DataSource'->new($_) };

declare 'RepeatedDataSource',
    as ArrayRef[DataSource()];

coerce 'RepeatedDataSource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::DataSource::DataSource'->new($_) } @$_ ] };

declare 'MapStringDataSource',
    as HashRef[DataSource()];

declare 'Service',
    as (Int | Str);

declare 'StorageProperties',
    as InstanceOf['Google::Cloud::Datacatalog::V1::DataSource::StorageProperties'];

coerce 'StorageProperties',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1::DataSource::StorageProperties'->new($_) };

declare 'RepeatedStorageProperties',
    as ArrayRef[StorageProperties()];

coerce 'RepeatedStorageProperties',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1::DataSource::StorageProperties'->new($_) } @$_ ] };

declare 'MapStringStorageProperties',
    as HashRef[StorageProperties()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1::DataSource::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
