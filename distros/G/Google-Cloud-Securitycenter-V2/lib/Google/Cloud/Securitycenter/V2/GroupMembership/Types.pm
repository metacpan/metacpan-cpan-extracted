package Google::Cloud::Securitycenter::V2::GroupMembership::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'GroupMembership',
    as InstanceOf['Google::Cloud::Securitycenter::V2::GroupMembership::GroupMembership'];

coerce 'GroupMembership',
    from HashRef, via { 'Google::Cloud::Securitycenter::V2::GroupMembership::GroupMembership'->new($_) };

declare 'RepeatedGroupMembership',
    as ArrayRef[GroupMembership()];

coerce 'RepeatedGroupMembership',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Securitycenter::V2::GroupMembership::GroupMembership'->new($_) } @$_ ] };

declare 'MapStringGroupMembership',
    as HashRef[GroupMembership()];

declare 'GroupType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Securitycenter::V2::GroupMembership::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
