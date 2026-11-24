package Google::Cloud::Channel::V1::Offers::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PromotionalOrderType',
    as (Int | Str);

declare 'PaymentPlan',
    as (Int | Str);

declare 'PaymentType',
    as (Int | Str);

declare 'ResourceType',
    as (Int | Str);

declare 'PeriodType',
    as (Int | Str);

declare 'DiscountType',
    as (Int | Str);

declare 'Offer',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::Offer'];

coerce 'Offer',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::Offer'->new($_) };

declare 'RepeatedOffer',
    as ArrayRef[Offer()];

coerce 'RepeatedOffer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::Offer'->new($_) } @$_ ] };

declare 'MapStringOffer',
    as HashRef[Offer()];

declare 'ParameterDefinition',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::ParameterDefinition'];

coerce 'ParameterDefinition',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::ParameterDefinition'->new($_) };

declare 'RepeatedParameterDefinition',
    as ArrayRef[ParameterDefinition()];

coerce 'RepeatedParameterDefinition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::ParameterDefinition'->new($_) } @$_ ] };

declare 'MapStringParameterDefinition',
    as HashRef[ParameterDefinition()];

declare 'ParameterType',
    as (Int | Str);

declare 'Constraints',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::Constraints'];

coerce 'Constraints',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::Constraints'->new($_) };

declare 'RepeatedConstraints',
    as ArrayRef[Constraints()];

coerce 'RepeatedConstraints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::Constraints'->new($_) } @$_ ] };

declare 'MapStringConstraints',
    as HashRef[Constraints()];

declare 'CustomerConstraints',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::CustomerConstraints'];

coerce 'CustomerConstraints',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::CustomerConstraints'->new($_) };

declare 'RepeatedCustomerConstraints',
    as ArrayRef[CustomerConstraints()];

coerce 'RepeatedCustomerConstraints',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::CustomerConstraints'->new($_) } @$_ ] };

declare 'MapStringCustomerConstraints',
    as HashRef[CustomerConstraints()];

declare 'Plan',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::Plan'];

coerce 'Plan',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::Plan'->new($_) };

declare 'RepeatedPlan',
    as ArrayRef[Plan()];

coerce 'RepeatedPlan',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::Plan'->new($_) } @$_ ] };

declare 'MapStringPlan',
    as HashRef[Plan()];

declare 'PriceByResource',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::PriceByResource'];

coerce 'PriceByResource',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::PriceByResource'->new($_) };

declare 'RepeatedPriceByResource',
    as ArrayRef[PriceByResource()];

coerce 'RepeatedPriceByResource',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::PriceByResource'->new($_) } @$_ ] };

declare 'MapStringPriceByResource',
    as HashRef[PriceByResource()];

declare 'Price',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::Price'];

coerce 'Price',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::Price'->new($_) };

declare 'RepeatedPrice',
    as ArrayRef[Price()];

coerce 'RepeatedPrice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::Price'->new($_) } @$_ ] };

declare 'MapStringPrice',
    as HashRef[Price()];

declare 'PricePhase',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::PricePhase'];

coerce 'PricePhase',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::PricePhase'->new($_) };

declare 'RepeatedPricePhase',
    as ArrayRef[PricePhase()];

coerce 'RepeatedPricePhase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::PricePhase'->new($_) } @$_ ] };

declare 'MapStringPricePhase',
    as HashRef[PricePhase()];

declare 'PriceTier',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::PriceTier'];

coerce 'PriceTier',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::PriceTier'->new($_) };

declare 'RepeatedPriceTier',
    as ArrayRef[PriceTier()];

coerce 'RepeatedPriceTier',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::PriceTier'->new($_) } @$_ ] };

declare 'MapStringPriceTier',
    as HashRef[PriceTier()];

declare 'Period',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::Period'];

coerce 'Period',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::Period'->new($_) };

declare 'RepeatedPeriod',
    as ArrayRef[Period()];

coerce 'RepeatedPeriod',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::Period'->new($_) } @$_ ] };

declare 'MapStringPeriod',
    as HashRef[Period()];

declare 'DiscountComponent',
    as InstanceOf['Google::Cloud::Channel::V1::Offers::DiscountComponent'];

coerce 'DiscountComponent',
    from HashRef, via { 'Google::Cloud::Channel::V1::Offers::DiscountComponent'->new($_) };

declare 'RepeatedDiscountComponent',
    as ArrayRef[DiscountComponent()];

coerce 'RepeatedDiscountComponent',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Offers::DiscountComponent'->new($_) } @$_ ] };

declare 'MapStringDiscountComponent',
    as HashRef[DiscountComponent()];

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::Offers::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
