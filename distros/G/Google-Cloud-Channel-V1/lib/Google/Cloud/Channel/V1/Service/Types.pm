package Google::Cloud::Channel::V1::Service::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'CheckCloudIdentityAccountsExistRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::CheckCloudIdentityAccountsExistRequest'];

coerce 'CheckCloudIdentityAccountsExistRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::CheckCloudIdentityAccountsExistRequest'->new($_) };

declare 'RepeatedCheckCloudIdentityAccountsExistRequest',
    as ArrayRef[CheckCloudIdentityAccountsExistRequest()];

coerce 'RepeatedCheckCloudIdentityAccountsExistRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::CheckCloudIdentityAccountsExistRequest'->new($_) } @$_ ] };

declare 'MapStringCheckCloudIdentityAccountsExistRequest',
    as HashRef[CheckCloudIdentityAccountsExistRequest()];

declare 'CloudIdentityCustomerAccount',
    as InstanceOf['Google::Cloud::Channel::V1::Service::CloudIdentityCustomerAccount'];

coerce 'CloudIdentityCustomerAccount',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::CloudIdentityCustomerAccount'->new($_) };

declare 'RepeatedCloudIdentityCustomerAccount',
    as ArrayRef[CloudIdentityCustomerAccount()];

coerce 'RepeatedCloudIdentityCustomerAccount',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::CloudIdentityCustomerAccount'->new($_) } @$_ ] };

declare 'MapStringCloudIdentityCustomerAccount',
    as HashRef[CloudIdentityCustomerAccount()];

declare 'CheckCloudIdentityAccountsExistResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::CheckCloudIdentityAccountsExistResponse'];

coerce 'CheckCloudIdentityAccountsExistResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::CheckCloudIdentityAccountsExistResponse'->new($_) };

declare 'RepeatedCheckCloudIdentityAccountsExistResponse',
    as ArrayRef[CheckCloudIdentityAccountsExistResponse()];

coerce 'RepeatedCheckCloudIdentityAccountsExistResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::CheckCloudIdentityAccountsExistResponse'->new($_) } @$_ ] };

declare 'MapStringCheckCloudIdentityAccountsExistResponse',
    as HashRef[CheckCloudIdentityAccountsExistResponse()];

declare 'ListCustomersRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListCustomersRequest'];

coerce 'ListCustomersRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListCustomersRequest'->new($_) };

declare 'RepeatedListCustomersRequest',
    as ArrayRef[ListCustomersRequest()];

coerce 'RepeatedListCustomersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListCustomersRequest'->new($_) } @$_ ] };

declare 'MapStringListCustomersRequest',
    as HashRef[ListCustomersRequest()];

declare 'ListCustomersResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListCustomersResponse'];

coerce 'ListCustomersResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListCustomersResponse'->new($_) };

declare 'RepeatedListCustomersResponse',
    as ArrayRef[ListCustomersResponse()];

coerce 'RepeatedListCustomersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListCustomersResponse'->new($_) } @$_ ] };

declare 'MapStringListCustomersResponse',
    as HashRef[ListCustomersResponse()];

declare 'GetCustomerRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::GetCustomerRequest'];

coerce 'GetCustomerRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::GetCustomerRequest'->new($_) };

declare 'RepeatedGetCustomerRequest',
    as ArrayRef[GetCustomerRequest()];

coerce 'RepeatedGetCustomerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::GetCustomerRequest'->new($_) } @$_ ] };

declare 'MapStringGetCustomerRequest',
    as HashRef[GetCustomerRequest()];

declare 'CreateCustomerRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::CreateCustomerRequest'];

coerce 'CreateCustomerRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::CreateCustomerRequest'->new($_) };

declare 'RepeatedCreateCustomerRequest',
    as ArrayRef[CreateCustomerRequest()];

coerce 'RepeatedCreateCustomerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::CreateCustomerRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCustomerRequest',
    as HashRef[CreateCustomerRequest()];

declare 'UpdateCustomerRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::UpdateCustomerRequest'];

coerce 'UpdateCustomerRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::UpdateCustomerRequest'->new($_) };

declare 'RepeatedUpdateCustomerRequest',
    as ArrayRef[UpdateCustomerRequest()];

coerce 'RepeatedUpdateCustomerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::UpdateCustomerRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCustomerRequest',
    as HashRef[UpdateCustomerRequest()];

declare 'DeleteCustomerRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::DeleteCustomerRequest'];

coerce 'DeleteCustomerRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::DeleteCustomerRequest'->new($_) };

declare 'RepeatedDeleteCustomerRequest',
    as ArrayRef[DeleteCustomerRequest()];

coerce 'RepeatedDeleteCustomerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::DeleteCustomerRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCustomerRequest',
    as HashRef[DeleteCustomerRequest()];

declare 'ImportCustomerRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ImportCustomerRequest'];

coerce 'ImportCustomerRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ImportCustomerRequest'->new($_) };

declare 'RepeatedImportCustomerRequest',
    as ArrayRef[ImportCustomerRequest()];

coerce 'RepeatedImportCustomerRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ImportCustomerRequest'->new($_) } @$_ ] };

declare 'MapStringImportCustomerRequest',
    as HashRef[ImportCustomerRequest()];

declare 'ProvisionCloudIdentityRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ProvisionCloudIdentityRequest'];

coerce 'ProvisionCloudIdentityRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ProvisionCloudIdentityRequest'->new($_) };

declare 'RepeatedProvisionCloudIdentityRequest',
    as ArrayRef[ProvisionCloudIdentityRequest()];

coerce 'RepeatedProvisionCloudIdentityRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ProvisionCloudIdentityRequest'->new($_) } @$_ ] };

declare 'MapStringProvisionCloudIdentityRequest',
    as HashRef[ProvisionCloudIdentityRequest()];

declare 'ListEntitlementsRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListEntitlementsRequest'];

coerce 'ListEntitlementsRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListEntitlementsRequest'->new($_) };

declare 'RepeatedListEntitlementsRequest',
    as ArrayRef[ListEntitlementsRequest()];

coerce 'RepeatedListEntitlementsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListEntitlementsRequest'->new($_) } @$_ ] };

declare 'MapStringListEntitlementsRequest',
    as HashRef[ListEntitlementsRequest()];

declare 'ListEntitlementsResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListEntitlementsResponse'];

coerce 'ListEntitlementsResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListEntitlementsResponse'->new($_) };

declare 'RepeatedListEntitlementsResponse',
    as ArrayRef[ListEntitlementsResponse()];

coerce 'RepeatedListEntitlementsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListEntitlementsResponse'->new($_) } @$_ ] };

declare 'MapStringListEntitlementsResponse',
    as HashRef[ListEntitlementsResponse()];

declare 'ListTransferableSkusRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListTransferableSkusRequest'];

coerce 'ListTransferableSkusRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListTransferableSkusRequest'->new($_) };

declare 'RepeatedListTransferableSkusRequest',
    as ArrayRef[ListTransferableSkusRequest()];

coerce 'RepeatedListTransferableSkusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListTransferableSkusRequest'->new($_) } @$_ ] };

declare 'MapStringListTransferableSkusRequest',
    as HashRef[ListTransferableSkusRequest()];

declare 'ListTransferableSkusResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListTransferableSkusResponse'];

coerce 'ListTransferableSkusResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListTransferableSkusResponse'->new($_) };

declare 'RepeatedListTransferableSkusResponse',
    as ArrayRef[ListTransferableSkusResponse()];

coerce 'RepeatedListTransferableSkusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListTransferableSkusResponse'->new($_) } @$_ ] };

declare 'MapStringListTransferableSkusResponse',
    as HashRef[ListTransferableSkusResponse()];

declare 'ListTransferableOffersRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListTransferableOffersRequest'];

coerce 'ListTransferableOffersRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListTransferableOffersRequest'->new($_) };

declare 'RepeatedListTransferableOffersRequest',
    as ArrayRef[ListTransferableOffersRequest()];

coerce 'RepeatedListTransferableOffersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListTransferableOffersRequest'->new($_) } @$_ ] };

declare 'MapStringListTransferableOffersRequest',
    as HashRef[ListTransferableOffersRequest()];

declare 'ListTransferableOffersResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListTransferableOffersResponse'];

coerce 'ListTransferableOffersResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListTransferableOffersResponse'->new($_) };

declare 'RepeatedListTransferableOffersResponse',
    as ArrayRef[ListTransferableOffersResponse()];

coerce 'RepeatedListTransferableOffersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListTransferableOffersResponse'->new($_) } @$_ ] };

declare 'MapStringListTransferableOffersResponse',
    as HashRef[ListTransferableOffersResponse()];

declare 'TransferableOffer',
    as InstanceOf['Google::Cloud::Channel::V1::Service::TransferableOffer'];

coerce 'TransferableOffer',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::TransferableOffer'->new($_) };

declare 'RepeatedTransferableOffer',
    as ArrayRef[TransferableOffer()];

coerce 'RepeatedTransferableOffer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::TransferableOffer'->new($_) } @$_ ] };

declare 'MapStringTransferableOffer',
    as HashRef[TransferableOffer()];

declare 'GetEntitlementRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::GetEntitlementRequest'];

coerce 'GetEntitlementRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::GetEntitlementRequest'->new($_) };

declare 'RepeatedGetEntitlementRequest',
    as ArrayRef[GetEntitlementRequest()];

coerce 'RepeatedGetEntitlementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::GetEntitlementRequest'->new($_) } @$_ ] };

declare 'MapStringGetEntitlementRequest',
    as HashRef[GetEntitlementRequest()];

declare 'ListChannelPartnerLinksRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListChannelPartnerLinksRequest'];

coerce 'ListChannelPartnerLinksRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListChannelPartnerLinksRequest'->new($_) };

declare 'RepeatedListChannelPartnerLinksRequest',
    as ArrayRef[ListChannelPartnerLinksRequest()];

coerce 'RepeatedListChannelPartnerLinksRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListChannelPartnerLinksRequest'->new($_) } @$_ ] };

declare 'MapStringListChannelPartnerLinksRequest',
    as HashRef[ListChannelPartnerLinksRequest()];

declare 'ListChannelPartnerLinksResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListChannelPartnerLinksResponse'];

coerce 'ListChannelPartnerLinksResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListChannelPartnerLinksResponse'->new($_) };

declare 'RepeatedListChannelPartnerLinksResponse',
    as ArrayRef[ListChannelPartnerLinksResponse()];

coerce 'RepeatedListChannelPartnerLinksResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListChannelPartnerLinksResponse'->new($_) } @$_ ] };

declare 'MapStringListChannelPartnerLinksResponse',
    as HashRef[ListChannelPartnerLinksResponse()];

declare 'GetChannelPartnerLinkRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::GetChannelPartnerLinkRequest'];

coerce 'GetChannelPartnerLinkRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::GetChannelPartnerLinkRequest'->new($_) };

