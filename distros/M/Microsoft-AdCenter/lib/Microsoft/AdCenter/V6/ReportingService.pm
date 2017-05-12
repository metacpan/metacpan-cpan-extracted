package Microsoft::AdCenter::V6::ReportingService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter::V6::ReportingService - Service client for Microsoft AdCenter Reporting Service.

=head1 SYNOPSIS

    use Microsoft::AdCenter::V6::ReportingService;

    my $service_client = Microsoft::AdCenter::V6::ReportingService->new
        ->ApplicationToken("application token")
        ->CustomerAccountId("customer account id")
        ->CustomerId("customer id")
        ->DeveloperToken("developer token")
        ->Password("password")
        ->UserName("user name");

    my $response = $service_client->PollGenerateReport(
        ReportRequestId => ...
    );

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for detailed documentation for this service.

=head1 METHODS

=head2 EndPoint

Changes the end point for this service client.

Default value: https://adcenterapi.microsoft.com/Api/Advertiser/V6/Reporting/ReportingService.svc

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
    return 'ReportingService';
}

sub _service_version {
    return 'V6';
}

sub _class_name {
    return 'ReportingService';
}

sub _namespace_uri {
    return 'https://adcenter.microsoft.com/v6';
}

sub _default_location {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/V6/Reporting/ReportingService.svc';
}

