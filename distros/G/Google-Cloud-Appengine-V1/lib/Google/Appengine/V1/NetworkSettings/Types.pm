package Google::Appengine::V1::NetworkSettings::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'NetworkSettings',
    as InstanceOf['Google::Appengine::V1::NetworkSettings::NetworkSettings'];

coerce 'NetworkSettings',
    from HashRef, via { 'Google::Appengine::V1::NetworkSettings::NetworkSettings'->new($_) };

declare 'RepeatedNetworkSettings',
    as ArrayRef[NetworkSettings()];

coerce 'RepeatedNetworkSettings',
    from ArrayRef[HashRef], via { [ map { 'Google::Appengine::V1::NetworkSettings::NetworkSettings'->new($_) } @$_ ] };

declare 'MapStringNetworkSettings',
    as HashRef[NetworkSettings()];

declare 'IngressTrafficAllowed',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Appengine::V1::NetworkSettings::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
