package Google::Cloud::Cloudcontrolspartner::V1::Customers::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Customer',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer'];

coerce 'Customer',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer'->new($_) };

declare 'RepeatedCustomer',
    as ArrayRef[Customer()];

coerce 'RepeatedCustomer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::Customer'->new($_) } @$_ ] };

declare 'MapStringCustomer',
    as HashRef[Customer()];

declare 'ListCustomersRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersRequest'];

coerce 'ListCustomersRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersRequest'->new($_) };

declare 'RepeatedListCustomersRequest',
    as ArrayRef[ListCustomersRequest()];

coerce 'RepeatedListCustomersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersRequest'->new($_) } @$_ ] };

declare 'MapStringListCustomersRequest',
    as HashRef[ListCustomersRequest()];

declare 'ListCustomersResponse',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersResponse'];

coerce 'ListCustomersResponse',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersResponse'->new($_) };

declare 'RepeatedListCustomersResponse',
    as ArrayRef[ListCustomersResponse()];

coerce 'RepeatedListCustomersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::ListCustomersResponse'->new($_) } @$_ ] };

declare 'MapStringListCustomersResponse',
    as HashRef[ListCustomersResponse()];

declare 'CreateCustomerRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Customers::CreateCustomerRequest'];

coerce 'CreateCustomerRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::CreateCustomerRequest'->new($_) };

declare 'RepeatedCreateCustomerRequest',
    as ArrayRef[CreateCustomerRequest()];

coerce 'RepeatedCreateCustomerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::CreateCustomerRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCustomerRequest',
    as HashRef[CreateCustomerRequest()];

declare 'GetCustomerRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Customers::GetCustomerRequest'];

coerce 'GetCustomerRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::GetCustomerRequest'->new($_) };

declare 'RepeatedGetCustomerRequest',
    as ArrayRef[GetCustomerRequest()];

coerce 'RepeatedGetCustomerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::GetCustomerRequest'->new($_) } @$_ ] };

declare 'MapStringGetCustomerRequest',
    as HashRef[GetCustomerRequest()];

declare 'CustomerOnboardingState',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingState'];

coerce 'CustomerOnboardingState',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingState'->new($_) };

declare 'RepeatedCustomerOnboardingState',
    as ArrayRef[CustomerOnboardingState()];

coerce 'RepeatedCustomerOnboardingState',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingState'->new($_) } @$_ ] };

declare 'MapStringCustomerOnboardingState',
    as HashRef[CustomerOnboardingState()];

declare 'CustomerOnboardingStep',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingStep'];

coerce 'CustomerOnboardingStep',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingStep'->new($_) };

declare 'RepeatedCustomerOnboardingStep',
    as ArrayRef[CustomerOnboardingStep()];

coerce 'RepeatedCustomerOnboardingStep',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::CustomerOnboardingStep'->new($_) } @$_ ] };

declare 'MapStringCustomerOnboardingStep',
    as HashRef[CustomerOnboardingStep()];

declare 'Step',
    as (Int | Str);

declare 'UpdateCustomerRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Customers::UpdateCustomerRequest'];

coerce 'UpdateCustomerRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::UpdateCustomerRequest'->new($_) };

declare 'RepeatedUpdateCustomerRequest',
    as ArrayRef[UpdateCustomerRequest()];

coerce 'RepeatedUpdateCustomerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::UpdateCustomerRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCustomerRequest',
    as HashRef[UpdateCustomerRequest()];

declare 'DeleteCustomerRequest',
    as InstanceOf['Google::Cloud::Cloudcontrolspartner::V1::Customers::DeleteCustomerRequest'];

coerce 'DeleteCustomerRequest',
    from HashRef, via { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::DeleteCustomerRequest'->new($_) };

declare 'RepeatedDeleteCustomerRequest',
    as ArrayRef[DeleteCustomerRequest()];

coerce 'RepeatedDeleteCustomerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Cloudcontrolspartner::V1::Customers::DeleteCustomerRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCustomerRequest',
    as HashRef[DeleteCustomerRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Cloudcontrolspartner::V1::Customers::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
