package Microsoft::AdCenter::V6::CampaignManagementService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V6::CampaignManagementService - Service client for Microsoft AdCenter Campaign Management Service.

=head1 SYNOPSIS

    use Microsoft::AdCenter::V6::CampaignManagementService;

    my $service_client = Microsoft::AdCenter::V6::CampaignManagementService->new
        ->ApplicationToken("application token")
        ->CustomerAccountId("customer account id")
        ->CustomerId("customer id")
        ->DeveloperToken("developer token")
        ->Password("password")
        ->UserName("user name");

    my $response = $service_client->AddAdGroups(
        CampaignId => ...
        AdGroups => ...
    );

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for detailed documentation for this service.

=head1 METHODS

=head2 EndPoint

Changes the end point for this service client.

Default value: https://adcenterapi.microsoft.com/Api/Advertiser/V6/CampaignManagement/CampaignManagementService.svc

=head2 ApplicationToken

Gets/sets ApplicationToken (string) in the request header

=head2 CustomerAccountId

Gets/sets CustomerAccountId (string) in the request header

=head2 CustomerId

Gets/sets CustomerId (string) in the request header

=head2 DeveloperToken

Gets/sets DeveloperToken (string) in the request header

=head2 Password

Gets/sets Password (string) in the request header

=head2 UserName

Gets/sets UserName (string) in the request header

=head2 TrackingId

Gets TrackingId (string) in the response header

=cut

use base qw/Microsoft::AdCenter::Service/;

sub _service_name {
    return 'CampaignManagementService';
}

sub _service_version {
    return 'V6';
}

sub _class_name {
    return 'CampaignManagementService';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v6';
}

sub _default_location {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/V6/CampaignManagement/CampaignManagementService.svc';
}

sub _wsdl {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/v6/CampaignManagement/CampaignManagementService.svc?wsdl';
}

our $_request_headers = [
    { name => 'ApplicationToken', type => 'string', namespace => 'https://adcenter.microsoft.com/v6' },
    { name => 'CustomerAccountId', type => 'string', namespace => 'https://adcenter.microsoft.com/v6' },
    { name => 'CustomerId', type => 'string', namespace => 'https://adcenter.microsoft.com/v6' },
    { name => 'DeveloperToken', type => 'string', namespace => 'https://adcenter.microsoft.com/v6' },
    { name => 'Password', type => 'string', namespace => 'https://adcenter.microsoft.com/v6' },
    { name => 'UserName', type => 'string', namespace => 'https://adcenter.microsoft.com/v6' }
];

our $_request_headers_expanded = {
    ApplicationToken => 'string',
    CustomerAccountId => 'string',
    CustomerId => 'string',
    DeveloperToken => 'string',
    Password => 'string',
    UserName => 'string'
};

sub _request_headers {
    return $_request_headers;
}

sub _request_headers_expanded {
    return $_request_headers_expanded;
}

our $_response_headers = [
    { name => 'TrackingId', type => 'string', namespace => 'https://adcenter.microsoft.com/v6' }
];

our $_response_headers_expanded = {
    TrackingId => 'string'
};

sub _response_headers {
    return $_response_headers;
}

sub _response_headers_expanded {
    return $_response_headers_expanded;
}

=head2 AddAdGroups

=over

=item Parameters:

    CampaignId (long)
    AdGroups (ArrayOfAdGroup)

=item Returns:

    AddAdGroupsResponse

=back

=cut

sub AddAdGroups {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddAdGroups',
        request => {
            name => 'AddAdGroupsRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdGroups', type => 'ArrayOfAdGroup', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'AddAdGroupsResponse'
        },
        parameters => \%args
    );
}

=head2 AddAds

=over

=item Parameters:

    AdGroupId (long)
    Ads (ArrayOfAd)

=item Returns:

    AddAdsResponse

=back

=cut

sub AddAds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddAds',
        request => {
            name => 'AddAdsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'Ads', type => 'ArrayOfAd', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'AddAdsResponse'
        },
        parameters => \%args
    );
}

=head2 AddBehavioralBids

=over

=item Parameters:

    AdGroupId (long)
    BehavioralBids (ArrayOfBehavioralBid)

=item Returns:

    AddBehavioralBidsResponse

=back

=cut

sub AddBehavioralBids {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddBehavioralBids',
        request => {
            name => 'AddBehavioralBidsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'BehavioralBids', type => 'ArrayOfBehavioralBid', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'AddBehavioralBidsResponse'
        },
        parameters => \%args
    );
}

=head2 AddBusinesses

=over

=item Parameters:

    Businesses (ArrayOfBusiness)

=item Returns:

    AddBusinessesResponse

=back

=cut

