package Google::Cloud::Compute::V1beta::TargetHttpsProxiesClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Compute::V1beta::Compute;

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

    my $target = 'compute/v1beta.googleapis.com:443';
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

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AggregatedListTargetHttpsProxiesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxyAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::InsertTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListTargetHttpsProxiesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxyList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub patch {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PatchTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/Patch',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'Patch',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_certificate_map {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetCertificateMapTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/SetCertificateMap',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'SetCertificateMap',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_quic_override {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetQuicOverrideTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/SetQuicOverride',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'SetQuicOverride',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_ssl_certificates {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetSslCertificatesTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/SetSslCertificates',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'SetSslCertificates',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_ssl_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetSslPolicyTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/SetSslPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'SetSslPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_url_map {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetUrlMapTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/SetUrlMap',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'SetUrlMap',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsTargetHttpsProxyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetHttpsProxies/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetHttpsProxies',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1beta::TargetHttpsProxiesClient

__END__

=head1 NAME

Google::Cloud::Compute::V1beta::TargetHttpsProxiesClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1beta::TargetHttpsProxiesClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1beta::TargetHttpsProxiesClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1beta::TargetHttpsProxiesClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1beta::TargetHttpsProxiesClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1beta/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1beta::TargetHttpsProxiesClient->new(
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

=item * B<aggregated_list>

    my $response = $client->aggregated_list(
        filter                   => $filter,
        include_all_scopes       => $include_all_scopes,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        return_partial_success   => $return_partial_success,
        service_project_number   => $service_project_number,
    );

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AggregatedListTargetHttpsProxiesRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxyAggregatedList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<include_all_scopes> - C<bool>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<service_project_number> - C<int64>

=back

=item * B<delete>

    my $response = $client->delete(
        project                  => $project,
        request_id               => $request_id,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxy> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        project                  => $project,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxy>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<target_https_proxy> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        project                  => $project,
        request_id               => $request_id,
        target_https_proxy_resource => $target_https_proxy_resource,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::InsertTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxy_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxy>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        return_partial_success   => $return_partial_success,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListTargetHttpsProxiesRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxyList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=back

=item * B<patch>

    my $response = $client->patch(
        project                  => $project,
        request_id               => $request_id,
        target_https_proxy       => $target_https_proxy,
        target_https_proxy_resource => $target_https_proxy_resource,
    );

Calls the RPC method C<Patch> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PatchTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxy> - C<string>

=item * C<target_https_proxy_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxy>

=back

=item * B<set_certificate_map>

    my $response = $client->set_certificate_map(
        project                  => $project,
        request_id               => $request_id,
        target_https_proxies_set_certificate_map_request_resource => $target_https_proxies_set_certificate_map_request_resource,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<SetCertificateMap> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetCertificateMapTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxies_set_certificate_map_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxiesSetCertificateMapRequest>

=item * C<target_https_proxy> - C<string>

=back

=item * B<set_quic_override>

    my $response = $client->set_quic_override(
        project                  => $project,
        request_id               => $request_id,
        target_https_proxies_set_quic_override_request_resource => $target_https_proxies_set_quic_override_request_resource,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<SetQuicOverride> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetQuicOverrideTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxies_set_quic_override_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxiesSetQuicOverrideRequest>

=item * C<target_https_proxy> - C<string>

=back

=item * B<set_ssl_certificates>

    my $response = $client->set_ssl_certificates(
        project                  => $project,
        request_id               => $request_id,
        target_https_proxies_set_ssl_certificates_request_resource => $target_https_proxies_set_ssl_certificates_request_resource,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<SetSslCertificates> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetSslCertificatesTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxies_set_ssl_certificates_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetHttpsProxiesSetSslCertificatesRequest>

=item * C<target_https_proxy> - C<string>

=back

=item * B<set_ssl_policy>

    my $response = $client->set_ssl_policy(
        project                  => $project,
        request_id               => $request_id,
        ssl_policy_reference_resource => $ssl_policy_reference_resource,
        target_https_proxy       => $target_https_proxy,
    );

Calls the RPC method C<SetSslPolicy> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetSslPolicyTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<ssl_policy_reference_resource> - L<Google::Cloud::Compute::V1beta::Compute::SslPolicyReference>

=item * C<target_https_proxy> - C<string>

=back

=item * B<set_url_map>

    my $response = $client->set_url_map(
        project                  => $project,
        request_id               => $request_id,
        target_https_proxy       => $target_https_proxy,
        url_map_reference_resource => $url_map_reference_resource,
    );

Calls the RPC method C<SetUrlMap> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetUrlMapTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<target_https_proxy> - C<string>

=item * C<url_map_reference_resource> - L<Google::Cloud::Compute::V1beta::Compute::UrlMapReference>

=back

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions(
        project                  => $project,
        resource                 => $resource,
        test_permissions_request_resource => $test_permissions_request_resource,
    );

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1beta.TargetHttpsProxies>.

Request: L<Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsTargetHttpsProxyRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsRequest>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
