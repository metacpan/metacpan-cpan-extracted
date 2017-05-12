package Microsoft::AdCenter::V6::CustomerManagementService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V6::CustomerManagementService - Service client for Microsoft AdCenter Customer Management Service.

=head1 SYNOPSIS

    use Microsoft::AdCenter::V6::CustomerManagementService;

    my $service_client = Microsoft::AdCenter::V6::CustomerManagementService->new
        ->Password("password");
        ->UserAccessKey("user access key")
        ->UserName("user name")

    my $response = $service_client->CustomerSignUp(
        apiFlags => ...
        user => ...
        customer => ...
        account => ...
        consentToTermsAndConditions => ...
        couponCode => ...
    );

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for detailed documentation for this service.

=head1 METHODS

=head2 EndPoint

Changes the end point for this service client.

Default value: https://adcenterapi.microsoft.com/Api/Advertiser/v6/CustomerManagement/CustomerManagement.asmx

=head2 Password

Gets/sets Password (string) in the request header

=head2 UserAccessKey

Gets/sets UserAccessKey (string) in the request header

=head2 UserName

Gets/sets UserName (string) in the request header

=cut

use base qw/Microsoft::AdCenter::Service/;

sub _service_name {
    return 'CustomerManagement';
}

sub _service_version {
    return 'V6';
}

sub _class_name {
    return 'CustomerManagementService';
}

sub _namespace_uri {
    return 'http://adcenter.microsoft.com/syncapis';
}

sub _default_location {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/v6/CustomerManagement/CustomerManagement.asmx';
}

sub _wsdl {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/v6/CustomerManagement/CustomerManagement.asmx?wsdl';
}

our $_request_headers = [
    { name => 'ApiUserAuthHeader', type => 'ApiUserAuthHeader', namespace => 'http://adcenter.microsoft.com/syncapis' }
];

our $_request_headers_expanded = {
    Password => 'string',
    UserAccessKey => 'string',
    UserName => 'string'
};

sub _request_headers {
    return $_request_headers;
}

sub _request_headers_expanded {
    return $_request_headers_expanded;
}

our $_response_headers = [
];

our $_response_headers_expanded = {
};

sub _response_headers {
    return $_response_headers;
}

sub _response_headers_expanded {
    return $_response_headers_expanded;
}

=head2 CustomerSignUp

=over

=item Parameters:

    apiFlags (int)
    user (AdCenterUser)
    customer (AdCenterCustomer)
    account (AdCenterAccount)
    consentToTermsAndConditions (boolean)
    couponCode (string)

=item Returns:

    CustomerSignUpResponse

=back

=cut

sub CustomerSignUp {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'http://adcenter.microsoft.com/syncapis/CustomerSignUp',
        request => {
            name => 'CustomerSignUp',
            parameters => [
                { name => 'apiFlags', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'user', type => 'AdCenterUser', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'customer', type => 'AdCenterCustomer', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'account', type => 'AdCenterAccount', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'consentToTermsAndConditions', type => 'boolean', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'couponCode', type => 'string', namespace => 'http://adcenter.microsoft.com/syncapis' }
            ]
        },
        response => {
            name => 'CustomerSignUpResponse'
        },
        parameters => \%args
    );
}

=head2 GetAccountBillingInfo

=over

=item Parameters:

    apiFlags (int)
    accountId (int)
    customerId (int)
    userId (int)
    activityDays (int)

=item Returns:

    GetAccountBillingInfoResponse

=back

=cut

sub GetAccountBillingInfo {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'http://adcenter.microsoft.com/syncapis/GetAccountBillingInfo',
        request => {
            name => 'GetAccountBillingInfo',
            parameters => [
                { name => 'apiFlags', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'accountId', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'customerId', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'userId', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'activityDays', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' }
            ]
        },
        response => {
            name => 'GetAccountBillingInfoResponse'
        },
        parameters => \%args
    );
}

=head2 GetAccounts

=over

=item Parameters:

    APIFlags (int)

=item Returns:

    GetAccountsResponse

=back

=cut