sub _wsdl {
    return 'https://adcenterapi.microsoft.com/Api/Advertiser/V6/Reporting/ReportingService.svc?wsdl';
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

=head2 PollGenerateReport

=over

=item Parameters:

    ReportRequestId (string)

=item Returns:

    PollGenerateReportResponse

=back

=cut

sub PollGenerateReport {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'PollGenerateReport',
        request => {
            name => 'PollGenerateReportRequest',
            parameters => [
                { name => 'ReportRequestId', type => 'string', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'PollGenerateReportResponse'
        },
        parameters => \%args
    );
}

=head2 SubmitGenerateReport

=over

=item Parameters:

    ReportRequest (ReportRequest)

=item Returns:

    SubmitGenerateReportResponse

=back

=cut

sub SubmitGenerateReport {
    my ($self, %args) = @_;
    return $self->_invoke(
        soap_action => 'SubmitGenerateReport',
        request => {
            name => 'SubmitGenerateReportRequest',
            parameters => [
                { name => 'ReportRequest', type => 'ReportRequest', namespace => 'https://adcenter.microsoft.com/v6' }
            ]
        },
        response => {
            name => 'SubmitGenerateReportResponse'
        },
        parameters => \%args
    );
}

our %_simple_types = (
    AccountPerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    AdDistributionReportFilter => 'https://adcenter.microsoft.com/v6',
    AdDynamicTextPerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    AdGroupPerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    AdGroupStatusReportFilter => 'https://adcenter.microsoft.com/v6',
    AdPerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    AdStatusReportFilter => 'https://adcenter.microsoft.com/v6',
    AdTypeReportFilter => 'https://adcenter.microsoft.com/v6',
    AgeGenderDemographicReportColumn => 'https://adcenter.microsoft.com/v6',
    AgeGroupReportFilter => 'https://adcenter.microsoft.com/v6',
    BehavioralPerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    BehavioralTargetReportColumn => 'https://adcenter.microsoft.com/v6',
    BiddedMatchTypeReportFilter => 'https://adcenter.microsoft.com/v6',
    BudgetSummaryReportColumn => 'https://adcenter.microsoft.com/v6',
    BudgetSummaryReportTimePeriod => 'https://adcenter.microsoft.com/v6',
    CampaignPerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    CampaignStatusReportFilter => 'https://adcenter.microsoft.com/v6',
    CashbackReportFilter => 'https://adcenter.microsoft.com/v6',
    ConversionPerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    CountryReportFilter => 'https://adcenter.microsoft.com/v6',
    DeliveredMatchTypeReportFilter => 'https://adcenter.microsoft.com/v6',
    DestinationUrlPerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    DeviceTypeReportFilter => 'https://adcenter.microsoft.com/v6',
    GenderReportFilter => 'https://adcenter.microsoft.com/v6',
    GoalsAndFunnelsReportColumn => 'https://adcenter.microsoft.com/v6',
    KeywordPerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    LanguageAndRegionReportFilter => 'https://adcenter.microsoft.com/v6',
    MetroAreaDemographicReportColumn => 'https://adcenter.microsoft.com/v6',
    NonHourlyReportAggregation => 'https://adcenter.microsoft.com/v6',
    PublisherUsagePerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    ReportAggregation => 'https://adcenter.microsoft.com/v6',
    ReportFormat => 'https://adcenter.microsoft.com/v6',
    ReportLanguage => 'https://adcenter.microsoft.com/v6',
    ReportRequestStatusType => 'https://adcenter.microsoft.com/v6',
    ReportTimePeriod => 'https://adcenter.microsoft.com/v6',
    SearchQueryPerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    SearchQueryReportAggregation => 'https://adcenter.microsoft.com/v6',
    SegmentationReportColumn => 'https://adcenter.microsoft.com/v6',
    SitePerformanceReportColumn => 'https://adcenter.microsoft.com/v6',
    TacticChannelReportColumn => 'https://adcenter.microsoft.com/v6',
    TrafficSourcesReportColumn => 'https://adcenter.microsoft.com/v6',
    char => 'http://schemas.microsoft.com/2003/10/Serialization/',
    duration => 'http://schemas.microsoft.com/2003/10/Serialization/',
    guid => 'http://schemas.microsoft.com/2003/10/Serialization/',
);

sub _simple_types {
    return %_simple_types;
}

our @_complex_types = (qw/
    AccountPerformanceReportFilter
    AccountPerformanceReportRequest
    AccountReportScope
    AccountThroughAdGroupReportScope
    AccountThroughCampaignReportScope
    AdApiError
    AdApiFaultDetail
    AdDynamicTextPerformanceReportFilter
    AdDynamicTextPerformanceReportRequest
    AdGroupPerformanceReportFilter
    AdGroupPerformanceReportRequest
    AdGroupReportScope
    AdPerformanceReportFilter
    AdPerformanceReportRequest
    AgeGenderDemographicReportFilter
    AgeGenderDemographicReportRequest
    ApiFaultDetail
    ApplicationFault
    BatchError
    BehavioralPerformanceReportFilter
    BehavioralPerformanceReportRequest
    BehavioralTargetReportFilter
    BehavioralTargetReportRequest
    BudgetSummaryReportRequest
    BudgetSummaryReportTime
    CampaignPerformanceReportFilter
    CampaignPerformanceReportRequest
    CampaignReportScope
    ConversionPerformanceReportFilter
    ConversionPerformanceReportRequest
    Date
    DestinationUrlPerformanceReportFilter
    DestinationUrlPerformanceReportRequest
    GoalsAndFunnelsReportFilter
    GoalsAndFunnelsReportRequest
    KeywordPerformanceReportFilter
    KeywordPerformanceReportRequest
    MetroAreaDemographicReportFilter
    MetroAreaDemographicReportRequest
    OperationError
    PollGenerateReportResponse
    PublisherUsagePerformanceReportFilter
    PublisherUsagePerformanceReportRequest
    ReportRequest
    ReportRequestStatus
    ReportTime
    SearchQueryPerformanceReportFilter
    SearchQueryPerformanceReportRequest
    SegmentationReportFilter
    SegmentationReportRequest
    SitePerformanceReportFilter
    SitePerformanceReportRequest
    SubmitGenerateReportResponse
    TacticChannelReportFilter
    TacticChannelReportRequest
    TrafficSourcesReportFilter
    TrafficSourcesReportRequest
/);

sub _complex_types {
    return @_complex_types;
}

our %_array_types = (
    ArrayOfAccountPerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'AccountPerformanceReportColumn',
        element_type => 'AccountPerformanceReportColumn'
    },
    ArrayOfAdApiError => {
        namespace_uri => 'https://adapi.microsoft.com',
        element_name => 'AdApiError',
        element_type => 'AdApiError'
    },
    ArrayOfAdDynamicTextPerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'AdDynamicTextPerformanceReportColumn',
        element_type => 'AdDynamicTextPerformanceReportColumn'
    },
    ArrayOfAdGroupPerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'AdGroupPerformanceReportColumn',
        element_type => 'AdGroupPerformanceReportColumn'
    },
    ArrayOfAdGroupReportScope => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'AdGroupReportScope',
        element_type => 'AdGroupReportScope'
    },
    ArrayOfAdPerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'AdPerformanceReportColumn',
        element_type => 'AdPerformanceReportColumn'
    },
    ArrayOfAgeGenderDemographicReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'AgeGenderDemographicReportColumn',
        element_type => 'AgeGenderDemographicReportColumn'
    },
    ArrayOfBatchError => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'BatchError',
        element_type => 'BatchError'
    },
    ArrayOfBehavioralPerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'BehavioralPerformanceReportColumn',
        element_type => 'BehavioralPerformanceReportColumn'
    },
    ArrayOfBehavioralTargetReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'BehavioralTargetReportColumn',
        element_type => 'BehavioralTargetReportColumn'
    },
    ArrayOfBudgetSummaryReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'BudgetSummaryReportColumn',
        element_type => 'BudgetSummaryReportColumn'
    },
    ArrayOfCampaignPerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'CampaignPerformanceReportColumn',
        element_type => 'CampaignPerformanceReportColumn'
    },
    ArrayOfCampaignReportScope => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'CampaignReportScope',
        element_type => 'CampaignReportScope'
    },
    ArrayOfConversionPerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'ConversionPerformanceReportColumn',
        element_type => 'ConversionPerformanceReportColumn'
    },
    ArrayOfDate => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'Date',
        element_type => 'Date'
    },
    ArrayOfDestinationUrlPerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'DestinationUrlPerformanceReportColumn',
        element_type => 'DestinationUrlPerformanceReportColumn'
    },
    ArrayOfGoalsAndFunnelsReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'GoalsAndFunnelsReportColumn',
        element_type => 'GoalsAndFunnelsReportColumn'
    },
    ArrayOfKeywordPerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'KeywordPerformanceReportColumn',
        element_type => 'KeywordPerformanceReportColumn'
    },
    ArrayOfMetroAreaDemographicReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'MetroAreaDemographicReportColumn',
        element_type => 'MetroAreaDemographicReportColumn'
    },
    ArrayOfOperationError => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'OperationError',
        element_type => 'OperationError'
    },
    ArrayOfPublisherUsagePerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'PublisherUsagePerformanceReportColumn',
        element_type => 'PublisherUsagePerformanceReportColumn'
    },
    ArrayOfSearchQueryPerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'SearchQueryPerformanceReportColumn',
        element_type => 'SearchQueryPerformanceReportColumn'
    },
    ArrayOfSegmentationReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'SegmentationReportColumn',
        element_type => 'SegmentationReportColumn'
    },
    ArrayOfSitePerformanceReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'SitePerformanceReportColumn',
        element_type => 'SitePerformanceReportColumn'
    },
    ArrayOfTacticChannelReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'TacticChannelReportColumn',
        element_type => 'TacticChannelReportColumn'
    },
    ArrayOfTrafficSourcesReportColumn => {
        namespace_uri => 'https://adcenter.microsoft.com/v6',
        element_name => 'TrafficSourcesReportColumn',
        element_type => 'TrafficSourcesReportColumn'
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
    CustomerAccountId
    CustomerId
    DeveloperToken
    Password
    UserName
    TrackingId
/);

1;
