package Google::Cloud::Bigquery::V2::DatasetReference::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DatasetReference',
    as InstanceOf['Google::Cloud::Bigquery::V2::DatasetReference::DatasetReference'];

coerce 'DatasetReference',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::DatasetReference::DatasetReference'->new($_) };

declare 'RepeatedDatasetReference',
    as ArrayRef[DatasetReference()];

coerce 'RepeatedDatasetReference',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::DatasetReference::DatasetReference'->new($_) } @$_ ] };

declare 'MapStringDatasetReference',
    as HashRef[DatasetReference()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::DatasetReference::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
