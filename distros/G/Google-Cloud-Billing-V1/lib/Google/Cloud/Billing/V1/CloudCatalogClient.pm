package Google::Cloud::Billing::V1::CloudCatalogClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Billing::V1::CloudCatalog;
use Google::Cloud::Billing::V1::CloudBilling;

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

    my $target = 'cloudbilling.googleapis.com:443';
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

sub list_services {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Billing::V1::CloudCatalog::ListServicesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Billing::V1::CloudCatalog::ListServicesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.billing.v1.CloudCatalog/ListServices',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.billing.v1.CloudCatalog',
        method         => 'ListServices',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_skus {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Billing::V1::CloudCatalog::ListSkusRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Billing::V1::CloudCatalog::ListSkusResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.billing.v1.CloudCatalog/ListSkus',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.billing.v1.CloudCatalog',
        method         => 'ListSkus',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Billing::V1::CloudCatalogClient

__END__

=head1 NAME

Google::Cloud::Billing::V1::CloudCatalogClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Billing::V1::CloudCatalogClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Billing::V1::CloudCatalogClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Billing::V1::CloudCatalogClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Billing::V1::CloudCatalogClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/billing/v1/cloud_billing.proto>

=item * C<googleapis/google/cloud/billing/v1/cloud_catalog.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Billing::V1::CloudCatalogClient->new(
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

=item * B<list_services>

    my $response = $client->list_services(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListServices> on C<google.cloud.billing.v1.CloudCatalog>.

Request: L<Google::Cloud::Billing::V1::CloudCatalog::ListServicesRequest>

Returns: L<Google::Cloud::Billing::V1::CloudCatalog::ListServicesResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_skus>

    my $response = $client->list_skus(
        parent                   => $parent,
        start_time               => $start_time,
        end_time                 => $end_time,
        currency_code            => $currency_code,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListSkus> on C<google.cloud.billing.v1.CloudCatalog>.

Request: L<Google::Cloud::Billing::V1::CloudCatalog::ListSkusRequest>

Returns: L<Google::Cloud::Billing::V1::CloudCatalog::ListSkusResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<start_time> - L<Google::Protobuf::Timestamp::Timestamp>

=item * C<end_time> - L<Google::Protobuf::Timestamp::Timestamp>

=item * C<currency_code> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