sub GetAccounts {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'http://adcenter.microsoft.com/syncapis/GetAccounts',
        request => {
            name => 'GetAccounts',
            parameters => [
                { name => 'APIFlags', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' }
            ]
        },
        response => {
            name => 'GetAccountsResponse'
        },
        parameters => \%args
    );
}

=head2 GetAccountsByIds

=over

=item Parameters:

    APIFlags (int)
    accountIds (ArrayOfInt)

=item Returns:

    GetAccountsByIdsResponse

=back

=cut

sub GetAccountsByIds {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'http://adcenter.microsoft.com/syncapis/GetAccountsByIds',
        request => {
            name => 'GetAccountsByIds',
            parameters => [
                { name => 'APIFlags', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'accountIds', type => 'ArrayOfInt', namespace => 'http://adcenter.microsoft.com/syncapis' }
            ]
        },
        response => {
            name => 'GetAccountsByIdsResponse'
        },
        parameters => \%args
    );
}

=head2 GetCardInvoice

=over

=item Parameters:

    apiFlags (int)
    customerId (int)
    userId (int)
    handle (AdCenterCardInvoiceHandle)

=item Returns:

    GetCardInvoiceResponse

=back

=cut

sub GetCardInvoice {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'http://adcenter.microsoft.com/syncapis/GetCardInvoice',
        request => {
            name => 'GetCardInvoice',
            parameters => [
                { name => 'apiFlags', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'customerId', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'userId', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'handle', type => 'AdCenterCardInvoiceHandle', namespace => 'http://adcenter.microsoft.com/syncapis' }
            ]
        },
        response => {
            name => 'GetCardInvoiceResponse'
        },
        parameters => \%args
    );
}

=head2 GetCustomer

=over

=item Parameters:

    apiFlags (int)
    customerId (int)

=item Returns:

    GetCustomerResponse

=back

=cut

sub GetCustomer {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'http://adcenter.microsoft.com/syncapis/GetCustomer',
        request => {
            name => 'GetCustomer',
            parameters => [
                { name => 'apiFlags', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'customerId', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' }
            ]
        },
        response => {
            name => 'GetCustomerResponse'
        },
        parameters => \%args
    );
}

=head2 GetPaymentInstrument

=over

=item Parameters:

    apiFlags (int)
    accountId (int)

=item Returns:

    GetPaymentInstrumentResponse

=back

=cut

sub GetPaymentInstrument {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'http://adcenter.microsoft.com/syncapis/GetPaymentInstrument',
        request => {
            name => 'GetPaymentInstrument',
            parameters => [
                { name => 'apiFlags', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'accountId', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' }
            ]
        },
        response => {
            name => 'GetPaymentInstrumentResponse'
        },
        parameters => \%args
    );
}

=head2 UpdateCustomer

=over

=item Parameters:

    apiFlags (int)
    customer (AdCenterCustomer)

=item Returns:

    UpdateCustomerResponse

=back

=cut

sub UpdateCustomer {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'http://adcenter.microsoft.com/syncapis/UpdateCustomer',
        request => {
            name => 'UpdateCustomer',
            parameters => [
                { name => 'apiFlags', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'customer', type => 'AdCenterCustomer', namespace => 'http://adcenter.microsoft.com/syncapis' }
            ]
        },
        response => {
            name => 'UpdateCustomerResponse'
        },
        parameters => \%args
    );
}

=head2 UpdatePaymentInstrument

=over

=item Parameters:

    apiFlags (int)
    accountId (int)
    creditCard (AdCenterCreditCard)

=item Returns:

    UpdatePaymentInstrumentResponse

=back

=cut

sub UpdatePaymentInstrument {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'http://adcenter.microsoft.com/syncapis/UpdatePaymentInstrument',
        request => {
            name => 'UpdatePaymentInstrument',
            parameters => [
                { name => 'apiFlags', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'accountId', type => 'int', namespace => 'http://adcenter.microsoft.com/syncapis' },
                { name => 'creditCard', type => 'AdCenterCreditCard', namespace => 'http://adcenter.microsoft.com/syncapis' }
            ]
        },
        response => {
            name => 'UpdatePaymentInstrumentResponse'
        },
        parameters => \%args
    );
}