declare 'RepeatedGetChannelPartnerLinkRequest',
    as ArrayRef[GetChannelPartnerLinkRequest()];

coerce 'RepeatedGetChannelPartnerLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::GetChannelPartnerLinkRequest'->new($_) } @$_ ] };

declare 'MapStringGetChannelPartnerLinkRequest',
    as HashRef[GetChannelPartnerLinkRequest()];

declare 'CreateChannelPartnerLinkRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::CreateChannelPartnerLinkRequest'];

coerce 'CreateChannelPartnerLinkRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::CreateChannelPartnerLinkRequest'->new($_) };

declare 'RepeatedCreateChannelPartnerLinkRequest',
    as ArrayRef[CreateChannelPartnerLinkRequest()];

coerce 'RepeatedCreateChannelPartnerLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::CreateChannelPartnerLinkRequest'->new($_) } @$_ ] };

declare 'MapStringCreateChannelPartnerLinkRequest',
    as HashRef[CreateChannelPartnerLinkRequest()];

declare 'UpdateChannelPartnerLinkRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::UpdateChannelPartnerLinkRequest'];

coerce 'UpdateChannelPartnerLinkRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::UpdateChannelPartnerLinkRequest'->new($_) };

declare 'RepeatedUpdateChannelPartnerLinkRequest',
    as ArrayRef[UpdateChannelPartnerLinkRequest()];

coerce 'RepeatedUpdateChannelPartnerLinkRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::UpdateChannelPartnerLinkRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateChannelPartnerLinkRequest',
    as HashRef[UpdateChannelPartnerLinkRequest()];

declare 'GetCustomerRepricingConfigRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::GetCustomerRepricingConfigRequest'];

coerce 'GetCustomerRepricingConfigRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::GetCustomerRepricingConfigRequest'->new($_) };

declare 'RepeatedGetCustomerRepricingConfigRequest',
    as ArrayRef[GetCustomerRepricingConfigRequest()];

coerce 'RepeatedGetCustomerRepricingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::GetCustomerRepricingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetCustomerRepricingConfigRequest',
    as HashRef[GetCustomerRepricingConfigRequest()];

declare 'ListCustomerRepricingConfigsRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListCustomerRepricingConfigsRequest'];

coerce 'ListCustomerRepricingConfigsRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListCustomerRepricingConfigsRequest'->new($_) };

declare 'RepeatedListCustomerRepricingConfigsRequest',
    as ArrayRef[ListCustomerRepricingConfigsRequest()];

coerce 'RepeatedListCustomerRepricingConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListCustomerRepricingConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListCustomerRepricingConfigsRequest',
    as HashRef[ListCustomerRepricingConfigsRequest()];

declare 'ListCustomerRepricingConfigsResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListCustomerRepricingConfigsResponse'];

coerce 'ListCustomerRepricingConfigsResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListCustomerRepricingConfigsResponse'->new($_) };

declare 'RepeatedListCustomerRepricingConfigsResponse',
    as ArrayRef[ListCustomerRepricingConfigsResponse()];

coerce 'RepeatedListCustomerRepricingConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListCustomerRepricingConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListCustomerRepricingConfigsResponse',
    as HashRef[ListCustomerRepricingConfigsResponse()];

declare 'CreateCustomerRepricingConfigRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::CreateCustomerRepricingConfigRequest'];

coerce 'CreateCustomerRepricingConfigRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::CreateCustomerRepricingConfigRequest'->new($_) };

declare 'RepeatedCreateCustomerRepricingConfigRequest',
    as ArrayRef[CreateCustomerRepricingConfigRequest()];

coerce 'RepeatedCreateCustomerRepricingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::CreateCustomerRepricingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateCustomerRepricingConfigRequest',
    as HashRef[CreateCustomerRepricingConfigRequest()];

declare 'UpdateCustomerRepricingConfigRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::UpdateCustomerRepricingConfigRequest'];

coerce 'UpdateCustomerRepricingConfigRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::UpdateCustomerRepricingConfigRequest'->new($_) };

declare 'RepeatedUpdateCustomerRepricingConfigRequest',
    as ArrayRef[UpdateCustomerRepricingConfigRequest()];

coerce 'RepeatedUpdateCustomerRepricingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::UpdateCustomerRepricingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateCustomerRepricingConfigRequest',
    as HashRef[UpdateCustomerRepricingConfigRequest()];

declare 'DeleteCustomerRepricingConfigRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::DeleteCustomerRepricingConfigRequest'];

coerce 'DeleteCustomerRepricingConfigRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::DeleteCustomerRepricingConfigRequest'->new($_) };

declare 'RepeatedDeleteCustomerRepricingConfigRequest',
    as ArrayRef[DeleteCustomerRepricingConfigRequest()];

coerce 'RepeatedDeleteCustomerRepricingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::DeleteCustomerRepricingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteCustomerRepricingConfigRequest',
    as HashRef[DeleteCustomerRepricingConfigRequest()];

declare 'GetChannelPartnerRepricingConfigRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::GetChannelPartnerRepricingConfigRequest'];

coerce 'GetChannelPartnerRepricingConfigRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::GetChannelPartnerRepricingConfigRequest'->new($_) };

declare 'RepeatedGetChannelPartnerRepricingConfigRequest',
    as ArrayRef[GetChannelPartnerRepricingConfigRequest()];

coerce 'RepeatedGetChannelPartnerRepricingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::GetChannelPartnerRepricingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringGetChannelPartnerRepricingConfigRequest',
    as HashRef[GetChannelPartnerRepricingConfigRequest()];

