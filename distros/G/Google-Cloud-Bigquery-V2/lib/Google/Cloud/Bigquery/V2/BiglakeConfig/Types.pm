package Google::Cloud::Bigquery::V2::BiglakeConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BigLakeConfiguration',
    as InstanceOf['Google::Cloud::Bigquery::V2::BiglakeConfig::BigLakeConfiguration'];

coerce 'BigLakeConfiguration',
    from HashRef, via { 'Google::Cloud::Bigquery::V2::BiglakeConfig::BigLakeConfiguration'->new($_) };

declare 'RepeatedBigLakeConfiguration',
    as ArrayRef[BigLakeConfiguration()];

coerce 'RepeatedBigLakeConfiguration',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::V2::BiglakeConfig::BigLakeConfiguration'->new($_) } @$_ ] };

declare 'MapStringBigLakeConfiguration',
    as HashRef[BigLakeConfiguration()];

declare 'FileFormat',
    as (Int | Str);

declare 'TableFormat',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::V2::BiglakeConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
