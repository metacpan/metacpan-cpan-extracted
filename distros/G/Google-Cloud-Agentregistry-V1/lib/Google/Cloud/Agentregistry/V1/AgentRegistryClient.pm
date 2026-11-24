package Google::Cloud::Agentregistry::V1::AgentRegistryClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Agentregistry::V1::Properties;
use Google::Cloud::Agentregistry::V1::Skill;
use Google::Cloud::Agentregistry::V1::SkillEncryptionSpec;
use Google::Cloud::Agentregistry::V1::Binding;
use Google::Cloud::Agentregistry::V1::Finding;
use Google::Cloud::Agentregistry::V1::AiApplication;
use Google::Cloud::Agentregistry::V1::Endpoint;
use Google::Cloud::Agentregistry::V1::Agent;
use Google::Cloud::Agentregistry::V1::Service;
use Google::Cloud::Agentregistry::V1::McpServer;
use Google::Cloud::Agentregistry::V1::AgentregistryService;

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

    my $target = 'agentregistry.googleapis.com:443';
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

sub list_agents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAgentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Agentregistry::V1::AgentregistryService::ListAgentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.agentregistry.v1.AgentRegistry/ListAgents',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.agentregistry.v1.AgentRegistry',
        method         => 'ListAgents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Agentregistry::V1::AgentRegistryClient

__END__

=head1 NAME

Google::Cloud::Agentregistry::V1::AgentRegistryClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::AgentRegistryClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Agentregistry::V1::AgentRegistryClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Agentregistry::V1::AgentRegistryClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Agentregistry::V1::AgentRegistryClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/agentregistry/v1/agent.proto>

=item * C<googleapis/google/cloud/agentregistry/v1/agentregistry_service.proto>

=item * C<googleapis/google/cloud/agentregistry/v1/ai_application.proto>

=item * C<googleapis/google/cloud/agentregistry/v1/binding.proto>

=item * C<googleapis/google/cloud/agentregistry/v1/endpoint.proto>

=item * C<googleapis/google/cloud/agentregistry/v1/finding.proto>

=item * C<googleapis/google/cloud/agentregistry/v1/mcp_server.proto>

=item * C<googleapis/google/cloud/agentregistry/v1/properties.proto>

=item * C<googleapis/google/cloud/agentregistry/v1/service.proto>

=item * C<googleapis/google/cloud/agentregistry/v1/skill.proto>

=item * C<googleapis/google/cloud/agentregistry/v1/skill_encryption_spec.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Agentregistry::V1::AgentRegistryClient->new(
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

=item * B<list_agents>

    my $response = $client->list_agents(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListAgents> on C<google.cloud.agentregistry.v1.AgentRegistry>.

Request: L<Google::Cloud::Agentregistry::V1::AgentregistryService::ListAgentsRequest>

Returns: L<Google::Cloud::Agentregistry::V1::AgentregistryService::ListAgentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
