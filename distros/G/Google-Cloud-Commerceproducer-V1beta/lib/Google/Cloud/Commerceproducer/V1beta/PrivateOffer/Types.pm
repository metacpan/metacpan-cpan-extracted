package Google::Cloud::Commerceproducer::V1beta::PrivateOffer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PrivateOffer',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer'];

coerce 'PrivateOffer',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer'->new($_) };

declare 'RepeatedPrivateOffer',
    as ArrayRef[PrivateOffer()];

coerce 'RepeatedPrivateOffer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer'->new($_) } @$_ ] };

declare 'MapStringPrivateOffer',
    as HashRef[PrivateOffer()];

declare 'State',
    as (Int | Str);

declare 'OfferDealType',
    as (Int | Str);

declare 'PublishRequirementGoogleReview',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::PublishRequirementGoogleReview'];

coerce 'PublishRequirementGoogleReview',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::PublishRequirementGoogleReview'->new($_) };

declare 'RepeatedPublishRequirementGoogleReview',
    as ArrayRef[PublishRequirementGoogleReview()];

coerce 'RepeatedPublishRequirementGoogleReview',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::PublishRequirementGoogleReview'->new($_) } @$_ ] };

declare 'MapStringPublishRequirementGoogleReview',
    as HashRef[PublishRequirementGoogleReview()];

declare 'ResellerContact',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::ResellerContact'];

coerce 'ResellerContact',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::ResellerContact'->new($_) };

declare 'RepeatedResellerContact',
    as ArrayRef[ResellerContact()];

coerce 'RepeatedResellerContact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::ResellerContact'->new($_) } @$_ ] };

declare 'MapStringResellerContact',
    as HashRef[ResellerContact()];

declare 'PartnerContact',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::PartnerContact'];

coerce 'PartnerContact',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::PartnerContact'->new($_) };

declare 'RepeatedPartnerContact',
    as ArrayRef[PartnerContact()];

coerce 'RepeatedPartnerContact',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::PartnerContact'->new($_) } @$_ ] };

declare 'MapStringPartnerContact',
    as HashRef[PartnerContact()];

declare 'Customer',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::Customer'];

coerce 'Customer',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::Customer'->new($_) };

declare 'RepeatedCustomer',
    as ArrayRef[Customer()];

coerce 'RepeatedCustomer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::Customer'->new($_) } @$_ ] };

declare 'MapStringCustomer',
    as HashRef[Customer()];

declare 'Term',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::Term'];

coerce 'Term',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::Term'->new($_) };

declare 'RepeatedTerm',
    as ArrayRef[Term()];

coerce 'RepeatedTerm',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::Term'->new($_) } @$_ ] };

declare 'MapStringTerm',
    as HashRef[Term()];

declare 'StartPolicy',
    as (Int | Str);

declare 'EndPolicy',
    as (Int | Str);

declare 'SingleProductOffer',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer'];

coerce 'SingleProductOffer',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer'->new($_) };

declare 'RepeatedSingleProductOffer',
    as ArrayRef[SingleProductOffer()];

coerce 'RepeatedSingleProductOffer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer'->new($_) } @$_ ] };

declare 'MapStringSingleProductOffer',
    as HashRef[SingleProductOffer()];

declare 'Feature',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::Feature'];

coerce 'Feature',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::Feature'->new($_) };

declare 'RepeatedFeature',
    as ArrayRef[Feature()];

coerce 'RepeatedFeature',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::Feature'->new($_) } @$_ ] };

declare 'MapStringFeature',
    as HashRef[Feature()];

declare 'PriceModel',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel'];

coerce 'PriceModel',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel'->new($_) };

declare 'RepeatedPriceModel',
    as ArrayRef[PriceModel()];

coerce 'RepeatedPriceModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel'->new($_) } @$_ ] };

declare 'MapStringPriceModel',
    as HashRef[PriceModel()];

declare 'SkuDiscount',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::SkuDiscount'];

coerce 'SkuDiscount',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::SkuDiscount'->new($_) };

declare 'RepeatedSkuDiscount',
    as ArrayRef[SkuDiscount()];

coerce 'RepeatedSkuDiscount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::SkuDiscount'->new($_) } @$_ ] };

declare 'MapStringSkuDiscount',
    as HashRef[SkuDiscount()];

