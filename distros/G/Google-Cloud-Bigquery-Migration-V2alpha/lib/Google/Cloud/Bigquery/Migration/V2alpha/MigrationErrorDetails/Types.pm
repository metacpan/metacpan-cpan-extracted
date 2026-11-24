package Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ResourceErrorDetail',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ResourceErrorDetail'];

coerce 'ResourceErrorDetail',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ResourceErrorDetail'->new($_) };

declare 'RepeatedResourceErrorDetail',
    as ArrayRef[ResourceErrorDetail()];

coerce 'RepeatedResourceErrorDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ResourceErrorDetail'->new($_) } @$_ ] };

declare 'MapStringResourceErrorDetail',
    as HashRef[ResourceErrorDetail()];

declare 'ErrorDetail',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorDetail'];

coerce 'ErrorDetail',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorDetail'->new($_) };

declare 'RepeatedErrorDetail',
    as ArrayRef[ErrorDetail()];

coerce 'RepeatedErrorDetail',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorDetail'->new($_) } @$_ ] };

declare 'MapStringErrorDetail',
    as HashRef[ErrorDetail()];

declare 'ErrorLocation',
    as InstanceOf['Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorLocation'];

coerce 'ErrorLocation',
    from HashRef, via { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorLocation'->new($_) };

declare 'RepeatedErrorLocation',
    as ArrayRef[ErrorLocation()];

coerce 'RepeatedErrorLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::ErrorLocation'->new($_) } @$_ ] };

declare 'MapStringErrorLocation',
    as HashRef[ErrorLocation()];

1;

__END__

=head1 NAME

Google::Cloud::Bigquery::Migration::V2alpha::MigrationErrorDetails::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
