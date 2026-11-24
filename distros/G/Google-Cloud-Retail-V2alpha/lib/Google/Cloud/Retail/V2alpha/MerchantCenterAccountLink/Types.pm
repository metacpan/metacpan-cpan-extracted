package Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'MerchantCenterAccountLink',
    as InstanceOf['Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink'];

coerce 'MerchantCenterAccountLink',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink'->new($_) };

declare 'RepeatedMerchantCenterAccountLink',
    as ArrayRef[MerchantCenterAccountLink()];

coerce 'RepeatedMerchantCenterAccountLink',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink'->new($_) } @$_ ] };

declare 'MapStringMerchantCenterAccountLink',
    as HashRef[MerchantCenterAccountLink()];

declare 'State',
    as (Int | Str);

declare 'MerchantCenterFeedFilter',
    as InstanceOf['Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink::MerchantCenterFeedFilter'];

coerce 'MerchantCenterFeedFilter',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink::MerchantCenterFeedFilter'->new($_) };

declare 'RepeatedMerchantCenterFeedFilter',
    as ArrayRef[MerchantCenterFeedFilter()];

coerce 'RepeatedMerchantCenterFeedFilter',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::MerchantCenterAccountLink::MerchantCenterFeedFilter'->new($_) } @$_ ] };

declare 'MapStringMerchantCenterFeedFilter',
    as HashRef[MerchantCenterFeedFilter()];

declare 'CreateMerchantCenterAccountLinkMetadata',
    as InstanceOf['Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::CreateMerchantCenterAccountLinkMetadata'];

coerce 'CreateMerchantCenterAccountLinkMetadata',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::CreateMerchantCenterAccountLinkMetadata'->new($_) };

declare 'RepeatedCreateMerchantCenterAccountLinkMetadata',
    as ArrayRef[CreateMerchantCenterAccountLinkMetadata()];

coerce 'RepeatedCreateMerchantCenterAccountLinkMetadata',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::CreateMerchantCenterAccountLinkMetadata'->new($_) } @$_ ] };

declare 'MapStringCreateMerchantCenterAccountLinkMetadata',
    as HashRef[CreateMerchantCenterAccountLinkMetadata()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::MerchantCenterAccountLink::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
