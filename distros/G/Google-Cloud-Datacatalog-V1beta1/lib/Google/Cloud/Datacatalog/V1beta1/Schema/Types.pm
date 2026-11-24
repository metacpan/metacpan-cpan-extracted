package Google::Cloud::Datacatalog::V1beta1::Schema::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Schema',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Schema::Schema'];

coerce 'Schema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Schema::Schema'->new($_) };

declare 'RepeatedSchema',
    as ArrayRef[Schema()];

coerce 'RepeatedSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Schema::Schema'->new($_) } @$_ ] };

declare 'MapStringSchema',
    as HashRef[Schema()];

declare 'ColumnSchema',
    as InstanceOf['Google::Cloud::Datacatalog::V1beta1::Schema::ColumnSchema'];

coerce 'ColumnSchema',
    from HashRef, via { 'Google::Cloud::Datacatalog::V1beta1::Schema::ColumnSchema'->new($_) };

declare 'RepeatedColumnSchema',
    as ArrayRef[ColumnSchema()];

coerce 'RepeatedColumnSchema',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Datacatalog::V1beta1::Schema::ColumnSchema'->new($_) } @$_ ] };

declare 'MapStringColumnSchema',
    as HashRef[ColumnSchema()];

1;

__END__

=head1 NAME

Google::Cloud::Datacatalog::V1beta1::Schema::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
