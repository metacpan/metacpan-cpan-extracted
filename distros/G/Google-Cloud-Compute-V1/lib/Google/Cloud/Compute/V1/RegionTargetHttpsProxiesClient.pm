package Google::Cloud::Compute::V1::RegionTargetHttpsProxiesClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Compute::V1::Compute;

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

    my $target = 'compute/v1.googleapis.com:443';
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

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteRegionTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionTargetHttpsProxies/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionTargetHttpsProxies',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetRegionTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::TargetHttpsProxy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionTargetHttpsProxies/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionTargetHttpsProxies',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::InsertRegionTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionTargetHttpsProxies/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionTargetHttpsProxies',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListRegionTargetHttpsProxiesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::TargetHttpsProxyList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionTargetHttpsProxies/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionTargetHttpsProxies',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PatchRegionTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionTargetHttpsProxies/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionTargetHttpsProxies',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_ssl_certificates {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetSslCertificatesRegionTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionTargetHttpsProxies/SetSslCertificates',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionTargetHttpsProxies',
        method         => 'SetSslCertificates',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_url_map {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetUrlMapRegionTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.RegionTargetHttpsProxies/SetUrlMap',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.RegionTargetHttpsProxies',
        method         => 'SetUrlMap',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::RegionTargetHttpsProxiesClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::RegionTargetHttpsProxiesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::RegionTargetHttpsProxiesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::RegionTargetHttpsProxiesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::RegionTargetHttpsProxiesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::RegionTargetHttpsProxiesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::RegionTargetHttpsProxiesClient->new(
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

=item * B<delete>

    my $response = $client->delete(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.RegionTargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteRegionTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxy> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        project                  => $project,
        region                   => $region,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.RegionTargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::GetRegionTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::TargetHttpsProxy>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<target_https_proxy> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_https_proxy_resource => $target_https_proxy_resource,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1.RegionTargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::InsertRegionTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxy_resource> - L<Google::Cloud::Compute::V1::Compute::TargetHttpsProxy>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1.RegionTargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::ListRegionTargetHttpsProxiesRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::TargetHttpsProxyList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=back

=item * B<patch>

    my $response = $client->patch(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_https_proxy       => $target_https_proxy,
        target_https_proxy_resource => $target_https_proxy_resource,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1.RegionTargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::PatchRegionTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxy> - C<string>

=item * C<target_https_proxy_resource> - L<Google::Cloud::Compute::V1::Compute::TargetHttpsProxy>

=back

=item * B<set_ssl_certificates>

    my $response = $client->set_ssl_certificates(
        project                  => $project,
        region                   => $region,
        region_target_https_proxies_set_ssl_certificates_request_resource => $region_target_https_proxies_set_ssl_certificates_request_resource,
        request_id               => $request_id,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<SetSslCertificates> on C<google.cloud.compute.v1.RegionTargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::SetSslCertificatesRegionTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<region_target_https_proxies_set_ssl_certificates_request_resource> - L<Google::Cloud::Compute::V1::Compute::RegionTargetHttpsProxiesSetSslCertificatesRequest>

=item * C<request_id> - C<string>

=item * C<target_https_proxy> - C<string>

=back

=item * B<set_url_map>

    my $response = $client->set_url_map(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_https_proxy       => $target_https_proxy,
        url_map_reference_resource => $url_map_reference_resource,
    );

Calls the RPC method C<SetUrlMap> on C<google.cloud.compute.v1.RegionTargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1::Compute::SetUrlMapRegionTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxy> - C<string>

=item * C<url_map_reference_resource> - L<Google::Cloud::Compute::V1::Compute::UrlMapReference>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
