package Microsoft::AdCenter::V8::NotificationService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::NotificationService - Service client for Microsoft AdCenter Notification Service.

=head1 SYNOPSIS

    use Microsoft::AdCenter::V8::NotificationService;

    my $service_client = Microsoft::AdCenter::V8::NotificationService->new
        ->ApplicationToken("application token")
        ->DeveloperToken("developer token")
        ->Password("password")
        ->UserName("user name");

    my $response = $service_client->GetArchivedNotifications(
        NotificationTypes => ...
        TopN => ...
        StartDate => ...
        EndDate => ...
    );

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for detailed documentation for this service.

=head1 METHODS

=head2 EndPoint

Changes the end point for this service client.

Default value: https://sharedservices.adcenterapi.microsoft.com/Api/Notification/v8/NotificationService.svc

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
    return 'NotificationService';
}

sub _service_version {
    return 'V8';
}

sub _class_name {
    return 'NotificationService';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/notifications';
}

sub _default_location {
    return 'https://sharedservices.adcenterapi.microsoft.com/Api/Notification/v8/NotificationService.svc';
}

sub _wsdl {
    return 'https://sharedservices.adcenterapi.microsoft.com/Api/Notification/v8/NotificationService.svc?wsdl';
}

our $_request_headers = [
    { name => 'ApplicationToken', type => 'string', namespace => 'https://adcenter.microsoft.com/api/notifications' },
    { name => 'DeveloperToken', type => 'string', namespace => 'https://adcenter.microsoft.com/api/notifications' },
    { name => 'Password', type => 'string', namespace => 'https://adcenter.microsoft.com/api/notifications' },
    { name => 'UserName', type => 'string', namespace => 'https://adcenter.microsoft.com/api/notifications' }
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
    { name => 'TrackingId', type => 'string', namespace => 'https://adcenter.microsoft.com/api/notifications' }
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

=head2 GetArchivedNotifications

=over

=item Parameters:

    NotificationTypes (NotificationType)
    TopN (int)
    StartDate (dateTime)
    EndDate (dateTime)

=item Returns:

    GetArchivedNotificationsResponse

=back

=cut

sub GetArchivedNotifications {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetArchivedNotifications',
        request => {
            name => 'GetArchivedNotificationsRequest',
            parameters => [
                { name => 'NotificationTypes', type => 'NotificationType', namespace => 'https://adcenter.microsoft.com/api/notifications' },
                { name => 'TopN', type => 'int', namespace => 'https://adcenter.microsoft.com/api/notifications' },
                { name => 'StartDate', type => 'dateTime', namespace => 'https://adcenter.microsoft.com/api/notifications' },
                { name => 'EndDate', type => 'dateTime', namespace => 'https://adcenter.microsoft.com/api/notifications' }
            ]
        },
        response => {
            name => 'GetArchivedNotificationsResponse'
        },
        parameters => \%args
    );
}

=head2 GetNotifications

=over

=item Parameters:

    NotificationTypes (NotificationType)
    TopN (int)

=item Returns:

    GetNotificationsResponse

=back

=cut

sub GetNotifications {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetNotifications',
        request => {
            name => 'GetNotificationsRequest',
            parameters => [
                { name => 'NotificationTypes', type => 'NotificationType', namespace => 'https://adcenter.microsoft.com/api/notifications' },
                { name => 'TopN', type => 'int', namespace => 'https://adcenter.microsoft.com/api/notifications' }
            ]
        },
        response => {
            name => 'GetNotificationsResponse'
        },
        parameters => \%args
    );
}

our %_simple_types = (
    NotificationType => 'https://adcenter.microsoft.com/api/notifications/Entities',
    char => 'http://schemas.microsoft.com/2003/10/Serialization/',
    duration => 'http://schemas.microsoft.com/2003/10/Serialization/',
    guid => 'http://schemas.microsoft.com/2003/10/Serialization/',
);

sub _simple_types {
    return %_simple_types;
}

our @_complex_types = (qw/
    AccountNotification
    AdApiError
    AdApiFaultDetail
    ApiFault
    ApplicationFault
    BudgetDepletedCampaignInfo
    BudgetDepletedNotification
    CampaignInfo
    CreditCardPendingExpirationNotification
    EditorialRejectionNotification
    ExpiredCreditCardNotification
    ExpiredInsertionOrderNotification
    GetArchivedNotificationsResponse
    GetNotificationsResponse
    LowBudgetBalanceCampaignInfo
    LowBudgetBalanceNotification
    Notification
    OperationError
/);

sub _complex_types {
    return @_complex_types;
}

our %_array_types = (
    ArrayOfAdApiError => {
        namespace_uri => 'https://adapi.microsoft.com',
        element_name => 'AdApiError',
        element_type => 'AdApiError'
    },
    ArrayOfBudgetDepletedCampaignInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/api/notifications/Entities',
        element_name => 'BudgetDepletedCampaignInfo',
        element_type => 'BudgetDepletedCampaignInfo'
    },
    ArrayOfLowBudgetBalanceCampaignInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/api/notifications/Entities',
        element_name => 'LowBudgetBalanceCampaignInfo',
        element_type => 'LowBudgetBalanceCampaignInfo'
    },
    ArrayOfNotification => {
        namespace_uri => 'https://adcenter.microsoft.com/api/notifications/Entities',
        element_name => 'Notification',
        element_type => 'Notification'
    },
    ArrayOfOperationError => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Exception',
        element_name => 'OperationError',
        element_type => 'OperationError'
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
