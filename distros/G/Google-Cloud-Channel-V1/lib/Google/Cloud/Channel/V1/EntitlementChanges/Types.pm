package Google::Cloud::Channel::V1::EntitlementChanges::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'EntitlementChange',
    as InstanceOf['Google::Cloud::Channel::V1::EntitlementChanges::EntitlementChange'];

coerce 'EntitlementChange',
    from HashRef, via { 'Google::Cloud::Channel::V1::EntitlementChanges::EntitlementChange'->new($_) };

declare 'RepeatedEntitlementChange',
    as ArrayRef[EntitlementChange()];

coerce 'RepeatedEntitlementChange',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::EntitlementChanges::EntitlementChange'->new($_) } @$_ ] };

declare 'MapStringEntitlementChange',
    as HashRef[EntitlementChange()];

declare 'ChangeType',
    as (Int | Str);

declare 'OperatorType',
    as (Int | Str);

declare 'CancellationReason',
    as (Int | Str);

declare 'ActivationReason',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::EntitlementChanges::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
