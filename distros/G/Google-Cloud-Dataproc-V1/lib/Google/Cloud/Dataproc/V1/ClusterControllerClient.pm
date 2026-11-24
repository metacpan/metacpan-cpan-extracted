package Google::Cloud::Dataproc::V1::ClusterControllerClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Dataproc::V1::Operations;
use Google::Cloud::Dataproc::V1::AutoscalingPolicies;
use Google::Cloud::Dataproc::V1::Shared;
use Google::Cloud::Dataproc::V1::Jobs;
use Google::Cloud::Dataproc::V1::Batches;
use Google::Cloud::Dataproc::V1::Sessions;
use Google::Cloud::Dataproc::V1::Clusters;
use Google::Cloud::Dataproc::V1::SessionTemplates;
use Google::Cloud::Dataproc::V1::WorkflowTemplates;
use Google::Cloud::Dataproc::V1::NodeGroups;

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

    my $target = 'dataproc.googleapis.com:443';
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

sub create_cluster {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Clusters::CreateClusterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dataproc.v1.ClusterController/CreateCluster',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.ClusterController',
        method         => 'CreateCluster',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_cluster {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Clusters::UpdateClusterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dataproc.v1.ClusterController/UpdateCluster',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.ClusterController',
        method         => 'UpdateCluster',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub stop_cluster {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Clusters::StopClusterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dataproc.v1.ClusterController/StopCluster',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.ClusterController',
        method         => 'StopCluster',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub start_cluster {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Clusters::StartClusterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dataproc.v1.ClusterController/StartCluster',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.ClusterController',
        method         => 'StartCluster',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_cluster {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Clusters::DeleteClusterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dataproc.v1.ClusterController/DeleteCluster',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.ClusterController',
        method         => 'DeleteCluster',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_cluster {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Clusters::GetClusterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dataproc::V1::Clusters::Cluster';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dataproc.v1.ClusterController/GetCluster',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.ClusterController',
        method         => 'GetCluster',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_clusters {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Clusters::ListClustersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dataproc.v1.ClusterController/ListClusters',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.ClusterController',
        method         => 'ListClusters',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub diagnose_cluster {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Dataproc::V1::Clusters::DiagnoseClusterRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.dataproc.v1.ClusterController/DiagnoseCluster',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.dataproc.v1.ClusterController',
        method         => 'DiagnoseCluster',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Dataproc::V1::ClusterControllerClient

__END__

=head1 NAME

Google::Cloud::Dataproc::V1::ClusterControllerClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Dataproc::V1::ClusterControllerClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Dataproc::V1::ClusterControllerClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Dataproc::V1::ClusterControllerClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Dataproc::V1::ClusterControllerClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/dataproc/v1/autoscaling_policies.proto>

=item * C<googleapis/google/cloud/dataproc/v1/batches.proto>

=item * C<googleapis/google/cloud/dataproc/v1/clusters.proto>

=item * C<googleapis/google/cloud/dataproc/v1/jobs.proto>

=item * C<googleapis/google/cloud/dataproc/v1/node_groups.proto>

=item * C<googleapis/google/cloud/dataproc/v1/operations.proto>

=item * C<googleapis/google/cloud/dataproc/v1/session_templates.proto>

=item * C<googleapis/google/cloud/dataproc/v1/sessions.proto>

=item * C<googleapis/google/cloud/dataproc/v1/shared.proto>

=item * C<googleapis/google/cloud/dataproc/v1/workflow_templates.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Dataproc::V1::ClusterControllerClient->new(
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

=item * B<create_cluster>

    my $response = $client->create_cluster(
        project_id               => $project_id,
        region                   => $region,
        cluster                  => $cluster,
        request_id               => $request_id,
        action_on_failed_primary_workers => $action_on_failed_primary_workers,
    );

Calls the RPC method C<CreateCluster> on C<google.cloud.dataproc.v1.ClusterController>.

Request: L<Google::Cloud::Dataproc::V1::Clusters::CreateClusterRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<region> - C<string>

=item * C<cluster> - L<Google::Cloud::Dataproc::V1::Clusters::Cluster>

=item * C<request_id> - C<string>

=item * C<action_on_failed_primary_workers> - L<Google::Cloud::Dataproc::V1::Clusters::FailureAction>

=back

=item * B<update_cluster>

    my $response = $client->update_cluster(
        project_id               => $project_id,
        region                   => $region,
        cluster_name             => $cluster_name,
        cluster                  => $cluster,
        graceful_decommission_timeout => $graceful_decommission_timeout,
        update_mask              => $update_mask,
        request_id               => $request_id,
    );

Calls the RPC method C<UpdateCluster> on C<google.cloud.dataproc.v1.ClusterController>.

Request: L<Google::Cloud::Dataproc::V1::Clusters::UpdateClusterRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<region> - C<string>

=item * C<cluster_name> - C<string>

=item * C<cluster> - L<Google::Cloud::Dataproc::V1::Clusters::Cluster>

=item * C<graceful_decommission_timeout> - L<Google::Protobuf::Duration::Duration>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<request_id> - C<string>

=back

=item * B<stop_cluster>

    my $response = $client->stop_cluster(
        project_id               => $project_id,
        region                   => $region,
        cluster_name             => $cluster_name,
        cluster_uuid             => $cluster_uuid,
        request_id               => $request_id,
    );

Calls the RPC method C<StopCluster> on C<google.cloud.dataproc.v1.ClusterController>.

Request: L<Google::Cloud::Dataproc::V1::Clusters::StopClusterRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<region> - C<string>

=item * C<cluster_name> - C<string>

=item * C<cluster_uuid> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<start_cluster>

    my $response = $client->start_cluster(
        project_id               => $project_id,
        region                   => $region,
        cluster_name             => $cluster_name,
        cluster_uuid             => $cluster_uuid,
        request_id               => $request_id,
    );

Calls the RPC method C<StartCluster> on C<google.cloud.dataproc.v1.ClusterController>.

Request: L<Google::Cloud::Dataproc::V1::Clusters::StartClusterRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<region> - C<string>

=item * C<cluster_name> - C<string>

=item * C<cluster_uuid> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<delete_cluster>

    my $response = $client->delete_cluster(
        project_id               => $project_id,
        region                   => $region,
        cluster_name             => $cluster_name,
        cluster_uuid             => $cluster_uuid,
        request_id               => $request_id,
    );

Calls the RPC method C<DeleteCluster> on C<google.cloud.dataproc.v1.ClusterController>.

Request: L<Google::Cloud::Dataproc::V1::Clusters::DeleteClusterRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<region> - C<string>

=item * C<cluster_name> - C<string>

=item * C<cluster_uuid> - C<string>

=item * C<request_id> - C<string>

=back

=item * B<get_cluster>

    my $response = $client->get_cluster(
        project_id               => $project_id,
        region                   => $region,
        cluster_name             => $cluster_name,
    );

Calls the RPC method C<GetCluster> on C<google.cloud.dataproc.v1.ClusterController>.

Request: L<Google::Cloud::Dataproc::V1::Clusters::GetClusterRequest>

Returns: L<Google::Cloud::Dataproc::V1::Clusters::Cluster>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<region> - C<string>

=item * C<cluster_name> - C<string>

=back

=item * B<list_clusters>

    my $response = $client->list_clusters(
        project_id               => $project_id,
        region                   => $region,
        filter                   => $filter,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListClusters> on C<google.cloud.dataproc.v1.ClusterController>.

Request: L<Google::Cloud::Dataproc::V1::Clusters::ListClustersRequest>

Returns: L<Google::Cloud::Dataproc::V1::Clusters::ListClustersResponse>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<region> - C<string>

=item * C<filter> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<diagnose_cluster>

    my $response = $client->diagnose_cluster(
        project_id               => $project_id,
        region                   => $region,
        cluster_name             => $cluster_name,
        tarball_gcs_dir          => $tarball_gcs_dir,
        tarball_access           => $tarball_access,
        diagnosis_interval       => $diagnosis_interval,
        jobs                     => [ ... ],
        yarn_application_ids     => [ ... ],
    );

Calls the RPC method C<DiagnoseCluster> on C<google.cloud.dataproc.v1.ClusterController>.

Request: L<Google::Cloud::Dataproc::V1::Clusters::DiagnoseClusterRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<project_id> - C<string>

=item * C<region> - C<string>

=item * C<cluster_name> - C<string>

=item * C<tarball_gcs_dir> - C<string>

=item * C<tarball_access> - L<Google::Cloud::Dataproc::V1::Clusters::TarballAccess>

=item * C<diagnosis_interval> - L<Google::Type::Interval::Interval>

=item * C<jobs> - ArrayRef of C<string>

=item * C<yarn_application_ids> - ArrayRef of C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
