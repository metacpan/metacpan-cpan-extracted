package Microsoft::AdCenter::V8::OptimizerService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V8::OptimizerService - Service client for Microsoft AdCenter Optimizer Service.

=head1 SYNOPSIS

    use Microsoft::AdCenter::V8::OptimizerService;

    my $service_client = Microsoft::AdCenter::V8::OptimizerService->new
        ->ApplicationToken("application token")
        ->CustomerAccountId("customer account id")
        ->CustomerId("customer id")
        ->DeveloperToken("developer token")
        ->Password("password")
        ->UserName("user name");

    my $response = $service_client->ApplyBudgetOpportunities(
        AccountId => ...
        OpportunityKeys => ...
    );

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for detailed documentation for this service.

=head1 METHODS

=head2 EndPoint

Changes the end point for this service client.

Default value: https://adcenterapi.microsoft.com/Api/Advertiser/V8/Optimizer/OptimizerService.svc

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
    return 'OptimizerService';
}

sub _service_version {
    return 'V8';
}

sub _class_name {
    return 'OptimizerService';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v8';
}

sub _default_location {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/V8/Optimizer/OptimizerService.svc';
}

sub _wsdl {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/v8/Optimizer/OptimizerService.svc?wsdl';
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

=head2 ApplyBudgetOpportunities

=over

=item Parameters:

    AccountId (long)
    OpportunityKeys (ArrayOfstring)

=item Returns:

    ApplyBudgetOpportunitiesResponse

=back

=cut

sub ApplyBudgetOpportunities {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'ApplyBudgetOpportunities',
        request => {
            name => 'ApplyBudgetOpportunitiesRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'OpportunityKeys', type => 'ArrayOfstring', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'ApplyBudgetOpportunitiesResponse'
        },
        parameters => \%args
    );
}

=head2 ApplyOpportunities

=over

=item Parameters:

    AccountId (long)
    OpportunityKeys (ArrayOfstring)

=item Returns:

    ApplyOpportunitiesResponse

=back

=cut

sub ApplyOpportunities {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'ApplyOpportunities',
        request => {
            name => 'ApplyOpportunitiesRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'OpportunityKeys', type => 'ArrayOfstring', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'ApplyOpportunitiesResponse'
        },
        parameters => \%args
    );
}

=head2 GetBidOpportunities

=over

=item Parameters:

    AccountId (long)
    AdGroupId (long)
    CampaignId (long)

=item Returns:

    GetBidOpportunitiesResponse

=back

=cut

sub GetBidOpportunities {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetBidOpportunities',
        request => {
            name => 'GetBidOpportunitiesRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'AdGroupId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' },
                { name => 'CampaignId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetBidOpportunitiesResponse'
        },
        parameters => \%args
    );
}

=head2 GetBudgetOpportunities

=over

=item Parameters:

    AccountId (long)

=item Returns:

    GetBudgetOpportunitiesResponse

=back

=cut

sub GetBudgetOpportunities {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'GetBudgetOpportunities',
        request => {
            name => 'GetBudgetOpportunitiesRequest',
            parameters => [
                { name => 'AccountId', type => 'long', namespace => 'https://adcenter.microsoft.com/v8' }
            ]
        },
        response => {
            name => 'GetBudgetOpportunitiesResponse'
        },
        parameters => \%args
    );
}

our %_simple_types = (
    BudgetLimitType => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.Optimizer.Api.DataContracts',
    ErrorCodes => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Shared.Api',
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
    ApplyBudgetOpportunitiesResponse
    ApplyOpportunitiesResponse
    BatchError
    BidOpportunity
    BudgetOpportunity
    GetBidOpportunitiesResponse
    GetBudgetOpportunitiesResponse
    OperationError
    Opportunity
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
    ArrayOfBidOpportunity => {
        namespace_uri => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.Optimizer.Api.DataContracts.Entities',
        element_name => 'BidOpportunity',
        element_type => 'BidOpportunity'
    },
    ArrayOfBudgetOpportunity => {
        namespace_uri => 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.Optimizer.Api.DataContracts.Entities',
        element_name => 'BudgetOpportunity',
        element_type => 'BudgetOpportunity'
    },
    ArrayOfOperationError => {
        namespace_uri => 'https://adcenter.microsoft.com/v8',
        element_name => 'OperationError',
        element_type => 'OperationError'
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
