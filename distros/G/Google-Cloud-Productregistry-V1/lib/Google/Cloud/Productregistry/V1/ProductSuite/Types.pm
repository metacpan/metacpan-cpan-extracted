package Google::Cloud::Productregistry::V1::ProductSuite::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ProductSuite',
    as InstanceOf['Google::Cloud::Productregistry::V1::ProductSuite::ProductSuite'];

coerce 'ProductSuite',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::ProductSuite::ProductSuite'->new($_) };

declare 'RepeatedProductSuite',
    as ArrayRef[ProductSuite()];

coerce 'RepeatedProductSuite',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::ProductSuite::ProductSuite'->new($_) } @$_ ] };

declare 'MapStringProductSuite',
    as HashRef[ProductSuite()];

1;

__END__

=head1 NAME

Google::Cloud::Productregistry::V1::ProductSuite::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