declare 'Usage',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::Usage'];

coerce 'Usage',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::Usage'->new($_) };

declare 'RepeatedUsage',
    as ArrayRef[Usage()];

coerce 'RepeatedUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::Usage'->new($_) } @$_ ] };

declare 'MapStringUsage',
    as HashRef[Usage()];

declare 'FlatFee',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::FlatFee'];

coerce 'FlatFee',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::FlatFee'->new($_) };

declare 'RepeatedFlatFee',
    as ArrayRef[FlatFee()];

coerce 'RepeatedFlatFee',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::FlatFee'->new($_) } @$_ ] };

declare 'MapStringFlatFee',
    as HashRef[FlatFee()];

declare 'Commitment',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::Commitment'];

coerce 'Commitment',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::Commitment'->new($_) };

declare 'RepeatedCommitment',
    as ArrayRef[Commitment()];

coerce 'RepeatedCommitment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::PriceModel::Commitment'->new($_) } @$_ ] };

declare 'MapStringCommitment',
    as HashRef[Commitment()];

declare 'StandardIntervalPrice',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::StandardIntervalPrice'];

coerce 'StandardIntervalPrice',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::StandardIntervalPrice'->new($_) };

declare 'RepeatedStandardIntervalPrice',
    as ArrayRef[StandardIntervalPrice()];

coerce 'RepeatedStandardIntervalPrice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::StandardIntervalPrice'->new($_) } @$_ ] };

declare 'MapStringStandardIntervalPrice',
    as HashRef[StandardIntervalPrice()];

declare 'StandardInterval',
    as (Int | Str);

declare 'Installment',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::Installment'];

coerce 'Installment',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::Installment'->new($_) };

declare 'RepeatedInstallment',
    as ArrayRef[Installment()];

coerce 'RepeatedInstallment',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::Installment'->new($_) } @$_ ] };

declare 'MapStringInstallment',
    as HashRef[Installment()];

declare 'CustomIntervalPrice',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::CustomIntervalPrice'];

coerce 'CustomIntervalPrice',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::CustomIntervalPrice'->new($_) };

declare 'RepeatedCustomIntervalPrice',
    as ArrayRef[CustomIntervalPrice()];

coerce 'RepeatedCustomIntervalPrice',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::CustomIntervalPrice'->new($_) } @$_ ] };

declare 'MapStringCustomIntervalPrice',
    as HashRef[CustomIntervalPrice()];

declare 'ContractValue',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::ContractValue'];

coerce 'ContractValue',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::ContractValue'->new($_) };

declare 'RepeatedContractValue',
    as ArrayRef[ContractValue()];

coerce 'RepeatedContractValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::ContractValue'->new($_) } @$_ ] };

declare 'MapStringContractValue',
    as HashRef[ContractValue()];

declare 'RevenueShare',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::RevenueShare'];

coerce 'RevenueShare',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::RevenueShare'->new($_) };

declare 'RepeatedRevenueShare',
    as ArrayRef[RevenueShare()];

coerce 'RepeatedRevenueShare',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::RevenueShare'->new($_) } @$_ ] };

declare 'MapStringRevenueShare',
    as HashRef[RevenueShare()];

declare 'AdditionalContractValue',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::AdditionalContractValue'];

coerce 'AdditionalContractValue',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::AdditionalContractValue'->new($_) };

declare 'RepeatedAdditionalContractValue',
    as ArrayRef[AdditionalContractValue()];

coerce 'RepeatedAdditionalContractValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOffer::SingleProductOffer::AdditionalContractValue'->new($_) } @$_ ] };

declare 'MapStringAdditionalContractValue',
    as HashRef[AdditionalContractValue()];

declare 'PrivateOfferDocument',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOfferDocument'];

coerce 'PrivateOfferDocument',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOfferDocument'->new($_) };

declare 'RepeatedPrivateOfferDocument',
    as ArrayRef[PrivateOfferDocument()];

coerce 'RepeatedPrivateOfferDocument',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::PrivateOffer::PrivateOfferDocument'->new($_) } @$_ ] };

declare 'MapStringPrivateOfferDocument',
    as HashRef[PrivateOfferDocument()];

declare 'DocumentType',
    as (Int | Str);

1;

__END__

=head1 NAME

Google::Cloud::Commerceproducer::V1beta::PrivateOffer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
