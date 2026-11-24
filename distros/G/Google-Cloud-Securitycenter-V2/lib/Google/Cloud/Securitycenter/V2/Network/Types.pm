package Google::Cloud::Securitycenter::V2::Network::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Network',
    as InstanceOf['Google::Cloud::Securitycenter::V2::Network::Network'];

coerce 'Network',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::Network::Network'->new($_) };

declare 'RepeatedNetwork',
    as ArrayRef[Network()];

coerce 'RepeatedNetwork',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::Network::Network'->new($_) } @$_ ] };

declare 'MapStringNetwork',
    as HashRef[Network()];

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::Network::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
