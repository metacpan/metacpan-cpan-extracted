package Google::Cloud::Ces::V1beta::SessionServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Ces::V1beta::GoldenRun;
use Google::Cloud::Ces::V1beta::SearchSuggestions;
use Google::Cloud::Ces::V1beta::GoogleSearchTool;
use Google::Cloud::Ces::V1beta::FileSearchTool;
use Google::Cloud::Ces::V1beta::SystemTool;
use Google::Cloud::Ces::V1beta::EvaluationMetricsConfig;
use Google::Cloud::Ces::V1beta::FileContext;
use Google::Cloud::Ces::V1beta::Fakes;
use Google::Cloud::Ces::V1beta::BigqueryExport;
use Google::Cloud::Ces::V1beta::Schema;
use Google::Cloud::Ces::V1beta::AgentTool;
use Google::Cloud::Ces::V1beta::AgentTransfers;
use Google::Cloud::Ces::V1beta::Auth;
use Google::Cloud::Ces::V1beta::ToolsetTool;
use Google::Cloud::Ces::V1beta::SecuritySettings;
use Google::Cloud::Ces::V1beta::Omnichannel;
use Google::Cloud::Ces::V1beta::WidgetService;
use Google::Cloud::Ces::V1beta::OmnichannelService;
use Google::Cloud::Ces::V1beta::Common;
use Google::Cloud::Ces::V1beta::Changelog;
use Google::Cloud::Ces::V1beta::DataStore;
use Google::Cloud::Ces::V1beta::ClientFunction;
use Google::Cloud::Ces::V1beta::AgentCard;
use Google::Cloud::Ces::V1beta::ConnectorTool;
use Google::Cloud::Ces::V1beta::Example;
use Google::Cloud::Ces::V1beta::Mocks;
use Google::Cloud::Ces::V1beta::McpToolset;
use Google::Cloud::Ces::V1beta::OpenApiTool;
use Google::Cloud::Ces::V1beta::OpenApiToolset;
use Google::Cloud::Ces::V1beta::Guardrail;
use Google::Cloud::Ces::V1beta::App;
use Google::Cloud::Ces::V1beta::PythonFunction;
use Google::Cloud::Ces::V1beta::Deployment;
use Google::Cloud::Ces::V1beta::McpTool;
use Google::Cloud::Ces::V1beta::AssistantService;
use Google::Cloud::Ces::V1beta::DataStoreTool;
use Google::Cloud::Ces::V1beta::Agent;
use Google::Cloud::Ces::V1beta::ConnectorToolset;
use Google::Cloud::Ces::V1beta::Conversation;
use Google::Cloud::Ces::V1beta::SessionService;
use Google::Cloud::Ces::V1beta::WidgetTool;
use Google::Cloud::Ces::V1beta::Toolset;
use Google::Cloud::Ces::V1beta::Evaluation;
use Google::Cloud::Ces::V1beta::Tool;
use Google::Cloud::Ces::V1beta::ToolService;
use Google::Cloud::Ces::V1beta::AppVersion;
use Google::Cloud::Ces::V1beta::AgentService;
use Google::Cloud::Ces::V1beta::EvaluationService;

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

    my $target = 'ces.googleapis.com:443';
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

