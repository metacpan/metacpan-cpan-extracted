package Google::Api::Billing::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Billing',
    as InstanceOf['Google::Api::Billing::Billing'];

coerce 'Billing',
    from HashRef, via { 'Google::Api::Billing::Billing'->new($_) };

declare 'RepeatedBilling',
    as ArrayRef[Billing()];

coerce 'RepeatedBilling',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Billing::Billing'->new($_) } @$_ ] };

declare 'MapStringBilling',
    as HashRef[Billing()];

declare 'BillingDestination',
    as InstanceOf['Google::Api::Billing::Billing::BillingDestination'];

coerce 'BillingDestination',
    from HashRef, via { 'Google::Api::Billing::Billing::BillingDestination'->new($_) };

declare 'RepeatedBillingDestination',
    as ArrayRef[BillingDestination()];

coerce 'RepeatedBillingDestination',
    from ArrayRef[HashRef], via { [ map { 'Google::Api::Billing::Billing::BillingDestination'->new($_) } @$_ ] };

declare 'MapStringBillingDestination',
    as HashRef[BillingDestination()];

1;

__END__

=head1 NAME

Google::Api::Billing::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
