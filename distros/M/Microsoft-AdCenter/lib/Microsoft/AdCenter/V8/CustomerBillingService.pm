package Microsoft::AdCenter::V8::CustomerBillingService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::CustomerBillingService - Service client for Microsoft AdCenter Customer Billing Service.

=head1 SYNOPSIS

    use Microsoft::AdCenter::V8::CustomerBillingService;

    my $service_client = Microsoft::AdCenter::V8::CustomerBillingService->new
        ->ApplicationToken("application token")
        ->DeveloperToken("developer token")
        ->Password("password")
        ->UserName("user name");

    my $response = $service_client->AddInsertionOrder(
        InsertionOrder => ...
    );

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for detailed documentation for this service.

=head1 METHODS

=head2 EndPoint

Changes the end point for this service client.

Default value: https://sharedservices.adcenterapi.microsoft.com/Api/Billing/v8/CustomerBillingService.svc

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
    return 'CustomerBillingService';
}

sub _service_version {
    return 'V8';
}

sub _class_name {
    return 'CustomerBillingService';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/api/customerbilling';
}

sub _default_location {
    return 'https://sharedservices.adcenterapi.microsoft.com/Api/Billing/v8/CustomerBillingService.svc';
}

sub _wsdl {
    return 'https://sharedservices.adcenterapi.microsoft.com/Api/Billing/v8/CustomerBillingService.svc?wsdl';
}

our $_request_headers = [
    { name => 'ApplicationToken', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customerbilling' },
    { name => 'DeveloperToken', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customerbilling' },
    { name => 'Password', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customerbilling' },
    { name => 'UserName', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customerbilling' }
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
    { name => 'TrackingId', type => 'string', namespace => 'https://adcenter.microsoft.com/api/customerbilling' }
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

=head2 AddInsertionOrder

=over

=item Parameters:

    InsertionOrder (InsertionOrder)

=item Returns:

    AddInsertionOrderResponse

=back

=cut

sub AddInsertionOrder {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'AddInsertionOrder',
        request => {
            name => 'AddInsertionOrderRequest',
            parameters => [
                { name => 'InsertionOrder', type => 'InsertionOrder', namespace => 'https://adcenter.microsoft.com/api/customerbilling' }
            ]
        },
        response => {
            name => 'AddInsertionOrderResponse'
        },
        parameters => \%args
    );
}

=head2 GetAccountMonthlySpend

=over

=item Parameters:

    AccountId (long)
    MonthYear (dateTime)

=item Returns:

    GetAccountMonthlySpendResponse

=back

=cut

sub GetAccountMonthlySpend {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetAccountMonthlySpend',
        request => {
            name => 'GetAccountMonthlySpendRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customerbilling' },
                { name => 'MonthYear', type => 'dateTime', namespace => 'https://adcenter.microsoft.com/api/customerbilling' }
            ]
        },
        response => {
            name => 'GetAccountMonthlySpendResponse'
        },
        parameters => \%args
    );
}

=head2 GetDisplayInvoices

=over

=item Parameters:

    InvoiceIds (ArrayOflong)
    Type (DataType)

=item Returns:

    GetDisplayInvoicesResponse

=back

=cut

sub GetDisplayInvoices {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetDisplayInvoices',
        request => {
            name => 'GetDisplayInvoicesRequest',
            parameters => [
                { name => 'InvoiceIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/api/customerbilling' },
                { name => 'Type', type => 'DataType', namespace => 'https://adcenter.microsoft.com/api/customerbilling' }
            ]
        },
        response => {
            name => 'GetDisplayInvoicesResponse'
        },
        parameters => \%args
    );
}

=head2 GetInsertionOrdersByAccount

=over

=item Parameters:

    AccountId (long)
    InsertionOrderIds (ArrayOflong)

=item Returns:

    GetInsertionOrdersByAccountResponse

=back

=cut

