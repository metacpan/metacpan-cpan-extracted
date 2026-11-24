package Google::Cloud::Commerceproducer::V1beta::StandardOffer::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'StandardOffer',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer'];

coerce 'StandardOffer',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer'->new($_) };

declare 'RepeatedStandardOffer',
    as ArrayRef[StandardOffer()];

coerce 'RepeatedStandardOffer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer'->new($_) } @$_ ] };

declare 'MapStringStandardOffer',
    as HashRef[StandardOffer()];

declare 'PriceModel',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel'];

coerce 'PriceModel',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel'->new($_) };

declare 'RepeatedPriceModel',
    as ArrayRef[PriceModel()];

coerce 'RepeatedPriceModel',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel'->new($_) } @$_ ] };

declare 'MapStringPriceModel',
    as HashRef[PriceModel()];

declare 'SkuList',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::SkuList'];

coerce 'SkuList',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::SkuList'->new($_) };

declare 'RepeatedSkuList',
    as ArrayRef[SkuList()];

coerce 'RepeatedSkuList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::SkuList'->new($_) } @$_ ] };

declare 'MapStringSkuList',
    as HashRef[SkuList()];

declare 'SkuGroupList',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::SkuGroupList'];

coerce 'SkuGroupList',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::SkuGroupList'->new($_) };

declare 'RepeatedSkuGroupList',
    as ArrayRef[SkuGroupList()];

coerce 'RepeatedSkuGroupList',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::SkuGroupList'->new($_) } @$_ ] };

declare 'MapStringSkuGroupList',
    as HashRef[SkuGroupList()];

declare 'Usage',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::Usage'];

coerce 'Usage',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::Usage'->new($_) };

declare 'RepeatedUsage',
    as ArrayRef[Usage()];

coerce 'RepeatedUsage',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::Usage'->new($_) } @$_ ] };

declare 'MapStringUsage',
    as HashRef[Usage()];

declare 'FlatFeeSubscription',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::FlatFeeSubscription'];

coerce 'FlatFeeSubscription',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::FlatFeeSubscription'->new($_) };

declare 'RepeatedFlatFeeSubscription',
    as ArrayRef[FlatFeeSubscription()];

coerce 'RepeatedFlatFeeSubscription',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::StandardOffer::StandardOffer::PriceModel::FlatFeeSubscription'->new($_) } @$_ ] };

declare 'MapStringFlatFeeSubscription',
    as HashRef[FlatFeeSubscription()];

1;

__END__

=head1 NAME

Google::Cloud::Commerceproducer::V1beta::StandardOffer::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
