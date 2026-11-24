package Google::Cloud::Gkehub::Metering::V1beta::Metering::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MembershipState',
    as InstanceOf['Google::Cloud::Gkehub::Metering::V1beta::Metering::MembershipState'];

coerce 'MembershipState',
    from HashRef, via { 'Google::Cloud::Gkehub::Metering::V1beta::Metering::MembershipState'->new($_) };

declare 'RepeatedMembershipState',
    as ArrayRef[MembershipState()];

coerce 'RepeatedMembershipState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Gkehub::Metering::V1beta::Metering::MembershipState'->new($_) } @$_ ] };

declare 'MapStringMembershipState',
    as HashRef[MembershipState()];

1;

__END__

=head1 NAME

Google::Cloud::Gkehub::Metering::V1beta::Metering::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