sub AddBusinesses {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddBusinesses',
        request => {
            name => 'AddBusinessesRequest',
            parameters => [
                { name => 'Businesses', type => 'ArrayOfBusiness', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'AddBusinessesResponse'
        },
        parameters => \%args
    );
}

=head2 AddCampaigns

=over

=item Parameters:

    AccountId (long)
    Campaigns (ArrayOfCampaign)

=item Returns:

    AddCampaignsResponse

=back

=cut

sub AddCampaigns {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddCampaigns',
        request => {
            name => 'AddCampaignsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'Campaigns', type => 'ArrayOfCampaign', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'AddCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 AddKeywords

=over

=item Parameters:

    AdGroupId (long)
    Keywords (ArrayOfKeyword)

=item Returns:

    AddKeywordsResponse

=back

=cut

sub AddKeywords {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddKeywords',
        request => {
            name => 'AddKeywordsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'Keywords', type => 'ArrayOfKeyword', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'AddKeywordsResponse'
        },
        parameters => \%args
    );
}

=head2 AddSegments

=over

=item Parameters:

    Segments (ArrayOfSegment)

=item Returns:

    AddSegmentsResponse

=back

=cut

sub AddSegments {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddSegments',
        request => {
            name => 'AddSegmentsRequest',
            parameters => [
                { name => 'Segments', type => 'ArrayOfSegment', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'AddSegmentsResponse'
        },
        parameters => \%args
    );
}

=head2 AddSitePlacements

=over

=item Parameters:

    AdGroupId (long)
    SitePlacements (ArrayOfSitePlacement)

=item Returns:

    AddSitePlacementsResponse

=back

=cut

sub AddSitePlacements {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddSitePlacements',
        request => {
            name => 'AddSitePlacementsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'SitePlacements', type => 'ArrayOfSitePlacement', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'AddSitePlacementsResponse'
        },
        parameters => \%args
    );
}

=head2 AddTarget

=over

=item Parameters:

    AdGroupId (long)
    Target (Target)

=item Returns:

    AddTargetResponse

=back

=cut

sub AddTarget {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddTarget',
        request => {
            name => 'AddTargetRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'Target', type => 'Target', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'AddTargetResponse'
        },
        parameters => \%args
    );
}

=head2 AddTargetsToLibrary

=over

=item Parameters:

    Targets (ArrayOfTarget)

=item Returns:

    AddTargetsToLibraryResponse

=back

=cut

sub AddTargetsToLibrary {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddTargetsToLibrary',
        request => {
            name => 'AddTargetsToLibraryRequest',
            parameters => [
                { name => 'Targets', type => 'ArrayOfTarget', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'AddTargetsToLibraryResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteAdGroups

=over

=item Parameters:

    CampaignId (long)
    AdGroupIds (ArrayOflong)

=item Returns:

    DeleteAdGroupsResponse

=back

=cut

sub DeleteAdGroups {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteAdGroups',
        request => {
            name => 'DeleteAdGroupsRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteAdGroupsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteAds

=over

=item Parameters:

    AdGroupId (long)
    AdIds (ArrayOflong)

=item Returns:

    DeleteAdsResponse

=back

=cut

sub DeleteAds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteAds',
        request => {
            name => 'DeleteAdsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteAdsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteBehavioralBids

=over

=item Parameters:

    AdGroupId (long)
    BehavioralBidIds (ArrayOflong)

=item Returns:

    DeleteBehavioralBidsResponse

=back

=cut

sub DeleteBehavioralBids {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteBehavioralBids',
        request => {
            name => 'DeleteBehavioralBidsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'BehavioralBidIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteBehavioralBidsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteBusinesses

=over

=item Parameters:

    BusinessIds (ArrayOflong)

=item Returns:

    DeleteBusinessesResponse

=back

=cut

sub DeleteBusinesses {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteBusinesses',
        request => {
            name => 'DeleteBusinessesRequest',
            parameters => [
                { name => 'BusinessIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteBusinessesResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteCampaigns

=over

=item Parameters:

    AccountId (long)
    CampaignIds (ArrayOflong)

=item Returns:

    DeleteCampaignsResponse

=back

=cut

sub DeleteCampaigns {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteCampaigns',
        request => {
            name => 'DeleteCampaignsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteKeywords

=over

=item Parameters:

    AdGroupId (long)
    KeywordIds (ArrayOflong)

=item Returns:

    DeleteKeywordsResponse

=back

=cut

sub DeleteKeywords {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteKeywords',
        request => {
            name => 'DeleteKeywordsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'KeywordIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteKeywordsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteSegments

=over

=item Parameters:

    SegmentIds (ArrayOflong)

=item Returns:

    DeleteSegmentsResponse

=back

=cut

sub DeleteSegments {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteSegments',
        request => {
            name => 'DeleteSegmentsRequest',
            parameters => [
                { name => 'SegmentIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteSegmentsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteSitePlacements

=over

=item Parameters:

    AdGroupId (long)
    SitePlacementIds (ArrayOflong)

=item Returns:

    DeleteSitePlacementsResponse

=back

=cut

sub DeleteSitePlacements {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteSitePlacements',
        request => {
            name => 'DeleteSitePlacementsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'SitePlacementIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteSitePlacementsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteTarget

=over

=item Parameters:

    AdGroupId (long)

=item Returns:

    DeleteTargetResponse

=back

=cut

sub DeleteTarget {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteTarget',
        request => {
            name => 'DeleteTargetRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteTargetResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteTargetFromAdGroup

=over

=item Parameters:

    AdGroupId (long)

=item Returns:

    DeleteTargetFromAdGroupResponse

=back

=cut

sub DeleteTargetFromAdGroup {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteTargetFromAdGroup',
        request => {
            name => 'DeleteTargetFromAdGroupRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteTargetFromAdGroupResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteTargetFromCampaign

=over

=item Parameters:

    CampaignId (long)

=item Returns:

    DeleteTargetFromCampaignResponse

=back

=cut

sub DeleteTargetFromCampaign {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteTargetFromCampaign',
        request => {
            name => 'DeleteTargetFromCampaignRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteTargetFromCampaignResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteTargetsFromLibrary

=over

=item Parameters:

    TargetIds (ArrayOflong)

=item Returns:

    DeleteTargetsFromLibraryResponse

=back

=cut

sub DeleteTargetsFromLibrary {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteTargetsFromLibrary',
        request => {
            name => 'DeleteTargetsFromLibraryRequest',
            parameters => [
                { name => 'TargetIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteTargetsFromLibraryResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteUsersFromSegment

=over

=item Parameters:

    UserHash (ArrayOfbase64Binary)

=item Returns:

    DeleteUsersFromSegmentResponse

=back

=cut

sub DeleteUsersFromSegment {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteUsersFromSegment',
        request => {
            name => 'DeleteUsersFromSegmentRequest',
            parameters => [
                { name => 'UserHash', type => 'ArrayOfbase64Binary', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'DeleteUsersFromSegmentResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdGroupsByCampaignId

=over

=item Parameters:

    CampaignId (long)

=item Returns:

    GetAdGroupsByCampaignIdResponse

=back

=cut

sub GetAdGroupsByCampaignId {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdGroupsByCampaignId',
        request => {
            name => 'GetAdGroupsByCampaignIdRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetAdGroupsByCampaignIdResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdGroupsByIds

=over

=item Parameters:

    CampaignId (long)
    AdGroupIds (ArrayOflong)

=item Returns:

    GetAdGroupsByIdsResponse

=back

=cut

sub GetAdGroupsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdGroupsByIds',
        request => {
            name => 'GetAdGroupsByIdsRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetAdGroupsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdGroupsInfoByCampaignId

=over

=item Parameters:

    CampaignId (long)

=item Returns:

    GetAdGroupsInfoByCampaignIdResponse

=back

=cut

sub GetAdGroupsInfoByCampaignId {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdGroupsInfoByCampaignId',
        request => {
            name => 'GetAdGroupsInfoByCampaignIdRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetAdGroupsInfoByCampaignIdResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdsByAdGroupId

=over

=item Parameters:

    AdGroupId (long)

=item Returns:

    GetAdsByAdGroupIdResponse

=back

=cut

sub GetAdsByAdGroupId {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdsByAdGroupId',
        request => {
            name => 'GetAdsByAdGroupIdRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetAdsByAdGroupIdResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdsByEditorialStatus

=over

=item Parameters:

    AdGroupId (long)
    EditorialStatus (AdEditorialStatus)

=item Returns:

    GetAdsByEditorialStatusResponse

=back

=cut

sub GetAdsByEditorialStatus {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdsByEditorialStatus',
        request => {
            name => 'GetAdsByEditorialStatusRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'EditorialStatus', type => 'AdEditorialStatus', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetAdsByEditorialStatusResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdsByIds

=over

=item Parameters:

    AdGroupId (long)
    AdIds (ArrayOflong)

=item Returns:

    GetAdsByIdsResponse

=back

=cut

sub GetAdsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdsByIds',
        request => {
            name => 'GetAdsByIdsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetAdsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetBehavioralBidsByAdGroupId

=over

=item Parameters:

    AdGroupId (long)

=item Returns:

    GetBehavioralBidsByAdGroupIdResponse

=back

=cut

sub GetBehavioralBidsByAdGroupId {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetBehavioralBidsByAdGroupId',
        request => {
            name => 'GetBehavioralBidsByAdGroupIdRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetBehavioralBidsByAdGroupIdResponse'
        },
        parameters => \%args
    );
}

=head2 GetBehavioralBidsByIds

=over

=item Parameters:

    AdGroupId (long)
    BehavioralBidIds (ArrayOflong)

=item Returns:

    GetBehavioralBidsByIdsResponse

=back

=cut

sub GetBehavioralBidsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetBehavioralBidsByIds',
        request => {
            name => 'GetBehavioralBidsByIdsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'BehavioralBidIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetBehavioralBidsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetBusinessesByIds

=over

=item Parameters:

    BusinessIds (ArrayOflong)

=item Returns:

    GetBusinessesByIdsResponse

=back

=cut

sub GetBusinessesByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetBusinessesByIds',
        request => {
            name => 'GetBusinessesByIdsRequest',
            parameters => [
                { name => 'BusinessIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetBusinessesByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetBusinessesInfo

=over

=item Parameters:


=item Returns:

    GetBusinessesInfoResponse

=back

=cut

sub GetBusinessesInfo {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetBusinessesInfo',
        request => {
            name => 'GetBusinessesInfoRequest',
            parameters => [
            ]
        },
        response => {
            name => 'GetBusinessesInfoResponse'
        },
        parameters => \%args
    );
}

=head2 GetCampaignsByAccountId

=over

=item Parameters:

    AccountId (long)

=item Returns:

    GetCampaignsByAccountIdResponse

=back

=cut

sub GetCampaignsByAccountId {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetCampaignsByAccountId',
        request => {
            name => 'GetCampaignsByAccountIdRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetCampaignsByAccountIdResponse'
        },
        parameters => \%args
    );
}

=head2 GetCampaignsByIds

=over

=item Parameters:

    AccountId (long)
    CampaignIds (ArrayOflong)

=item Returns:

    GetCampaignsByIdsResponse

=back

=cut

sub GetCampaignsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetCampaignsByIds',
        request => {
            name => 'GetCampaignsByIdsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetCampaignsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetCampaignsInfoByAccountId

=over

=item Parameters:

    AccountId (long)

=item Returns:

    GetCampaignsInfoByAccountIdResponse

=back

=cut

sub GetCampaignsInfoByAccountId {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetCampaignsInfoByAccountId',
        request => {
            name => 'GetCampaignsInfoByAccountIdRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetCampaignsInfoByAccountIdResponse'
        },
        parameters => \%args
    );
}

=head2 GetCustomSegments

=over

=item Parameters:


=item Returns:

    GetCustomSegmentsResponse

=back

=cut

sub GetCustomSegments {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetCustomSegments',
        request => {
            name => 'GetCustomSegmentsRequest',
            parameters => [
            ]
        },
        response => {
            name => 'GetCustomSegmentsResponse'
        },
        parameters => \%args
    );
}

=head2 GetKeywordEstimatesByBids

=over

=item Parameters:

    AccountId (long)
    LanguageAndRegion (string)
    Currency (string)
    KeywordBids (ArrayOfKeywordBid)
    PricingModel (PricingModel)

=item Returns:

    GetKeywordEstimatesByBidsResponse

=back

=cut

sub GetKeywordEstimatesByBids {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetKeywordEstimatesByBids',
        request => {
            name => 'GetKeywordEstimatesByBidsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'LanguageAndRegion', type => 'string', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'Currency', type => 'string', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'KeywordBids', type => 'ArrayOfKeywordBid', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'PricingModel', type => 'PricingModel', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetKeywordEstimatesByBidsResponse'
        },
        parameters => \%args
    );
}

=head2 GetKeywordsByAdGroupId

=over

=item Parameters:

    AdGroupId (long)

=item Returns:

    GetKeywordsByAdGroupIdResponse

=back

=cut

sub GetKeywordsByAdGroupId {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetKeywordsByAdGroupId',
        request => {
            name => 'GetKeywordsByAdGroupIdRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetKeywordsByAdGroupIdResponse'
        },
        parameters => \%args
    );
}

=head2 GetKeywordsByEditorialStatus

=over

=item Parameters:

    AdGroupId (long)
    EditorialStatus (KeywordEditorialStatus)

=item Returns:

    GetKeywordsByEditorialStatusResponse

=back

=cut

sub GetKeywordsByEditorialStatus {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetKeywordsByEditorialStatus',
        request => {
            name => 'GetKeywordsByEditorialStatusRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'EditorialStatus', type => 'KeywordEditorialStatus', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetKeywordsByEditorialStatusResponse'
        },
        parameters => \%args
    );
}

=head2 GetKeywordsByIds

=over

=item Parameters:

    AdGroupId (long)
    KeywordIds (ArrayOflong)

=item Returns:

    GetKeywordsByIdsResponse

=back

=cut

sub GetKeywordsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetKeywordsByIds',
        request => {
            name => 'GetKeywordsByIdsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'KeywordIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetKeywordsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetNegativeKeywordsByAdGroupIds

=over

=item Parameters:

    CampaignId (long)
    AdGroupIds (ArrayOflong)

=item Returns:

    GetNegativeKeywordsByAdGroupIdsResponse

=back

=cut

sub GetNegativeKeywordsByAdGroupIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetNegativeKeywordsByAdGroupIds',
        request => {
            name => 'GetNegativeKeywordsByAdGroupIdsRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetNegativeKeywordsByAdGroupIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetNegativeKeywordsByCampaignIds

=over

=item Parameters:

    AccountId (long)
    CampaignIds (ArrayOflong)

=item Returns:

    GetNegativeKeywordsByCampaignIdsResponse

=back

=cut

sub GetNegativeKeywordsByCampaignIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetNegativeKeywordsByCampaignIds',
        request => {
            name => 'GetNegativeKeywordsByCampaignIdsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetNegativeKeywordsByCampaignIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetPlacementDetailsForUrls

=over

=item Parameters:

    Urls (ArrayOfstring)

=item Returns:

    GetPlacementDetailsForUrlsResponse

=back

=cut

sub GetPlacementDetailsForUrls {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetPlacementDetailsForUrls',
        request => {
            name => 'GetPlacementDetailsForUrlsRequest',
            parameters => [
                { name => 'Urls', type => 'ArrayOfstring', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetPlacementDetailsForUrlsResponse'
        },
        parameters => \%args
    );
}

=head2 GetSegments

=over

=item Parameters:


=item Returns:

    GetSegmentsResponse

=back

=cut

sub GetSegments {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetSegments',
        request => {
            name => 'GetSegmentsRequest',
            parameters => [
            ]
        },
        response => {
            name => 'GetSegmentsResponse'
        },
        parameters => \%args
    );
}

=head2 GetSegmentsByIds

=over

=item Parameters:

    SegmentIds (ArrayOflong)

=item Returns:

    GetSegmentsByIdsResponse

=back

=cut

sub GetSegmentsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetSegmentsByIds',
        request => {
            name => 'GetSegmentsByIdsRequest',
            parameters => [
                { name => 'SegmentIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetSegmentsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetSitePlacementsByAdGroupId

=over

=item Parameters:

    AdGroupId (long)

=item Returns:

    GetSitePlacementsByAdGroupIdResponse

=back

=cut

sub GetSitePlacementsByAdGroupId {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetSitePlacementsByAdGroupId',
        request => {
            name => 'GetSitePlacementsByAdGroupIdRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetSitePlacementsByAdGroupIdResponse'
        },
        parameters => \%args
    );
}

=head2 GetSitePlacementsByIds

=over

=item Parameters:

    AdGroupId (long)
    SitePlacementIds (ArrayOflong)

=item Returns:

    GetSitePlacementsByIdsResponse

=back

=cut

sub GetSitePlacementsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetSitePlacementsByIds',
        request => {
            name => 'GetSitePlacementsByIdsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'SitePlacementIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetSitePlacementsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetTargetByAdGroupId

=over

=item Parameters:

    AdGroupId (long)

=item Returns:

    GetTargetByAdGroupIdResponse

=back

=cut

sub GetTargetByAdGroupId {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetTargetByAdGroupId',
        request => {
            name => 'GetTargetByAdGroupIdRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetTargetByAdGroupIdResponse'
        },
        parameters => \%args
    );
}

=head2 GetTargetsByAdGroupIds

=over

=item Parameters:

    AdGroupIds (ArrayOflong)

=item Returns:

    GetTargetsByAdGroupIdsResponse

=back

=cut

sub GetTargetsByAdGroupIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetTargetsByAdGroupIds',
        request => {
            name => 'GetTargetsByAdGroupIdsRequest',
            parameters => [
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetTargetsByAdGroupIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetTargetsByCampaignIds

=over

=item Parameters:

    CampaignIds (ArrayOflong)

=item Returns:

    GetTargetsByCampaignIdsResponse

=back

=cut

sub GetTargetsByCampaignIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetTargetsByCampaignIds',
        request => {
            name => 'GetTargetsByCampaignIdsRequest',
            parameters => [
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetTargetsByCampaignIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetTargetsByIds

=over

=item Parameters:

    TargetIds (ArrayOflong)

=item Returns:

    GetTargetsByIdsResponse

=back

=cut

sub GetTargetsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetTargetsByIds',
        request => {
            name => 'GetTargetsByIdsRequest',
            parameters => [
                { name => 'TargetIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'GetTargetsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetTargetsInfoFromLibrary

=over

=item Parameters:


=item Returns:

    GetTargetsInfoFromLibraryResponse

=back

=cut

sub GetTargetsInfoFromLibrary {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetTargetsInfoFromLibrary',
        request => {
            name => 'GetTargetsInfoFromLibraryRequest',
            parameters => [
            ]
        },
        response => {
            name => 'GetTargetsInfoFromLibraryResponse'
        },
        parameters => \%args
    );
}

=head2 PauseAdGroups

=over

=item Parameters:

    CampaignId (long)
    AdGroupIds (ArrayOflong)

=item Returns:

    PauseAdGroupsResponse

=back

=cut

sub PauseAdGroups {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'PauseAdGroups',
        request => {
            name => 'PauseAdGroupsRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'PauseAdGroupsResponse'
        },
        parameters => \%args
    );
}

=head2 PauseAds

=over

=item Parameters:

    AdGroupId (long)
    AdIds (ArrayOflong)

=item Returns:

    PauseAdsResponse

=back

=cut

sub PauseAds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'PauseAds',
        request => {
            name => 'PauseAdsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'PauseAdsResponse'
        },
        parameters => \%args
    );
}

=head2 PauseBehavioralBids

=over

=item Parameters:

    AdGroupId (long)
    BehavioralBidIds (ArrayOflong)

=item Returns:

    PauseBehavioralBidsResponse

=back

=cut

sub PauseBehavioralBids {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'PauseBehavioralBids',
        request => {
            name => 'PauseBehavioralBidsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'BehavioralBidIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'PauseBehavioralBidsResponse'
        },
        parameters => \%args
    );
}

=head2 PauseCampaigns

=over

=item Parameters:

    AccountId (long)
    CampaignIds (ArrayOflong)

=item Returns:

    PauseCampaignsResponse

=back

=cut

sub PauseCampaigns {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'PauseCampaigns',
        request => {
            name => 'PauseCampaignsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'PauseCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 PauseKeywords

=over

=item Parameters:

    AdGroupId (long)
    KeywordIds (ArrayOflong)

=item Returns:

    PauseKeywordsResponse

=back

=cut

sub PauseKeywords {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'PauseKeywords',
        request => {
            name => 'PauseKeywordsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'KeywordIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'PauseKeywordsResponse'
        },
        parameters => \%args
    );
}

=head2 PauseSitePlacements

=over

=item Parameters:

    AdGroupId (long)
    SitePlacementIds (ArrayOflong)

=item Returns:

    PauseSitePlacementsResponse

=back

=cut

sub PauseSitePlacements {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'PauseSitePlacements',
        request => {
            name => 'PauseSitePlacementsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'SitePlacementIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'PauseSitePlacementsResponse'
        },
        parameters => \%args
    );
}

=head2 ResumeAdGroups

=over

=item Parameters:

    CampaignId (long)
    AdGroupIds (ArrayOflong)

=item Returns:

    ResumeAdGroupsResponse

=back

=cut

sub ResumeAdGroups {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'ResumeAdGroups',
        request => {
            name => 'ResumeAdGroupsRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'ResumeAdGroupsResponse'
        },
        parameters => \%args
    );
}

=head2 ResumeAds

=over

=item Parameters:

    AdGroupId (long)
    AdIds (ArrayOflong)

=item Returns:

    ResumeAdsResponse

=back

=cut

sub ResumeAds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'ResumeAds',
        request => {
            name => 'ResumeAdsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'ResumeAdsResponse'
        },
        parameters => \%args
    );
}

=head2 ResumeBehavioralBids

=over

=item Parameters:

    AdGroupId (long)
    BehavioralBidIds (ArrayOflong)

=item Returns:

    ResumeBehavioralBidsResponse

=back

=cut

sub ResumeBehavioralBids {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'ResumeBehavioralBids',
        request => {
            name => 'ResumeBehavioralBidsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'BehavioralBidIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'ResumeBehavioralBidsResponse'
        },
        parameters => \%args
    );
}

=head2 ResumeCampaigns

=over

=item Parameters:

    AccountId (long)
    CampaignIds (ArrayOflong)

=item Returns:

    ResumeCampaignsResponse

=back

=cut

sub ResumeCampaigns {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'ResumeCampaigns',
        request => {
            name => 'ResumeCampaignsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'ResumeCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 ResumeKeywords

=over

=item Parameters:

    AdGroupId (long)
    KeywordIds (ArrayOflong)

=item Returns:

    ResumeKeywordsResponse

=back

=cut

sub ResumeKeywords {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'ResumeKeywords',
        request => {
            name => 'ResumeKeywordsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'KeywordIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'ResumeKeywordsResponse'
        },
        parameters => \%args
    );
}

=head2 ResumeSitePlacements

=over

=item Parameters:

    AdGroupId (long)
    SitePlacementIds (ArrayOflong)

=item Returns:

    ResumeSitePlacementsResponse

=back

=cut

sub ResumeSitePlacements {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'ResumeSitePlacements',
        request => {
            name => 'ResumeSitePlacementsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'SitePlacementIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'ResumeSitePlacementsResponse'
        },
        parameters => \%args
    );
}

=head2 SetNegativeKeywordsToAdGroups

=over

=item Parameters:

    CampaignId (long)
    AdGroupNegativeKeywords (ArrayOfAdGroupNegativeKeywords)

=item Returns:

    SetNegativeKeywordsToAdGroupsResponse

=back

=cut

sub SetNegativeKeywordsToAdGroups {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetNegativeKeywordsToAdGroups',
        request => {
            name => 'SetNegativeKeywordsToAdGroupsRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdGroupNegativeKeywords', type => 'ArrayOfAdGroupNegativeKeywords', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'SetNegativeKeywordsToAdGroupsResponse'
        },
        parameters => \%args
    );
}

=head2 SetNegativeKeywordsToCampaigns

=over

=item Parameters:

    AccountId (long)
    CampaignNegativeKeywords (ArrayOfCampaignNegativeKeywords)

=item Returns:

    SetNegativeKeywordsToCampaignsResponse

=back

=cut

sub SetNegativeKeywordsToCampaigns {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetNegativeKeywordsToCampaigns',
        request => {
            name => 'SetNegativeKeywordsToCampaignsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'CampaignNegativeKeywords', type => 'ArrayOfCampaignNegativeKeywords', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'SetNegativeKeywordsToCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 SetTargetToAdGroup

=over

=item Parameters:

    AdGroupId (long)
    TargetId (long)

=item Returns:

    SetTargetToAdGroupResponse

=back

=cut

sub SetTargetToAdGroup {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetTargetToAdGroup',
        request => {
            name => 'SetTargetToAdGroupRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'TargetId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'SetTargetToAdGroupResponse'
        },
        parameters => \%args
    );
}

=head2 SetTargetToCampaign

=over

=item Parameters:

    CampaignId (long)
    TargetId (long)

=item Returns:

    SetTargetToCampaignResponse

=back

=cut

sub SetTargetToCampaign {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetTargetToCampaign',
        request => {
            name => 'SetTargetToCampaignRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'TargetId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'SetTargetToCampaignResponse'
        },
        parameters => \%args
    );
}

=head2 SetUsersToSegments

=over

=item Parameters:

    SegmentId (long)
    UserHash (ArrayOfbase64Binary)

=item Returns:

    SetUsersToSegmentsResponse

=back

=cut

sub SetUsersToSegments {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetUsersToSegments',
        request => {
            name => 'SetUsersToSegmentsRequest',
            parameters => [
                { name => 'SegmentId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'UserHash', type => 'ArrayOfbase64Binary', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'SetUsersToSegmentsResponse'
        },
        parameters => \%args
    );
}

=head2 SubmitAdGroupForApproval

=over

=item Parameters:

    AdGroupId (long)

=item Returns:

    SubmitAdGroupForApprovalResponse

=back

=cut

sub SubmitAdGroupForApproval {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SubmitAdGroupForApproval',
        request => {
            name => 'SubmitAdGroupForApprovalRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'SubmitAdGroupForApprovalResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateAdGroups

=over

=item Parameters:

    CampaignId (long)
    AdGroups (ArrayOfAdGroup)

=item Returns:

    UpdateAdGroupsResponse

=back

=cut

sub UpdateAdGroups {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateAdGroups',
        request => {
            name => 'UpdateAdGroupsRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'AdGroups', type => 'ArrayOfAdGroup', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'UpdateAdGroupsResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateAds

=over

=item Parameters:

    AdGroupId (long)
    Ads (ArrayOfAd)

=item Returns:

    UpdateAdsResponse

=back

=cut

sub UpdateAds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateAds',
        request => {
            name => 'UpdateAdsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'Ads', type => 'ArrayOfAd', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'UpdateAdsResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateBehavioralBids

=over

=item Parameters:

    AdGroupId (long)
    BehavioralBids (ArrayOfBehavioralBid)

=item Returns:

    UpdateBehavioralBidsResponse

=back

=cut

sub UpdateBehavioralBids {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateBehavioralBids',
        request => {
            name => 'UpdateBehavioralBidsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'BehavioralBids', type => 'ArrayOfBehavioralBid', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'UpdateBehavioralBidsResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateBusinesses

=over

=item Parameters:

    Businesses (ArrayOfBusiness)

=item Returns:

    UpdateBusinessesResponse

=back

=cut

sub UpdateBusinesses {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateBusinesses',
        request => {
            name => 'UpdateBusinessesRequest',
            parameters => [
                { name => 'Businesses', type => 'ArrayOfBusiness', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'UpdateBusinessesResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateCampaigns

=over

=item Parameters:

    AccountId (long)
    Campaigns (ArrayOfCampaign)

=item Returns:

    UpdateCampaignsResponse

=back

=cut

sub UpdateCampaigns {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateCampaigns',
        request => {
            name => 'UpdateCampaignsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'Campaigns', type => 'ArrayOfCampaign', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'UpdateCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateKeywords

=over

=item Parameters:

    AdGroupId (long)
    Keywords (ArrayOfKeyword)

=item Returns:

    UpdateKeywordsResponse

=back

=cut

sub UpdateKeywords {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateKeywords',
        request => {
            name => 'UpdateKeywordsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'Keywords', type => 'ArrayOfKeyword', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'UpdateKeywordsResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateSitePlacements

=over

=item Parameters:

    AdGroupId (long)
    SitePlacements (ArrayOfSitePlacement)

=item Returns:

    UpdateSitePlacementsResponse

=back

=cut

sub UpdateSitePlacements {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateSitePlacements',
        request => {
            name => 'UpdateSitePlacementsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'SitePlacements', type => 'ArrayOfSitePlacement', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'UpdateSitePlacementsResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateTarget

=over

=item Parameters:

    AdGroupId (long)
    Target (Target)

=item Returns:

    UpdateTargetResponse

=back

=cut

sub UpdateTarget {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateTarget',
        request => {
            name => 'UpdateTargetRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v6' },
                { name => 'Target', type => 'Target', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'UpdateTargetResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateTargetsInLibrary

=over

=item Parameters:

    Targets (ArrayOfTarget)

=item Returns:

    UpdateTargetsInLibraryResponse

=back

=cut

sub UpdateTargetsInLibrary {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateTargetsInLibrary',
        request => {
            name => 'UpdateTargetsInLibraryRequest',
            parameters => [
                { name => 'Targets', type => 'ArrayOfTarget', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'UpdateTargetsInLibraryResponse'
        },
        parameters => \%args
    );
}

our %_simple_types = (
    AdDistribution => 'https://adcenter.microsoft.com/v6',
    AdEditorialStatus => 'https://adcenter.microsoft.com/v6',
    AdGroupStatus => 'https://adcenter.microsoft.com/v6',
    AdStatus => 'https://adcenter.microsoft.com/v6',
    AdType => 'https://adcenter.microsoft.com/v6',
    AgeRange => 'https://adcenter.microsoft.com/v6',
    BehavioralBidStatus => 'https://adcenter.microsoft.com/v6',
    BiddingModel => 'https://adcenter.microsoft.com/v6',
    BudgetLimitType => 'https://adcenter.microsoft.com/v6',
    BusinessGeoCodeStatus => 'https://adcenter.microsoft.com/v6',
    BusinessStatus => 'https://adcenter.microsoft.com/v6',
    CampaignStatus => 'https://adcenter.microsoft.com/v6',
    CashBackStatus => 'https://adcenter.microsoft.com/v6',
    Day => 'https://adcenter.microsoft.com/v6',
    GenderType => 'https://adcenter.microsoft.com/v6',
    HourRange => 'https://adcenter.microsoft.com/v6',
    IncrementalBidPercentage => 'https://adcenter.microsoft.com/v6',
    KeywordEditorialStatus => 'https://adcenter.microsoft.com/v6',
    KeywordStatus => 'https://adcenter.microsoft.com/v6',
    OverridePriority => 'https://adcenter.microsoft.com/v6',
    PaymentType => 'https://adcenter.microsoft.com/v6',
    PricingModel => 'https://adcenter.microsoft.com/v6',
    SitePlacementStatus => 'https://adcenter.microsoft.com/v6',
    StandardBusinessIcon => 'https://adcenter.microsoft.com/v6',
    char => 'http://schemas.microsoft.com/2003/10/Serialization/',
    duration => 'http://schemas.microsoft.com/2003/10/Serialization/',
    guid => 'http://schemas.microsoft.com/2003/10/Serialization/',
);

sub _simple_types {
    return %_simple_types;
}

our @_complex_types = (qw/
    Ad
    AdApiError
    AdApiFaultDetail
    AdGroup
    AdGroupInfo
    AdGroupNegativeKeywords
    AddAdGroupsResponse
    AddAdsResponse
    AddBehavioralBidsResponse
    AddBusinessesResponse
    AddCampaignsResponse
    AddKeywordsResponse
    AddSegmentsResponse
    AddSitePlacementsResponse
    AddTargetResponse
    AddTargetsToLibraryResponse
    AgeTarget
    AgeTargetBid
    ApiFaultDetail
    ApplicationFault
    BatchError
    BehavioralBid
    BehavioralTarget
    BehavioralTargetBid
    Bid
    Business
    BusinessImageIcon
    BusinessInfo
    BusinessTarget
    BusinessTargetBid
    Campaign
    CampaignInfo
    CampaignNegativeKeywords
    CashBackInfo
    CityTarget
    CityTargetBid
    CountryTarget
    CountryTargetBid
    Date
    DayTarget
    DayTargetBid
    DayTimeInterval
    DeleteAdGroupsResponse
    DeleteAdsResponse
    DeleteBehavioralBidsResponse
    DeleteBusinessesResponse
    DeleteCampaignsResponse
    DeleteKeywordsResponse
    DeleteSegmentsResponse
    DeleteSitePlacementsResponse
    DeleteTargetFromAdGroupResponse
    DeleteTargetFromCampaignResponse
    DeleteTargetResponse
    DeleteTargetsFromLibraryResponse
    DeleteUsersFromSegmentResponse
    Dimension
    EditorialApiFaultDetail
    EditorialError
    GenderTarget
    GenderTargetBid
    GetAdGroupsByCampaignIdResponse
    GetAdGroupsByIdsResponse
    GetAdGroupsInfoByCampaignIdResponse
    GetAdsByAdGroupIdResponse
    GetAdsByEditorialStatusResponse
    GetAdsByIdsResponse
    GetBehavioralBidsByAdGroupIdResponse
    GetBehavioralBidsByIdsResponse
    GetBusinessesByIdsResponse
    GetBusinessesInfoResponse
    GetCampaignsByAccountIdResponse
    GetCampaignsByIdsResponse
    GetCampaignsInfoByAccountIdResponse
    GetCustomSegmentsResponse
    GetKeywordEstimatesByBidsResponse
    GetKeywordsByAdGroupIdResponse
    GetKeywordsByEditorialStatusResponse
    GetKeywordsByIdsResponse
    GetNegativeKeywordsByAdGroupIdsResponse
    GetNegativeKeywordsByCampaignIdsResponse
    GetPlacementDetailsForUrlsResponse
    GetSegmentsByIdsResponse
    GetSegmentsResponse
    GetSitePlacementsByAdGroupIdResponse
    GetSitePlacementsByIdsResponse
    GetTargetByAdGroupIdResponse
    GetTargetsByAdGroupIdsResponse
    GetTargetsByCampaignIdsResponse
    GetTargetsByIdsResponse
    GetTargetsInfoFromLibraryResponse
    HourTarget
    HourTargetBid
    HoursOfOperation
    ImpressionsPerDayRange
    Keyword
    KeywordBid
    KeywordEstimate
    LocationTarget
    MatchTypeEstimate
    MediaType
    MetroAreaTarget
    MetroAreaTargetBid
    MobileAd
    OperationError
    PauseAdGroupsResponse
    PauseAdsResponse
    PauseBehavioralBidsResponse
    PauseCampaignsResponse
    PauseKeywordsResponse
    PauseSitePlacementsResponse
    PlacementDetail
    RadiusTarget
    RadiusTargetBid
    ResumeAdGroupsResponse
    ResumeAdsResponse
    ResumeBehavioralBidsResponse
    ResumeCampaignsResponse
    ResumeKeywordsResponse
    ResumeSitePlacementsResponse
    Segment
    SegmentTarget
    SegmentTargetBid
    SetNegativeKeywordsToAdGroupsResponse
    SetNegativeKeywordsToCampaignsResponse
    SetTargetToAdGroupResponse
    SetTargetToCampaignResponse
    SetUsersToSegmentsResponse
    SitePlacement
    StateTarget
    StateTargetBid
    SubmitAdGroupForApprovalResponse
    Target
    TargetInfo
    TextAd
    TimeOfTheDay
    UpdateAdGroupsResponse
    UpdateAdsResponse
    UpdateBehavioralBidsResponse
    UpdateBusinessesResponse
    UpdateCampaignsResponse
    UpdateKeywordsResponse
    UpdateSitePlacementsResponse
    UpdateTargetResponse
    UpdateTargetsInLibraryResponse
/);

sub _complex_types {
    return @_complex_types;
}

our %_array_types = (
    ArrayOfAd => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'Ad',
        element_type => 'Ad'
    },
    ArrayOfAdApiError => {
        namespace_uri => 'https://adapi.microsoft.com',
        element_name => 'AdApiError',
        element_type => 'AdApiError'
    },
    ArrayOfAdGroup => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'AdGroup',
        element_type => 'AdGroup'
    },
    ArrayOfAdGroupInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'AdGroupInfo',
        element_type => 'AdGroupInfo'
    },
    ArrayOfAdGroupNegativeKeywords => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'AdGroupNegativeKeywords',
        element_type => 'AdGroupNegativeKeywords'
    },
    ArrayOfAgeTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'AgeTargetBid',
        element_type => 'AgeTargetBid'
    },
    ArrayOfArrayOfPlacementDetail => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'ArrayOfPlacementDetail',
        element_type => 'ArrayOfPlacementDetail'
    },
    ArrayOfBatchError => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'BatchError',
        element_type => 'BatchError'
    },
    ArrayOfBehavioralBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'BehavioralBid',
        element_type => 'BehavioralBid'
    },
    ArrayOfBehavioralTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'BehavioralTargetBid',
        element_type => 'BehavioralTargetBid'
    },
    ArrayOfBusiness => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'Business',
        element_type => 'Business'
    },
    ArrayOfBusinessInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'BusinessInfo',
        element_type => 'BusinessInfo'
    },
    ArrayOfBusinessTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'BusinessTargetBid',
        element_type => 'BusinessTargetBid'
    },
    ArrayOfCampaign => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'Campaign',
        element_type => 'Campaign'
    },
    ArrayOfCampaignInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'CampaignInfo',
        element_type => 'CampaignInfo'
    },
    ArrayOfCampaignNegativeKeywords => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'CampaignNegativeKeywords',
        element_type => 'CampaignNegativeKeywords'
    },
    ArrayOfCityTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'CityTargetBid',
        element_type => 'CityTargetBid'
    },
    ArrayOfCountryTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'CountryTargetBid',
        element_type => 'CountryTargetBid'
    },
    ArrayOfDayTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'DayTargetBid',
        element_type => 'DayTargetBid'
    },
    ArrayOfDimension => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'Dimension',
        element_type => 'Dimension'
    },
    ArrayOfEditorialError => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'EditorialError',
        element_type => 'EditorialError'
    },
    ArrayOfGenderTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'GenderTargetBid',
        element_type => 'GenderTargetBid'
    },
    ArrayOfHourTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'HourTargetBid',
        element_type => 'HourTargetBid'
    },
    ArrayOfHoursOfOperation => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'HoursOfOperation',
        element_type => 'HoursOfOperation'
    },
    ArrayOfKeyword => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'Keyword',
        element_type => 'Keyword'
    },
    ArrayOfKeywordBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'KeywordBid',
        element_type => 'KeywordBid'
    },
    ArrayOfKeywordEstimate => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'KeywordEstimate',
        element_type => 'KeywordEstimate'
    },
    ArrayOfMediaType => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'MediaType',
        element_type => 'MediaType'
    },
    ArrayOfMetroAreaTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'MetroAreaTargetBid',
        element_type => 'MetroAreaTargetBid'
    },
    ArrayOfOperationError => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'OperationError',
        element_type => 'OperationError'
    },
    ArrayOfPaymentType => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'PaymentType',
        element_type => 'PaymentType'
    },
    ArrayOfPlacementDetail => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'PlacementDetail',
        element_type => 'PlacementDetail'
    },
    ArrayOfRadiusTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'RadiusTargetBid',
        element_type => 'RadiusTargetBid'
    },
    ArrayOfSegment => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'Segment',
        element_type => 'Segment'
    },
    ArrayOfSegmentTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'SegmentTargetBid',
        element_type => 'SegmentTargetBid'
    },
    ArrayOfSitePlacement => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'SitePlacement',
        element_type => 'SitePlacement'
    },
    ArrayOfStateTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'StateTargetBid',
        element_type => 'StateTargetBid'
    },
    ArrayOfTarget => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'Target',
        element_type => 'Target'
    },
    ArrayOfTargetInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'TargetInfo',
        element_type => 'TargetInfo'
    },
    ArrayOfbase64Binary => {
        namespace_uri => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays',
        element_name => 'base64Binary',
        element_type => 'base64Binary'
    },
    ArrayOflong => {
        namespace_uri => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays',
        element_name => 'long',
        element_type => 'long'
    },
    ArrayOfstring => {
        namespace_uri => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays',
        element_name => 'string',
        element_type => 'string'
    },
);

sub _array_types {
    return %_array_types;
}

__PACKAGE__->mk_accessors(qw/
    ApplicationToken
    CustomerAccountId
    CustomerId
    DeveloperToken
    Password
    UserName
    TrackingId
/);

1;
