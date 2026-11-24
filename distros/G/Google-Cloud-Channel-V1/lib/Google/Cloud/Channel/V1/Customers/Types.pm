package Google::Cloud::Channel::V1::Customers::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Customer',
    as InstanceOf['Google::Cloud::Channel::V1::Customers::Customer'];

coerce 'Customer',
    from HashRef, via { 'Google::Cloud::Channel::V1::Customers::Customer'->new($_) };

declare 'RepeatedCustomer',
    as ArrayRef[Customer()];

coerce 'RepeatedCustomer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Customers::Customer'->new($_) } @$_ ] };

declare 'MapStringCustomer',
    as HashRef[Customer()];

declare 'CustomerAttestationState',
    as (Int | Str);

declare 'ContactInfo',
    as InstanceOf['Google::Cloud::Channel::V1::Customers::ContactInfo'];

coerce 'ContactInfo',
    from HashRef, via { 'Google::Cloud::Channel::V1::Customers::ContactInfo'->new($_) };

declare 'RepeatedContactInfo',
    as ArrayRef[ContactInfo()];

coerce 'RepeatedContactInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Customers::ContactInfo'->new($_) } @$_ ] };

declare 'MapStringContactInfo',
    as HashRef[ContactInfo()];

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::Customers::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
