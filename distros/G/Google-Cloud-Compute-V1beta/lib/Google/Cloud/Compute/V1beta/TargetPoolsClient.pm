package Google::Cloud::Compute::V1beta::TargetPoolsClient;

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

sub add_health_check {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddHealthCheckTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1beta.TargetPools/AddHealthCheck',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'AddHealthCheck',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub add_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AddInstanceTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1beta.TargetPools/AddInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'AddInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AggregatedListTargetPoolsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::TargetPoolAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetPools/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1beta.TargetPools/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetTargetPoolRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::TargetPool';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetPools/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_health {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetHealthTargetPoolRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::TargetPoolInstanceHealth';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetPools/GetHealth',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'GetHealth',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::InsertTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1beta.TargetPools/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListTargetPoolsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::TargetPoolList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.TargetPools/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_health_check {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::RemoveHealthCheckTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1beta.TargetPools/RemoveHealthCheck',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'RemoveHealthCheck',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub remove_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::RemoveInstanceTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1beta.TargetPools/RemoveInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'RemoveInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_backup {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetBackupTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1beta.TargetPools/SetBackup',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'SetBackup',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_security_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetSecurityPolicyTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1beta.TargetPools/SetSecurityPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'SetSecurityPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsTargetPoolRequest';
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
            path           => '/google.cloud.compute.v1beta.TargetPools/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.TargetPools',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1beta::TargetPoolsClient

__END__

=head1 NAME

Google::Cloud::Compute::V1beta::TargetPoolsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1beta::TargetPoolsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1beta::TargetPoolsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1beta::TargetPoolsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1beta::TargetPoolsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1beta/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1beta::TargetPoolsClient->new(
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

=item * B<add_health_check>

    my $response = $client->add_health_check(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
        target_pools_add_health_check_request_resource => $target_pools_add_health_check_request_resource,
    );

Calls the RPC method C<AddHealthCheck> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddHealthCheckTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=item * C<target_pools_add_health_check_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetPoolsAddHealthCheckRequest>

=back

=item * B<add_instance>

    my $response = $client->add_instance(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
        target_pools_add_instance_request_resource => $target_pools_add_instance_request_resource,
    );

Calls the RPC method C<AddInstance> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AddInstanceTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=item * C<target_pools_add_instance_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetPoolsAddInstanceRequest>

=back

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

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AggregatedListTargetPoolsRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TargetPoolAggregatedList>

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
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        project                  => $project,
        region                   => $region,
        target_pool              => $target_pool,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TargetPool>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<target_pool> - C<string>

=back

=item * B<get_health>

    my $response = $client->get_health(
        instance_reference_resource => $instance_reference_resource,
        project                  => $project,
        region                   => $region,
        target_pool              => $target_pool,
    );

Calls the RPC method C<GetHealth> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetHealthTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TargetPoolInstanceHealth>

Parameters:

=over 4

=item * C<instance_reference_resource> - L<Google::Cloud::Compute::V1beta::Compute::InstanceReference>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<target_pool> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool_resource     => $target_pool_resource,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::InsertTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetPool>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        region                   => $region,
        return_partial_success   => $return_partial_success,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListTargetPoolsRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TargetPoolList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<return_partial_success> - C<bool>

=back

=item * B<remove_health_check>

    my $response = $client->remove_health_check(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
        target_pools_remove_health_check_request_resource => $target_pools_remove_health_check_request_resource,
    );

Calls the RPC method C<RemoveHealthCheck> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::RemoveHealthCheckTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=item * C<target_pools_remove_health_check_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetPoolsRemoveHealthCheckRequest>

=back

=item * B<remove_instance>

    my $response = $client->remove_instance(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
        target_pools_remove_instance_request_resource => $target_pools_remove_instance_request_resource,
    );

Calls the RPC method C<RemoveInstance> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::RemoveInstanceTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=item * C<target_pools_remove_instance_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetPoolsRemoveInstanceRequest>

=back

=item * B<set_backup>

    my $response = $client->set_backup(
        failover_ratio           => $failover_ratio,
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        target_pool              => $target_pool,
        target_reference_resource => $target_reference_resource,
    );

Calls the RPC method C<SetBackup> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetBackupTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<failover_ratio> - C<float>

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<target_pool> - C<string>

=item * C<target_reference_resource> - L<Google::Cloud::Compute::V1beta::Compute::TargetReference>

=back

=item * B<set_security_policy>

    my $response = $client->set_security_policy(
        project                  => $project,
        region                   => $region,
        request_id               => $request_id,
        security_policy_reference_resource => $security_policy_reference_resource,
        target_pool              => $target_pool,
    );

Calls the RPC method C<SetSecurityPolicy> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetSecurityPolicyTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<request_id> - C<string>

=item * C<security_policy_reference_resource> - L<Google::Cloud::Compute::V1beta::Compute::SecurityPolicyReference>

=item * C<target_pool> - C<string>

=back

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions(
        project                  => $project,
        region                   => $region,
        resource                 => $resource,
        test_permissions_request_resource => $test_permissions_request_resource,
    );

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1beta.TargetPools>.

Request: L<Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsTargetPoolRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<region> - C<string>

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsRequest>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
