package Google::Cloud::Productregistry::V1::LogicalProduct::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LogicalProduct',
    as InstanceOf['Google::Cloud::Productregistry::V1::LogicalProduct::LogicalProduct'];

coerce 'LogicalProduct',
    from HashRef, via { 'Google::Cloud::Productregistry::V1::LogicalProduct::LogicalProduct'->new($_) };

declare 'RepeatedLogicalProduct',
    as ArrayRef[LogicalProduct()];

coerce 'RepeatedLogicalProduct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Productregistry::V1::LogicalProduct::LogicalProduct'->new($_) } @$_ ] };

declare 'MapStringLogicalProduct',
    as HashRef[LogicalProduct()];

1;

__END__

=head1 NAME

Google::Cloud::Productregistry::V1::LogicalProduct::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
