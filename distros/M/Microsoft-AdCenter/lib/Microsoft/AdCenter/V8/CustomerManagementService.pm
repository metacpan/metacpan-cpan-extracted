package Microsoft::AdCenter::V8::CustomerManagementService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CustomerManagementService - Service client for Microsoft AdCenter Customer Management Service.

=head1 SYNOPSIS

    use Microsoft::AdCenter::V8::CustomerManagementService;

    my $service_client = Microsoft::AdCenter::V8::CustomerManagementService->new
        ->ApplicationToken("application token")
        ->DeveloperToken("developer token")
        ->Password("password")
        ->UserName("user name");

    my $response = $service_client->AcceptRequestToManageAccounts(
        ManageAccountsRequestId => ...
        PaymentMethodId => ...
    );

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for detailed documentation for this service.

=head1 METHODS

=head2 EndPoint

Changes the end point for this service client.

Default value: https://sharedservices.adcenterapi.microsoft.com/Api/CustomerManagement/v8/CustomerManagementService.svc

=head2 ApplicationToken

Gets/sets ApplicationToken (string) in the request header

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
    return 'CustomerManagementService';
}

sub _service_version {
    return 'V8';
}

sub _class_name {
    return 'CustomerManagementService';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customermanagement';
}

sub _default_location {
    return 'https://sharedservices.adcenterapi.microsoft.com/Api/CustomerManagement/v8/CustomerManagementService.svc';
}

sub _wsdl {
    return 'https://sharedservices.adcenterapi.microsoft.com/Api/CustomerManagement/v8/CustomerManagementService.svc?wsdl';
}

