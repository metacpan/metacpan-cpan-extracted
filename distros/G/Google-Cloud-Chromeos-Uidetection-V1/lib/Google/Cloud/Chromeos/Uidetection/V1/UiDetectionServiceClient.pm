package Google::Cloud::Chromeos::Uidetection::V1::UiDetectionServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Chromeos::Uidetection::V1::UiDetection;

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

    my $target = 'chromeosuidetection.googleapis.com:443';
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

sub execute_detection {
    my ($self, %params) = @_;

    my $request_class = 'Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.chromeos.uidetection.v1.UiDetectionService/ExecuteDetection',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.chromeos.uidetection.v1.UiDetectionService',
        method         => 'ExecuteDetection',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Chromeos::Uidetection::V1::UiDetectionServiceClient

__END__

=head1 NAME

Google::Cloud::Chromeos::Uidetection::V1::UiDetectionServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Chromeos::Uidetection::V1::UiDetectionServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Chromeos::Uidetection::V1::UiDetectionServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Chromeos::Uidetection::V1::UiDetectionServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Chromeos::Uidetection::V1::UiDetectionServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/chromeos/uidetection/v1/ui_detection.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Chromeos::Uidetection::V1::UiDetectionServiceClient->new(
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

=item * B<execute_detection>

    my $response = $client->execute_detection(
        image_png                => $image_png,
        request                  => $request,
        resize_image             => $resize_image,
        test_id                  => $test_id,
        test_metadata            => $test_metadata,
        force_image_resizing     => $force_image_resizing,
        return_transformed_image => $return_transformed_image,
    );

Calls the RPC method C<ExecuteDetection> on C<google.chromeos.uidetection.v1.UiDetectionService>.

Request: L<Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionRequest>

Returns: L<Google::Chromeos::Uidetection::V1::UiDetection::UiDetectionResponse>

Parameters:

=over 4

=item * C<image_png> - C<bytes>

=item * C<request> - L<Google::Chromeos::Uidetection::V1::UiDetection::DetectionRequest>

=item * C<resize_image> - C<bool>

=item * C<test_id> - C<string>

=item * C<test_metadata> - L<Google::Chromeos::Uidetection::V1::UiDetection::TestMetadata>

=item * C<force_image_resizing> - C<bool>

=item * C<return_transformed_image> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
