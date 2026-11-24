package Google::Cloud::Gkerecommender::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Gkerecommender::V1::Gkerecommender;

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

    my $target = 'gkerecommender.googleapis.com:443';
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

sub fetch_models {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.gkerecommender.v1.GkeInferenceQuickstart/FetchModels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart',
        method         => 'FetchModels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub fetch_model_servers {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.gkerecommender.v1.GkeInferenceQuickstart/FetchModelServers',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart',
        method         => 'FetchModelServers',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub fetch_model_server_versions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.gkerecommender.v1.GkeInferenceQuickstart/FetchModelServerVersions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart',
        method         => 'FetchModelServerVersions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub fetch_profiles {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.gkerecommender.v1.GkeInferenceQuickstart/FetchProfiles',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart',
        method         => 'FetchProfiles',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub generate_optimized_manifest {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.gkerecommender.v1.GkeInferenceQuickstart/GenerateOptimizedManifest',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart',
        method         => 'GenerateOptimizedManifest',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub fetch_benchmarking_data {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.gkerecommender.v1.GkeInferenceQuickstart/FetchBenchmarkingData',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.gkerecommender.v1.GkeInferenceQuickstart',
        method         => 'FetchBenchmarkingData',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Gkerecommender::V1

__END__

=head1 NAME

Google::Cloud::Gkerecommender::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Gkerecommender::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Gkerecommender::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Gkerecommender::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Gkerecommender::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/gkerecommender/v1/gkerecommender.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Gkerecommender::V1->new(
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

=item * B<fetch_models>

    my $response = $client->fetch_models(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<FetchModels> on C<google.cloud.gkerecommender.v1.GkeInferenceQuickstart>.

Request: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsRequest>

Returns: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<fetch_model_servers>

    my $response = $client->fetch_model_servers(
        model                    => $model,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<FetchModelServers> on C<google.cloud.gkerecommender.v1.GkeInferenceQuickstart>.

Request: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersRequest>

Returns: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServersResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<fetch_model_server_versions>

    my $response = $client->fetch_model_server_versions(
        model                    => $model,
        model_server             => $model_server,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<FetchModelServerVersions> on C<google.cloud.gkerecommender.v1.GkeInferenceQuickstart>.

Request: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsRequest>

Returns: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchModelServerVersionsResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<model_server> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<fetch_profiles>

    my $response = $client->fetch_profiles(
        model                    => $model,
        model_server             => $model_server,
        model_server_version     => $model_server_version,
        performance_requirements => $performance_requirements,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<FetchProfiles> on C<google.cloud.gkerecommender.v1.GkeInferenceQuickstart>.

Request: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesRequest>

Returns: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchProfilesResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<model_server> - C<string>

=item * C<model_server_version> - C<string>

=item * C<performance_requirements> - L<Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceRequirements>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<generate_optimized_manifest>

    my $response = $client->generate_optimized_manifest(
        model_server_info        => $model_server_info,
        accelerator_type         => $accelerator_type,
        kubernetes_namespace     => $kubernetes_namespace,
        performance_requirements => $performance_requirements,
        storage_config           => $storage_config,
    );

Calls the RPC method C<GenerateOptimizedManifest> on C<google.cloud.gkerecommender.v1.GkeInferenceQuickstart>.

Request: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestRequest>

Returns: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::GenerateOptimizedManifestResponse>

Parameters:

=over 4

=item * C<model_server_info> - L<Google::Cloud::Gkerecommender::V1::Gkerecommender::ModelServerInfo>

=item * C<accelerator_type> - C<string>

=item * C<kubernetes_namespace> - C<string>

=item * C<performance_requirements> - L<Google::Cloud::Gkerecommender::V1::Gkerecommender::PerformanceRequirements>

=item * C<storage_config> - L<Google::Cloud::Gkerecommender::V1::Gkerecommender::StorageConfig>

=back

=item * B<fetch_benchmarking_data>

    my $response = $client->fetch_benchmarking_data(
        model_server_info        => $model_server_info,
        instance_type            => $instance_type,
        pricing_model            => $pricing_model,
    );

Calls the RPC method C<FetchBenchmarkingData> on C<google.cloud.gkerecommender.v1.GkeInferenceQuickstart>.

Request: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataRequest>

Returns: L<Google::Cloud::Gkerecommender::V1::Gkerecommender::FetchBenchmarkingDataResponse>

Parameters:

=over 4

=item * C<model_server_info> - L<Google::Cloud::Gkerecommender::V1::Gkerecommender::ModelServerInfo>

=item * C<instance_type> - C<string>

=item * C<pricing_model> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
