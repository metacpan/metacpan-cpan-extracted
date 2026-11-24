package Google::Cloud::Channel::V1::Products::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MediaType',
    as (Int | Str);

declare 'Product',
    as InstanceOf['Google::Cloud::Channel::V1::Products::Product'];

coerce 'Product',
    from HashRef, via { 'Google::Cloud::Channel::V1::Products::Product'->new($_) };

declare 'RepeatedProduct',
    as ArrayRef[Product()];

coerce 'RepeatedProduct',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Products::Product'->new($_) } @$_ ] };

declare 'MapStringProduct',
    as HashRef[Product()];

declare 'Sku',
    as InstanceOf['Google::Cloud::Channel::V1::Products::Sku'];

coerce 'Sku',
    from HashRef, via { 'Google::Cloud::Channel::V1::Products::Sku'->new($_) };

declare 'RepeatedSku',
    as ArrayRef[Sku()];

coerce 'RepeatedSku',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Products::Sku'->new($_) } @$_ ] };

declare 'MapStringSku',
    as HashRef[Sku()];

declare 'MarketingInfo',
    as InstanceOf['Google::Cloud::Channel::V1::Products::MarketingInfo'];

coerce 'MarketingInfo',
    from HashRef, via { 'Google::Cloud::Channel::V1::Products::MarketingInfo'->new($_) };

declare 'RepeatedMarketingInfo',
    as ArrayRef[MarketingInfo()];

coerce 'RepeatedMarketingInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Products::MarketingInfo'->new($_) } @$_ ] };

declare 'MapStringMarketingInfo',
    as HashRef[MarketingInfo()];

declare 'Media',
    as InstanceOf['Google::Cloud::Channel::V1::Products::Media'];

coerce 'Media',
    from HashRef, via { 'Google::Cloud::Channel::V1::Products::Media'->new($_) };

declare 'RepeatedMedia',
    as ArrayRef[Media()];

coerce 'RepeatedMedia',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Products::Media'->new($_) } @$_ ] };

declare 'MapStringMedia',
    as HashRef[Media()];

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::Products::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
