package Google::Cloud::Integrations::V1alpha::Coordinate::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Coordinate',
    as InstanceOf['Google::Cloud::Integrations::V1alpha::Coordinate::Coordinate'];

coerce 'Coordinate',
    from HashRef, via { 'Google::Cloud::Integrations::V1alpha::Coordinate::Coordinate'->new($_) };

declare 'RepeatedCoordinate',
    as ArrayRef[Coordinate()];

coerce 'RepeatedCoordinate',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Integrations::V1alpha::Coordinate::Coordinate'->new($_) } @$_ ] };

declare 'MapStringCoordinate',
    as HashRef[Coordinate()];

1;

__END__

=head1 NAME

Google::Cloud::Integrations::V1alpha::Coordinate::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