our $_request_headers = [
    { name => 'ApplicationToken', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
    { name => 'DeveloperToken', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
    { name => 'Password', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
    { name => 'UserName', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
];

our $_request_headers_expanded = {
    ApplicationToken => 'string',
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
    { name => 'TrackingId', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
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

=head2 AcceptRequestToManageAccounts

=over

=item Parameters:

    ManageAccountsRequestId (long)
    PaymentMethodId (long)

=item Returns:

    AcceptRequestToManageAccountsResponse

=back

=cut

sub AcceptRequestToManageAccounts {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AcceptRequestToManageAccounts',
        request => {
            name => 'AcceptRequestToManageAccountsRequest',
            parameters => [
                { name => 'ManageAccountsRequestId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'PaymentMethodId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'AcceptRequestToManageAccountsResponse'
        },
        parameters => \%args
    );
}

=head2 AddAccount

=over

=item Parameters:

    Account (Account)

=item Returns:

    AddAccountResponse

=back

=cut

sub AddAccount {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddAccount',
        request => {
            name => 'AddAccountRequest',
            parameters => [
                { name => 'Account', type => 'Account', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'AddAccountResponse'
        },
        parameters => \%args
    );
}

=head2 AddPrepayAccount

=over

=item Parameters:

    Account (Account)

=item Returns:

    AddPrepayAccountResponse

=back

=cut

sub AddPrepayAccount {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddPrepayAccount',
        request => {
            name => 'AddPrepayAccountRequest',
            parameters => [
                { name => 'Account', type => 'Account', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'AddPrepayAccountResponse'
        },
        parameters => \%args
    );
}

=head2 AddUser

=over

=item Parameters:

    User (User)
    Role (UserRole)
    AccountIds (ArrayOflong)

=item Returns:

    AddUserResponse

=back

=cut

sub AddUser {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddUser',
        request => {
            name => 'AddUserRequest',
            parameters => [
                { name => 'User', type => 'User', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'Role', type => 'UserRole', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'AccountIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'AddUserResponse'
        },
        parameters => \%args
    );
}

=head2 CancelRequestToManageAccounts

=over

=item Parameters:

    ManageAccountsRequestId (long)

=item Returns:

    CancelRequestToManageAccountsResponse

=back

=cut

sub CancelRequestToManageAccounts {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'CancelRequestToManageAccounts',
        request => {
            name => 'CancelRequestToManageAccountsRequest',
            parameters => [
                { name => 'ManageAccountsRequestId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'CancelRequestToManageAccountsResponse'
        },
        parameters => \%args
    );
}

=head2 DeclineRequestToManageAccounts

=over

=item Parameters:

    ManageAccountsRequestId (long)

=item Returns:

    DeclineRequestToManageAccountsResponse

=back

=cut

sub DeclineRequestToManageAccounts {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeclineRequestToManageAccounts',
        request => {
            name => 'DeclineRequestToManageAccountsRequest',
            parameters => [
                { name => 'ManageAccountsRequestId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'DeclineRequestToManageAccountsResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteAccount

=over

=item Parameters:

    AccountId (long)
    TimeStamp (base64Binary)

=item Returns:

    DeleteAccountResponse

=back

=cut

sub DeleteAccount {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteAccount',
        request => {
            name => 'DeleteAccountRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'TimeStamp', type => 'base64Binary', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'DeleteAccountResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteCustomer

=over

=item Parameters:

    CustomerId (long)
    TimeStamp (base64Binary)

=item Returns:

    DeleteCustomerResponse

=back

=cut

sub DeleteCustomer {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteCustomer',
        request => {
            name => 'DeleteCustomerRequest',
            parameters => [
                { name => 'CustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'TimeStamp', type => 'base64Binary', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'DeleteCustomerResponse'
        },
        parameters => \%args
    );
}

=head2 DeleteUser

=over

=item Parameters:

    UserId (long)
    TimeStamp (base64Binary)

=item Returns:

    DeleteUserResponse

=back

=cut

sub DeleteUser {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DeleteUser',
        request => {
            name => 'DeleteUserRequest',
            parameters => [
                { name => 'UserId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'TimeStamp', type => 'base64Binary', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'DeleteUserResponse'
        },
        parameters => \%args
    );
}

=head2 FindAccounts

=over

=item Parameters:

    CustomerId (long)
    AccountFilter (string)
    TopN (int)
    ApplicationScope (ApplicationType)

=item Returns:

    FindAccountsResponse

=back

=cut

sub FindAccounts {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'FindAccounts',
        request => {
            name => 'FindAccountsRequest',
            parameters => [
                { name => 'CustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'AccountFilter', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'TopN', type => 'int', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'ApplicationScope', type => 'ApplicationType', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'FindAccountsResponse'
        },
        parameters => \%args
    );
}

=head2 FindAccountsOrCustomersInfo

=over

=item Parameters:

    Filter (string)
    TopN (int)
    ApplicationScope (ApplicationType)

=item Returns:

    FindAccountsOrCustomersInfoResponse

=back

=cut

sub FindAccountsOrCustomersInfo {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'FindAccountsOrCustomersInfo',
        request => {
            name => 'FindAccountsOrCustomersInfoRequest',
            parameters => [
                { name => 'Filter', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'TopN', type => 'int', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'ApplicationScope', type => 'ApplicationType', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'FindAccountsOrCustomersInfoResponse'
        },
        parameters => \%args
    );
}

=head2 GetAccessibleCustomer

=over

=item Parameters:

    CustomerId (long)

=item Returns:

    GetAccessibleCustomerResponse

=back

=cut

sub GetAccessibleCustomer {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAccessibleCustomer',
        request => {
            name => 'GetAccessibleCustomerRequest',
            parameters => [
                { name => 'CustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'GetAccessibleCustomerResponse'
        },
        parameters => \%args
    );
}

=head2 GetAccount

=over

=item Parameters:

    AccountId (long)

=item Returns:

    GetAccountResponse

=back

=cut

sub GetAccount {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAccount',
        request => {
            name => 'GetAccountRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'GetAccountResponse'
        },
        parameters => \%args
    );
}

=head2 GetAccountsInfo

=over

=item Parameters:

    CustomerId (long)
    OnlyParentAccounts (boolean)

=item Returns:

    GetAccountsInfoResponse

=back

=cut

sub GetAccountsInfo {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAccountsInfo',
        request => {
            name => 'GetAccountsInfoRequest',
            parameters => [
                { name => 'CustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'OnlyParentAccounts', type => 'boolean', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'GetAccountsInfoResponse'
        },
        parameters => \%args
    );
}

=head2 GetCurrentUser

=over

=item Parameters:


=item Returns:

    GetCurrentUserResponse

=back

=cut

sub GetCurrentUser {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetCurrentUser',
        request => {
            name => 'GetCurrentUserRequest',
            parameters => [
            ]
        },
        response => {
            name => 'GetCurrentUserResponse'
        },
        parameters => \%args
    );
}

=head2 GetCustomer

=over

=item Parameters:

    CustomerId (long)

=item Returns:

    GetCustomerResponse

=back

=cut

sub GetCustomer {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetCustomer',
        request => {
            name => 'GetCustomerRequest',
            parameters => [
                { name => 'CustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'GetCustomerResponse'
        },
        parameters => \%args
    );
}

=head2 GetCustomerPilotFeature

=over

=item Parameters:

    CustomerId (long)

=item Returns:

    GetCustomerPilotFeatureResponse

=back

=cut

sub GetCustomerPilotFeature {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetCustomerPilotFeature',
        request => {
            name => 'GetCustomerPilotFeatureRequest',
            parameters => [
                { name => 'CustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'GetCustomerPilotFeatureResponse'
        },
        parameters => \%args
    );
}

=head2 GetCustomersInfo

=over

=item Parameters:

    CustomerNameFilter (string)
    TopN (int)
    ApplicationScope (ApplicationType)

=item Returns:

    GetCustomersInfoResponse

=back

=cut

sub GetCustomersInfo {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetCustomersInfo',
        request => {
            name => 'GetCustomersInfoRequest',
            parameters => [
                { name => 'CustomerNameFilter', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'TopN', type => 'int', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'ApplicationScope', type => 'ApplicationType', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'GetCustomersInfoResponse'
        },
        parameters => \%args
    );
}

=head2 GetPilotFeaturesCountries

=over

=item Parameters:


=item Returns:

    GetPilotFeaturesCountriesResponse

=back

=cut

sub GetPilotFeaturesCountries {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetPilotFeaturesCountries',
        request => {
            name => 'GetPilotFeaturesCountriesRequest',
            parameters => [
            ]
        },
        response => {
            name => 'GetPilotFeaturesCountriesResponse'
        },
        parameters => \%args
    );
}

=head2 GetRequestToManageAccounts

=over

=item Parameters:

    ManageAccountsRequestId (long)

=item Returns:

    GetRequestToManageAccountsResponse

=back

=cut

sub GetRequestToManageAccounts {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetRequestToManageAccounts',
        request => {
            name => 'GetRequestToManageAccountsRequest',
            parameters => [
                { name => 'ManageAccountsRequestId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'GetRequestToManageAccountsResponse'
        },
        parameters => \%args
    );
}

=head2 GetRequestToManageAccountsInfos

=over

=item Parameters:

    AccountNumber (string)
    CustomerNumber (string)
    RequestsSentAfter (dateTime)
    RequestsSentBefore (dateTime)
    RequestStatusFilter (ArrayOfManageAccountsRequestStatus)
    RequestTypeFilter (ArrayOfManageAccountsRequestType)

=item Returns:

    GetRequestToManageAccountsInfosResponse

=back

=cut

sub GetRequestToManageAccountsInfos {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetRequestToManageAccountsInfos',
        request => {
            name => 'GetRequestToManageAccountsInfosRequest',
            parameters => [
                { name => 'AccountNumber', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'CustomerNumber', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'RequestsSentAfter', type => 'dateTime', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'RequestsSentBefore', type => 'dateTime', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'RequestStatusFilter', type => 'ArrayOfManageAccountsRequestStatus', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'RequestTypeFilter', type => 'ArrayOfManageAccountsRequestType', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'GetRequestToManageAccountsInfosResponse'
        },
        parameters => \%args
    );
}

=head2 GetUser

=over

=item Parameters:

    UserId (long)

=item Returns:

    GetUserResponse

=back

=cut

sub GetUser {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetUser',
        request => {
            name => 'GetUserRequest',
            parameters => [
                { name => 'UserId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'GetUserResponse'
        },
        parameters => \%args
    );
}

=head2 GetUsersInfo

=over

=item Parameters:

    CustomerId (long)
    StatusFilter (UserLifeCycleStatus)

=item Returns:

    GetUsersInfoResponse

=back

=cut

sub GetUsersInfo {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetUsersInfo',
        request => {
            name => 'GetUsersInfoRequest',
            parameters => [
                { name => 'CustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'StatusFilter', type => 'UserLifeCycleStatus', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'GetUsersInfoResponse'
        },
        parameters => \%args
    );
}

=head2 MapAccountIdToExternalAccountIds

=over

=item Parameters:

    AccountId (long)
    ExternalAccountIds (ArrayOfstring)

=item Returns:

    MapAccountIdToExternalAccountIdsResponse

=back

=cut

sub MapAccountIdToExternalAccountIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'MapAccountIdToExternalAccountIds',
        request => {
            name => 'MapAccountIdToExternalAccountIdsRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'ExternalAccountIds', type => 'ArrayOfstring', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'MapAccountIdToExternalAccountIdsResponse'
        },
        parameters => \%args
    );
}

=head2 MapCustomerIdToExternalCustomerId

=over

=item Parameters:

    CustomerId (long)
    ExternalCustomerId (string)

=item Returns:

    MapCustomerIdToExternalCustomerIdResponse

=back

=cut

sub MapCustomerIdToExternalCustomerId {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'MapCustomerIdToExternalCustomerId',
        request => {
            name => 'MapCustomerIdToExternalCustomerIdRequest',
            parameters => [
                { name => 'CustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'ExternalCustomerId', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'MapCustomerIdToExternalCustomerIdResponse'
        },
        parameters => \%args
    );
}

=head2 SendRequestToManageAccounts

=over

=item Parameters:

    ManageAccountsRequest (ManageAccountsRequest)

=item Returns:

    SendRequestToManageAccountsResponse

=back

=cut

sub SendRequestToManageAccounts {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SendRequestToManageAccounts',
        request => {
            name => 'SendRequestToManageAccountsRequest',
            parameters => [
                { name => 'ManageAccountsRequest', type => 'ManageAccountsRequest', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'SendRequestToManageAccountsResponse'
        },
        parameters => \%args
    );
}

=head2 SendRequestToStopManagingAccounts

=over

=item Parameters:

    ManageAccountsRequest (ManageAccountsRequest)

=item Returns:

    SendRequestToStopManagingAccountsResponse

=back

=cut

sub SendRequestToStopManagingAccounts {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SendRequestToStopManagingAccounts',
        request => {
            name => 'SendRequestToStopManagingAccountsRequest',
            parameters => [
                { name => 'ManageAccountsRequest', type => 'ManageAccountsRequest', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'SendRequestToStopManagingAccountsResponse'
        },
        parameters => \%args
    );
}

=head2 SignupCustomer

=over

=item Parameters:

    Customer (Customer)
    User (User)
    Account (Account)
    ParentCustomerId (long)
    ApplicationScope (ApplicationType)

=item Returns:

    SignupCustomerResponse

=back

=cut

sub SignupCustomer {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SignupCustomer',
        request => {
            name => 'SignupCustomerRequest',
            parameters => [
                { name => 'Customer', type => 'Customer', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'User', type => 'User', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'Account', type => 'Account', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'ParentCustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'ApplicationScope', type => 'ApplicationType', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'SignupCustomerResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateAccount

=over

=item Parameters:

    Account (Account)

=item Returns:

    UpdateAccountResponse

=back

=cut

sub UpdateAccount {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateAccount',
        request => {
            name => 'UpdateAccountRequest',
            parameters => [
                { name => 'Account', type => 'Account', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'UpdateAccountResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateCustomer

=over

=item Parameters:

    Customer (Customer)

=item Returns:

    UpdateCustomerResponse

=back

=cut

sub UpdateCustomer {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateCustomer',
        request => {
            name => 'UpdateCustomerRequest',
            parameters => [
                { name => 'Customer', type => 'Customer', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'UpdateCustomerResponse'
        },
        parameters => \%args
    );
}

=head2 UpdatePrepayAccount

=over

=item Parameters:

    Account (Account)

=item Returns:

    UpdatePrepayAccountResponse

=back

=cut

sub UpdatePrepayAccount {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdatePrepayAccount',
        request => {
            name => 'UpdatePrepayAccountRequest',
            parameters => [
                { name => 'Account', type => 'Account', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'UpdatePrepayAccountResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateUser

=over

=item Parameters:

    User (User)

=item Returns:

    UpdateUserResponse

=back

=cut

sub UpdateUser {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateUser',
        request => {
            name => 'UpdateUserRequest',
            parameters => [
                { name => 'User', type => 'User', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'UpdateUserResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateUserRoles

=over

=item Parameters:

    CustomerId (long)
    UserId (long)
    NewRoleId (int)
    NewAccountIds (ArrayOflong)
    NewCustomerIds (ArrayOflong)
    DeleteRoleId (int)
    DeleteAccountIds (ArrayOflong)
    DeleteCustomerIds (ArrayOflong)

=item Returns:

    UpdateUserRolesResponse

=back

=cut

sub UpdateUserRoles {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateUserRoles',
        request => {
            name => 'UpdateUserRolesRequest',
            parameters => [
                { name => 'CustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'UserId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'NewRoleId', type => 'int', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'NewAccountIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'NewCustomerIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'DeleteRoleId', type => 'int', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'DeleteAccountIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/api/customermanagement' },
                { name => 'DeleteCustomerIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'UpdateUserRolesResponse'
        },
        parameters => \%args
    );
}

=head2 UpgradeCustomerToAgency

=over

=item Parameters:

    CustomerId (long)

=item Returns:

    UpgradeCustomerToAgencyResponse

=back

=cut

sub UpgradeCustomerToAgency {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpgradeCustomerToAgency',
        request => {
            name => 'UpgradeCustomerToAgencyRequest',
            parameters => [
                { name => 'CustomerId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customermanagement' }
            ]
        },
        response => {
            name => 'UpgradeCustomerToAgencyResponse'
        },
        parameters => \%args
    );
}

our %_simple_types = (
    AccountFinancialStatus => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    AccountLifeCycleStatus => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    AccountType => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    ApplicationType => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    CurrencyType => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    CustomerFinancialStatus => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    CustomerLifeCycleStatus => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    EmailFormat => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    Industry => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    LCID => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    LanguageType => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    ManageAccountsRequestStatus => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    ManageAccountsRequestType => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    PaymentMethodType => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    SecretQuestion => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    ServiceLevel => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    TimeZoneType => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    UserLifeCycleStatus => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    UserRole => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
    char => 'http://schemas.microsoft.com/2003/10/Serialization/',
    duration => 'http://schemas.microsoft.com/2003/10/Serialization/',
    guid => 'http://schemas.microsoft.com/2003/10/Serialization/',
);

sub _simple_types {
    return %_simple_types;
}

our @_complex_types = (qw/
    AcceptRequestToManageAccountsResponse
    Account
    AccountInfo
    AccountInfoWithCustomerData
    AdApiError
    AdApiFaultDetail
    AddAccountResponse
    AddPrepayAccountResponse
    AddUserResponse
    Address
    AdvertiserAccount
    ApiFault
    ApplicationFault
    CancelRequestToManageAccountsResponse
    ContactInfo
    Customer
    CustomerInfo
    Date
    DeclineRequestToManageAccountsResponse
    DeleteAccountResponse
    DeleteCustomerResponse
    DeleteUserResponse
    FindAccountsOrCustomersInfoResponse
    FindAccountsResponse
    GetAccessibleCustomerResponse
    GetAccountResponse
    GetAccountsInfoResponse
    GetCurrentUserResponse
    GetCustomerPilotFeatureResponse
    GetCustomerResponse
    GetCustomersInfoResponse
    GetPilotFeaturesCountriesResponse
    GetRequestToManageAccountsInfosResponse
    GetRequestToManageAccountsResponse
    GetUserResponse
    GetUsersInfoResponse
    ManageAccountsRequest
    ManageAccountsRequestInfo
    MapAccountIdToExternalAccountIdsResponse
    MapCustomerIdToExternalCustomerIdResponse
    OperationError
    PersonName
    PilotFeature
    PublisherAccount
    SendRequestToManageAccountsResponse
    SendRequestToStopManagingAccountsResponse
    SignupCustomerResponse
    UpdateAccountResponse
    UpdateCustomerResponse
    UpdatePrepayAccountResponse
    UpdateUserResponse
    UpdateUserRolesResponse
    UpgradeCustomerToAgencyResponse
    User
    UserInfo
/);

sub _complex_types {
    return @_complex_types;
}

our %_array_types = (
    ArrayOfAccountInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'AccountInfo',
        element_type => 'AccountInfo'
    },
    ArrayOfAccountInfoWithCustomerData => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'AccountInfoWithCustomerData',
        element_type => 'AccountInfoWithCustomerData'
    },
    ArrayOfAdApiError => {
        namespace_uri => 'https://adapi.microsoft.com',
        element_name => 'AdApiError',
        element_type => 'AdApiError'
    },
    ArrayOfCustomerInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'CustomerInfo',
        element_type => 'CustomerInfo'
    },
    ArrayOfManageAccountsRequestInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'ManageAccountsRequestInfo',
        element_type => 'ManageAccountsRequestInfo'
    },
    ArrayOfManageAccountsRequestStatus => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'ManageAccountsRequestStatus',
        element_type => 'ManageAccountsRequestStatus'
    },
    ArrayOfManageAccountsRequestType => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'ManageAccountsRequestType',
        element_type => 'ManageAccountsRequestType'
    },
    ArrayOfOperationError => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Exception',
        element_name => 'OperationError',
        element_type => 'OperationError'
    },
    ArrayOfPilotFeature => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'PilotFeature',
        element_type => 'PilotFeature'
    },
    ArrayOfUserInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'UserInfo',
        element_type => 'UserInfo'
    },
    ArrayOfint => {
        namespace_uri => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays',
        element_name => 'int',
        element_type => 'int'
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
    DeveloperToken
    Password
    UserName
    TrackingId
/);

1;
