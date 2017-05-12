package Microsoft::AdCenter;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

=head1 NAME

Microsoft::AdCenter - An interface which abstracts Microsoft adCenter API.

=cut

our $VERSION = '8.11';

=head1 SYNOPSIS

This collection of modules makes interacting with Microsoft adCenter APIs easier.

Sample Usage:

    use Microsoft::AdCenter::V7::CampaignManagementService;
    use Microsoft::AdCenter::V7::CampaignManagementService::Bid;
    use Microsoft::AdCenter::V7::CampaignManagementService::Keyword;
    use Microsoft::AdCenter::Retry;

    # Defines when and how to retry an failed API call due to a connection or internal server error
    my $retry = Microsoft::AdCenter::Retry->new(
        ErrorType => Microsoft::AdCenter::Retry->CONNECTION_ERROR | Microsoft::AdCenter::Retry->INTERNAL_SERVER_ERROR,
        RetryTimes => 3,
        WaitTime => 30
    );

    # Create the service client
    my $campaign_mgmt_service = Microsoft::AdCenter::V7::CampaignManagementService->new(
        ApplicationToken  => "your_application_token",
        CustomerAccountId => "your_customer_account_id",
        CustomerId        => "your_customer_id",
        DeveloperToken    => "your_developer_token",
        Password          => "your_password",
        UserName          => "your_user_name",
        RetrySettings     => [$retry]
    );

    # Create a Keyword object
    my $keyword = Microsoft::AdCenter::V7::CampaignManagementService::Keyword->new
        ->Text("some text")
        ->BroadMatchBid(Microsoft::AdCenter::V7::CampaignManagementService::Bid->new->Amount(0.1))
        ->ExactMatchBid(Microsoft::AdCenter::V7::CampaignManagementService::Bid->new->Amount(0.1));

    # Call AddKeywords
    my $response = $campaign_mgmt_service->AddKeywords(
        AdGroupId => "",
        Keywords => [$keyword]
    );

    # Check the response
    my $keyword_ids = $response->KeywordIds;
    ...

=head1 OVERVIEW

Microsoft adCenter API allows you to manage your adCenter account in an automated fashion rather than manually.  The API is exposed as a standard SOAP service that you can make calls to.  This set of modules is designed to make using the SOAP service easier than using SOAP::Lite (for example) directly.  There are 2 main types of modules available.  The service modules (AdministrationService, CampaignManagementService, CustomerManagementService, etc.) are used to make the actual calls to each of the SOAP services in the API.  The other type of module provided are the complex type modules, each of which represents one of the complex types defined in one of the WSDLs of the SOAP service.  Examples include Campaign, AdGroup, Ad, Keyword, etc.

The calls you can make to the various services are documented on MSDN.  See

L<http://msdn.microsoft.com/en-us/library/ee730327.aspx>

Where the documentation indicates that a complex type must be passed in to a particular service call, you must pass in the appropriate Microsoft::AdCenter::ComplexType object.  For example, CampaignManagementService->AddCampaigns requires that an array of Campaigns be passed in:

    use Microsoft::AdCenter::V7::CampaignManagementService;
    use Microsoft::AdCenter::V7::CampaignManagementService::Campaign;

    # Create the service client
    my $campaign_mgmt_service = Microsoft::AdCenter::V7::CampaignManagementService->new(
        ApplicationToken  => "your_application_token",
        CustomerAccountId => "your_customer_account_id",
        CustomerId        => "your_customer_id",
        DeveloperToken    => "your_developer_token",
        Password          => "your_password",
        UserName          => "your_user_name"
    );

    # Create a Campaign object
    my $campaign = Microsoft::AdCenter::V7::CampaignManagementService::Campaign->new
        ->BudgetType("MonthlyBudgetDivideDailyAcrossMonth")
        ->ConversionTrackingEnabled("false")
        ->DaylightSaving("true")
        ->Description("the campaign description")
        ->MonthlyBudget(1000)
        ->Name("the campaign name")
        ->TimeZone("EasternTimeUSCanada")

    # Call AddCampaigns
    my $response = $campaign_mgmt_service->AddCampaigns(
        AccountId => "",
        Campaigns => [$campaign]
    );

    # Check the response
    my $campaign_ids = $response->CampaignIds;
    ...

Note that all simple types referenced in the WSDLs are automatically handled for you - just pass in an appropriate string, and let Microsoft::AdCenter do the rest.

When a method expects an array of objects / strings / numbers / etc., you must pass an array reference.

If the SOAP call succeeded, you will receive a response object.  See the perldoc for the specific service client module for the return types.

If a SOAP Fault is encountered (whenever a call fails), the service client will throw a Microsoft::AdCenter::SOAPFault object.

=head1 METHODS

There are no methods available in Microsoft::AdCenter directly.  All functionality is exposed by the various service client modules and complex types.

=head1 EXAMPLES

=head2 Example 1 - Create a new campaign

    use Microsoft::AdCenter::V7::CampaignManagementService;
    use Microsoft::AdCenter::V7::CampaignManagementService::Campaign;

    # Create the service client
    my $campaign_mgmt_service = Microsoft::AdCenter::V7::CampaignManagementService->new
        ->ApplicationToken("your_application_token")
        ->CustomerAccountId("your_customer_account_id")
        ->CustomerId("your_customer_id")
        ->DeveloperToken("your_developer_token")
        ->Password("your_password")
        ->UserName("your_user_name");

    # Create a Campaign object
    my $campaign = Microsoft::AdCenter::V7::CampaignManagementService::Campaign->new
        ->BudgetType("MonthlyBudgetDivideDailyAcrossMonth")
        ->ConversionTrackingEnabled("false")
        ->DaylightSaving("true")
        ->Description("the campaign description")
        ->MonthlyBudget(1000)
        ->Name("the campaign name")
        ->TimeZone("EasternTimeUSCanada")

    # Call AddCampaigns
    my $response = $campaign_mgmt_service->AddCampaigns(
        AccountId => "",
        Campaigns => [$campaign]
    );

    # Check the response header
    my $tracking_id = $campaign_mgmt_service->response_header->{TrackingId};

    # Check the response
    my $campaign_ids = $response->CampaignIds;
    ...

