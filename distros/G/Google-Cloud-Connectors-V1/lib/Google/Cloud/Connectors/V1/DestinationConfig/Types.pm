package Google::Cloud::Connectors::V1::DestinationConfig::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'DestinationConfig',
    as InstanceOf['Google::Cloud::Connectors::V1::DestinationConfig::DestinationConfig'];

coerce 'DestinationConfig',
    from HashRef, via { 'Google::Cloud::Connectors::V1::DestinationConfig::DestinationConfig'->new($_) };

declare 'RepeatedDestinationConfig',
    as ArrayRef[DestinationConfig()];

coerce 'RepeatedDestinationConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::DestinationConfig::DestinationConfig'->new($_) } @$_ ] };

declare 'MapStringDestinationConfig',
    as HashRef[DestinationConfig()];

declare 'Destination',
    as InstanceOf['Google::Cloud::Connectors::V1::DestinationConfig::Destination'];

coerce 'Destination',
    from HashRef, via { 'Google::Cloud::Connectors::V1::DestinationConfig::Destination'->new($_) };

declare 'RepeatedDestination',
    as ArrayRef[Destination()];

coerce 'RepeatedDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Connectors::V1::DestinationConfig::Destination'->new($_) } @$_ ] };

declare 'MapStringDestination',
    as HashRef[Destination()];

1;

__END__

=head1 NAME

Google::Cloud::Connectors::V1::DestinationConfig::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
