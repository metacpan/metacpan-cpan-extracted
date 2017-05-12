package Microsoft::AdCenter::V8::CampaignManagementService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CampaignManagementService - Service client for Microsoft AdCenter Campaign Management Service.

=head1 SYNOPSIS

    use Microsoft::AdCenter::V8::CampaignManagementService;

    my $service_client = Microsoft::AdCenter::V8::CampaignManagementService->new
        ->ApplicationToken("application token")
        ->CustomerAccountId("customer account id")
        ->CustomerId("customer id")
        ->DeveloperToken("developer token")
        ->Password("password")
        ->UserName("user name");

    my $response = $service_client->AddAdExtensions(
        AccountId => ...
        AdExtensions => ...
    );

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for detailed documentation for this service.

=head1 METHODS

=head2 EndPoint

Changes the end point for this service client.

Default value: https://adcenterapi.microsoft.com/Api/Advertiser/V8/CampaignManagement/CampaignManagementService.svc

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
    return 'V8';
}

sub _class_name {
    return 'CampaignManagementService';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

sub _default_location {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/V8/CampaignManagement/CampaignManagementService.svc';
}

sub _wsdl {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/V8/CampaignManagement/CampaignManagementService.svc?wsdl';
}

our $_request_headers = [
    { name => 'ApplicationToken', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' },
    { name => 'CustomerAccountId', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' },
    { name => 'CustomerId', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' },
    { name => 'DeveloperToken', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' },
    { name => 'Password', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' },
    { name => 'UserName', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
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
    { name => 'TrackingId', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
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

=head2 AddAdExtensions

=over

=item Parameters:

    AccountId (long)
    AdExtensions (ArrayOfAdExtension2)

=item Returns:

    AddAdExtensionsResponse

=back

=cut

sub AddAdExtensions {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddAdExtensions',
        request => {
            name => 'AddAdExtensionsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdExtensions', type => 'ArrayOfAdExtension2', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'AddAdExtensionsResponse'
        },
        parameters => \%args
    );
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroups', type => 'ArrayOfAdGroup', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Ads', type => 'ArrayOfAd', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'AddAdsResponse'
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
                { name => 'Businesses', type => 'ArrayOfBusiness', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Campaigns', type => 'ArrayOfCampaign', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'AddCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 AddGoals

=over

=item Parameters:

    AccountId (long)
    Goals (ArrayOfGoal)

=item Returns:

    AddGoalsResponse

=back

=cut

sub AddGoals {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddGoals',
        request => {
            name => 'AddGoalsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Goals', type => 'ArrayOfGoal', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'AddGoalsResponse'
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Keywords', type => 'ArrayOfKeyword', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'AddKeywordsResponse'
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'SitePlacements', type => 'ArrayOfSitePlacement', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Target', type => 'Target', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'Targets', type => 'ArrayOfTarget', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'AddTargetsToLibraryResponse'
        },
        parameters => \%args
    );
}

=head2 AppealEditorialRejections

=over

=item Parameters:

    EntityIds (ArrayOflong)
    EntityType (EntityType)
    JustificationText (string)

=item Returns:

    AppealEditorialRejectionsResponse

=back

=cut

sub AppealEditorialRejections {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AppealEditorialRejections',
        request => {
            name => 'AppealEditorialRejectionsRequest',
            parameters => [
                { name => 'EntityIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'EntityType', type => 'EntityType', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'JustificationText', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'AppealEditorialRejectionsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteAdExtensions

=over

=item Parameters:

    AccountId (long)
    AdExtensionIds (ArrayOflong)

=item Returns:

    DeleteAdExtensionsResponse

=back

=cut

sub DeleteAdExtensions {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteAdExtensions',
        request => {
            name => 'DeleteAdExtensionsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdExtensionIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'DeleteAdExtensionsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteAdExtensionsFromCampaigns

=over

=item Parameters:

    AccountId (long)
    AdExtensionIdToCampaignIdAssociations (ArrayOfAdExtensionIdToCampaignIdAssociation)

=item Returns:

    DeleteAdExtensionsFromCampaignsResponse

=back

=cut

sub DeleteAdExtensionsFromCampaigns {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteAdExtensionsFromCampaigns',
        request => {
            name => 'DeleteAdExtensionsFromCampaignsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdExtensionIdToCampaignIdAssociations', type => 'ArrayOfAdExtensionIdToCampaignIdAssociation', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'DeleteAdExtensionsFromCampaignsResponse'
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'DeleteAdsResponse'
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
                { name => 'BusinessIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'DeleteCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteGoals

=over

=item Parameters:

    AccountId (long)
    GoalIds (ArrayOflong)

=item Returns:

    DeleteGoalsResponse

=back

=cut

sub DeleteGoals {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteGoals',
        request => {
            name => 'DeleteGoalsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'GoalIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'DeleteGoalsResponse'
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'KeywordIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'DeleteKeywordsResponse'
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'SitePlacementIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'TargetIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'DeleteTargetsFromLibraryResponse'
        },
        parameters => \%args
    );
}

=head2 GetAccountMigrationStatuses

=over

=item Parameters:

    AccountIds (ArrayOflong)
    MigrationType (string)

=item Returns:

    GetAccountMigrationStatusesResponse

=back

=cut

sub GetAccountMigrationStatuses {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAccountMigrationStatuses',
        request => {
            name => 'GetAccountMigrationStatusesRequest',
            parameters => [
                { name => 'AccountIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'MigrationType', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetAccountMigrationStatusesResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdEditorialReasonsByIds

=over

=item Parameters:

    AdIds (ArrayOflong)
    AccountId (long)

=item Returns:

    GetAdEditorialReasonsByIdsResponse

=back

=cut

sub GetAdEditorialReasonsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdEditorialReasonsByIds',
        request => {
            name => 'GetAdEditorialReasonsByIdsRequest',
            parameters => [
                { name => 'AdIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetAdEditorialReasonsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdExtensionsByCampaignIds

=over

=item Parameters:

    AccountId (long)
    CampaignIds (ArrayOflong)
    AdExtensionType (AdExtensionsTypeFilter)

=item Returns:

    GetAdExtensionsByCampaignIdsResponse

=back

=cut

sub GetAdExtensionsByCampaignIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdExtensionsByCampaignIds',
        request => {
            name => 'GetAdExtensionsByCampaignIdsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdExtensionType', type => 'AdExtensionsTypeFilter', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetAdExtensionsByCampaignIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdExtensionsByIds

=over

=item Parameters:

    AccountId (long)
    AdExtensionIds (ArrayOflong)
    AdExtensionType (AdExtensionsTypeFilter)

=item Returns:

    GetAdExtensionsByIdsResponse

=back

=cut

sub GetAdExtensionsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdExtensionsByIds',
        request => {
            name => 'GetAdExtensionsByIdsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdExtensionIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdExtensionType', type => 'AdExtensionsTypeFilter', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetAdExtensionsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdExtensionsEditorialReasonsByCampaignIds

=over

=item Parameters:

    AccountId (long)
    AdExtensionIdToCampaignIdAssociations (ArrayOfAdExtensionIdToCampaignIdAssociation)
    AdExtensionType (AdExtensionsTypeFilter)

=item Returns:

    GetAdExtensionsEditorialReasonsByCampaignIdsResponse

=back

=cut

sub GetAdExtensionsEditorialReasonsByCampaignIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdExtensionsEditorialReasonsByCampaignIds',
        request => {
            name => 'GetAdExtensionsEditorialReasonsByCampaignIdsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdExtensionIdToCampaignIdAssociations', type => 'ArrayOfAdExtensionIdToCampaignIdAssociation', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdExtensionType', type => 'AdExtensionsTypeFilter', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetAdExtensionsEditorialReasonsByCampaignIdsResponse'
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetAdGroupsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetAdRotationByAdGroupIds

=over

=item Parameters:

    AdGroupIds (ArrayOflong)
    CampaignId (long)

=item Returns:

    GetAdRotationByAdGroupIdsResponse

=back

=cut

sub GetAdRotationByAdGroupIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAdRotationByAdGroupIds',
        request => {
            name => 'GetAdRotationByAdGroupIdsRequest',
            parameters => [
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetAdRotationByAdGroupIdsResponse'
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'EditorialStatus', type => 'AdEditorialStatus', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetAdsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetAnalyticsType

=over

=item Parameters:

    AccountIds (ArrayOflong)

=item Returns:

    GetAnalyticsTypeResponse

=back

=cut

sub GetAnalyticsType {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAnalyticsType',
        request => {
            name => 'GetAnalyticsTypeRequest',
            parameters => [
                { name => 'AccountIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetAnalyticsTypeResponse'
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
                { name => 'BusinessIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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

=head2 GetCampaignAdExtensions

=over

=item Parameters:

    AccountId (long)
    CampaignIds (ArrayOflong)

=item Returns:

    GetCampaignAdExtensionsResponse

=back

=cut

sub GetCampaignAdExtensions {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetCampaignAdExtensions',
        request => {
            name => 'GetCampaignAdExtensionsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetCampaignAdExtensionsResponse'
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
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetCampaignsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetDestinationUrlByKeywordIds

=over

=item Parameters:

    AdGroupId (long)
    KeywordIds (ArrayOflong)

=item Returns:

    GetDestinationUrlByKeywordIdsResponse

=back

=cut

sub GetDestinationUrlByKeywordIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetDestinationUrlByKeywordIds',
        request => {
            name => 'GetDestinationUrlByKeywordIdsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'KeywordIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetDestinationUrlByKeywordIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetDeviceOSTargetsByIds

=over

=item Parameters:

    TargetIds (ArrayOflong)

=item Returns:

    GetDeviceOSTargetsByIdsResponse

=back

=cut

sub GetDeviceOSTargetsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetDeviceOSTargetsByIds',
        request => {
            name => 'GetDeviceOSTargetsByIdsRequest',
            parameters => [
                { name => 'TargetIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetDeviceOSTargetsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetEditorialReasonsByIds

=over

=item Parameters:

    AccountId (long)
    EntityIds (ArrayOflong)
    EntityType (EntityType)

=item Returns:

    GetEditorialReasonsByIdsResponse

=back

=cut

sub GetEditorialReasonsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetEditorialReasonsByIds',
        request => {
            name => 'GetEditorialReasonsByIdsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'EntityIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'EntityType', type => 'EntityType', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetEditorialReasonsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetExclusionsByAssociatedEntityIds

=over

=item Parameters:

    Entities (ArrayOfEntity)
    ExclusionType (ExclusionType)
    LocationTargetVersion (string)

=item Returns:

    GetExclusionsByAssociatedEntityIdsResponse

=back

=cut

sub GetExclusionsByAssociatedEntityIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetExclusionsByAssociatedEntityIds',
        request => {
            name => 'GetExclusionsByAssociatedEntityIdsRequest',
            parameters => [
                { name => 'Entities', type => 'ArrayOfEntity', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'ExclusionType', type => 'ExclusionType', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'LocationTargetVersion', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetExclusionsByAssociatedEntityIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetGoals

=over

=item Parameters:

    AccountId (long)

=item Returns:

    GetGoalsResponse

=back

=cut

sub GetGoals {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetGoals',
        request => {
            name => 'GetGoalsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetGoalsResponse'
        },
        parameters => \%args
    );
}

=head2 GetKeywordEditorialReasonsByIds

=over

=item Parameters:

    KeywordIds (ArrayOflong)
    AccountId (long)

=item Returns:

    GetKeywordEditorialReasonsByIdsResponse

=back

=cut

sub GetKeywordEditorialReasonsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetKeywordEditorialReasonsByIds',
        request => {
            name => 'GetKeywordEditorialReasonsByIdsRequest',
            parameters => [
                { name => 'KeywordIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetKeywordEditorialReasonsByIdsResponse'
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'EditorialStatus', type => 'KeywordEditorialStatus', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'KeywordIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetNegativeKeywordsByCampaignIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetNegativeSitesByAdGroupIds

=over

=item Parameters:

    CampaignId (long)
    AdGroupIds (ArrayOflong)

=item Returns:

    GetNegativeSitesByAdGroupIdsResponse

=back

=cut

sub GetNegativeSitesByAdGroupIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetNegativeSitesByAdGroupIds',
        request => {
            name => 'GetNegativeSitesByAdGroupIdsRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetNegativeSitesByAdGroupIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetNegativeSitesByCampaignIds

=over

=item Parameters:

    AccountId (long)
    CampaignIds (ArrayOflong)

=item Returns:

    GetNegativeSitesByCampaignIdsResponse

=back

=cut

sub GetNegativeSitesByCampaignIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetNegativeSitesByCampaignIds',
        request => {
            name => 'GetNegativeSitesByCampaignIdsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetNegativeSitesByCampaignIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetNormalizedStrings

=over

=item Parameters:

    Strings (ArrayOfstring)
    Language (string)
    RemoveNoise (boolean)

=item Returns:

    GetNormalizedStringsResponse

=back

=cut

sub GetNormalizedStrings {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetNormalizedStrings',
        request => {
            name => 'GetNormalizedStringsRequest',
            parameters => [
                { name => 'Strings', type => 'ArrayOfstring', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Language', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'RemoveNoise', type => 'boolean', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetNormalizedStringsResponse'
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
                { name => 'Urls', type => 'ArrayOfstring', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetPlacementDetailsForUrlsResponse'
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'SitePlacementIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
    LocationTargetVersion (string)

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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'LocationTargetVersion', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
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
    LocationTargetVersion (string)

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
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'LocationTargetVersion', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
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
    LocationTargetVersion (string)

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
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'LocationTargetVersion', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
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
    LocationTargetVersion (string)

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
                { name => 'TargetIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'LocationTargetVersion', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'PauseAdsResponse'
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
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'KeywordIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'SitePlacementIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroupIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'ResumeAdsResponse'
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
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'KeywordIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'SitePlacementIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'ResumeSitePlacementsResponse'
        },
        parameters => \%args
    );
}

=head2 SetAdExtensionsToCampaigns

=over

=item Parameters:

    AccountId (long)
    AdExtensionIdToCampaignIdAssociations (ArrayOfAdExtensionIdToCampaignIdAssociation)

=item Returns:

    SetAdExtensionsToCampaignsResponse

=back

=cut

sub SetAdExtensionsToCampaigns {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetAdExtensionsToCampaigns',
        request => {
            name => 'SetAdExtensionsToCampaignsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdExtensionIdToCampaignIdAssociations', type => 'ArrayOfAdExtensionIdToCampaignIdAssociation', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'SetAdExtensionsToCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 SetAdRotationToAdGroups

=over

=item Parameters:

    AdGroupAdRotations (ArrayOfAdGroupAdRotation)
    CampaignId (long)

=item Returns:

    SetAdRotationToAdGroupsResponse

=back

=cut

sub SetAdRotationToAdGroups {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetAdRotationToAdGroups',
        request => {
            name => 'SetAdRotationToAdGroupsRequest',
            parameters => [
                { name => 'AdGroupAdRotations', type => 'ArrayOfAdGroupAdRotation', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'SetAdRotationToAdGroupsResponse'
        },
        parameters => \%args
    );
}

=head2 SetAnalyticsType

=over

=item Parameters:

    AccountAnalyticsTypes (ArrayOfAccountAnalyticsType)

=item Returns:

    SetAnalyticsTypeResponse

=back

=cut

sub SetAnalyticsType {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetAnalyticsType',
        request => {
            name => 'SetAnalyticsTypeRequest',
            parameters => [
                { name => 'AccountAnalyticsTypes', type => 'ArrayOfAccountAnalyticsType', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'SetAnalyticsTypeResponse'
        },
        parameters => \%args
    );
}

=head2 SetCampaignAdExtensions

=over

=item Parameters:

    AccountId (long)
    AdExtensions (ArrayOfAdExtension)

=item Returns:

    SetCampaignAdExtensionsResponse

=back

=cut

sub SetCampaignAdExtensions {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetCampaignAdExtensions',
        request => {
            name => 'SetCampaignAdExtensionsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdExtensions', type => 'ArrayOfAdExtension', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'SetCampaignAdExtensionsResponse'
        },
        parameters => \%args
    );
}

=head2 SetDestinationUrlToKeywords

=over

=item Parameters:

    AdGroupId (long)
    KeywordDestinationUrls (ArrayOfKeywordDestinationUrl)

=item Returns:

    SetDestinationUrlToKeywordsResponse

=back

=cut

sub SetDestinationUrlToKeywords {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetDestinationUrlToKeywords',
        request => {
            name => 'SetDestinationUrlToKeywordsRequest',
            parameters => [
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'KeywordDestinationUrls', type => 'ArrayOfKeywordDestinationUrl', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'SetDestinationUrlToKeywordsResponse'
        },
        parameters => \%args
    );
}

=head2 SetExclusionsToAssociatedEntities

=over

=item Parameters:

    ExclusionToEntityAssociations (ArrayOfExclusionToEntityAssociation)

=item Returns:

    SetExclusionsToAssociatedEntitiesResponse

=back

=cut

sub SetExclusionsToAssociatedEntities {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetExclusionsToAssociatedEntities',
        request => {
            name => 'SetExclusionsToAssociatedEntitiesRequest',
            parameters => [
                { name => 'ExclusionToEntityAssociations', type => 'ArrayOfExclusionToEntityAssociation', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'SetExclusionsToAssociatedEntitiesResponse'
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroupNegativeKeywords', type => 'ArrayOfAdGroupNegativeKeywords', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignNegativeKeywords', type => 'ArrayOfCampaignNegativeKeywords', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'SetNegativeKeywordsToCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 SetNegativeSitesToAdGroups

=over

=item Parameters:

    CampaignId (long)
    AdGroupNegativeSites (ArrayOfAdGroupNegativeSites)

=item Returns:

    SetNegativeSitesToAdGroupsResponse

=back

=cut

sub SetNegativeSitesToAdGroups {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetNegativeSitesToAdGroups',
        request => {
            name => 'SetNegativeSitesToAdGroupsRequest',
            parameters => [
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroupNegativeSites', type => 'ArrayOfAdGroupNegativeSites', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'SetNegativeSitesToAdGroupsResponse'
        },
        parameters => \%args
    );
}

=head2 SetNegativeSitesToCampaigns

=over

=item Parameters:

    AccountId (long)
    CampaignNegativeSites (ArrayOfCampaignNegativeSites)

=item Returns:

    SetNegativeSitesToCampaignsResponse

=back

=cut

sub SetNegativeSitesToCampaigns {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SetNegativeSitesToCampaigns',
        request => {
            name => 'SetNegativeSitesToCampaignsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignNegativeSites', type => 'ArrayOfCampaignNegativeSites', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'SetNegativeSitesToCampaignsResponse'
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'TargetId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'TargetId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'SetTargetToCampaignResponse'
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroups', type => 'ArrayOfAdGroup', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Ads', type => 'ArrayOfAd', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'UpdateAdsResponse'
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
                { name => 'Businesses', type => 'ArrayOfBusiness', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Campaigns', type => 'ArrayOfCampaign', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'UpdateCampaignsResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateDeviceOSTargets

=over

=item Parameters:

    TargetAssociations (ArrayOfTargetAssociation)

=item Returns:

    UpdateDeviceOSTargetsResponse

=back

=cut

sub UpdateDeviceOSTargets {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateDeviceOSTargets',
        request => {
            name => 'UpdateDeviceOSTargetsRequest',
            parameters => [
                { name => 'TargetAssociations', type => 'ArrayOfTargetAssociation', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'UpdateDeviceOSTargetsResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateGoals

=over

=item Parameters:

    AccountId (long)
    Goals (ArrayOfGoal)

=item Returns:

    UpdateGoalsResponse

=back

=cut

sub UpdateGoals {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateGoals',
        request => {
            name => 'UpdateGoalsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Goals', type => 'ArrayOfGoal', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'UpdateGoalsResponse'
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Keywords', type => 'ArrayOfKeyword', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'SitePlacements', type => 'ArrayOfSitePlacement', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Target', type => 'Target', namespace => 'https://adcenter.microsoft.com/v8' }
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
                { name => 'Targets', type => 'ArrayOfTarget', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'UpdateTargetsInLibraryResponse'
        },
        parameters => \%args
    );
}

our %_simple_types = (
    AdComponent => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
    AdDistribution => 'https://adcenter.microsoft.com/v8',
    AdEditorialStatus => 'https://adcenter.microsoft.com/v8',
    AdExtensionStatus => 'https://adcenter.microsoft.com/v8',
    AdExtensionsTypeFilter => 'https://adcenter.microsoft.com/v8',
    AdGroupStatus => 'https://adcenter.microsoft.com/v8',
    AdRotationType => 'https://adcenter.microsoft.com/v8',
    AdStatus => 'https://adcenter.microsoft.com/v8',
    AdType => 'https://adcenter.microsoft.com/v8',
    AgeRange => 'https://adcenter.microsoft.com/v8',
    AnalyticsType => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
    AppealStatus => 'https://adcenter.microsoft.com/v8',
    BiddingModel => 'https://adcenter.microsoft.com/v8',
    BudgetLimitType => 'https://adcenter.microsoft.com/v8',
    BusinessGeoCodeStatus => 'https://adcenter.microsoft.com/v8',
    BusinessStatus => 'https://adcenter.microsoft.com/v8',
    CampaignAdExtensionEditorialStatus => 'https://adcenter.microsoft.com/v8',
    CampaignStatus => 'https://adcenter.microsoft.com/v8',
    CostModel => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
    Day => 'https://adcenter.microsoft.com/v8',
    DaysApplicableForConversion => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
    DeviceType => 'https://adcenter.microsoft.com/v8',
    EntityType => 'https://adcenter.microsoft.com/v8',
    ExclusionType => 'https://adcenter.microsoft.com/v8',
    GenderType => 'https://adcenter.microsoft.com/v8',
    GeoLocationType => 'https://adcenter.microsoft.com/v8',
    HourRange => 'https://adcenter.microsoft.com/v8',
    IncrementalBidPercentage => 'https://adcenter.microsoft.com/v8',
    KeywordEditorialStatus => 'https://adcenter.microsoft.com/v8',
    KeywordStatus => 'https://adcenter.microsoft.com/v8',
    MigrationStatus => 'https://adcenter.microsoft.com/v8',
    Network => 'https://adcenter.microsoft.com/v8',
    PaymentType => 'https://adcenter.microsoft.com/v8',
    PricingModel => 'https://adcenter.microsoft.com/v8',
    RevenueModelType => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
    SitePlacementStatus => 'https://adcenter.microsoft.com/v8',
    StandardBusinessIcon => 'https://adcenter.microsoft.com/v8',
    StepType => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
    char => 'http://schemas.microsoft.com/2003/10/Serialization/',
    duration => 'http://schemas.microsoft.com/2003/10/Serialization/',
    guid => 'http://schemas.microsoft.com/2003/10/Serialization/',
);

sub _simple_types {
    return %_simple_types;
}

our @_complex_types = (qw/
    AccountAnalyticsType
    AccountMigrationStatusesInfo
    Ad
    AdApiError
    AdApiFaultDetail
    AdExtension
    AdExtension2
    AdExtensionEditorialReason
    AdExtensionEditorialReasonCollection
    AdExtensionIdToCampaignIdAssociation
    AdExtensionIdentity
    AdGroup
    AdGroupAdRotation
    AdGroupNegativeKeywords
    AdGroupNegativeSites
    AdRotation
    AddAdExtensionsResponse
    AddAdGroupsResponse
    AddAdsResponse
    AddBusinessesResponse
    AddCampaignsResponse
    AddGoalsResponse
    AddKeywordsResponse
    AddSitePlacementsResponse
    AddTargetResponse
    AddTargetsToLibraryResponse
    AgeTarget
    AgeTargetBid
    AnalyticsApiFaultDetail
    ApiFaultDetail
    AppealEditorialRejectionsResponse
    ApplicationFault
    BatchError
    Bid
    Business
    BusinessImageIcon
    BusinessInfo
    BusinessTarget
    BusinessTargetBid
    Campaign
    CampaignAdExtension
    CampaignAdExtensionCollection
    CampaignNegativeKeywords
    CampaignNegativeSites
    CityTarget
    CityTargetBid
    CountryTarget
    CountryTargetBid
    Date
    DayTarget
    DayTargetBid
    DayTimeInterval
    DeleteAdExtensionsFromCampaignsResponse
    DeleteAdExtensionsResponse
    DeleteAdGroupsResponse
    DeleteAdsResponse
    DeleteBusinessesResponse
    DeleteCampaignsResponse
    DeleteGoalsResponse
    DeleteKeywordsResponse
    DeleteSitePlacementsResponse
    DeleteTargetFromAdGroupResponse
    DeleteTargetFromCampaignResponse
    DeleteTargetResponse
    DeleteTargetsFromLibraryResponse
    DeviceOS
    DeviceOSTarget
    DeviceTarget
    Dimension
    EditorialApiFaultDetail
    EditorialError
    EditorialReason
    EditorialReasonCollection
    Entity
    EntityToExclusionsAssociation
    ExcludedGeoLocation
    ExcludedRadiusLocation
    ExcludedRadiusTarget
    Exclusion
    ExclusionToEntityAssociation
    GenderTarget
    GenderTargetBid
    GetAccountMigrationStatusesResponse
    GetAdEditorialReasonsByIdsResponse
    GetAdExtensionsByCampaignIdsResponse
    GetAdExtensionsByIdsResponse
    GetAdExtensionsEditorialReasonsByCampaignIdsResponse
    GetAdGroupsByCampaignIdResponse
    GetAdGroupsByIdsResponse
    GetAdRotationByAdGroupIdsResponse
    GetAdsByAdGroupIdResponse
    GetAdsByEditorialStatusResponse
    GetAdsByIdsResponse
    GetAnalyticsTypeResponse
    GetBusinessesByIdsResponse
    GetBusinessesInfoResponse
    GetCampaignAdExtensionsResponse
    GetCampaignsByAccountIdResponse
    GetCampaignsByIdsResponse
    GetDestinationUrlByKeywordIdsResponse
    GetDeviceOSTargetsByIdsResponse
    GetEditorialReasonsByIdsResponse
    GetExclusionsByAssociatedEntityIdsResponse
    GetGoalsResponse
    GetKeywordEditorialReasonsByIdsResponse
    GetKeywordsByAdGroupIdResponse
    GetKeywordsByEditorialStatusResponse
    GetKeywordsByIdsResponse
    GetNegativeKeywordsByAdGroupIdsResponse
    GetNegativeKeywordsByCampaignIdsResponse
    GetNegativeSitesByAdGroupIdsResponse
    GetNegativeSitesByCampaignIdsResponse
    GetNormalizedStringsResponse
    GetPlacementDetailsForUrlsResponse
    GetSitePlacementsByAdGroupIdResponse
    GetSitePlacementsByIdsResponse
    GetTargetByAdGroupIdResponse
    GetTargetsByAdGroupIdsResponse
    GetTargetsByCampaignIdsResponse
    GetTargetsByIdsResponse
    GetTargetsInfoFromLibraryResponse
    Goal
    GoalError
    GoalResult
    HourTarget
    HourTargetBid
    HoursOfOperation
    ImpressionsPerDayRange
    Keyword
    KeywordDestinationUrl
    LocationExclusion
    LocationTarget
    MediaType
    MetroAreaTarget
    MetroAreaTargetBid
    MigrationStatusInfo
    MobileAd
    OperationError
    PauseAdGroupsResponse
    PauseAdsResponse
    PauseCampaignsResponse
    PauseKeywordsResponse
    PauseSitePlacementsResponse
    PhoneExtension
    PlacementDetail
    PublisherCountry
    RadiusTarget
    RadiusTargetBid
    ResumeAdGroupsResponse
    ResumeAdsResponse
    ResumeCampaignsResponse
    ResumeKeywordsResponse
    ResumeSitePlacementsResponse
    RevenueModel
    SetAdExtensionsToCampaignsResponse
    SetAdRotationToAdGroupsResponse
    SetAnalyticsTypeResponse
    SetCampaignAdExtensionsResponse
    SetDestinationUrlToKeywordsResponse
    SetExclusionsToAssociatedEntitiesResponse
    SetNegativeKeywordsToAdGroupsResponse
    SetNegativeKeywordsToCampaignsResponse
    SetNegativeSitesToAdGroupsResponse
    SetNegativeSitesToCampaignsResponse
    SetTargetToAdGroupResponse
    SetTargetToCampaignResponse
    SiteLink
    SiteLinksAdExtension
    SitePlacement
    StateTarget
    StateTargetBid
    Step
    SubmitAdGroupForApprovalResponse
    Target
    TargetAssociation
    TargetInfo
    TextAd
    TimeOfTheDay
    UpdateAdGroupsResponse
    UpdateAdsResponse
    UpdateBusinessesResponse
    UpdateCampaignsResponse
    UpdateDeviceOSTargetsResponse
    UpdateGoalsResponse
    UpdateKeywordsResponse
    UpdateSitePlacementsResponse
    UpdateTargetResponse
    UpdateTargetsInLibraryResponse
/);

sub _complex_types {
    return @_complex_types;
}

our %_array_types = (
    ArrayOfAccountAnalyticsType => {
        namespace_uri => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
        element_name => 'AccountAnalyticsType',
        element_type => 'AccountAnalyticsType'
    },
    ArrayOfAccountMigrationStatusesInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AccountMigrationStatusesInfo',
        element_type => 'AccountMigrationStatusesInfo'
    },
    ArrayOfAd => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'Ad',
        element_type => 'Ad'
    },
    ArrayOfAdApiError => {
        namespace_uri => 'https://adapi.microsoft.com',
        element_name => 'AdApiError',
        element_type => 'AdApiError'
    },
    ArrayOfAdExtension => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdExtension',
        element_type => 'AdExtension'
    },
    ArrayOfAdExtension2 => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdExtension2',
        element_type => 'AdExtension2'
    },
    ArrayOfAdExtensionEditorialReason => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdExtensionEditorialReason',
        element_type => 'AdExtensionEditorialReason'
    },
    ArrayOfAdExtensionEditorialReasonCollection => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdExtensionEditorialReasonCollection',
        element_type => 'AdExtensionEditorialReasonCollection'
    },
    ArrayOfAdExtensionIdToCampaignIdAssociation => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdExtensionIdToCampaignIdAssociation',
        element_type => 'AdExtensionIdToCampaignIdAssociation'
    },
    ArrayOfAdExtensionIdentity => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdExtensionIdentity',
        element_type => 'AdExtensionIdentity'
    },
    ArrayOfAdGroup => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdGroup',
        element_type => 'AdGroup'
    },
    ArrayOfAdGroupAdRotation => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdGroupAdRotation',
        element_type => 'AdGroupAdRotation'
    },
    ArrayOfAdGroupNegativeKeywords => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdGroupNegativeKeywords',
        element_type => 'AdGroupNegativeKeywords'
    },
    ArrayOfAdGroupNegativeSites => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdGroupNegativeSites',
        element_type => 'AdGroupNegativeSites'
    },
    ArrayOfAdRotation => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AdRotation',
        element_type => 'AdRotation'
    },
    ArrayOfAgeTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'AgeTargetBid',
        element_type => 'AgeTargetBid'
    },
    ArrayOfAnalyticsType => {
        namespace_uri => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
        element_name => 'AnalyticsType',
        element_type => 'AnalyticsType'
    },
    ArrayOfArrayOfPlacementDetail => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'ArrayOfPlacementDetail',
        element_type => 'ArrayOfPlacementDetail'
    },
    ArrayOfBatchError => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'BatchError',
        element_type => 'BatchError'
    },
    ArrayOfBusiness => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'Business',
        element_type => 'Business'
    },
    ArrayOfBusinessInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'BusinessInfo',
        element_type => 'BusinessInfo'
    },
    ArrayOfBusinessTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'BusinessTargetBid',
        element_type => 'BusinessTargetBid'
    },
    ArrayOfCampaign => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'Campaign',
        element_type => 'Campaign'
    },
    ArrayOfCampaignAdExtension => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'CampaignAdExtension',
        element_type => 'CampaignAdExtension'
    },
    ArrayOfCampaignAdExtensionCollection => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'CampaignAdExtensionCollection',
        element_type => 'CampaignAdExtensionCollection'
    },
    ArrayOfCampaignNegativeKeywords => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'CampaignNegativeKeywords',
        element_type => 'CampaignNegativeKeywords'
    },
    ArrayOfCampaignNegativeSites => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'CampaignNegativeSites',
        element_type => 'CampaignNegativeSites'
    },
    ArrayOfCityTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'CityTargetBid',
        element_type => 'CityTargetBid'
    },
    ArrayOfCountryTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'CountryTargetBid',
        element_type => 'CountryTargetBid'
    },
    ArrayOfDayTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'DayTargetBid',
        element_type => 'DayTargetBid'
    },
    ArrayOfDeviceOS => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'DeviceOS',
        element_type => 'DeviceOS'
    },
    ArrayOfDeviceType => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'DeviceType',
        element_type => 'DeviceType'
    },
    ArrayOfDimension => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'Dimension',
        element_type => 'Dimension'
    },
    ArrayOfEditorialError => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'EditorialError',
        element_type => 'EditorialError'
    },
    ArrayOfEditorialReason => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'EditorialReason',
        element_type => 'EditorialReason'
    },
    ArrayOfEditorialReasonCollection => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'EditorialReasonCollection',
        element_type => 'EditorialReasonCollection'
    },
    ArrayOfEntity => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'Entity',
        element_type => 'Entity'
    },
    ArrayOfEntityToExclusionsAssociation => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'EntityToExclusionsAssociation',
        element_type => 'EntityToExclusionsAssociation'
    },
    ArrayOfExcludedGeoLocation => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'ExcludedGeoLocation',
        element_type => 'ExcludedGeoLocation'
    },
    ArrayOfExcludedRadiusLocation => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'ExcludedRadiusLocation',
        element_type => 'ExcludedRadiusLocation'
    },
    ArrayOfExclusion => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'Exclusion',
        element_type => 'Exclusion'
    },
    ArrayOfExclusionToEntityAssociation => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'ExclusionToEntityAssociation',
        element_type => 'ExclusionToEntityAssociation'
    },
    ArrayOfGenderTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'GenderTargetBid',
        element_type => 'GenderTargetBid'
    },
    ArrayOfGoal => {
        namespace_uri => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
        element_name => 'Goal',
        element_type => 'Goal'
    },
    ArrayOfGoalError => {
        namespace_uri => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
        element_name => 'GoalError',
        element_type => 'GoalError'
    },
    ArrayOfGoalResult => {
        namespace_uri => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
        element_name => 'GoalResult',
        element_type => 'GoalResult'
    },
    ArrayOfHourTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'HourTargetBid',
        element_type => 'HourTargetBid'
    },
    ArrayOfHoursOfOperation => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'HoursOfOperation',
        element_type => 'HoursOfOperation'
    },
    ArrayOfKeyword => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'Keyword',
        element_type => 'Keyword'
    },
    ArrayOfKeywordDestinationUrl => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'KeywordDestinationUrl',
        element_type => 'KeywordDestinationUrl'
    },
    ArrayOfMediaType => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'MediaType',
        element_type => 'MediaType'
    },
    ArrayOfMetroAreaTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'MetroAreaTargetBid',
        element_type => 'MetroAreaTargetBid'
    },
    ArrayOfMigrationStatusInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'MigrationStatusInfo',
        element_type => 'MigrationStatusInfo'
    },
    ArrayOfOperationError => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'OperationError',
        element_type => 'OperationError'
    },
    ArrayOfPaymentType => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'PaymentType',
        element_type => 'PaymentType'
    },
    ArrayOfPlacementDetail => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'PlacementDetail',
        element_type => 'PlacementDetail'
    },
    ArrayOfPublisherCountry => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'PublisherCountry',
        element_type => 'PublisherCountry'
    },
    ArrayOfRadiusTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'RadiusTargetBid',
        element_type => 'RadiusTargetBid'
    },
    ArrayOfSiteLink => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'SiteLink',
        element_type => 'SiteLink'
    },
    ArrayOfSitePlacement => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'SitePlacement',
        element_type => 'SitePlacement'
    },
    ArrayOfStateTargetBid => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'StateTargetBid',
        element_type => 'StateTargetBid'
    },
    ArrayOfStep => {
        namespace_uri => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts',
        element_name => 'Step',
        element_type => 'Step'
    },
    ArrayOfTarget => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'Target',
        element_type => 'Target'
    },
    ArrayOfTargetAssociation => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'TargetAssociation',
        element_type => 'TargetAssociation'
    },
    ArrayOfTargetInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'TargetInfo',
        element_type => 'TargetInfo'
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
