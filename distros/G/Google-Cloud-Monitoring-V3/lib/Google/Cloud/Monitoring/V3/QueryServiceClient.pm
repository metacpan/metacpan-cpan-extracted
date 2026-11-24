package Google::Cloud::Monitoring::V3::QueryServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Monitoring::V3::DroppedLabels;
use Google::Monitoring::V3::SpanContext;
use Google::Monitoring::V3::MutationRecord;
use Google::Monitoring::V3::Group;
use Google::Monitoring::V3::Common;
use Google::Monitoring::V3::Uptime;
use Google::Monitoring::V3::Service;
use Google::Monitoring::V3::Snooze;
use Google::Monitoring::V3::GroupService;
use Google::Monitoring::V3::Metric;
use Google::Monitoring::V3::Notification;
use Google::Monitoring::V3::Alert;
use Google::Monitoring::V3::UptimeService;
use Google::Monitoring::V3::ServiceService;
use Google::Monitoring::V3::SnoozeService;
use Google::Monitoring::V3::MetricService;
use Google::Monitoring::V3::NotificationService;
use Google::Monitoring::V3::AlertService;
use Google::Monitoring::V3::QueryService;

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

    my $target = 'monitoring.googleapis.com:443';
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

sub query_time_series {
    my ($self, %params) = @_;

    my $request_class = 'Google::Monitoring::V3::MetricService::QueryTimeSeriesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.monitoring.v3.QueryService/QueryTimeSeries',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.monitoring.v3.QueryService',
        method         => 'QueryTimeSeries',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Monitoring::V3::QueryServiceClient

__END__

=head1 NAME

Google::Cloud::Monitoring::V3::QueryServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Monitoring::V3::QueryServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Monitoring::V3::QueryServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Monitoring::V3::QueryServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Monitoring::V3::QueryServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/monitoring/v3/alert.proto>

=item * C<googleapis/google/monitoring/v3/alert_service.proto>

=item * C<googleapis/google/monitoring/v3/common.proto>

=item * C<googleapis/google/monitoring/v3/dropped_labels.proto>

=item * C<googleapis/google/monitoring/v3/group.proto>

=item * C<googleapis/google/monitoring/v3/group_service.proto>

=item * C<googleapis/google/monitoring/v3/metric.proto>

=item * C<googleapis/google/monitoring/v3/metric_service.proto>

=item * C<googleapis/google/monitoring/v3/mutation_record.proto>

=item * C<googleapis/google/monitoring/v3/notification.proto>

=item * C<googleapis/google/monitoring/v3/notification_service.proto>

=item * C<googleapis/google/monitoring/v3/query_service.proto>

=item * C<googleapis/google/monitoring/v3/service.proto>

=item * C<googleapis/google/monitoring/v3/service_service.proto>

=item * C<googleapis/google/monitoring/v3/snooze.proto>

=item * C<googleapis/google/monitoring/v3/snooze_service.proto>

=item * C<googleapis/google/monitoring/v3/span_context.proto>

=item * C<googleapis/google/monitoring/v3/uptime.proto>

=item * C<googleapis/google/monitoring/v3/uptime_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Monitoring::V3::QueryServiceClient->new(
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

=item * B<query_time_series>

    my $response = $client->query_time_series(
        name                     => $name,
        query                    => $query,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<QueryTimeSeries> on C<google.monitoring.v3.QueryService>.

Request: L<Google::Monitoring::V3::MetricService::QueryTimeSeriesRequest>

Returns: L<Google::Monitoring::V3::MetricService::QueryTimeSeriesResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<query> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
