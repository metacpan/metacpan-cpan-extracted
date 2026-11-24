package Google::Cloud::Apihub::V1::ApiHubPluginClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Apihub::V1::CommonFields;
use Google::Cloud::Apihub::V1::HostProjectRegistrationService;
use Google::Cloud::Apihub::V1::CurateService;
use Google::Cloud::Apihub::V1::RuntimeProjectAttachmentService;
use Google::Cloud::Apihub::V1::CollectService;
use Google::Cloud::Apihub::V1::PluginService;
use Google::Cloud::Apihub::V1::DiscoveryService;
use Google::Cloud::Apihub::V1::ProvisioningService;
use Google::Cloud::Apihub::V1::ApihubService;
use Google::Cloud::Apihub::V1::LintingService;

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

    my $target = 'apihub.googleapis.com:443';
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

sub get_plugin {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apihub::V1::PluginService::GetPluginRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apihub::V1::PluginService::Plugin';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apihub.v1.ApiHubPlugin/GetPlugin',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apihub.v1.ApiHubPlugin',
        method         => 'GetPlugin',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Apihub::V1::ApiHubPluginClient

__END__

=head1 NAME

Google::Cloud::Apihub::V1::ApiHubPluginClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Apihub::V1::ApiHubPluginClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Apihub::V1::ApiHubPluginClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Apihub::V1::ApiHubPluginClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Apihub::V1::ApiHubPluginClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/apihub/v1/apihub_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/collect_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/common_fields.proto>

=item * C<googleapis/google/cloud/apihub/v1/curate_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/discovery_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/host_project_registration_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/linting_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/plugin_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/provisioning_service.proto>

=item * C<googleapis/google/cloud/apihub/v1/runtime_project_attachment_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Apihub::V1::ApiHubPluginClient->new(
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

=item * B<get_plugin>

    my $response = $client->get_plugin(
        name                     => $name,
    );

Calls the RPC method C<GetPlugin> on C<google.cloud.apihub.v1.ApiHubPlugin>.

Request: L<Google::Cloud::Apihub::V1::PluginService::GetPluginRequest>

Returns: L<Google::Cloud::Apihub::V1::PluginService::Plugin>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