declare 'ListChannelPartnerRepricingConfigsRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListChannelPartnerRepricingConfigsRequest'];

coerce 'ListChannelPartnerRepricingConfigsRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListChannelPartnerRepricingConfigsRequest'->new($_) };

declare 'RepeatedListChannelPartnerRepricingConfigsRequest',
    as ArrayRef[ListChannelPartnerRepricingConfigsRequest()];

coerce 'RepeatedListChannelPartnerRepricingConfigsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListChannelPartnerRepricingConfigsRequest'->new($_) } @$_ ] };

declare 'MapStringListChannelPartnerRepricingConfigsRequest',
    as HashRef[ListChannelPartnerRepricingConfigsRequest()];

declare 'ListChannelPartnerRepricingConfigsResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListChannelPartnerRepricingConfigsResponse'];

coerce 'ListChannelPartnerRepricingConfigsResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListChannelPartnerRepricingConfigsResponse'->new($_) };

declare 'RepeatedListChannelPartnerRepricingConfigsResponse',
    as ArrayRef[ListChannelPartnerRepricingConfigsResponse()];

coerce 'RepeatedListChannelPartnerRepricingConfigsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListChannelPartnerRepricingConfigsResponse'->new($_) } @$_ ] };

declare 'MapStringListChannelPartnerRepricingConfigsResponse',
    as HashRef[ListChannelPartnerRepricingConfigsResponse()];

declare 'CreateChannelPartnerRepricingConfigRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::CreateChannelPartnerRepricingConfigRequest'];

coerce 'CreateChannelPartnerRepricingConfigRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::CreateChannelPartnerRepricingConfigRequest'->new($_) };

declare 'RepeatedCreateChannelPartnerRepricingConfigRequest',
    as ArrayRef[CreateChannelPartnerRepricingConfigRequest()];

coerce 'RepeatedCreateChannelPartnerRepricingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::CreateChannelPartnerRepricingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringCreateChannelPartnerRepricingConfigRequest',
    as HashRef[CreateChannelPartnerRepricingConfigRequest()];

declare 'UpdateChannelPartnerRepricingConfigRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::UpdateChannelPartnerRepricingConfigRequest'];

coerce 'UpdateChannelPartnerRepricingConfigRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::UpdateChannelPartnerRepricingConfigRequest'->new($_) };

declare 'RepeatedUpdateChannelPartnerRepricingConfigRequest',
    as ArrayRef[UpdateChannelPartnerRepricingConfigRequest()];

coerce 'RepeatedUpdateChannelPartnerRepricingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::UpdateChannelPartnerRepricingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringUpdateChannelPartnerRepricingConfigRequest',
    as HashRef[UpdateChannelPartnerRepricingConfigRequest()];

declare 'DeleteChannelPartnerRepricingConfigRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::DeleteChannelPartnerRepricingConfigRequest'];

coerce 'DeleteChannelPartnerRepricingConfigRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::DeleteChannelPartnerRepricingConfigRequest'->new($_) };

declare 'RepeatedDeleteChannelPartnerRepricingConfigRequest',
    as ArrayRef[DeleteChannelPartnerRepricingConfigRequest()];

coerce 'RepeatedDeleteChannelPartnerRepricingConfigRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::DeleteChannelPartnerRepricingConfigRequest'->new($_) } @$_ ] };

declare 'MapStringDeleteChannelPartnerRepricingConfigRequest',
    as HashRef[DeleteChannelPartnerRepricingConfigRequest()];

declare 'ListSkuGroupsRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListSkuGroupsRequest'];

coerce 'ListSkuGroupsRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListSkuGroupsRequest'->new($_) };

declare 'RepeatedListSkuGroupsRequest',
    as ArrayRef[ListSkuGroupsRequest()];

coerce 'RepeatedListSkuGroupsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListSkuGroupsRequest'->new($_) } @$_ ] };

declare 'MapStringListSkuGroupsRequest',
    as HashRef[ListSkuGroupsRequest()];

declare 'ListSkuGroupBillableSkusRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListSkuGroupBillableSkusRequest'];

coerce 'ListSkuGroupBillableSkusRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListSkuGroupBillableSkusRequest'->new($_) };

declare 'RepeatedListSkuGroupBillableSkusRequest',
    as ArrayRef[ListSkuGroupBillableSkusRequest()];

coerce 'RepeatedListSkuGroupBillableSkusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListSkuGroupBillableSkusRequest'->new($_) } @$_ ] };

declare 'MapStringListSkuGroupBillableSkusRequest',
    as HashRef[ListSkuGroupBillableSkusRequest()];

declare 'ListSkuGroupsResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListSkuGroupsResponse'];

coerce 'ListSkuGroupsResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListSkuGroupsResponse'->new($_) };

declare 'RepeatedListSkuGroupsResponse',
    as ArrayRef[ListSkuGroupsResponse()];

coerce 'RepeatedListSkuGroupsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListSkuGroupsResponse'->new($_) } @$_ ] };

declare 'MapStringListSkuGroupsResponse',
    as HashRef[ListSkuGroupsResponse()];

declare 'ListSkuGroupBillableSkusResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListSkuGroupBillableSkusResponse'];

coerce 'ListSkuGroupBillableSkusResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListSkuGroupBillableSkusResponse'->new($_) };

declare 'RepeatedListSkuGroupBillableSkusResponse',
    as ArrayRef[ListSkuGroupBillableSkusResponse()];

coerce 'RepeatedListSkuGroupBillableSkusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListSkuGroupBillableSkusResponse'->new($_) } @$_ ] };

