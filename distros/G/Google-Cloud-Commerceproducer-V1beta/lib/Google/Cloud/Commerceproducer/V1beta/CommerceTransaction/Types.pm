package Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'PrivateOfferView',
    as (Int | Str);

declare 'StandardOfferView',
    as (Int | Str);

declare 'ServiceView',
    as (Int | Str);

declare 'ListPrivateOffersRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOffersRequest'];

coerce 'ListPrivateOffersRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOffersRequest'->new($_) };

declare 'RepeatedListPrivateOffersRequest',
    as ArrayRef[ListPrivateOffersRequest()];

coerce 'RepeatedListPrivateOffersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOffersRequest'->new($_) } @$_ ] };

declare 'MapStringListPrivateOffersRequest',
    as HashRef[ListPrivateOffersRequest()];

declare 'ListPrivateOffersResponse',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOffersResponse'];

coerce 'ListPrivateOffersResponse',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOffersResponse'->new($_) };

declare 'RepeatedListPrivateOffersResponse',
    as ArrayRef[ListPrivateOffersResponse()];

coerce 'RepeatedListPrivateOffersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOffersResponse'->new($_) } @$_ ] };

declare 'MapStringListPrivateOffersResponse',
    as HashRef[ListPrivateOffersResponse()];

declare 'GetPrivateOfferRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetPrivateOfferRequest'];

coerce 'GetPrivateOfferRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetPrivateOfferRequest'->new($_) };

declare 'RepeatedGetPrivateOfferRequest',
    as ArrayRef[GetPrivateOfferRequest()];

coerce 'RepeatedGetPrivateOfferRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetPrivateOfferRequest'->new($_) } @$_ ] };

declare 'MapStringGetPrivateOfferRequest',
    as HashRef[GetPrivateOfferRequest()];

declare 'ResolveAmendmentTargetRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ResolveAmendmentTargetRequest'];

coerce 'ResolveAmendmentTargetRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ResolveAmendmentTargetRequest'->new($_) };

declare 'RepeatedResolveAmendmentTargetRequest',
    as ArrayRef[ResolveAmendmentTargetRequest()];

coerce 'RepeatedResolveAmendmentTargetRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ResolveAmendmentTargetRequest'->new($_) } @$_ ] };

declare 'MapStringResolveAmendmentTargetRequest',
    as HashRef[ResolveAmendmentTargetRequest()];

declare 'ResolveAmendmentTargetResponse',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ResolveAmendmentTargetResponse'];

coerce 'ResolveAmendmentTargetResponse',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ResolveAmendmentTargetResponse'->new($_) };

declare 'RepeatedResolveAmendmentTargetResponse',
    as ArrayRef[ResolveAmendmentTargetResponse()];

coerce 'RepeatedResolveAmendmentTargetResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ResolveAmendmentTargetResponse'->new($_) } @$_ ] };

declare 'MapStringResolveAmendmentTargetResponse',
    as HashRef[ResolveAmendmentTargetResponse()];

declare 'OptionalOffers',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ResolveAmendmentTargetResponse::OptionalOffers'];

coerce 'OptionalOffers',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ResolveAmendmentTargetResponse::OptionalOffers'->new($_) };

declare 'RepeatedOptionalOffers',
    as ArrayRef[OptionalOffers()];

coerce 'RepeatedOptionalOffers',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ResolveAmendmentTargetResponse::OptionalOffers'->new($_) } @$_ ] };

declare 'MapStringOptionalOffers',
    as HashRef[OptionalOffers()];

declare 'CreatePrivateOfferRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::CreatePrivateOfferRequest'];

coerce 'CreatePrivateOfferRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::CreatePrivateOfferRequest'->new($_) };

declare 'RepeatedCreatePrivateOfferRequest',
    as ArrayRef[CreatePrivateOfferRequest()];

coerce 'RepeatedCreatePrivateOfferRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::CreatePrivateOfferRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePrivateOfferRequest',
    as HashRef[CreatePrivateOfferRequest()];

declare 'UpdatePrivateOfferRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::UpdatePrivateOfferRequest'];

coerce 'UpdatePrivateOfferRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::UpdatePrivateOfferRequest'->new($_) };

declare 'RepeatedUpdatePrivateOfferRequest',
    as ArrayRef[UpdatePrivateOfferRequest()];

coerce 'RepeatedUpdatePrivateOfferRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::UpdatePrivateOfferRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePrivateOfferRequest',
    as HashRef[UpdatePrivateOfferRequest()];

declare 'PublishPrivateOfferRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::PublishPrivateOfferRequest'];

coerce 'PublishPrivateOfferRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::PublishPrivateOfferRequest'->new($_) };

declare 'RepeatedPublishPrivateOfferRequest',
    as ArrayRef[PublishPrivateOfferRequest()];

coerce 'RepeatedPublishPrivateOfferRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::PublishPrivateOfferRequest'->new($_) } @$_ ] };

