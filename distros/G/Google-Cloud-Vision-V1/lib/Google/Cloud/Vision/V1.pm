package Google::Cloud::Vision::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Vision::V1::WebDetection;
use Google::Cloud::Vision::V1::Geometry;
use Google::Cloud::Vision::V1::TextAnnotation;
use Google::Cloud::Vision::V1::ProductSearchService;
use Google::Cloud::Vision::V1::ProductSearch;
use Google::Cloud::Vision::V1::ImageAnnotator;

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

    my $target = 'vision.googleapis.com:443';
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

sub batch_annotate_images {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.vision.v1.ImageAnnotator/BatchAnnotateImages',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.vision.v1.ImageAnnotator',
        method         => 'BatchAnnotateImages',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_product_set {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Vision::V1::ProductSearchService::CreateProductSetRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Vision::V1::ProductSearchService::ProductSet';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.vision.v1.ProductSearch/CreateProductSet',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.vision.v1.ProductSearch',
        method         => 'CreateProductSet',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Vision::V1

__END__

=head1 NAME

Google::Cloud::Vision::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Vision::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Vision::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Vision::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Vision::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/vision/v1/geometry.proto>

=item * C<googleapis/google/cloud/vision/v1/image_annotator.proto>

=item * C<googleapis/google/cloud/vision/v1/product_search.proto>

=item * C<googleapis/google/cloud/vision/v1/product_search_service.proto>

=item * C<googleapis/google/cloud/vision/v1/text_annotation.proto>

=item * C<googleapis/google/cloud/vision/v1/web_detection.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Vision::V1->new(
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

=item * B<batch_annotate_images>

    my $response = $client->batch_annotate_images(
        requests                 => [ ... ],
        parent                   => $parent,
        labels                   => { ... },
    );

Calls the RPC method C<BatchAnnotateImages> on C<google.cloud.vision.v1.ImageAnnotator>.

Request: L<Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesRequest>

Returns: L<Google::Cloud::Vision::V1::ImageAnnotator::BatchAnnotateImagesResponse>

Parameters:

=over 4

=item * C<requests> - ArrayRef of L<Google::Cloud::Vision::V1::ImageAnnotator::AnnotateImageRequest>

=item * C<parent> - C<string>

=item * C<labels> - C<map<string, string>> (HashRef)

=back

=item * B<create_product_set>

    my $response = $client->create_product_set(
        parent                   => $parent,
        product_set              => $product_set,
        product_set_id           => $product_set_id,
    );

Calls the RPC method C<CreateProductSet> on C<google.cloud.vision.v1.ProductSearch>.

Request: L<Google::Cloud::Vision::V1::ProductSearchService::CreateProductSetRequest>

Returns: L<Google::Cloud::Vision::V1::ProductSearchService::ProductSet>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<product_set> - L<Google::Cloud::Vision::V1::ProductSearchService::ProductSet>

=item * C<product_set_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