declare 'MapStringListSkuGroupBillableSkusResponse',
    as HashRef[ListSkuGroupBillableSkusResponse()];

declare 'SkuGroup',
    as InstanceOf['Google::Cloud::Channel::V1::Service::SkuGroup'];

coerce 'SkuGroup',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::SkuGroup'->new($_) };

declare 'RepeatedSkuGroup',
    as ArrayRef[SkuGroup()];

coerce 'RepeatedSkuGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::SkuGroup'->new($_) } @$_ ] };

declare 'MapStringSkuGroup',
    as HashRef[SkuGroup()];

declare 'BillableSku',
    as InstanceOf['Google::Cloud::Channel::V1::Service::BillableSku'];

coerce 'BillableSku',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::BillableSku'->new($_) };

declare 'RepeatedBillableSku',
    as ArrayRef[BillableSku()];

coerce 'RepeatedBillableSku',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::BillableSku'->new($_) } @$_ ] };

declare 'MapStringBillableSku',
    as HashRef[BillableSku()];

declare 'CreateEntitlementRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::CreateEntitlementRequest'];

coerce 'CreateEntitlementRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::CreateEntitlementRequest'->new($_) };

declare 'RepeatedCreateEntitlementRequest',
    as ArrayRef[CreateEntitlementRequest()];

coerce 'RepeatedCreateEntitlementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::CreateEntitlementRequest'->new($_) } @$_ ] };

declare 'MapStringCreateEntitlementRequest',
    as HashRef[CreateEntitlementRequest()];

declare 'TransferEntitlementsRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::TransferEntitlementsRequest'];

coerce 'TransferEntitlementsRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::TransferEntitlementsRequest'->new($_) };

declare 'RepeatedTransferEntitlementsRequest',
    as ArrayRef[TransferEntitlementsRequest()];

coerce 'RepeatedTransferEntitlementsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::TransferEntitlementsRequest'->new($_) } @$_ ] };

declare 'MapStringTransferEntitlementsRequest',
    as HashRef[TransferEntitlementsRequest()];

declare 'TransferEntitlementsResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::TransferEntitlementsResponse'];

coerce 'TransferEntitlementsResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::TransferEntitlementsResponse'->new($_) };

declare 'RepeatedTransferEntitlementsResponse',
    as ArrayRef[TransferEntitlementsResponse()];

coerce 'RepeatedTransferEntitlementsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::TransferEntitlementsResponse'->new($_) } @$_ ] };

declare 'MapStringTransferEntitlementsResponse',
    as HashRef[TransferEntitlementsResponse()];

declare 'TransferEntitlementsToGoogleRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::TransferEntitlementsToGoogleRequest'];

coerce 'TransferEntitlementsToGoogleRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::TransferEntitlementsToGoogleRequest'->new($_) };

declare 'RepeatedTransferEntitlementsToGoogleRequest',
    as ArrayRef[TransferEntitlementsToGoogleRequest()];

coerce 'RepeatedTransferEntitlementsToGoogleRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::TransferEntitlementsToGoogleRequest'->new($_) } @$_ ] };

declare 'MapStringTransferEntitlementsToGoogleRequest',
    as HashRef[TransferEntitlementsToGoogleRequest()];

declare 'ChangeParametersRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ChangeParametersRequest'];

coerce 'ChangeParametersRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ChangeParametersRequest'->new($_) };

declare 'RepeatedChangeParametersRequest',
    as ArrayRef[ChangeParametersRequest()];

coerce 'RepeatedChangeParametersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ChangeParametersRequest'->new($_) } @$_ ] };

declare 'MapStringChangeParametersRequest',
    as HashRef[ChangeParametersRequest()];

declare 'ChangeRenewalSettingsRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ChangeRenewalSettingsRequest'];

coerce 'ChangeRenewalSettingsRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ChangeRenewalSettingsRequest'->new($_) };

declare 'RepeatedChangeRenewalSettingsRequest',
    as ArrayRef[ChangeRenewalSettingsRequest()];

coerce 'RepeatedChangeRenewalSettingsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ChangeRenewalSettingsRequest'->new($_) } @$_ ] };

declare 'MapStringChangeRenewalSettingsRequest',
    as HashRef[ChangeRenewalSettingsRequest()];

declare 'ChangeOfferRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ChangeOfferRequest'];

coerce 'ChangeOfferRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ChangeOfferRequest'->new($_) };

declare 'RepeatedChangeOfferRequest',
    as ArrayRef[ChangeOfferRequest()];

coerce 'RepeatedChangeOfferRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ChangeOfferRequest'->new($_) } @$_ ] };

declare 'MapStringChangeOfferRequest',
    as HashRef[ChangeOfferRequest()];

declare 'StartPaidServiceRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::StartPaidServiceRequest'];

coerce 'StartPaidServiceRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::StartPaidServiceRequest'->new($_) };

declare 'RepeatedStartPaidServiceRequest',
    as ArrayRef[StartPaidServiceRequest()];

coerce 'RepeatedStartPaidServiceRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::StartPaidServiceRequest'->new($_) } @$_ ] };

declare 'MapStringStartPaidServiceRequest',
    as HashRef[StartPaidServiceRequest()];

declare 'CancelEntitlementRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::CancelEntitlementRequest'];

coerce 'CancelEntitlementRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::CancelEntitlementRequest'->new($_) };

declare 'RepeatedCancelEntitlementRequest',
    as ArrayRef[CancelEntitlementRequest()];

coerce 'RepeatedCancelEntitlementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::CancelEntitlementRequest'->new($_) } @$_ ] };

