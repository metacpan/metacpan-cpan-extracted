package Google::Cloud::Automl::V1beta1::PredictionServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Automl::V1beta1::DataTypes;
use Google::Cloud::Automl::V1beta1::Io;
use Google::Cloud::Automl::V1beta1::Geometry;
use Google::Cloud::Automl::V1beta1::TextSegment;
use Google::Cloud::Automl::V1beta1::Regression;
use Google::Cloud::Automl::V1beta1::DataStats;
use Google::Cloud::Automl::V1beta1::Ranges;
use Google::Cloud::Automl::V1beta1::Temporal;
use Google::Cloud::Automl::V1beta1::Detection;
use Google::Cloud::Automl::V1beta1::TextExtraction;
use Google::Cloud::Automl::V1beta1::AnnotationSpec;
use Google::Cloud::Automl::V1beta1::TableSpec;
use Google::Cloud::Automl::V1beta1::ColumnSpec;
use Google::Cloud::Automl::V1beta1::DataItems;
use Google::Cloud::Automl::V1beta1::Classification;
use Google::Cloud::Automl::V1beta1::Translation;
use Google::Cloud::Automl::V1beta1::TextSentiment;
use Google::Cloud::Automl::V1beta1::Text;
use Google::Cloud::Automl::V1beta1::Image;
use Google::Cloud::Automl::V1beta1::Video;
use Google::Cloud::Automl::V1beta1::Tables;
use Google::Cloud::Automl::V1beta1::AnnotationPayload;
use Google::Cloud::Automl::V1beta1::Model;
use Google::Cloud::Automl::V1beta1::ModelEvaluation;
use Google::Cloud::Automl::V1beta1::Dataset;
use Google::Cloud::Automl::V1beta1::Operations;
use Google::Cloud::Automl::V1beta1::Service;
use Google::Cloud::Automl::V1beta1::PredictionService;

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

    my $target = 'automl.googleapis.com:443';
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

sub predict {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Automl::V1beta1::PredictionService::PredictRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Automl::V1beta1::PredictionService::PredictResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.automl.v1beta1.PredictionService/Predict',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.automl.v1beta1.PredictionService',
        method         => 'Predict',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Automl::V1beta1::PredictionServiceClient

__END__

=head1 NAME

Google::Cloud::Automl::V1beta1::PredictionServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::PredictionServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Automl::V1beta1::PredictionServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Automl::V1beta1::PredictionServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Automl::V1beta1::PredictionServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/automl/v1beta1/annotation_payload.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/annotation_spec.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/classification.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/column_spec.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/data_items.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/data_stats.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/data_types.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/dataset.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/detection.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/geometry.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/image.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/io.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/model.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/model_evaluation.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/operations.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/prediction_service.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/ranges.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/regression.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/service.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/table_spec.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/tables.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/temporal.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/text.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/text_extraction.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/text_segment.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/text_sentiment.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/translation.proto>

=item * C<googleapis/google/cloud/automl/v1beta1/video.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Automl::V1beta1::PredictionServiceClient->new(
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

=item * B<predict>

    my $response = $client->predict(
        name                     => $name,
        payload                  => $payload,
        params                   => { ... },
    );

Calls the RPC method C<Predict> on C<google.cloud.automl.v1beta1.PredictionService>.

Request: L<Google::Cloud::Automl::V1beta1::PredictionService::PredictRequest>

Returns: L<Google::Cloud::Automl::V1beta1::PredictionService::PredictResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<payload> - L<Google::Cloud::Automl::V1beta1::DataItems::ExamplePayload>

=item * C<params> - C<map<string, string>> (HashRef)

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