sub run_session {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Ces::V1beta::SessionService::RunSessionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Ces::V1beta::SessionService::RunSessionResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.ces.v1beta.SessionService/RunSession',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.ces.v1beta.SessionService',
        method         => 'RunSession',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Ces::V1beta::SessionServiceClient

__END__

=head1 NAME

Google::Cloud::Ces::V1beta::SessionServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::SessionServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Ces::V1beta::SessionServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Ces::V1beta::SessionServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Ces::V1beta::SessionServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/ces/v1beta/agent.proto>

=item * C<googleapis/google/cloud/ces/v1beta/agent_card.proto>

=item * C<googleapis/google/cloud/ces/v1beta/agent_service.proto>

=item * C<googleapis/google/cloud/ces/v1beta/agent_tool.proto>

=item * C<googleapis/google/cloud/ces/v1beta/agent_transfers.proto>

=item * C<googleapis/google/cloud/ces/v1beta/app.proto>

=item * C<googleapis/google/cloud/ces/v1beta/app_version.proto>

=item * C<googleapis/google/cloud/ces/v1beta/assistant_service.proto>

=item * C<googleapis/google/cloud/ces/v1beta/auth.proto>

=item * C<googleapis/google/cloud/ces/v1beta/bigquery_export.proto>

=item * C<googleapis/google/cloud/ces/v1beta/changelog.proto>

=item * C<googleapis/google/cloud/ces/v1beta/client_function.proto>

=item * C<googleapis/google/cloud/ces/v1beta/common.proto>

=item * C<googleapis/google/cloud/ces/v1beta/connector_tool.proto>

=item * C<googleapis/google/cloud/ces/v1beta/connector_toolset.proto>

=item * C<googleapis/google/cloud/ces/v1beta/conversation.proto>

=item * C<googleapis/google/cloud/ces/v1beta/data_store.proto>

=item * C<googleapis/google/cloud/ces/v1beta/data_store_tool.proto>

=item * C<googleapis/google/cloud/ces/v1beta/deployment.proto>

=item * C<googleapis/google/cloud/ces/v1beta/evaluation.proto>

=item * C<googleapis/google/cloud/ces/v1beta/evaluation_metrics_config.proto>

=item * C<googleapis/google/cloud/ces/v1beta/evaluation_service.proto>

=item * C<googleapis/google/cloud/ces/v1beta/example.proto>

=item * C<googleapis/google/cloud/ces/v1beta/fakes.proto>

=item * C<googleapis/google/cloud/ces/v1beta/file_context.proto>

=item * C<googleapis/google/cloud/ces/v1beta/file_search_tool.proto>

=item * C<googleapis/google/cloud/ces/v1beta/golden_run.proto>

=item * C<googleapis/google/cloud/ces/v1beta/google_search_tool.proto>

=item * C<googleapis/google/cloud/ces/v1beta/guardrail.proto>

=item * C<googleapis/google/cloud/ces/v1beta/mcp_tool.proto>

=item * C<googleapis/google/cloud/ces/v1beta/mcp_toolset.proto>

=item * C<googleapis/google/cloud/ces/v1beta/mocks.proto>

=item * C<googleapis/google/cloud/ces/v1beta/omnichannel.proto>

=item * C<googleapis/google/cloud/ces/v1beta/omnichannel_service.proto>

=item * C<googleapis/google/cloud/ces/v1beta/open_api_tool.proto>

=item * C<googleapis/google/cloud/ces/v1beta/open_api_toolset.proto>

=item * C<googleapis/google/cloud/ces/v1beta/python_function.proto>

=item * C<googleapis/google/cloud/ces/v1beta/schema.proto>

=item * C<googleapis/google/cloud/ces/v1beta/search_suggestions.proto>

=item * C<googleapis/google/cloud/ces/v1beta/security_settings.proto>

=item * C<googleapis/google/cloud/ces/v1beta/session_service.proto>

=item * C<googleapis/google/cloud/ces/v1beta/system_tool.proto>

=item * C<googleapis/google/cloud/ces/v1beta/tool.proto>

=item * C<googleapis/google/cloud/ces/v1beta/tool_service.proto>

=item * C<googleapis/google/cloud/ces/v1beta/toolset.proto>

=item * C<googleapis/google/cloud/ces/v1beta/toolset_tool.proto>

=item * C<googleapis/google/cloud/ces/v1beta/widget_service.proto>

=item * C<googleapis/google/cloud/ces/v1beta/widget_tool.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Ces::V1beta::SessionServiceClient->new(
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

=item * B<run_session>

    my $response = $client->run_session(
        config                   => $config,
        inputs                   => [ ... ],
    );

Calls the RPC method C<RunSession> on C<google.cloud.ces.v1beta.SessionService>.

Request: L<Google::Cloud::Ces::V1beta::SessionService::RunSessionRequest>

Returns: L<Google::Cloud::Ces::V1beta::SessionService::RunSessionResponse>

Parameters:

=over 4

=item * C<config> - L<Google::Cloud::Ces::V1beta::SessionService::SessionConfig>

=item * C<inputs> - ArrayRef of L<Google::Cloud::Ces::V1beta::SessionService::SessionInput>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
