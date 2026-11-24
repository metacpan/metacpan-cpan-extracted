package Google::Cloud::Capacityplanner::V1beta::Location::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'LocationLevel',
    as (Int | Str);

declare 'LocationIdentifier',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier'];

coerce 'LocationIdentifier',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier'->new($_) };

declare 'RepeatedLocationIdentifier',
    as ArrayRef[LocationIdentifier()];

coerce 'RepeatedLocationIdentifier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier'->new($_) } @$_ ] };

declare 'MapStringLocationIdentifier',
    as HashRef[LocationIdentifier()];

declare 'LinkedLocation',
    as InstanceOf['Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier::LinkedLocation'];

coerce 'LinkedLocation',
    from HashRef, via { 'Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier::LinkedLocation'->new($_) };

declare 'RepeatedLinkedLocation',
    as ArrayRef[LinkedLocation()];

coerce 'RepeatedLinkedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Capacityplanner::V1beta::Location::LocationIdentifier::LinkedLocation'->new($_) } @$_ ] };

declare 'MapStringLinkedLocation',
    as HashRef[LinkedLocation()];

1;

__END__

=head1 NAME

Google::Cloud::Capacityplanner::V1beta::Location::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