declare 'MapStringPublishPrivateOfferRequest',
    as HashRef[PublishPrivateOfferRequest()];

declare 'CancelPrivateOfferRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::CancelPrivateOfferRequest'];

coerce 'CancelPrivateOfferRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::CancelPrivateOfferRequest'->new($_) };

declare 'RepeatedCancelPrivateOfferRequest',
    as ArrayRef[CancelPrivateOfferRequest()];

coerce 'RepeatedCancelPrivateOfferRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::CancelPrivateOfferRequest'->new($_) } @$_ ] };

declare 'MapStringCancelPrivateOfferRequest',
    as HashRef[CancelPrivateOfferRequest()];

declare 'DeletePrivateOfferRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::DeletePrivateOfferRequest'];

coerce 'DeletePrivateOfferRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::DeletePrivateOfferRequest'->new($_) };

declare 'RepeatedDeletePrivateOfferRequest',
    as ArrayRef[DeletePrivateOfferRequest()];

coerce 'RepeatedDeletePrivateOfferRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::DeletePrivateOfferRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePrivateOfferRequest',
    as HashRef[DeletePrivateOfferRequest()];

declare 'ListPrivateOfferDocumentsRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOfferDocumentsRequest'];

coerce 'ListPrivateOfferDocumentsRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOfferDocumentsRequest'->new($_) };

declare 'RepeatedListPrivateOfferDocumentsRequest',
    as ArrayRef[ListPrivateOfferDocumentsRequest()];

coerce 'RepeatedListPrivateOfferDocumentsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOfferDocumentsRequest'->new($_) } @$_ ] };

declare 'MapStringListPrivateOfferDocumentsRequest',
    as HashRef[ListPrivateOfferDocumentsRequest()];

declare 'ListPrivateOfferDocumentsResponse',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOfferDocumentsResponse'];

coerce 'ListPrivateOfferDocumentsResponse',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOfferDocumentsResponse'->new($_) };

declare 'RepeatedListPrivateOfferDocumentsResponse',
    as ArrayRef[ListPrivateOfferDocumentsResponse()];

coerce 'RepeatedListPrivateOfferDocumentsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListPrivateOfferDocumentsResponse'->new($_) } @$_ ] };

declare 'MapStringListPrivateOfferDocumentsResponse',
    as HashRef[ListPrivateOfferDocumentsResponse()];

declare 'GetPrivateOfferDocumentRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetPrivateOfferDocumentRequest'];

coerce 'GetPrivateOfferDocumentRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetPrivateOfferDocumentRequest'->new($_) };

declare 'RepeatedGetPrivateOfferDocumentRequest',
    as ArrayRef[GetPrivateOfferDocumentRequest()];

coerce 'RepeatedGetPrivateOfferDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetPrivateOfferDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringGetPrivateOfferDocumentRequest',
    as HashRef[GetPrivateOfferDocumentRequest()];

declare 'CreatePrivateOfferDocumentRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::CreatePrivateOfferDocumentRequest'];

coerce 'CreatePrivateOfferDocumentRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::CreatePrivateOfferDocumentRequest'->new($_) };

declare 'RepeatedCreatePrivateOfferDocumentRequest',
    as ArrayRef[CreatePrivateOfferDocumentRequest()];

coerce 'RepeatedCreatePrivateOfferDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::CreatePrivateOfferDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringCreatePrivateOfferDocumentRequest',
    as HashRef[CreatePrivateOfferDocumentRequest()];

declare 'UpdatePrivateOfferDocumentRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::UpdatePrivateOfferDocumentRequest'];

coerce 'UpdatePrivateOfferDocumentRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::UpdatePrivateOfferDocumentRequest'->new($_) };

declare 'RepeatedUpdatePrivateOfferDocumentRequest',
    as ArrayRef[UpdatePrivateOfferDocumentRequest()];

coerce 'RepeatedUpdatePrivateOfferDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::UpdatePrivateOfferDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringUpdatePrivateOfferDocumentRequest',
    as HashRef[UpdatePrivateOfferDocumentRequest()];

declare 'DeletePrivateOfferDocumentRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::DeletePrivateOfferDocumentRequest'];

coerce 'DeletePrivateOfferDocumentRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::DeletePrivateOfferDocumentRequest'->new($_) };

declare 'RepeatedDeletePrivateOfferDocumentRequest',
    as ArrayRef[DeletePrivateOfferDocumentRequest()];

coerce 'RepeatedDeletePrivateOfferDocumentRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::DeletePrivateOfferDocumentRequest'->new($_) } @$_ ] };

declare 'MapStringDeletePrivateOfferDocumentRequest',
    as HashRef[DeletePrivateOfferDocumentRequest()];

declare 'ListServicesRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListServicesRequest'];

coerce 'ListServicesRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListServicesRequest'->new($_) };

declare 'RepeatedListServicesRequest',
    as ArrayRef[ListServicesRequest()];

coerce 'RepeatedListServicesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListServicesRequest'->new($_) } @$_ ] };

