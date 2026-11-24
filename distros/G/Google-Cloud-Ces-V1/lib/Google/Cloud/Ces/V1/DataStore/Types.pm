package Google::Cloud::Ces::V1::DataStore::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DataStore',
    as InstanceOf['Google::Cloud::Ces::V1::DataStore::DataStore'];

coerce 'DataStore',
    from HashRef, via { 'Google::Cloud::Ces::V1::DataStore::DataStore'->new($_) };

declare 'RepeatedDataStore',
    as ArrayRef[DataStore()];

coerce 'RepeatedDataStore',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::DataStore::DataStore'->new($_) } @$_ ] };

declare 'MapStringDataStore',
    as HashRef[DataStore()];

declare 'DataStoreType',
    as (Int | Str);

declare 'DocumentProcessingMode',
    as (Int | Str);

declare 'ConnectorConfig',
    as InstanceOf['Google::Cloud::Ces::V1::DataStore::DataStore::ConnectorConfig'];

coerce 'ConnectorConfig',
    from HashRef, via { 'Google::Cloud::Ces::V1::DataStore::DataStore::ConnectorConfig'->new($_) };

declare 'RepeatedConnectorConfig',
    as ArrayRef[ConnectorConfig()];

coerce 'RepeatedConnectorConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Ces::V1::DataStore::DataStore::ConnectorConfig'->new($_) } @$_ ] };

declare 'MapStringConnectorConfig',
    as HashRef[ConnectorConfig()];

1;

__END__

=head1 NAME

Google::Cloud::Ces::V1::DataStore::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
