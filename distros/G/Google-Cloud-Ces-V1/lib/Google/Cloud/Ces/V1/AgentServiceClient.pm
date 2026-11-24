package Google::Cloud::Ces::V1::AgentServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Ces::V1::SearchSuggestions;
use Google::Cloud::Ces::V1::Fakes;
use Google::Cloud::Ces::V1::DataStore;
use Google::Cloud::Ces::V1::SystemTool;
use Google::Cloud::Ces::V1::FileSearchTool;
use Google::Cloud::Ces::V1::BigqueryExport;
use Google::Cloud::Ces::V1::GoogleSearchTool;
use Google::Cloud::Ces::V1::Schema;
use Google::Cloud::Ces::V1::OmnichannelService;
use Google::Cloud::Ces::V1::ToolsetTool;
use Google::Cloud::Ces::V1::Auth;
use Google::Cloud::Ces::V1::Common;
use Google::Cloud::Ces::V1::Changelog;
use Google::Cloud::Ces::V1::AgentTool;
use Google::Cloud::Ces::V1::Omnichannel;
use Google::Cloud::Ces::V1::WidgetService;
use Google::Cloud::Ces::V1::SecuritySettings;
use Google::Cloud::Ces::V1::AgentTransfers;
use Google::Cloud::Ces::V1::ClientFunction;
use Google::Cloud::Ces::V1::Mocks;
use Google::Cloud::Ces::V1::Example;
use Google::Cloud::Ces::V1::ConnectorTool;
use Google::Cloud::Ces::V1::AgentCard;
use Google::Cloud::Ces::V1::OpenApiToolset;
use Google::Cloud::Ces::V1::DataStoreTool;
use Google::Cloud::Ces::V1::McpToolset;
use Google::Cloud::Ces::V1::McpTool;
use Google::Cloud::Ces::V1::PythonFunction;
use Google::Cloud::Ces::V1::Deployment;
use Google::Cloud::Ces::V1::Guardrail;
use Google::Cloud::Ces::V1::App;
use Google::Cloud::Ces::V1::OpenApiTool;
use Google::Cloud::Ces::V1::Agent;
use Google::Cloud::Ces::V1::Conversation;
use Google::Cloud::Ces::V1::SessionService;
use Google::Cloud::Ces::V1::ConnectorToolset;
use Google::Cloud::Ces::V1::WidgetTool;
use Google::Cloud::Ces::V1::Toolset;
use Google::Cloud::Ces::V1::Tool;
use Google::Cloud::Ces::V1::ToolService;
use Google::Cloud::Ces::V1::AppVersion;
use Google::Cloud::Ces::V1::AgentService;

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

sub list_apps {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Ces::V1::AgentService::ListAppsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Ces::V1::AgentService::ListAppsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.ces.v1.AgentService/ListApps',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.ces.v1.AgentService',
        method         => 'ListApps',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Ces::V1::AgentServiceClient

__END__

=head1 NAME

Google::Cloud::Ces::V1::AgentServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::AgentServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Ces::V1::AgentServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Ces::V1::AgentServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Ces::V1::AgentServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/ces/v1/agent.proto>

=item * C<googleapis/google/cloud/ces/v1/agent_card.proto>

=item * C<googleapis/google/cloud/ces/v1/agent_service.proto>

=item * C<googleapis/google/cloud/ces/v1/agent_tool.proto>

=item * C<googleapis/google/cloud/ces/v1/agent_transfers.proto>

=item * C<googleapis/google/cloud/ces/v1/app.proto>

=item * C<googleapis/google/cloud/ces/v1/app_version.proto>

=item * C<googleapis/google/cloud/ces/v1/auth.proto>

=item * C<googleapis/google/cloud/ces/v1/bigquery_export.proto>

=item * C<googleapis/google/cloud/ces/v1/changelog.proto>

=item * C<googleapis/google/cloud/ces/v1/client_function.proto>

=item * C<googleapis/google/cloud/ces/v1/common.proto>

=item * C<googleapis/google/cloud/ces/v1/connector_tool.proto>

=item * C<googleapis/google/cloud/ces/v1/connector_toolset.proto>

=item * C<googleapis/google/cloud/ces/v1/conversation.proto>

=item * C<googleapis/google/cloud/ces/v1/data_store.proto>

=item * C<googleapis/google/cloud/ces/v1/data_store_tool.proto>

=item * C<googleapis/google/cloud/ces/v1/deployment.proto>

=item * C<googleapis/google/cloud/ces/v1/example.proto>

=item * C<googleapis/google/cloud/ces/v1/fakes.proto>

=item * C<googleapis/google/cloud/ces/v1/file_search_tool.proto>

=item * C<googleapis/google/cloud/ces/v1/google_search_tool.proto>

=item * C<googleapis/google/cloud/ces/v1/guardrail.proto>

=item * C<googleapis/google/cloud/ces/v1/mcp_tool.proto>

=item * C<googleapis/google/cloud/ces/v1/mcp_toolset.proto>

=item * C<googleapis/google/cloud/ces/v1/mocks.proto>

=item * C<googleapis/google/cloud/ces/v1/omnichannel.proto>

=item * C<googleapis/google/cloud/ces/v1/omnichannel_service.proto>

=item * C<googleapis/google/cloud/ces/v1/open_api_tool.proto>

=item * C<googleapis/google/cloud/ces/v1/open_api_toolset.proto>

=item * C<googleapis/google/cloud/ces/v1/python_function.proto>

=item * C<googleapis/google/cloud/ces/v1/schema.proto>

=item * C<googleapis/google/cloud/ces/v1/search_suggestions.proto>

=item * C<googleapis/google/cloud/ces/v1/security_settings.proto>

=item * C<googleapis/google/cloud/ces/v1/session_service.proto>

=item * C<googleapis/google/cloud/ces/v1/system_tool.proto>

=item * C<googleapis/google/cloud/ces/v1/tool.proto>

=item * C<googleapis/google/cloud/ces/v1/tool_service.proto>

=item * C<googleapis/google/cloud/ces/v1/toolset.proto>

=item * C<googleapis/google/cloud/ces/v1/toolset_tool.proto>

=item * C<googleapis/google/cloud/ces/v1/widget_service.proto>

=item * C<googleapis/google/cloud/ces/v1/widget_tool.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Ces::V1::AgentServiceClient->new(
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

=item * B<list_apps>

    my $response = $client->list_apps(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListApps> on C<google.cloud.ces.v1.AgentService>.

Request: L<Google::Cloud::Ces::V1::AgentService::ListAppsRequest>

Returns: L<Google::Cloud::Ces::V1::AgentService::ListAppsResponse>

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
