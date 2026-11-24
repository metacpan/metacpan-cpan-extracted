package Google::Cloud::Privatecatalog::V1beta1::PrivateCatalogClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog;

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

    my $target = 'cloudprivatecatalog.googleapis.com:443';
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

sub search_catalogs {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchCatalogsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchCatalogsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.privatecatalog.v1beta1.PrivateCatalog/SearchCatalogs',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.privatecatalog.v1beta1.PrivateCatalog',
        method         => 'SearchCatalogs',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_products {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchProductsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchProductsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.privatecatalog.v1beta1.PrivateCatalog/SearchProducts',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.privatecatalog.v1beta1.PrivateCatalog',
        method         => 'SearchProducts',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_versions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchVersionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchVersionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.privatecatalog.v1beta1.PrivateCatalog/SearchVersions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.privatecatalog.v1beta1.PrivateCatalog',
        method         => 'SearchVersions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Privatecatalog::V1beta1::PrivateCatalogClient

__END__

=head1 NAME

Google::Cloud::Privatecatalog::V1beta1::PrivateCatalogClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Privatecatalog::V1beta1::PrivateCatalogClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Privatecatalog::V1beta1::PrivateCatalogClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Privatecatalog::V1beta1::PrivateCatalogClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Privatecatalog::V1beta1::PrivateCatalogClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/privatecatalog/v1beta1/private_catalog.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Privatecatalog::V1beta1::PrivateCatalogClient->new(
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

=item * B<search_catalogs>

    my $response = $client->search_catalogs(
        resource                 => $resource,
        query                    => $query,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<SearchCatalogs> on C<google.cloud.privatecatalog.v1beta1.PrivateCatalog>.

Request: L<Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchCatalogsRequest>

Returns: L<Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchCatalogsResponse>

Parameters:

=over 4

=item * C<resource> - C<string>

=item * C<query> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<search_products>

    my $response = $client->search_products(
        resource                 => $resource,
        query                    => $query,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<SearchProducts> on C<google.cloud.privatecatalog.v1beta1.PrivateCatalog>.

Request: L<Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchProductsRequest>

Returns: L<Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchProductsResponse>

Parameters:

=over 4

=item * C<resource> - C<string>

=item * C<query> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<search_versions>

    my $response = $client->search_versions(
        resource                 => $resource,
        query                    => $query,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<SearchVersions> on C<google.cloud.privatecatalog.v1beta1.PrivateCatalog>.

Request: L<Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchVersionsRequest>

Returns: L<Google::Cloud::Privatecatalog::V1beta1::PrivateCatalog::SearchVersionsResponse>

Parameters:

=over 4

=item * C<resource> - C<string>

=item * C<query> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
