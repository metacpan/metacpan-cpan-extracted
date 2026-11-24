package Google::Cloud::Databasecenter::V1beta::Product::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Engine',
    as (Int | Str);

declare 'ProductType',
    as (Int | Str);

declare 'Product',
    as InstanceOf['Google::Cloud::Databasecenter::V1beta::Product::Product'];

coerce 'Product',
    from HashRef, via { 'Google::Cloud::Databasecenter::V1beta::Product::Product'->new($_) };

declare 'RepeatedProduct',
    as ArrayRef[Product()];

coerce 'RepeatedProduct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Databasecenter::V1beta::Product::Product'->new($_) } @$_ ] };

declare 'MapStringProduct',
    as HashRef[Product()];

1;

__END__

=head1 NAME

Google::Cloud::Databasecenter::V1beta::Product::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