sub GetInsertionOrdersByAccount {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetInsertionOrdersByAccount',
        request => {
            name => 'GetInsertionOrdersByAccountRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/api/customerbilling' },
                { name => 'InsertionOrderIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/api/customerbilling' }
            ]
        },
        response => {
            name => 'GetInsertionOrdersByAccountResponse'
        },
        parameters => \%args
    );
}

=head2 GetInvoices

=over

=item Parameters:

    InvoiceIds (ArrayOflong)
    Type (DataType)

=item Returns:

    GetInvoicesResponse

=back

=cut

sub GetInvoices {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetInvoices',
        request => {
            name => 'GetInvoicesRequest',
            parameters => [
                { name => 'InvoiceIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/api/customerbilling' },
                { name => 'Type', type => 'DataType', namespace => 'https://adcenter.microsoft.com/api/customerbilling' }
            ]
        },
        response => {
            name => 'GetInvoicesResponse'
        },
        parameters => \%args
    );
}

=head2 GetInvoicesInfo

=over

=item Parameters:

    AccountIds (ArrayOflong)
    StartDate (dateTime)
    EndDate (dateTime)

=item Returns:

    GetInvoicesInfoResponse

=back

=cut

sub GetInvoicesInfo {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetInvoicesInfo',
        request => {
            name => 'GetInvoicesInfoRequest',
            parameters => [
                { name => 'AccountIds', type => 'ArrayOflong', namespace => 'https://adcenter.microsoft.com/api/customerbilling' },
                { name => 'StartDate', type => 'dateTime', namespace => 'https://adcenter.microsoft.com/api/customerbilling' },
                { name => 'EndDate', type => 'dateTime', namespace => 'https://adcenter.microsoft.com/api/customerbilling' }
            ]
        },
        response => {
            name => 'GetInvoicesInfoResponse'
        },
        parameters => \%args
    );
}

=head2 GetKOHIOInvoices

=over

=item Parameters:

    InvoiceIds (ArrayOfstring)

=item Returns:

    GetKOHIOInvoicesResponse

=back

=cut

sub GetKOHIOInvoices {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetKOHIOInvoices',
        request => {
            name => 'GetKOHIOInvoicesRequest',
            parameters => [
                { name => 'InvoiceIds', type => 'ArrayOfstring', namespace => 'https://adcenter.microsoft.com/api/customerbilling' }
            ]
        },
        response => {
            name => 'GetKOHIOInvoicesResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateInsertionOrder

=over

=item Parameters:

    InsertionOrder (InsertionOrder)

=item Returns:

    UpdateInsertionOrderResponse

=back

=cut

sub UpdateInsertionOrder {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'UpdateInsertionOrder',
        request => {
            name => 'UpdateInsertionOrderRequest',
            parameters => [
                { name => 'InsertionOrder', type => 'InsertionOrder', namespace => 'https://adcenter.microsoft.com/api/customerbilling' }
            ]
        },
        response => {
            name => 'UpdateInsertionOrderResponse'
        },
        parameters => \%args
    );
}

our %_simple_types = (
    DataType => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
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
    AddInsertionOrderResponse
    ApiBatchFault
    ApiFault
    ApplicationFault
    BatchError
    GetAccountMonthlySpendResponse
    GetDisplayInvoicesResponse
    GetInsertionOrdersByAccountResponse
    GetInvoicesInfoResponse
    GetInvoicesResponse
    GetKOHIOInvoicesResponse
    InsertionOrder
    Invoice
    InvoiceInfo
    OperationError
    UpdateInsertionOrderResponse
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
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Exception',
        element_name => 'BatchError',
        element_type => 'BatchError'
    },
    ArrayOfInsertionOrder => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'InsertionOrder',
        element_type => 'InsertionOrder'
    },
    ArrayOfInvoice => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'Invoice',
        element_type => 'Invoice'
    },
    ArrayOfInvoiceInfo => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Entities',
        element_name => 'InvoiceInfo',
        element_type => 'InvoiceInfo'
    },
    ArrayOfOperationError => {
        namespace_uri => 'https://adcenter.microsoft.com/api/customermanagement/Exception',
        element_name => 'OperationError',
        element_type => 'OperationError'
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
