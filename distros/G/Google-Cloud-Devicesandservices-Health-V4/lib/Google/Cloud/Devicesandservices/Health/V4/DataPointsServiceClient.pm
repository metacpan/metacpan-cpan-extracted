package Google::Cloud::Devicesandservices::Health::V4::DataPointsServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Devicesandservices::Health::V4::DataSource;
use Google::Devicesandservices::Health::V4::MedicalDeviceInfo;
use Google::Devicesandservices::Health::V4::WebhookNotificationCloudLog;
use Google::Devicesandservices::Health::V4::HealthProfile;
use Google::Devicesandservices::Health::V4::DataCoordinates;
use Google::Devicesandservices::Health::V4::DataSubscriptionService;
use Google::Devicesandservices::Health::V4::DataModel;
use Google::Devicesandservices::Health::V4::DataPoints;

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

    my $target = 'health.googleapis.com:443';
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

sub get_data_point {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devicesandservices::Health::V4::DataPoints::GetDataPointRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Devicesandservices::Health::V4::DataPoints::DataPoint';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.devicesandservices.health.v4.DataPointsService/GetDataPoint',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devicesandservices.health.v4.DataPointsService',
        method         => 'GetDataPoint',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Devicesandservices::Health::V4::DataPointsServiceClient

__END__

=head1 NAME

Google::Cloud::Devicesandservices::Health::V4::DataPointsServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Devicesandservices::Health::V4::DataPointsServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Devicesandservices::Health::V4::DataPointsServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Devicesandservices::Health::V4::DataPointsServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Devicesandservices::Health::V4::DataPointsServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/devicesandservices/health/v4/data_coordinates.proto>

=item * C<googleapis/google/devicesandservices/health/v4/data_model.proto>

=item * C<googleapis/google/devicesandservices/health/v4/data_points.proto>

=item * C<googleapis/google/devicesandservices/health/v4/data_source.proto>

=item * C<googleapis/google/devicesandservices/health/v4/data_subscription_service.proto>

=item * C<googleapis/google/devicesandservices/health/v4/health_profile.proto>

=item * C<googleapis/google/devicesandservices/health/v4/medical_device_info.proto>

=item * C<googleapis/google/devicesandservices/health/v4/webhook_notification_cloud_log.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Devicesandservices::Health::V4::DataPointsServiceClient->new(
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

=item * B<get_data_point>

    my $response = $client->get_data_point(
        name                     => $name,
    );

Calls the RPC method C<GetDataPoint> on C<google.devicesandservices.health.v4.DataPointsService>.

Request: L<Google::Devicesandservices::Health::V4::DataPoints::GetDataPointRequest>

Returns: L<Google::Devicesandservices::Health::V4::DataPoints::DataPoint>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