declare 'MapStringCancelEntitlementRequest',
    as HashRef[CancelEntitlementRequest()];

declare 'SuspendEntitlementRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::SuspendEntitlementRequest'];

coerce 'SuspendEntitlementRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::SuspendEntitlementRequest'->new($_) };

declare 'RepeatedSuspendEntitlementRequest',
    as ArrayRef[SuspendEntitlementRequest()];

coerce 'RepeatedSuspendEntitlementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::SuspendEntitlementRequest'->new($_) } @$_ ] };

declare 'MapStringSuspendEntitlementRequest',
    as HashRef[SuspendEntitlementRequest()];

declare 'ActivateEntitlementRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ActivateEntitlementRequest'];

coerce 'ActivateEntitlementRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ActivateEntitlementRequest'->new($_) };

declare 'RepeatedActivateEntitlementRequest',
    as ArrayRef[ActivateEntitlementRequest()];

coerce 'RepeatedActivateEntitlementRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ActivateEntitlementRequest'->new($_) } @$_ ] };

declare 'MapStringActivateEntitlementRequest',
    as HashRef[ActivateEntitlementRequest()];

declare 'LookupOfferRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::LookupOfferRequest'];

coerce 'LookupOfferRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::LookupOfferRequest'->new($_) };

declare 'RepeatedLookupOfferRequest',
    as ArrayRef[LookupOfferRequest()];

coerce 'RepeatedLookupOfferRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::LookupOfferRequest'->new($_) } @$_ ] };

declare 'MapStringLookupOfferRequest',
    as HashRef[LookupOfferRequest()];

declare 'ListProductsRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListProductsRequest'];

coerce 'ListProductsRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListProductsRequest'->new($_) };

declare 'RepeatedListProductsRequest',
    as ArrayRef[ListProductsRequest()];

coerce 'RepeatedListProductsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListProductsRequest'->new($_) } @$_ ] };

declare 'MapStringListProductsRequest',
    as HashRef[ListProductsRequest()];

declare 'ListProductsResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListProductsResponse'];

coerce 'ListProductsResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListProductsResponse'->new($_) };

declare 'RepeatedListProductsResponse',
    as ArrayRef[ListProductsResponse()];

coerce 'RepeatedListProductsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListProductsResponse'->new($_) } @$_ ] };

declare 'MapStringListProductsResponse',
    as HashRef[ListProductsResponse()];

declare 'ListSkusRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListSkusRequest'];

coerce 'ListSkusRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListSkusRequest'->new($_) };

declare 'RepeatedListSkusRequest',
    as ArrayRef[ListSkusRequest()];

coerce 'RepeatedListSkusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListSkusRequest'->new($_) } @$_ ] };

declare 'MapStringListSkusRequest',
    as HashRef[ListSkusRequest()];

declare 'ListSkusResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListSkusResponse'];

coerce 'ListSkusResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListSkusResponse'->new($_) };

declare 'RepeatedListSkusResponse',
    as ArrayRef[ListSkusResponse()];

coerce 'RepeatedListSkusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListSkusResponse'->new($_) } @$_ ] };

declare 'MapStringListSkusResponse',
    as HashRef[ListSkusResponse()];

declare 'ListOffersRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListOffersRequest'];

coerce 'ListOffersRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListOffersRequest'->new($_) };

declare 'RepeatedListOffersRequest',
    as ArrayRef[ListOffersRequest()];

coerce 'RepeatedListOffersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListOffersRequest'->new($_) } @$_ ] };

declare 'MapStringListOffersRequest',
    as HashRef[ListOffersRequest()];

declare 'ListOffersResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListOffersResponse'];

coerce 'ListOffersResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListOffersResponse'->new($_) };

declare 'RepeatedListOffersResponse',
    as ArrayRef[ListOffersResponse()];

coerce 'RepeatedListOffersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListOffersResponse'->new($_) } @$_ ] };

declare 'MapStringListOffersResponse',
    as HashRef[ListOffersResponse()];

declare 'ListPurchasableSkusRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListPurchasableSkusRequest'];

coerce 'ListPurchasableSkusRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListPurchasableSkusRequest'->new($_) };

declare 'RepeatedListPurchasableSkusRequest',
    as ArrayRef[ListPurchasableSkusRequest()];

coerce 'RepeatedListPurchasableSkusRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListPurchasableSkusRequest'->new($_) } @$_ ] };

declare 'MapStringListPurchasableSkusRequest',
    as HashRef[ListPurchasableSkusRequest()];

declare 'CreateEntitlementPurchase',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListPurchasableSkusRequest::CreateEntitlementPurchase'];

coerce 'CreateEntitlementPurchase',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListPurchasableSkusRequest::CreateEntitlementPurchase'->new($_) };

declare 'RepeatedCreateEntitlementPurchase',
    as ArrayRef[CreateEntitlementPurchase()];

coerce 'RepeatedCreateEntitlementPurchase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListPurchasableSkusRequest::CreateEntitlementPurchase'->new($_) } @$_ ] };

declare 'MapStringCreateEntitlementPurchase',
    as HashRef[CreateEntitlementPurchase()];

declare 'ChangeOfferPurchase',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListPurchasableSkusRequest::ChangeOfferPurchase'];

coerce 'ChangeOfferPurchase',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListPurchasableSkusRequest::ChangeOfferPurchase'->new($_) };

declare 'RepeatedChangeOfferPurchase',
    as ArrayRef[ChangeOfferPurchase()];

