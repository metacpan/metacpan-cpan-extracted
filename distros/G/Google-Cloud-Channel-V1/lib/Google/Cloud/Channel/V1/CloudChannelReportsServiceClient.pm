package Google::Cloud::Channel::V1::CloudChannelReportsServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Channel::V1::Operations;
use Google::Cloud::Channel::V1::Common;
use Google::Cloud::Channel::V1::Repricing;
use Google::Cloud::Channel::V1::SubscriberEvent;
use Google::Cloud::Channel::V1::Products;
use Google::Cloud::Channel::V1::BillingAccounts;
use Google::Cloud::Channel::V1::ReportsService;
use Google::Cloud::Channel::V1::Customers;
use Google::Cloud::Channel::V1::ChannelPartnerLinks;
use Google::Cloud::Channel::V1::Offers;
use Google::Cloud::Channel::V1::Entitlements;
use Google::Cloud::Channel::V1::EntitlementChanges;
use Google::Cloud::Channel::V1::Service;

our $VERSION = '0.06';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    my $auth = $self->credentials;
    if (!defined $auth) {
        $auth = Google::Auth->default();
    } elsif (!eval { $auth->can('get_token') }) {
        croak 'Invalid credentials object: must implement get_token()';
    }
    my $token = $auth->get_token();

    my $target = 'cloudchannel.googleapis.com:443';
    my $t = $self->transport || 'grpc';

    if (ref($t) && eval { $t->can('call') }) {
        # Already a transport object
    } elsif (lc($t) eq 'rest') {
        my $client = Google::Cloud::REST::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    } else {
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub run_report_job {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Channel::V1::ReportsService::RunReportJobRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.channel.v1.CloudChannelReportsService/RunReportJob',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.channel.v1.CloudChannelReportsService',
        method         => 'RunReportJob',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_reports {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Channel::V1::ReportsService::ListReportsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Channel::V1::ReportsService::ListReportsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.channel.v1.CloudChannelReportsService/ListReports',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.channel.v1.CloudChannelReportsService',
        method         => 'ListReports',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Channel::V1::CloudChannelReportsServiceClient

__END__

=head1 NAME

Google::Cloud::Channel::V1::CloudChannelReportsServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::CloudChannelReportsServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Channel::V1::CloudChannelReportsServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Channel::V1::CloudChannelReportsServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Channel::V1::CloudChannelReportsServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/channel/v1/billing_accounts.proto>

=item * C<googleapis/google/cloud/channel/v1/channel_partner_links.proto>

=item * C<googleapis/google/cloud/channel/v1/common.proto>

=item * C<googleapis/google/cloud/channel/v1/customers.proto>

=item * C<googleapis/google/cloud/channel/v1/entitlement_changes.proto>

=item * C<googleapis/google/cloud/channel/v1/entitlements.proto>

=item * C<googleapis/google/cloud/channel/v1/offers.proto>

=item * C<googleapis/google/cloud/channel/v1/operations.proto>

=item * C<googleapis/google/cloud/channel/v1/products.proto>

=item * C<googleapis/google/cloud/channel/v1/reports_service.proto>

=item * C<googleapis/google/cloud/channel/v1/repricing.proto>

=item * C<googleapis/google/cloud/channel/v1/service.proto>

=item * C<googleapis/google/cloud/channel/v1/subscriber_event.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Channel::V1::CloudChannelReportsServiceClient->new(
        credentials => $auth,   # Optional: Google::Auth object (defaults to ADC)
        transport   => 'grpc', # Optional: 'grpc' (default) or 'rest'
    );

=head1 ATTRIBUTES

=head2 credentials

Returns or accepts the L<Google::Auth> credentials object.

=head2 transport

Returns or accepts the active transport object (L<Google::gRPC::Client> or L<Google::Cloud::REST::Client>).

=head1 METHODS

=head2 METHODS

The following RPC methods are available in this client:

=over 4

=item * B<run_report_job>

    my $response = $client->run_report_job(
        name                     => $name,
        date_range               => $date_range,
        filter                   => $filter,
        language_code            => $language_code,
    );

Calls the RPC method C<RunReportJob> on C<google.cloud.channel.v1.CloudChannelReportsService>.

Request: L<Google::Cloud::Channel::V1::ReportsService::RunReportJobRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<date_range> - L<Google::Cloud::Channel::V1::ReportsService::DateRange>

=item * C<filter> - C<string>

=item * C<language_code> - C<string>

=back

=item * B<list_reports>

    my $response = $client->list_reports(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        language_code            => $language_code,
    );

Calls the RPC method C<ListReports> on C<google.cloud.channel.v1.CloudChannelReportsService>.

Request: L<Google::Cloud::Channel::V1::ReportsService::ListReportsRequest>

Returns: L<Google::Cloud::Channel::V1::ReportsService::ListReportsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<language_code> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
