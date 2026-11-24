package Google::Cloud::Osconfig::Agentendpoint::V1beta;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Osconfig::Agentendpoint::V1beta::PatchJobs;
use Google::Cloud::Osconfig::Agentendpoint::V1beta::GuestPolicies;
use Google::Cloud::Osconfig::Agentendpoint::V1beta::Tasks;
use Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint;

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

    my $target = 'osconfig.googleapis.com:443';
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

sub receive_task_notification {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService/ReceiveTaskNotification',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'ReceiveTaskNotification',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_next_task {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService/StartNextTask',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'StartNextTask',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub report_task_progress {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService/ReportTaskProgress',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'ReportTaskProgress',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub report_task_complete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService/ReportTaskComplete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'ReportTaskComplete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub lookup_effective_guest_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::GuestPolicies::LookupEffectiveGuestPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::GuestPolicies::EffectiveGuestPolicy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService/LookupEffectiveGuestPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'LookupEffectiveGuestPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub register_agent {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService/RegisterAgent',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService',
        method         => 'RegisterAgent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Osconfig::Agentendpoint::V1beta

__END__

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1beta - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::Agentendpoint::V1beta;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Osconfig::Agentendpoint::V1beta->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Osconfig::Agentendpoint::V1beta->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Osconfig::Agentendpoint::V1beta> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/osconfig/agentendpoint/v1beta/agentendpoint.proto>

=item * C<googleapis/google/cloud/osconfig/agentendpoint/v1beta/guest_policies.proto>

=item * C<googleapis/google/cloud/osconfig/agentendpoint/v1beta/patch_jobs.proto>

=item * C<googleapis/google/cloud/osconfig/agentendpoint/v1beta/tasks.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Osconfig::Agentendpoint::V1beta->new(
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

=item * B<receive_task_notification>

    my $response = $client->receive_task_notification(
        instance_id_token        => $instance_id_token,
        agent_version            => $agent_version,
    );

Calls the RPC method C<ReceiveTaskNotification> on C<google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService>.

Request: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationRequest>

Returns: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReceiveTaskNotificationResponse>

Parameters:

=over 4

=item * C<instance_id_token> - C<string>

=item * C<agent_version> - C<string>

=back

=item * B<start_next_task>

    my $response = $client->start_next_task(
        instance_id_token        => $instance_id_token,
    );

Calls the RPC method C<StartNextTask> on C<google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService>.

Request: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskRequest>

Returns: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::StartNextTaskResponse>

Parameters:

=over 4

=item * C<instance_id_token> - C<string>

=back

=item * B<report_task_progress>

    my $response = $client->report_task_progress(
        instance_id_token        => $instance_id_token,
        task_id                  => $task_id,
        task_type                => $task_type,
    );

Calls the RPC method C<ReportTaskProgress> on C<google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService>.

Request: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressRequest>

Returns: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskProgressResponse>

Parameters:

=over 4

=item * C<instance_id_token> - C<string>

=item * C<task_id> - C<string>

=item * C<task_type> - L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::TaskType>

=back

=item * B<report_task_complete>

    my $response = $client->report_task_complete(
        instance_id_token        => $instance_id_token,
        task_id                  => $task_id,
        task_type                => $task_type,
        error_message            => $error_message,
    );

Calls the RPC method C<ReportTaskComplete> on C<google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService>.

Request: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteRequest>

Returns: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::ReportTaskCompleteResponse>

Parameters:

=over 4

=item * C<instance_id_token> - C<string>

=item * C<task_id> - C<string>

=item * C<task_type> - L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::TaskType>

=item * C<error_message> - C<string>

=back

=item * B<lookup_effective_guest_policy>

    my $response = $client->lookup_effective_guest_policy(
        instance_id_token        => $instance_id_token,
        os_short_name            => $os_short_name,
        os_version               => $os_version,
        os_architecture          => $os_architecture,
    );

Calls the RPC method C<LookupEffectiveGuestPolicy> on C<google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService>.

Request: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::GuestPolicies::LookupEffectiveGuestPolicyRequest>

Returns: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::GuestPolicies::EffectiveGuestPolicy>

Parameters:

=over 4

=item * C<instance_id_token> - C<string>

=item * C<os_short_name> - C<string>

=item * C<os_version> - C<string>

=item * C<os_architecture> - C<string>

=back

=item * B<register_agent>

    my $response = $client->register_agent(
        instance_id_token        => $instance_id_token,
        agent_version            => $agent_version,
        supported_capabilities   => [ ... ],
        os_long_name             => $os_long_name,
        os_short_name            => $os_short_name,
        os_version               => $os_version,
        os_architecture          => $os_architecture,
    );

Calls the RPC method C<RegisterAgent> on C<google.cloud.osconfig.agentendpoint.v1beta.AgentEndpointService>.

Request: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentRequest>

Returns: L<Google::Cloud::Osconfig::Agentendpoint::V1beta::Agentendpoint::RegisterAgentResponse>

Parameters:

=over 4

=item * C<instance_id_token> - C<string>

=item * C<agent_version> - C<string>

=item * C<supported_capabilities> - ArrayRef of C<string>

=item * C<os_long_name> - C<string>

=item * C<os_short_name> - C<string>

=item * C<os_version> - C<string>

=item * C<os_architecture> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
