package Google::Cloud::Compute::V1beta::ReservationsClient;

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

sub aggregated_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::AggregatedListReservationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::ReservationAggregatedList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Reservations/AggregatedList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'AggregatedList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::DeleteReservationRequest';
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
            path           => '/google.cloud.compute.v1beta.Reservations/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetReservationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Reservation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Reservations/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::GetIamPolicyReservationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Reservations/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub insert {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::InsertReservationRequest';
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
            path           => '/google.cloud.compute.v1beta.Reservations/Insert',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'Insert',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ListReservationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::ReservationList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Reservations/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub perform_maintenance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::PerformMaintenanceReservationRequest';
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
            path           => '/google.cloud.compute.v1beta.Reservations/PerformMaintenance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'PerformMaintenance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resize {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::ResizeReservationRequest';
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
            path           => '/google.cloud.compute.v1beta.Reservations/Resize',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'Resize',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub set_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::SetIamPolicyReservationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1beta::Compute::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1beta.Reservations/SetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'SetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub test_iam_permissions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsReservationRequest';
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
            path           => '/google.cloud.compute.v1beta.Reservations/TestIamPermissions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'TestIamPermissions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1beta::Compute::UpdateReservationRequest';
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
            path           => '/google.cloud.compute.v1beta.Reservations/Update',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1beta.Reservations',
        method         => 'Update',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1beta::ReservationsClient

__END__

=head1 NAME

Google::Cloud::Compute::V1beta::ReservationsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1beta::ReservationsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1beta::ReservationsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1beta::ReservationsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1beta::ReservationsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1beta/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1beta::ReservationsClient->new(
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

Calls the RPC method C<AggregatedList> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::AggregatedListReservationsRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::ReservationAggregatedList>

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
        request_id               => $request_id,
        reservation              => $reservation,
        zone                     => $zone,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::DeleteReservationRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<reservation> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        project                  => $project,
        reservation              => $reservation,
        zone                     => $zone,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetReservationRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Reservation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<reservation> - C<string>

=item * C<zone> - C<string>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy(
        options_requested_policy_version => $options_requested_policy_version,
        project                  => $project,
        resource                 => $resource,
        zone                     => $zone,
    );

Calls the RPC method C<GetIamPolicy> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::GetIamPolicyReservationRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Policy>

Parameters:

=over 4

=item * C<options_requested_policy_version> - C<int32>

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<zone> - C<string>

=back

=item * B<insert>

    my $response = $client->insert(
        project                  => $project,
        request_id               => $request_id,
        reservation_resource     => $reservation_resource,
        zone                     => $zone,
    );

Calls the RPC method C<Insert> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::InsertReservationRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<reservation_resource> - L<Google::Cloud::Compute::V1beta::Compute::Reservation>

=item * C<zone> - C<string>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
        return_partial_success   => $return_partial_success,
        zone                     => $zone,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ListReservationsRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::ReservationList>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=item * C<return_partial_success> - C<bool>

=item * C<zone> - C<string>

=back

=item * B<perform_maintenance>

    my $response = $client->perform_maintenance(
        project                  => $project,
        request_id               => $request_id,
        reservation              => $reservation,
        reservations_perform_maintenance_request_resource => $reservations_perform_maintenance_request_resource,
        zone                     => $zone,
    );

Calls the RPC method C<PerformMaintenance> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::PerformMaintenanceReservationRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<reservation> - C<string>

=item * C<reservations_perform_maintenance_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::ReservationsPerformMaintenanceRequest>

=item * C<zone> - C<string>

=back

=item * B<resize>

    my $response = $client->resize(
        project                  => $project,
        request_id               => $request_id,
        reservation              => $reservation,
        reservations_resize_request_resource => $reservations_resize_request_resource,
        zone                     => $zone,
    );

Calls the RPC method C<Resize> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::ResizeReservationRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<reservation> - C<string>

=item * C<reservations_resize_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::ReservationsResizeRequest>

=item * C<zone> - C<string>

=back

=item * B<set_iam_policy>

    my $response = $client->set_iam_policy(
        project                  => $project,
        resource                 => $resource,
        zone                     => $zone,
        zone_set_policy_request_resource => $zone_set_policy_request_resource,
    );

Calls the RPC method C<SetIamPolicy> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::SetIamPolicyReservationRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Policy>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<zone> - C<string>

=item * C<zone_set_policy_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::ZoneSetPolicyRequest>

=back

=item * B<test_iam_permissions>

    my $response = $client->test_iam_permissions(
        project                  => $project,
        resource                 => $resource,
        test_permissions_request_resource => $test_permissions_request_resource,
        zone                     => $zone,
    );

Calls the RPC method C<TestIamPermissions> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::TestIamPermissionsReservationRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<resource> - C<string>

=item * C<test_permissions_request_resource> - L<Google::Cloud::Compute::V1beta::Compute::TestPermissionsRequest>

=item * C<zone> - C<string>

=back

=item * B<update>

    my $response = $client->update(
        paths                    => $paths,
        project                  => $project,
        request_id               => $request_id,
        reservation              => $reservation,
        reservation_resource     => $reservation_resource,
        update_mask              => $update_mask,
        zone                     => $zone,
    );

Calls the RPC method C<Update> on C<google.cloud.compute.v1beta.Reservations>.

Request: L<Google::Cloud::Compute::V1beta::Compute::UpdateReservationRequest>

Returns: L<Google::Cloud::Compute::V1beta::Compute::Operation>

Parameters:

=over 4

=item * C<paths> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<reservation> - C<string>

=item * C<reservation_resource> - L<Google::Cloud::Compute::V1beta::Compute::Reservation>

=item * C<update_mask> - C<string>

=item * C<zone> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