our %_simple_types = (
    AccountStatus => 'http://adcenter.microsoft.com/syncapis',
    CountryCode => 'http://adcenter.microsoft.com/syncapis',
    CreditCardType => 'http://adcenter.microsoft.com/syncapis',
    Currency => 'http://adcenter.microsoft.com/syncapis',
    CurrencyType => 'http://adcenter.microsoft.com/syncapis',
    EmailFormat => 'http://adcenter.microsoft.com/syncapis',
    ErrorLevel => 'http://adcenter.microsoft.com/syncapis',
    Industry => 'http://adcenter.microsoft.com/syncapis',
    LCID => 'http://adcenter.microsoft.com/syncapis',
    LanguageType => 'http://adcenter.microsoft.com/syncapis',
    Market => 'http://adcenter.microsoft.com/syncapis',
    PaymentOption => 'http://adcenter.microsoft.com/syncapis',
    ResultStatus => 'http://adcenter.microsoft.com/syncapis',
    SecretQuestions => 'http://adcenter.microsoft.com/syncapis',
);

sub _simple_types {
    return %_simple_types;
}

our @_complex_types = (qw/
    AdCenterAccount
    AdCenterAddress
    AdCenterCardBillingStatement
    AdCenterCardBillingStatementEntry
    AdCenterCardInvoice
    AdCenterCardInvoiceEntry
    AdCenterCardInvoiceHandle
    AdCenterCardInvoiceHeader
    AdCenterContactInfo
    AdCenterCreditCard
    AdCenterCustomer
    AdCenterPaymentInstrument
    AdCenterSap
    AdCenterStatementEntry
    AdCenterUser
    ApiUserAuthHeader
    CardInvoiceResponseMsg
    CreditCardInfoUpdateResponseMsg
    CustomerSignUpResponse
    CustomerSignUpResponseMsg
    CustomerUpdateResponseMsg
    ErrorInfo
    GetAccountBillingInfoResponse
    GetAccountBillingInfoResponseMsg
    GetAccountsByIdsResponse
    GetAccountsResponse
    GetCardInvoiceResponse
    GetCreditCardInfoResponseMsg
    GetCustomerResponse
    GetCustomerResponseMsg
    GetPaymentInstrumentResponse
    OperationResult
    ResponseMsg
    UpdateCustomerResponse
    UpdatePaymentInstrumentResponse
/);

sub _complex_types {
    return @_complex_types;
}

our %_array_types = (
    ArrayOfAdCenterAccount => {
        namespace_uri => 'http://adcenter.microsoft.com/syncapis',
        element_name => 'AdCenterAccount',
        element_type => 'AdCenterAccount'
    },
    ArrayOfAdCenterCardBillingStatementEntry => {
        namespace_uri => 'http://adcenter.microsoft.com/syncapis',
        element_name => 'AdCenterCardBillingStatementEntry',
        element_type => 'AdCenterCardBillingStatementEntry'
    },
    ArrayOfAdCenterCardInvoiceEntry => {
        namespace_uri => 'http://adcenter.microsoft.com/syncapis',
        element_name => 'AdCenterCardInvoiceEntry',
        element_type => 'AdCenterCardInvoiceEntry'
    },
    ArrayOfAdCenterCreditCard => {
        namespace_uri => 'http://adcenter.microsoft.com/syncapis',
        element_name => 'AdCenterCreditCard',
        element_type => 'AdCenterCreditCard'
    },
    ArrayOfErrorInfo => {
        namespace_uri => 'http://adcenter.microsoft.com/syncapis',
        element_name => 'ErrorInfo',
        element_type => 'ErrorInfo'
    },
    ArrayOfInt => {
        namespace_uri => 'http://adcenter.microsoft.com/syncapis',
        element_name => 'int',
        element_type => 'int'
    },
    ArrayOfString => {
        namespace_uri => 'http://adcenter.microsoft.com/syncapis',
        element_name => 'string',
        element_type => 'string'
    },
);

sub _array_types {
    return %_array_types;
}

__PACKAGE__->mk_accessors(qw/
    Password
    UserAccessKey
    UserName
/);

1;
