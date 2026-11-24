package Google::Cloud::Oracledatabase::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Oracledatabase::V1::LocationMetadata;
use Google::Cloud::Oracledatabase::V1::GoldengateDeploymentEnvironment;
use Google::Cloud::Oracledatabase::V1::AutonomousDatabaseCharacterSet;
use Google::Cloud::Oracledatabase::V1::DbServer;
use Google::Cloud::Oracledatabase::V1::GoldengateConnectionType;
use Google::Cloud::Oracledatabase::V1::DbSystemShape;
use Google::Cloud::Oracledatabase::V1::DbSystemInitialStorageSize;
use Google::Cloud::Oracledatabase::V1::MinorVersion;
use Google::Cloud::Oracledatabase::V1::Entitlement;
use Google::Cloud::Oracledatabase::V1::DbVersion;
use Google::Cloud::Oracledatabase::V1::Common;
use Google::Cloud::Oracledatabase::V1::GiVersion;
use Google::Cloud::Oracledatabase::V1::GoldengateDeploymentType;
use Google::Cloud::Oracledatabase::V1::DatabaseCharacterSet;
use Google::Cloud::Oracledatabase::V1::PluggableDatabase;
use Google::Cloud::Oracledatabase::V1::GoldengateConnection;
use Google::Cloud::Oracledatabase::V1::GoldengateDeploymentVersion;
use Google::Cloud::Oracledatabase::V1::OdbSubnet;
use Google::Cloud::Oracledatabase::V1::GoldengateDeployment;
use Google::Cloud::Oracledatabase::V1::AutonomousDbBackup;
use Google::Cloud::Oracledatabase::V1::DbNode;
use Google::Cloud::Oracledatabase::V1::OdbNetwork;
use Google::Cloud::Oracledatabase::V1::DatabaseConnection;
use Google::Cloud::Oracledatabase::V1::OdbDnsZone;
use Google::Cloud::Oracledatabase::V1::GoldengateConnectionAssignment;
use Google::Cloud::Oracledatabase::V1::ExecuteSql;
use Google::Cloud::Oracledatabase::V1::ExascaleDbStorageVault;
use Google::Cloud::Oracledatabase::V1::FlexComponent;
use Google::Cloud::Oracledatabase::V1::DbSystemComputePerformance;
use Google::Cloud::Oracledatabase::V1::AutonomousDatabase;
use Google::Cloud::Oracledatabase::V1::ExadataInfra;
use Google::Cloud::Oracledatabase::V1::ExadbVmCluster;
use Google::Cloud::Oracledatabase::V1::VmCluster;
use Google::Cloud::Oracledatabase::V1::Database;
use Google::Cloud::Oracledatabase::V1::AutonomousDbVersion;
use Google::Cloud::Oracledatabase::V1::DbSystem;
use Google::Cloud::Oracledatabase::V1::Oracledatabase;

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

    my $target = 'oracledatabase.googleapis.com:443';
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

sub list_cloud_exadata_infrastructures {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudExadataInfrastructuresRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudExadataInfrastructuresResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.oracledatabase.v1.OracleDatabase/ListCloudExadataInfrastructures',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.oracledatabase.v1.OracleDatabase',
        method         => 'ListCloudExadataInfrastructures',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Oracledatabase::V1

__END__

=head1 NAME

Google::Cloud::Oracledatabase::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Oracledatabase::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Oracledatabase::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Oracledatabase::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Oracledatabase::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/oracledatabase/v1/autonomous_database.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/autonomous_database_character_set.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/autonomous_db_backup.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/autonomous_db_version.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/common.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/database.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/database_character_set.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/database_connection.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/db_node.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/db_server.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/db_system.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/db_system_compute_performance.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/db_system_initial_storage_size.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/db_system_shape.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/db_version.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/entitlement.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/exadata_infra.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/exadb_vm_cluster.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/exascale_db_storage_vault.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/execute_sql.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/flex_component.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/gi_version.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/goldengate_connection.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/goldengate_connection_assignment.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/goldengate_connection_type.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/goldengate_deployment.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/goldengate_deployment_environment.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/goldengate_deployment_type.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/goldengate_deployment_version.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/location_metadata.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/minor_version.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/odb_dns_zone.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/odb_network.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/odb_subnet.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/oracledatabase.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/pluggable_database.proto>

=item * C<googleapis/google/cloud/oracledatabase/v1/vm_cluster.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Oracledatabase::V1->new(
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

=item * B<list_cloud_exadata_infrastructures>

    my $response = $client->list_cloud_exadata_infrastructures(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListCloudExadataInfrastructures> on C<google.cloud.oracledatabase.v1.OracleDatabase>.

Request: L<Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudExadataInfrastructuresRequest>

Returns: L<Google::Cloud::Oracledatabase::V1::Oracledatabase::ListCloudExadataInfrastructuresResponse>

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
