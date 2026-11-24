package Google::Cloud::Productregistry::V1::LogicalProductVariant::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LogicalProductVariant',
    as InstanceOf['Google::Cloud::Productregistry::V1::LogicalProductVariant::LogicalProductVariant'];

coerce 'LogicalProductVariant',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::LogicalProductVariant::LogicalProductVariant'->new($_) };

declare 'RepeatedLogicalProductVariant',
    as ArrayRef[LogicalProductVariant()];

coerce 'RepeatedLogicalProductVariant',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::LogicalProductVariant::LogicalProductVariant'->new($_) } @$_ ] };

declare 'MapStringLogicalProductVariant',
    as HashRef[LogicalProductVariant()];

1;

__END__

=head1 NAME

Google::Cloud::Productregistry::V1::LogicalProductVariant::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