coerce 'RepeatedChangeOfferPurchase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListPurchasableSkusRequest::ChangeOfferPurchase'->new($_) } @$_ ] };

declare 'MapStringChangeOfferPurchase',
    as HashRef[ChangeOfferPurchase()];

declare 'ChangeType',
    as (Int | Str);

declare 'ListPurchasableSkusResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListPurchasableSkusResponse'];

coerce 'ListPurchasableSkusResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListPurchasableSkusResponse'->new($_) };

declare 'RepeatedListPurchasableSkusResponse',
    as ArrayRef[ListPurchasableSkusResponse()];

coerce 'RepeatedListPurchasableSkusResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListPurchasableSkusResponse'->new($_) } @$_ ] };

declare 'MapStringListPurchasableSkusResponse',
    as HashRef[ListPurchasableSkusResponse()];

declare 'PurchasableSku',
    as InstanceOf['Google::Cloud::Channel::V1::Service::PurchasableSku'];

coerce 'PurchasableSku',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::PurchasableSku'->new($_) };

declare 'RepeatedPurchasableSku',
    as ArrayRef[PurchasableSku()];

coerce 'RepeatedPurchasableSku',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::PurchasableSku'->new($_) } @$_ ] };

declare 'MapStringPurchasableSku',
    as HashRef[PurchasableSku()];

declare 'ListPurchasableOffersRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListPurchasableOffersRequest'];

coerce 'ListPurchasableOffersRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListPurchasableOffersRequest'->new($_) };

declare 'RepeatedListPurchasableOffersRequest',
    as ArrayRef[ListPurchasableOffersRequest()];

coerce 'RepeatedListPurchasableOffersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListPurchasableOffersRequest'->new($_) } @$_ ] };

declare 'MapStringListPurchasableOffersRequest',
    as HashRef[ListPurchasableOffersRequest()];

declare 'CreateEntitlementPurchase',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListPurchasableOffersRequest::CreateEntitlementPurchase'];

coerce 'CreateEntitlementPurchase',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListPurchasableOffersRequest::CreateEntitlementPurchase'->new($_) };

declare 'RepeatedCreateEntitlementPurchase',
    as ArrayRef[CreateEntitlementPurchase()];

coerce 'RepeatedCreateEntitlementPurchase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListPurchasableOffersRequest::CreateEntitlementPurchase'->new($_) } @$_ ] };

declare 'MapStringCreateEntitlementPurchase',
    as HashRef[CreateEntitlementPurchase()];

declare 'ChangeOfferPurchase',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListPurchasableOffersRequest::ChangeOfferPurchase'];

coerce 'ChangeOfferPurchase',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListPurchasableOffersRequest::ChangeOfferPurchase'->new($_) };

declare 'RepeatedChangeOfferPurchase',
    as ArrayRef[ChangeOfferPurchase()];

coerce 'RepeatedChangeOfferPurchase',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListPurchasableOffersRequest::ChangeOfferPurchase'->new($_) } @$_ ] };

declare 'MapStringChangeOfferPurchase',
    as HashRef[ChangeOfferPurchase()];

declare 'ListPurchasableOffersResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListPurchasableOffersResponse'];

coerce 'ListPurchasableOffersResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListPurchasableOffersResponse'->new($_) };

declare 'RepeatedListPurchasableOffersResponse',
    as ArrayRef[ListPurchasableOffersResponse()];

coerce 'RepeatedListPurchasableOffersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListPurchasableOffersResponse'->new($_) } @$_ ] };

declare 'MapStringListPurchasableOffersResponse',
    as HashRef[ListPurchasableOffersResponse()];

declare 'PurchasableOffer',
    as InstanceOf['Google::Cloud::Channel::V1::Service::PurchasableOffer'];

coerce 'PurchasableOffer',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::PurchasableOffer'->new($_) };

declare 'RepeatedPurchasableOffer',
    as ArrayRef[PurchasableOffer()];

coerce 'RepeatedPurchasableOffer',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::PurchasableOffer'->new($_) } @$_ ] };

declare 'MapStringPurchasableOffer',
    as HashRef[PurchasableOffer()];

declare 'QueryEligibleBillingAccountsRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::QueryEligibleBillingAccountsRequest'];

coerce 'QueryEligibleBillingAccountsRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::QueryEligibleBillingAccountsRequest'->new($_) };

declare 'RepeatedQueryEligibleBillingAccountsRequest',
    as ArrayRef[QueryEligibleBillingAccountsRequest()];

coerce 'RepeatedQueryEligibleBillingAccountsRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::QueryEligibleBillingAccountsRequest'->new($_) } @$_ ] };

declare 'MapStringQueryEligibleBillingAccountsRequest',
    as HashRef[QueryEligibleBillingAccountsRequest()];

declare 'QueryEligibleBillingAccountsResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::QueryEligibleBillingAccountsResponse'];

coerce 'QueryEligibleBillingAccountsResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::QueryEligibleBillingAccountsResponse'->new($_) };

declare 'RepeatedQueryEligibleBillingAccountsResponse',
    as ArrayRef[QueryEligibleBillingAccountsResponse()];

coerce 'RepeatedQueryEligibleBillingAccountsResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::QueryEligibleBillingAccountsResponse'->new($_) } @$_ ] };

declare 'MapStringQueryEligibleBillingAccountsResponse',
    as HashRef[QueryEligibleBillingAccountsResponse()];

declare 'SkuPurchaseGroup',
    as InstanceOf['Google::Cloud::Channel::V1::Service::SkuPurchaseGroup'];

