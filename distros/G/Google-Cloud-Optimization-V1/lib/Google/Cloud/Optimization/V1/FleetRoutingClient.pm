package Google::Cloud::Optimization::V1::FleetRoutingClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Optimization::V1::AsyncModel;
use Google::Cloud::Optimization::V1::FleetRouting;

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

    my $target = 'cloudoptimization.googleapis.com:443';
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

sub optimize_tours {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.optimization.v1.FleetRouting/OptimizeTours',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.optimization.v1.FleetRouting',
        method         => 'OptimizeTours',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Optimization::V1::FleetRoutingClient

__END__

=head1 NAME

Google::Cloud::Optimization::V1::FleetRoutingClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Optimization::V1::FleetRoutingClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Optimization::V1::FleetRoutingClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Optimization::V1::FleetRoutingClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Optimization::V1::FleetRoutingClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/optimization/v1/async_model.proto>

=item * C<googleapis/google/cloud/optimization/v1/fleet_routing.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Optimization::V1::FleetRoutingClient->new(
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

=item * B<optimize_tours>

    my $response = $client->optimize_tours(
        parent                   => $parent,
        timeout                  => $timeout,
        model                    => $model,
        solving_mode             => $solving_mode,
        search_mode              => $search_mode,
        injected_first_solution_routes => [ ... ],
        injected_solution_constraint => $injected_solution_constraint,
        refresh_details_routes   => [ ... ],
        interpret_injected_solutions_using_labels => $interpret_injected_solutions_using_labels,
        consider_road_traffic    => $consider_road_traffic,
        populate_polylines       => $populate_polylines,
        populate_transition_polylines => $populate_transition_polylines,
        allow_large_deadline_despite_interruption_risk => $allow_large_deadline_despite_interruption_risk,
        use_geodesic_distances   => $use_geodesic_distances,
        geodesic_meters_per_second => $geodesic_meters_per_second,
        max_validation_errors    => $max_validation_errors,
        label                    => $label,
        populate_travel_step_polylines => $populate_travel_step_polylines,
    );

Calls the RPC method C<OptimizeTours> on C<google.cloud.optimization.v1.FleetRouting>.

Request: L<Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursRequest>

Returns: L<Google::Cloud::Optimization::V1::FleetRouting::OptimizeToursResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<timeout> - L<Google::Protobuf::Duration::Duration>

=item * C<model> - L<Google::Cloud::Optimization::V1::FleetRouting::ShipmentModel>

=item * C<solving_mode> - L<Google::Cloud::Optimization::V1::FleetRouting::SolvingMode>

=item * C<search_mode> - L<Google::Cloud::Optimization::V1::FleetRouting::SearchMode>

=item * C<injected_first_solution_routes> - ArrayRef of L<Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute>

=item * C<injected_solution_constraint> - L<Google::Cloud::Optimization::V1::FleetRouting::InjectedSolutionConstraint>

=item * C<refresh_details_routes> - ArrayRef of L<Google::Cloud::Optimization::V1::FleetRouting::ShipmentRoute>

=item * C<interpret_injected_solutions_using_labels> - C<bool>

=item * C<consider_road_traffic> - C<bool>

=item * C<populate_polylines> - C<bool>

=item * C<populate_transition_polylines> - C<bool>

=item * C<allow_large_deadline_despite_interruption_risk> - C<bool>

=item * C<use_geodesic_distances> - C<bool>

=item * C<geodesic_meters_per_second> - C<double>

=item * C<max_validation_errors> - C<int32>

=item * C<label> - C<string>

=item * C<populate_travel_step_polylines> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
