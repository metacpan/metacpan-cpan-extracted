package Google::Cloud::Osconfig::V1::OsConfigZonalServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Osconfig::V1::OsconfigCommon;
use Google::Cloud::Osconfig::V1::OsPolicy;
use Google::Cloud::Osconfig::V1::Inventory;
use Google::Cloud::Osconfig::V1::Vulnerability;
use Google::Cloud::Osconfig::V1::PatchJobs;
use Google::Cloud::Osconfig::V1::OsPolicyAssignmentReports;
use Google::Cloud::Osconfig::V1::OsPolicyAssignments;
use Google::Cloud::Osconfig::V1::PatchDeployments;
use Google::Cloud::Osconfig::V1::OsconfigZonalService;
use Google::Cloud::Osconfig::V1::OsconfigService;

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

sub create_ospolicy_assignment {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Osconfig::V1::OsPolicyAssignments::CreateOSPolicyAssignmentRequest';
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
            path           => '/google.cloud.osconfig.v1.OsConfigZonalService/CreateOSPolicyAssignment',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'CreateOSPolicyAssignment',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_inventories {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Osconfig::V1::Inventory::ListInventoriesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Osconfig::V1::Inventory::ListInventoriesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.osconfig.v1.OsConfigZonalService/ListInventories',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'ListInventories',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_vulnerability_reports {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Osconfig::V1::Vulnerability::ListVulnerabilityReportsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Osconfig::V1::Vulnerability::ListVulnerabilityReportsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.osconfig.v1.OsConfigZonalService/ListVulnerabilityReports',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.osconfig.v1.OsConfigZonalService',
        method         => 'ListVulnerabilityReports',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Osconfig::V1::OsConfigZonalServiceClient

__END__

=head1 NAME

Google::Cloud::Osconfig::V1::OsConfigZonalServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::V1::OsConfigZonalServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Osconfig::V1::OsConfigZonalServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Osconfig::V1::OsConfigZonalServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Osconfig::V1::OsConfigZonalServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/osconfig/v1/inventory.proto>

=item * C<googleapis/google/cloud/osconfig/v1/os_policy.proto>

=item * C<googleapis/google/cloud/osconfig/v1/os_policy_assignment_reports.proto>

=item * C<googleapis/google/cloud/osconfig/v1/os_policy_assignments.proto>

=item * C<googleapis/google/cloud/osconfig/v1/osconfig_common.proto>

=item * C<googleapis/google/cloud/osconfig/v1/osconfig_service.proto>

=item * C<googleapis/google/cloud/osconfig/v1/osconfig_zonal_service.proto>

=item * C<googleapis/google/cloud/osconfig/v1/patch_deployments.proto>

=item * C<googleapis/google/cloud/osconfig/v1/patch_jobs.proto>

=item * C<googleapis/google/cloud/osconfig/v1/vulnerability.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Osconfig::V1::OsConfigZonalServiceClient->new(
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

=item * B<create_ospolicy_assignment>

    my $response = $client->create_ospolicy_assignment(
        parent                   => $parent,
        os_policy_assignment     => $os_policy_assignment,
        os_policy_assignment_id  => $os_policy_assignment_id,
    );

Calls the RPC method C<CreateOSPolicyAssignment> on C<google.cloud.osconfig.v1.OsConfigZonalService>.

Request: L<Google::Cloud::Osconfig::V1::OsPolicyAssignments::CreateOSPolicyAssignmentRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<os_policy_assignment> - L<Google::Cloud::Osconfig::V1::OsPolicyAssignments::OSPolicyAssignment>

=item * C<os_policy_assignment_id> - C<string>

=back

=item * B<list_inventories>

    my $response = $client->list_inventories(
        parent                   => $parent,
        view                     => $view,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListInventories> on C<google.cloud.osconfig.v1.OsConfigZonalService>.

Request: L<Google::Cloud::Osconfig::V1::Inventory::ListInventoriesRequest>

Returns: L<Google::Cloud::Osconfig::V1::Inventory::ListInventoriesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<view> - L<Google::Cloud::Osconfig::V1::Inventory::InventoryView>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<list_vulnerability_reports>

    my $response = $client->list_vulnerability_reports(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListVulnerabilityReports> on C<google.cloud.osconfig.v1.OsConfigZonalService>.

Request: L<Google::Cloud::Osconfig::V1::Vulnerability::ListVulnerabilityReportsRequest>

Returns: L<Google::Cloud::Osconfig::V1::Vulnerability::ListVulnerabilityReportsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