coerce 'SkuPurchaseGroup',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::SkuPurchaseGroup'->new($_) };

declare 'RepeatedSkuPurchaseGroup',
    as ArrayRef[SkuPurchaseGroup()];

coerce 'RepeatedSkuPurchaseGroup',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::SkuPurchaseGroup'->new($_) } @$_ ] };

declare 'MapStringSkuPurchaseGroup',
    as HashRef[SkuPurchaseGroup()];

declare 'BillingAccountPurchaseInfo',
    as InstanceOf['Google::Cloud::Channel::V1::Service::BillingAccountPurchaseInfo'];

coerce 'BillingAccountPurchaseInfo',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::BillingAccountPurchaseInfo'->new($_) };

declare 'RepeatedBillingAccountPurchaseInfo',
    as ArrayRef[BillingAccountPurchaseInfo()];

coerce 'RepeatedBillingAccountPurchaseInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::BillingAccountPurchaseInfo'->new($_) } @$_ ] };

declare 'MapStringBillingAccountPurchaseInfo',
    as HashRef[BillingAccountPurchaseInfo()];

declare 'RegisterSubscriberRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::RegisterSubscriberRequest'];

coerce 'RegisterSubscriberRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::RegisterSubscriberRequest'->new($_) };

declare 'RepeatedRegisterSubscriberRequest',
    as ArrayRef[RegisterSubscriberRequest()];

coerce 'RepeatedRegisterSubscriberRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::RegisterSubscriberRequest'->new($_) } @$_ ] };

declare 'MapStringRegisterSubscriberRequest',
    as HashRef[RegisterSubscriberRequest()];

declare 'RegisterSubscriberResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::RegisterSubscriberResponse'];

coerce 'RegisterSubscriberResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::RegisterSubscriberResponse'->new($_) };

declare 'RepeatedRegisterSubscriberResponse',
    as ArrayRef[RegisterSubscriberResponse()];

coerce 'RepeatedRegisterSubscriberResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::RegisterSubscriberResponse'->new($_) } @$_ ] };

declare 'MapStringRegisterSubscriberResponse',
    as HashRef[RegisterSubscriberResponse()];

declare 'UnregisterSubscriberRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::UnregisterSubscriberRequest'];

coerce 'UnregisterSubscriberRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::UnregisterSubscriberRequest'->new($_) };

declare 'RepeatedUnregisterSubscriberRequest',
    as ArrayRef[UnregisterSubscriberRequest()];

coerce 'RepeatedUnregisterSubscriberRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::UnregisterSubscriberRequest'->new($_) } @$_ ] };

declare 'MapStringUnregisterSubscriberRequest',
    as HashRef[UnregisterSubscriberRequest()];

declare 'UnregisterSubscriberResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::UnregisterSubscriberResponse'];

coerce 'UnregisterSubscriberResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::UnregisterSubscriberResponse'->new($_) };

declare 'RepeatedUnregisterSubscriberResponse',
    as ArrayRef[UnregisterSubscriberResponse()];

coerce 'RepeatedUnregisterSubscriberResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::UnregisterSubscriberResponse'->new($_) } @$_ ] };

declare 'MapStringUnregisterSubscriberResponse',
    as HashRef[UnregisterSubscriberResponse()];

declare 'ListSubscribersRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListSubscribersRequest'];

coerce 'ListSubscribersRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListSubscribersRequest'->new($_) };

declare 'RepeatedListSubscribersRequest',
    as ArrayRef[ListSubscribersRequest()];

coerce 'RepeatedListSubscribersRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListSubscribersRequest'->new($_) } @$_ ] };

declare 'MapStringListSubscribersRequest',
    as HashRef[ListSubscribersRequest()];

declare 'ListSubscribersResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListSubscribersResponse'];

coerce 'ListSubscribersResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListSubscribersResponse'->new($_) };

declare 'RepeatedListSubscribersResponse',
    as ArrayRef[ListSubscribersResponse()];

coerce 'RepeatedListSubscribersResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListSubscribersResponse'->new($_) } @$_ ] };

declare 'MapStringListSubscribersResponse',
    as HashRef[ListSubscribersResponse()];

declare 'ListEntitlementChangesRequest',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListEntitlementChangesRequest'];

coerce 'ListEntitlementChangesRequest',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListEntitlementChangesRequest'->new($_) };

declare 'RepeatedListEntitlementChangesRequest',
    as ArrayRef[ListEntitlementChangesRequest()];

coerce 'RepeatedListEntitlementChangesRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListEntitlementChangesRequest'->new($_) } @$_ ] };

declare 'MapStringListEntitlementChangesRequest',
    as HashRef[ListEntitlementChangesRequest()];

declare 'ListEntitlementChangesResponse',
    as InstanceOf['Google::Cloud::Channel::V1::Service::ListEntitlementChangesResponse'];

coerce 'ListEntitlementChangesResponse',
    from HashRef, via { 'Google::Cloud::Channel::V1::Service::ListEntitlementChangesResponse'->new($_) };

declare 'RepeatedListEntitlementChangesResponse',
    as ArrayRef[ListEntitlementChangesResponse()];

coerce 'RepeatedListEntitlementChangesResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Cloud::Channel::V1::Service::ListEntitlementChangesResponse'->new($_) } @$_ ] };

declare 'MapStringListEntitlementChangesResponse',
    as HashRef[ListEntitlementChangesResponse()];

1;

__END__

=head1 NAME

Google::Cloud::Channel::V1::Service::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
