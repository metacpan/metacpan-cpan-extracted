package Google::Cloud::Capacityplanner::V1beta;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Capacityplanner::V1beta::Allocation;
use Google::Cloud::Capacityplanner::V1beta::Resource;
use Google::Cloud::Capacityplanner::V1beta::Location;
use Google::Cloud::Capacityplanner::V1beta::FutureReservation;
use Google::Cloud::Capacityplanner::V1beta::UsageService;

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

    my $target = 'capacityplanner.googleapis.com:443';
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

sub query_usage_histories {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryUsageHistoriesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Capacityplanner::V1beta::UsageService::QueryUsageHistoriesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.capacityplanner.v1beta.UsageService/QueryUsageHistories',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.capacityplanner.v1beta.UsageService',
        method         => 'QueryUsageHistories',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Capacityplanner::V1beta

__END__

=head1 NAME

Google::Cloud::Capacityplanner::V1beta - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Capacityplanner::V1beta;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Capacityplanner::V1beta->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Capacityplanner::V1beta->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Capacityplanner::V1beta> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/capacityplanner/v1beta/allocation.proto>

=item * C<googleapis/google/cloud/capacityplanner/v1beta/future_reservation.proto>

=item * C<googleapis/google/cloud/capacityplanner/v1beta/location.proto>

=item * C<googleapis/google/cloud/capacityplanner/v1beta/resource.proto>

=item * C<googleapis/google/cloud/capacityplanner/v1beta/usage_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Capacityplanner::V1beta->new(
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

=item * B<query_usage_histories>

    my $response = $client->query_usage_histories(
        parent                   => $parent,
        location_level           => $location_level,
        is_spot                  => $is_spot,
        machine_family           => $machine_family,
        machine_shape            => $machine_shape,
        disk_type                => $disk_type,
        confidential_mode        => $confidential_mode,
        gpu_type                 => $gpu_type,
        tpu_type                 => $tpu_type,
        cloud_resource_type      => $cloud_resource_type,
        usage_aggregation_method => $usage_aggregation_method,
        start_date               => $start_date,
        end_date                 => $end_date,
    );

Calls the RPC method C<QueryUsageHistories> on C<google.cloud.capacityplanner.v1beta.UsageService>.

Request: L<Google::Cloud::Capacityplanner::V1beta::UsageService::QueryUsageHistoriesRequest>

Returns: L<Google::Cloud::Capacityplanner::V1beta::UsageService::QueryUsageHistoriesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<location_level> - L<TimeSeries::LocationType::LocationType>

=item * C<is_spot> - C<bool>

=item * C<machine_family> - C<string>

=item * C<machine_shape> - L<Google::Cloud::Capacityplanner::V1beta::UsageService::MachineShape>

=item * C<disk_type> - C<string>

=item * C<confidential_mode> - C<bool>

=item * C<gpu_type> - C<string>

=item * C<tpu_type> - C<string>

=item * C<cloud_resource_type> - C<string>

=item * C<usage_aggregation_method> - L<UsageHistory::AggregationMethod::AggregationMethod>

=item * C<start_date> - L<Google::Type::Date::Date>

=item * C<end_date> - L<Google::Type::Date::Date>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
