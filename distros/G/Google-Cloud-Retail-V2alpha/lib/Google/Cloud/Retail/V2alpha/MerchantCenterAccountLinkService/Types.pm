package Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'ListMerchantCenterAccountLinksRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksRequest'];

coerce 'ListMerchantCenterAccountLinksRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksRequest'->new($_) };

declare 'RepeatedListMerchantCenterAccountLinksRequest',
    as ArrayRef[ListMerchantCenterAccountLinksRequest()];

coerce 'RepeatedListMerchantCenterAccountLinksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksRequest'->new($_) } @$_ ] };

declare 'MapStringListMerchantCenterAccountLinksRequest',
    as HashRef[ListMerchantCenterAccountLinksRequest()];

declare 'ListMerchantCenterAccountLinksResponse',
    as InstanceOf['Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksResponse'];

coerce 'ListMerchantCenterAccountLinksResponse',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksResponse'->new($_) };

declare 'RepeatedListMerchantCenterAccountLinksResponse',
    as ArrayRef[ListMerchantCenterAccountLinksResponse()];

coerce 'RepeatedListMerchantCenterAccountLinksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::ListMerchantCenterAccountLinksResponse'->new($_) } @$_ ] };

declare 'MapStringListMerchantCenterAccountLinksResponse',
    as HashRef[ListMerchantCenterAccountLinksResponse()];

declare 'CreateMerchantCenterAccountLinkRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::CreateMerchantCenterAccountLinkRequest'];

coerce 'CreateMerchantCenterAccountLinkRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::CreateMerchantCenterAccountLinkRequest'->new($_) };

declare 'RepeatedCreateMerchantCenterAccountLinkRequest',
    as ArrayRef[CreateMerchantCenterAccountLinkRequest()];

coerce 'RepeatedCreateMerchantCenterAccountLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::CreateMerchantCenterAccountLinkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateMerchantCenterAccountLinkRequest',
    as HashRef[CreateMerchantCenterAccountLinkRequest()];

declare 'DeleteMerchantCenterAccountLinkRequest',
    as InstanceOf['Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::DeleteMerchantCenterAccountLinkRequest'];

coerce 'DeleteMerchantCenterAccountLinkRequest',
    from HashRef, via { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::DeleteMerchantCenterAccountLinkRequest'->new($_) };

declare 'RepeatedDeleteMerchantCenterAccountLinkRequest',
    as ArrayRef[DeleteMerchantCenterAccountLinkRequest()];

coerce 'RepeatedDeleteMerchantCenterAccountLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::DeleteMerchantCenterAccountLinkRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteMerchantCenterAccountLinkRequest',
    as HashRef[DeleteMerchantCenterAccountLinkRequest()];

1;

__END__

=head1 NAME

Google::Cloud::Retail::V2alpha::MerchantCenterAccountLinkService::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
