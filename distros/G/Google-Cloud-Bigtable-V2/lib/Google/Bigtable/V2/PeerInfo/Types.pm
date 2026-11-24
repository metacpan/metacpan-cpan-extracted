package Google::Bigtable::V2::PeerInfo::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PeerInfo',
    as InstanceOf['Google::Bigtable::V2::PeerInfo::PeerInfo'];

coerce 'PeerInfo',
    from HashRef, via { 'Google::Bigtable::V2::PeerInfo::PeerInfo'->new($_) };

declare 'RepeatedPeerInfo',
    as ArrayRef[PeerInfo()];

coerce 'RepeatedPeerInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Bigtable::V2::PeerInfo::PeerInfo'->new($_) } @$_ ] };

declare 'MapStringPeerInfo',
    as HashRef[PeerInfo()];

declare 'TransportType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Bigtable::V2::PeerInfo::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
