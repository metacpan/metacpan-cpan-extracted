package Google::Cloud::Channel::V1::BillingAccounts::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'BillingAccount',
    as InstanceOf['Google::Cloud::Channel::V1::BillingAccounts::BillingAccount'];

coerce 'BillingAccount',
    from HashRef, via { 'Google::Cloud::Channel::V1::BillingAccounts::BillingAccount'->new($_) };

declare 'RepeatedBillingAccount',
    as ArrayRef[BillingAccount()];

coerce 'RepeatedBillingAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::BillingAccounts::BillingAccount'->new($_) } @$_ ] };

declare 'MapStringBillingAccount',
    as HashRef[BillingAccount()];

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::BillingAccounts::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
