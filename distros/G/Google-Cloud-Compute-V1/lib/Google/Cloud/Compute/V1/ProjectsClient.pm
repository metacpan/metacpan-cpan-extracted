package Google::Cloud::Compute::V1::ProjectsClient;

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

sub disable_xpn_host {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DisableXpnHostProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/DisableXpnHost',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'DisableXpnHost',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub disable_xpn_resource {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DisableXpnResourceProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/DisableXpnResource',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'DisableXpnResource',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub enable_xpn_host {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::EnableXpnHostProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/EnableXpnHost',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'EnableXpnHost',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub enable_xpn_resource {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::EnableXpnResourceProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/EnableXpnResource',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'EnableXpnResource',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetProjectRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Project';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Projects/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_xpn_host {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetXpnHostProjectRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Project';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Projects/GetXpnHost',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'GetXpnHost',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_xpn_resources {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetXpnResourcesProjectsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::ProjectsGetXpnResources';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Projects/GetXpnResources',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'GetXpnResources',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_xpn_hosts {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListXpnHostsProjectsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::XpnHostList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Projects/ListXpnHosts',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'ListXpnHosts',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub move_disk {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::MoveDiskProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/MoveDisk',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'MoveDisk',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub move_instance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::MoveInstanceProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/MoveInstance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'MoveInstance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_cloud_armor_tier {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetCloudArmorTierProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/SetCloudArmorTier',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'SetCloudArmorTier',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_common_instance_metadata {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetCommonInstanceMetadataProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/SetCommonInstanceMetadata',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'SetCommonInstanceMetadata',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_default_network_tier {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetDefaultNetworkTierProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/SetDefaultNetworkTier',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'SetDefaultNetworkTier',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_usage_export_bucket {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::SetUsageExportBucketProjectRequest';
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
            path           => '/google.cloud.compute.v1.Projects/SetUsageExportBucket',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Projects',
        method         => 'SetUsageExportBucket',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::ProjectsClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::ProjectsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::ProjectsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::ProjectsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::ProjectsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::ProjectsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::ProjectsClient->new(
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

=item * B<disable_xpn_host>

    my $response = $client->disable_xpn_host(
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<DisableXpnHost> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::DisableXpnHostProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<disable_xpn_resource>

    my $response = $client->disable_xpn_resource(
        project                  => $project,
        projects_disable_xpn_resource_request_resource => $projects_disable_xpn_resource_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<DisableXpnResource> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::DisableXpnResourceProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<projects_disable_xpn_resource_request_resource> - L<Google::Cloud::Compute::V1::Compute::ProjectsDisableXpnResourceRequest>

=item * C<request_id> - C<string>

=back

=item * B<enable_xpn_host>

    my $response = $client->enable_xpn_host(
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<EnableXpnHost> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::EnableXpnHostProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<enable_xpn_resource>

    my $response = $client->enable_xpn_resource(
        project                  => $project,
        projects_enable_xpn_resource_request_resource => $projects_enable_xpn_resource_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<EnableXpnResource> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::EnableXpnResourceProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<projects_enable_xpn_resource_request_resource> - L<Google::Cloud::Compute::V1::Compute::ProjectsEnableXpnResourceRequest>

=item * C<request_id> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        project                  => $project,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::GetProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Project>

Parameters:

=over 4

=item * C<project> - C<string>

=back

=item * B<get_xpn_host>

    my $response = $client->get_xpn_host(
        project                  => $project,
    );

Calls the RPC method C<GetXpnHost> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::GetXpnHostProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Project>

Parameters:

=over 4

=item * C<project> - C<string>

=back

=item * B<get_xpn_resources>

    my $response = $client->get_xpn_resources(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
    );

Calls the RPC method C<GetXpnResources> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::GetXpnResourcesProjectsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::ProjectsGetXpnResources>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=back

=item * B<list_xpn_hosts>

    my $response = $client->list_xpn_hosts(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        projects_list_xpn_hosts_request_resource => $projects_list_xpn_hosts_request_resource,
    );

Calls the RPC method C<ListXpnHosts> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::ListXpnHostsProjectsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::XpnHostList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<projects_list_xpn_hosts_request_resource> - L<Google::Cloud::Compute::V1::Compute::ProjectsListXpnHostsRequest>

=back

=item * B<move_disk>

    my $response = $client->move_disk(
        disk_move_request_resource => $disk_move_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<MoveDisk> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::MoveDiskProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<disk_move_request_resource> - L<Google::Cloud::Compute::V1::Compute::DiskMoveRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<move_instance>

    my $response = $client->move_instance(
        instance_move_request_resource => $instance_move_request_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<MoveInstance> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::MoveInstanceProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<instance_move_request_resource> - L<Google::Cloud::Compute::V1::Compute::InstanceMoveRequest>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<set_cloud_armor_tier>

    my $response = $client->set_cloud_armor_tier(
        project                  => $project,
        projects_set_cloud_armor_tier_request_resource => $projects_set_cloud_armor_tier_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<SetCloudArmorTier> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::SetCloudArmorTierProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<projects_set_cloud_armor_tier_request_resource> - L<Google::Cloud::Compute::V1::Compute::ProjectsSetCloudArmorTierRequest>

=item * C<request_id> - C<string>

=back

=item * B<set_common_instance_metadata>

    my $response = $client->set_common_instance_metadata(
        metadata_resource        => $metadata_resource,
        project                  => $project,
        request_id               => $request_id,
    );

Calls the RPC method C<SetCommonInstanceMetadata> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::SetCommonInstanceMetadataProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<metadata_resource> - L<Google::Cloud::Compute::V1::Compute::Metadata>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<set_default_network_tier>

    my $response = $client->set_default_network_tier(
        project                  => $project,
        projects_set_default_network_tier_request_resource => $projects_set_default_network_tier_request_resource,
        request_id               => $request_id,
    );

Calls the RPC method C<SetDefaultNetworkTier> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::SetDefaultNetworkTierProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<projects_set_default_network_tier_request_resource> - L<Google::Cloud::Compute::V1::Compute::ProjectsSetDefaultNetworkTierRequest>

=item * C<request_id> - C<string>

=back

=item * B<set_usage_export_bucket>

    my $response = $client->set_usage_export_bucket(
        project                  => $project,
        request_id               => $request_id,
        usage_export_location_resource => $usage_export_location_resource,
    );

Calls the RPC method C<SetUsageExportBucket> on C<google.cloud.compute.v1.Projects>.

Request: L<Google::Cloud::Compute::V1::Compute::SetUsageExportBucketProjectRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<usage_export_location_resource> - L<Google::Cloud::Compute::V1::Compute::UsageExportLocation>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
