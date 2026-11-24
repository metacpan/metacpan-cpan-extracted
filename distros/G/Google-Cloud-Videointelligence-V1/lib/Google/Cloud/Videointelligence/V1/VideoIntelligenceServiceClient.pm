package Google::Cloud::Videointelligence::V1::VideoIntelligenceServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Videointelligence::V1::VideoIntelligence;

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

    my $target = 'videointelligence.googleapis.com:443';
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

sub annotate_video {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoRequest';
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
            path           => '/google.cloud.videointelligence.v1.VideoIntelligenceService/AnnotateVideo',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.videointelligence.v1.VideoIntelligenceService',
        method         => 'AnnotateVideo',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Videointelligence::V1::VideoIntelligenceServiceClient

__END__

=head1 NAME

Google::Cloud::Videointelligence::V1::VideoIntelligenceServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Videointelligence::V1::VideoIntelligenceServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Videointelligence::V1::VideoIntelligenceServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Videointelligence::V1::VideoIntelligenceServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Videointelligence::V1::VideoIntelligenceServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/videointelligence/v1/video_intelligence.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Videointelligence::V1::VideoIntelligenceServiceClient->new(
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

=item * B<annotate_video>

    my $response = $client->annotate_video(
        input_uri                => $input_uri,
        input_content            => $input_content,
        features                 => [ ... ],
        video_context            => $video_context,
        output_uri               => $output_uri,
        location_id              => $location_id,
    );

Calls the RPC method C<AnnotateVideo> on C<google.cloud.videointelligence.v1.VideoIntelligenceService>.

Request: L<Google::Cloud::Videointelligence::V1::VideoIntelligence::AnnotateVideoRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<input_uri> - C<string>

=item * C<input_content> - C<bytes>

=item * C<features> - ArrayRef of L<Google::Cloud::Videointelligence::V1::VideoIntelligence::Feature>

=item * C<video_context> - L<Google::Cloud::Videointelligence::V1::VideoIntelligence::VideoContext>

=item * C<output_uri> - C<string>

=item * C<location_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
