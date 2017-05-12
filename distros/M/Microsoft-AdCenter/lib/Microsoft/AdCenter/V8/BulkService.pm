package Microsoft::AdCenter::V8::BulkService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::BulkService - Service client for Microsoft AdCenter Bulk Service.

=head1 SYNOPSIS

    use Microsoft::AdCenter::V8::BulkService;

    my $service_client = Microsoft::AdCenter::V8::BulkService->new
        ->ApplicationToken("application token")
        ->CustomerAccountId("customer account id")
        ->CustomerId("customer id")
        ->DeveloperToken("developer token")
        ->Password("password")
        ->UserName("user name");

    my $response = $service_client->DownloadCampaignsByAccountIds(
        AccountIds => ...
        AdditionalEntities => ...
        LastSyncTimeInUTC => ...
        LocationTargetVersion => ...
    );

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for detailed documentation for this service.

=head1 METHODS

=head2 EndPoint

Changes the end point for this service client.

Default value: https://adcenterapi.microsoft.com/Api/Advertiser/V8/CampaignManagement/BulkService.svc

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
    return 'BulkService';
}

sub _service_version {
    return 'V8';
}

sub _class_name {
    return 'BulkService';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

sub _default_location {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/V8/CampaignManagement/BulkService.svc';
}

sub _wsdl {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/v8/CampaignManagement/BulkService.svc?wsdl';
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

=head2 DownloadCampaignsByAccountIds

=over

=item Parameters:

    AccountIds (ArrayOflong)
    AdditionalEntities (AdditionalEntity)
    LastSyncTimeInUTC (dateTime)
    LocationTargetVersion (string)

=item Returns:

    DownloadCampaignsByAccountIdsResponse

=back

=cut

sub DownloadCampaignsByAccountIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DownloadCampaignsByAccountIds',
        request => {
            name => 'DownloadCampaignsByAccountIdsRequest',
            parameters => [
                { name => 'AccountIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdditionalEntities', type => 'AdditionalEntity', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'LastSyncTimeInUTC', type => 'dateTime', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'LocationTargetVersion', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'DownloadCampaignsByAccountIdsResponse'
        },
        parameters => \%args
    );
}

=head2 DownloadCampaignsByCampaignIds

=over

=item Parameters:

    AdditionalEntities (AdditionalEntity)
    Campaigns (ArrayOfCampaignScope)
    LastSyncTimeInUTC (dateTime)
    LocationTargetVersion (string)

=item Returns:

    DownloadCampaignsByCampaignIdsResponse

=back

=cut

sub DownloadCampaignsByCampaignIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'DownloadCampaignsByCampaignIds',
        request => {
            name => 'DownloadCampaignsByCampaignIdsRequest',
            parameters => [
                { name => 'AdditionalEntities', type => 'AdditionalEntity', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'Campaigns', type => 'ArrayOfCampaignScope', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'LastSyncTimeInUTC', type => 'dateTime', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'LocationTargetVersion', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'DownloadCampaignsByCampaignIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetDownloadStatus

=over

=item Parameters:

    DownloadRequestId (string)

=item Returns:

    GetDownloadStatusResponse

=back

=cut

sub GetDownloadStatus {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetDownloadStatus',
        request => {
            name => 'GetDownloadStatusRequest',
            parameters => [
                { name => 'DownloadRequestId', type => 'string', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetDownloadStatusResponse'
        },
        parameters => \%args
    );
}

our %_simple_types = (
    AdditionalEntity => 'https://adcenter.microsoft.com/v8',
    DownloadStatus => 'https://adcenter.microsoft.com/v8',
    char => 'http://schemas.microsoft.com/2003/10/Serialization/',
    duration => 'http://schemas.microsoft.com/2003/10/Serialization/',
    guid => 'http://schemas.microsoft.com/2003/10/Serialization/',
);

sub _simple_types {
    return %_simple_types;
}

our @_complex_types = (qw/
    AdApiError
    AdApiFaultDetail
    ApiFaultDetail
    ApplicationFault
    BatchError
    CampaignScope
    DownloadCampaignsByAccountIdsResponse
    DownloadCampaignsByCampaignIdsResponse
    GetDownloadStatusResponse
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
    ArrayOfBatchError => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'BatchError',
        element_type => 'BatchError'
    },
    ArrayOfCampaignScope => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'CampaignScope',
        element_type => 'CampaignScope'
    },
    ArrayOfOperationError => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'OperationError',
        element_type => 'OperationError'
    },
    ArrayOflong => {
        namespace_uri => 'http://schemas.microsoft.com/2003/10/Serialization/Arrays',
        element_name => 'long',
        element_type => 'long'
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
