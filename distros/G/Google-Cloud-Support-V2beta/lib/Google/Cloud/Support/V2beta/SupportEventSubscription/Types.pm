package Google::Cloud::Support::V2beta::SupportEventSubscription::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SupportEventSubscription',
    as InstanceOf['Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription'];

coerce 'SupportEventSubscription',
    from HashRef, via { 'Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription'->new($_) };

declare 'RepeatedSupportEventSubscription',
    as ArrayRef[SupportEventSubscription()];

coerce 'RepeatedSupportEventSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription'->new($_) } @$_ ] };

declare 'MapStringSupportEventSubscription',
    as HashRef[SupportEventSubscription()];

declare 'State',
    as (Int | Str);

declare 'FailureReason',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Support::V2beta::SupportEventSubscription::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
