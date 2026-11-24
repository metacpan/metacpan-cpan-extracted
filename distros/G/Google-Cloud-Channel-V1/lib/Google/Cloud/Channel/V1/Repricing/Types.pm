package Google::Cloud::Channel::V1::Repricing::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'RebillingBasis',
    as (Int | Str);

declare 'CustomerRepricingConfig',
    as InstanceOf['Google::Cloud::Channel::V1::Repricing::CustomerRepricingConfig'];

coerce 'CustomerRepricingConfig',
    from HashRef, via { 'Google::Cloud::Channel::V1::Repricing::CustomerRepricingConfig'->new($_) };

declare 'RepeatedCustomerRepricingConfig',
    as ArrayRef[CustomerRepricingConfig()];

coerce 'RepeatedCustomerRepricingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Repricing::CustomerRepricingConfig'->new($_) } @$_ ] };

declare 'MapStringCustomerRepricingConfig',
    as HashRef[CustomerRepricingConfig()];

declare 'ChannelPartnerRepricingConfig',
    as InstanceOf['Google::Cloud::Channel::V1::Repricing::ChannelPartnerRepricingConfig'];

coerce 'ChannelPartnerRepricingConfig',
    from HashRef, via { 'Google::Cloud::Channel::V1::Repricing::ChannelPartnerRepricingConfig'->new($_) };

declare 'RepeatedChannelPartnerRepricingConfig',
    as ArrayRef[ChannelPartnerRepricingConfig()];

coerce 'RepeatedChannelPartnerRepricingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Repricing::ChannelPartnerRepricingConfig'->new($_) } @$_ ] };

declare 'MapStringChannelPartnerRepricingConfig',
    as HashRef[ChannelPartnerRepricingConfig()];

declare 'RepricingConfig',
    as InstanceOf['Google::Cloud::Channel::V1::Repricing::RepricingConfig'];

coerce 'RepricingConfig',
    from HashRef, via { 'Google::Cloud::Channel::V1::Repricing::RepricingConfig'->new($_) };

declare 'RepeatedRepricingConfig',
    as ArrayRef[RepricingConfig()];

coerce 'RepeatedRepricingConfig',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Repricing::RepricingConfig'->new($_) } @$_ ] };

declare 'MapStringRepricingConfig',
    as HashRef[RepricingConfig()];

declare 'EntitlementGranularity',
    as InstanceOf['Google::Cloud::Channel::V1::Repricing::RepricingConfig::EntitlementGranularity'];

coerce 'EntitlementGranularity',
    from HashRef, via { 'Google::Cloud::Channel::V1::Repricing::RepricingConfig::EntitlementGranularity'->new($_) };

declare 'RepeatedEntitlementGranularity',
    as ArrayRef[EntitlementGranularity()];

coerce 'RepeatedEntitlementGranularity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Repricing::RepricingConfig::EntitlementGranularity'->new($_) } @$_ ] };

declare 'MapStringEntitlementGranularity',
    as HashRef[EntitlementGranularity()];

declare 'ChannelPartnerGranularity',
    as InstanceOf['Google::Cloud::Channel::V1::Repricing::RepricingConfig::ChannelPartnerGranularity'];

coerce 'ChannelPartnerGranularity',
    from HashRef, via { 'Google::Cloud::Channel::V1::Repricing::RepricingConfig::ChannelPartnerGranularity'->new($_) };

declare 'RepeatedChannelPartnerGranularity',
    as ArrayRef[ChannelPartnerGranularity()];

coerce 'RepeatedChannelPartnerGranularity',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Repricing::RepricingConfig::ChannelPartnerGranularity'->new($_) } @$_ ] };

declare 'MapStringChannelPartnerGranularity',
    as HashRef[ChannelPartnerGranularity()];

declare 'RepricingAdjustment',
    as InstanceOf['Google::Cloud::Channel::V1::Repricing::RepricingAdjustment'];

coerce 'RepricingAdjustment',
    from HashRef, via { 'Google::Cloud::Channel::V1::Repricing::RepricingAdjustment'->new($_) };

declare 'RepeatedRepricingAdjustment',
    as ArrayRef[RepricingAdjustment()];

coerce 'RepeatedRepricingAdjustment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Repricing::RepricingAdjustment'->new($_) } @$_ ] };

declare 'MapStringRepricingAdjustment',
    as HashRef[RepricingAdjustment()];

declare 'PercentageAdjustment',
    as InstanceOf['Google::Cloud::Channel::V1::Repricing::PercentageAdjustment'];

coerce 'PercentageAdjustment',
    from HashRef, via { 'Google::Cloud::Channel::V1::Repricing::PercentageAdjustment'->new($_) };

declare 'RepeatedPercentageAdjustment',
    as ArrayRef[PercentageAdjustment()];

coerce 'RepeatedPercentageAdjustment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Repricing::PercentageAdjustment'->new($_) } @$_ ] };

declare 'MapStringPercentageAdjustment',
    as HashRef[PercentageAdjustment()];

declare 'ConditionalOverride',
    as InstanceOf['Google::Cloud::Channel::V1::Repricing::ConditionalOverride'];

coerce 'ConditionalOverride',
    from HashRef, via { 'Google::Cloud::Channel::V1::Repricing::ConditionalOverride'->new($_) };

declare 'RepeatedConditionalOverride',
    as ArrayRef[ConditionalOverride()];

coerce 'RepeatedConditionalOverride',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Repricing::ConditionalOverride'->new($_) } @$_ ] };

declare 'MapStringConditionalOverride',
    as HashRef[ConditionalOverride()];

declare 'RepricingCondition',
    as InstanceOf['Google::Cloud::Channel::V1::Repricing::RepricingCondition'];

coerce 'RepricingCondition',
    from HashRef, via { 'Google::Cloud::Channel::V1::Repricing::RepricingCondition'->new($_) };

declare 'RepeatedRepricingCondition',
    as ArrayRef[RepricingCondition()];

coerce 'RepeatedRepricingCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Repricing::RepricingCondition'->new($_) } @$_ ] };

declare 'MapStringRepricingCondition',
    as HashRef[RepricingCondition()];

declare 'SkuGroupCondition',
    as InstanceOf['Google::Cloud::Channel::V1::Repricing::SkuGroupCondition'];

coerce 'SkuGroupCondition',
    from HashRef, via { 'Google::Cloud::Channel::V1::Repricing::SkuGroupCondition'->new($_) };

declare 'RepeatedSkuGroupCondition',
    as ArrayRef[SkuGroupCondition()];

coerce 'RepeatedSkuGroupCondition',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Repricing::SkuGroupCondition'->new($_) } @$_ ] };

declare 'MapStringSkuGroupCondition',
    as HashRef[SkuGroupCondition()];

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::Repricing::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