declare 'MapStringListServicesRequest',
    as HashRef[ListServicesRequest()];

declare 'ListServicesResponse',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListServicesResponse'];

coerce 'ListServicesResponse',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListServicesResponse'->new($_) };

declare 'RepeatedListServicesResponse',
    as ArrayRef[ListServicesResponse()];

coerce 'RepeatedListServicesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListServicesResponse'->new($_) } @$_ ] };

declare 'MapStringListServicesResponse',
    as HashRef[ListServicesResponse()];

declare 'GetServiceRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetServiceRequest'];

coerce 'GetServiceRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetServiceRequest'->new($_) };

declare 'RepeatedGetServiceRequest',
    as ArrayRef[GetServiceRequest()];

coerce 'RepeatedGetServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetServiceRequest'->new($_) } @$_ ] };

declare 'MapStringGetServiceRequest',
    as HashRef[GetServiceRequest()];

declare 'ListStandardOffersRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListStandardOffersRequest'];

coerce 'ListStandardOffersRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListStandardOffersRequest'->new($_) };

declare 'RepeatedListStandardOffersRequest',
    as ArrayRef[ListStandardOffersRequest()];

coerce 'RepeatedListStandardOffersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListStandardOffersRequest'->new($_) } @$_ ] };

declare 'MapStringListStandardOffersRequest',
    as HashRef[ListStandardOffersRequest()];

declare 'ListStandardOffersResponse',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListStandardOffersResponse'];

coerce 'ListStandardOffersResponse',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListStandardOffersResponse'->new($_) };

declare 'RepeatedListStandardOffersResponse',
    as ArrayRef[ListStandardOffersResponse()];

coerce 'RepeatedListStandardOffersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListStandardOffersResponse'->new($_) } @$_ ] };

declare 'MapStringListStandardOffersResponse',
    as HashRef[ListStandardOffersResponse()];

declare 'GetStandardOfferRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetStandardOfferRequest'];

coerce 'GetStandardOfferRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetStandardOfferRequest'->new($_) };

declare 'RepeatedGetStandardOfferRequest',
    as ArrayRef[GetStandardOfferRequest()];

coerce 'RepeatedGetStandardOfferRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetStandardOfferRequest'->new($_) } @$_ ] };

declare 'MapStringGetStandardOfferRequest',
    as HashRef[GetStandardOfferRequest()];

declare 'ListSkusRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkusRequest'];

coerce 'ListSkusRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkusRequest'->new($_) };

declare 'RepeatedListSkusRequest',
    as ArrayRef[ListSkusRequest()];

coerce 'RepeatedListSkusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkusRequest'->new($_) } @$_ ] };

declare 'MapStringListSkusRequest',
    as HashRef[ListSkusRequest()];

declare 'ListSkusResponse',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkusResponse'];

coerce 'ListSkusResponse',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkusResponse'->new($_) };

declare 'RepeatedListSkusResponse',
    as ArrayRef[ListSkusResponse()];

coerce 'RepeatedListSkusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkusResponse'->new($_) } @$_ ] };

declare 'MapStringListSkusResponse',
    as HashRef[ListSkusResponse()];

declare 'GetSkuRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetSkuRequest'];

coerce 'GetSkuRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetSkuRequest'->new($_) };

declare 'RepeatedGetSkuRequest',
    as ArrayRef[GetSkuRequest()];

coerce 'RepeatedGetSkuRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetSkuRequest'->new($_) } @$_ ] };

declare 'MapStringGetSkuRequest',
    as HashRef[GetSkuRequest()];

declare 'GetSkuGroupRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetSkuGroupRequest'];

coerce 'GetSkuGroupRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetSkuGroupRequest'->new($_) };

declare 'RepeatedGetSkuGroupRequest',
    as ArrayRef[GetSkuGroupRequest()];

coerce 'RepeatedGetSkuGroupRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::GetSkuGroupRequest'->new($_) } @$_ ] };

declare 'MapStringGetSkuGroupRequest',
    as HashRef[GetSkuGroupRequest()];

declare 'ListSkuGroupsRequest',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkuGroupsRequest'];

coerce 'ListSkuGroupsRequest',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkuGroupsRequest'->new($_) };

declare 'RepeatedListSkuGroupsRequest',
    as ArrayRef[ListSkuGroupsRequest()];

coerce 'RepeatedListSkuGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkuGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListSkuGroupsRequest',
    as HashRef[ListSkuGroupsRequest()];

declare 'ListSkuGroupsResponse',
    as InstanceOf['Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkuGroupsResponse'];

coerce 'ListSkuGroupsResponse',
    from HashRef, via { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkuGroupsResponse'->new($_) };

declare 'RepeatedListSkuGroupsResponse',
    as ArrayRef[ListSkuGroupsResponse()];

coerce 'RepeatedListSkuGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::ListSkuGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListSkuGroupsResponse',
    as HashRef[ListSkuGroupsResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Commerceproducer::V1beta::CommerceTransaction::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