=head2 Example 2 - Get accounts

    use Microsoft::AdCenter::V7::CustomerManagementService;

    # Create the service client
    my $customer_mgmt_service = Microsoft::AdCenter::V7::CustomerManagementService->new(
        UserName         => "your_user_name",
        Password         => "your_password",
        ApplicationToken => "your_application_token",
        DeveloperToken   => "your_developer_token"
    );

    # Get accounts
    my $response = $customer_mgmt_service->GetAccountsInfo(CustomerId => "your_customer_id");

    # Check the response
    foreach my $account (@{$response->GetAccountsResult}) {
        ...
    }

=head2 Example 3 - Error handling

    use Microsoft::AdCenter::V7::CampaignManagementService;
    use Microsoft::AdCenter::V7::CampaignManagementService::Bid;
    use Microsoft::AdCenter::V7::CampaignManagementService::Keyword;

    # Create the service client
    my $campaign_mgmt_service = Microsoft::AdCenter::V7::CampaignManagementService->new(
        ApplicationToken  => "your_application_token",
        CustomerAccountId => "your_customer_account_id",
        CustomerId        => "your_customer_id",
        DeveloperToken    => "your_developer_token",
        Password          => "INVALID PASSWORD", # An invalid password
        UserName          => "your_user_name"
    );

    my $response;
    eval {
        $response = $campaign_mgmt_service->AddKeywords(
            AdGroupId => "",
            Keywords => [
                Microsoft::AdCenter::V7::CampaignManagementService::Keyword->new
                    ->Text("some text")
                    ->BroadMatchBid(Microsoft::AdCenter::V7::CampaignManagementService::Bid->new->Amount(0.1))
                    ->ExactMatchBid(Microsoft::AdCenter::V7::CampaignManagementService::Bid->new->Amount(0.1))
            ]
        );
    };
    if (my $e = $@) {
        print "Fault code: @{[$e->faultcode]}\n";
        print "Fault string: @{[$e->faultstring]}\n";
        print "Error messages:\n";
        print $_->Message . "\n" foreach @{$e->detail->Errors};
    }

=head2 Example 4 - Retrying an API call when an expected temporary network issue comes up

    use Microsoft::AdCenter::V7::CampaignManagementService;
    use Microsoft::AdCenter::V7::CampaignManagementService::Bid;
    use Microsoft::AdCenter::V7::CampaignManagementService::Keyword;
    use Microsoft::AdCenter::Retry;

    # Defines when and how to retry an failed API call due to a temporary network connection issue
    my $retry = Microsoft::AdCenter::Retry->new(
        ErrorType => Microsoft::AdCenter::Retry->CONNECTION_ERROR,
        RetryTimes => 3,
        WaitTime => 30,
        ScalingWaitTime => 2,
        Callback => sub { my $e = shift; warn "Successfully retried API call for " . __PACKAGE__ . " after error $e was caught"; }
    );

    # Create the service client
    my $campaign_mgmt_service = Microsoft::AdCenter::V7::CampaignManagementService->new(
        ApplicationToken  => "your_application_token",
        CustomerAccountId => "your_customer_account_id",
        CustomerId        => "your_customer_id",
        DeveloperToken    => "your_developer_token",
        Password          => "your_password",
        UserName          => "your_user_name",
        RetrySettings     => [$retry]
    );

    # Create a Keyword object
    my $keyword = Microsoft::AdCenter::V7::CampaignManagementService::Keyword->new
        ->Text("some text")
        ->BroadMatchBid(Microsoft::AdCenter::V7::CampaignManagementService::Bid->new->Amount(0.1))
        ->ExactMatchBid(Microsoft::AdCenter::V7::CampaignManagementService::Bid->new->Amount(0.1));

    # Call AddKeywords
    my $response = $campaign_mgmt_service->AddKeywords(
        AdGroupId => "",
        Keywords => [$keyword]
    );

    # Check the response
    my $keyword_ids = $response->KeywordIds;
    ...

=head1 DEBUGGING

If you'd like to see the SOAP requests and responses, or other debugging information available from SOAP::Lite, you can turn it on just as you would for SOAP::Lite.  See perldoc SOAP::Trace.  As an example, if you wanted to see all trace information available, you could add the following to the module or script you use Microsoft::AdCenter in:

 use SOAP::Lite +trace;

=head1 AUTHOR

Xerxes Tsang

=head1 BUGS

Please report any bugs or feature requests to
C<bug-microsoft-adcenter at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Microsoft-AdCenter>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Microsoft::AdCenter

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Microsoft-AdCenter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Microsoft-AdCenter>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Microsoft-AdCenter>

=item * Search CPAN

L<http://search.cpan.org/dist/Microsoft-AdCenter>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010 Xerxes Tsang

This program is free software; you can redistribute it and/or modify it under the terms of Perl Artistic License.

=head1 TODO

The TODO list is empty - if you have suggestions, please file a wishlist entry in RT (link above)

=cut

sub new {
    my ($class, %args) = @_;
    die "Cannot instantiate @{[ __PACKAGE__ ]} directly"
        if $class eq __PACKAGE__;
    my $self = bless %args, $class;
    return $self;
}

1; # End of Microsoft::AdCenter
