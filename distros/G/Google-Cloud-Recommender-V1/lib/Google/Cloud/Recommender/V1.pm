package Google::Cloud::Recommender::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Recommender::V1::Recommendation;
use Google::Cloud::Recommender::V1::InsightTypeConfig;
use Google::Cloud::Recommender::V1::Insight;
use Google::Cloud::Recommender::V1::RecommenderConfig;
use Google::Cloud::Recommender::V1::RecommenderService;

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

    my $target = 'recommender.googleapis.com:443';
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

sub list_insights {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Recommender::V1::RecommenderService::ListInsightsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Recommender::V1::RecommenderService::ListInsightsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.recommender.v1.Recommender/ListInsights',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.recommender.v1.Recommender',
        method         => 'ListInsights',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_recommender_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Recommender::V1::RecommenderService::UpdateRecommenderConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.recommender.v1.Recommender/UpdateRecommenderConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.recommender.v1.Recommender',
        method         => 'UpdateRecommenderConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_insight_type_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Recommender::V1::RecommenderService::UpdateInsightTypeConfigRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.recommender.v1.Recommender/UpdateInsightTypeConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.recommender.v1.Recommender',
        method         => 'UpdateInsightTypeConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Recommender::V1

__END__

=head1 NAME

Google::Cloud::Recommender::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Recommender::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Recommender::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Recommender::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Recommender::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/recommender/v1/insight.proto>

=item * C<googleapis/google/cloud/recommender/v1/insight_type_config.proto>

=item * C<googleapis/google/cloud/recommender/v1/recommendation.proto>

=item * C<googleapis/google/cloud/recommender/v1/recommender_config.proto>

=item * C<googleapis/google/cloud/recommender/v1/recommender_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Recommender::V1->new(
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

=item * B<list_insights>

    my $response = $client->list_insights(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListInsights> on C<google.cloud.recommender.v1.Recommender>.

Request: L<Google::Cloud::Recommender::V1::RecommenderService::ListInsightsRequest>

Returns: L<Google::Cloud::Recommender::V1::RecommenderService::ListInsightsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<update_recommender_config>

    my $response = $client->update_recommender_config(
        recommender_config       => $recommender_config,
        update_mask              => $update_mask,
        validate_only            => $validate_only,
    );

Calls the RPC method C<UpdateRecommenderConfig> on C<google.cloud.recommender.v1.Recommender>.

Request: L<Google::Cloud::Recommender::V1::RecommenderService::UpdateRecommenderConfigRequest>

Returns: L<Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig>

Parameters:

=over 4

=item * C<recommender_config> - L<Google::Cloud::Recommender::V1::RecommenderConfig::RecommenderConfig>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<validate_only> - C<bool>

=back

=item * B<update_insight_type_config>

    my $response = $client->update_insight_type_config(
        insight_type_config      => $insight_type_config,
        update_mask              => $update_mask,
        validate_only            => $validate_only,
    );

Calls the RPC method C<UpdateInsightTypeConfig> on C<google.cloud.recommender.v1.Recommender>.

Request: L<Google::Cloud::Recommender::V1::RecommenderService::UpdateInsightTypeConfigRequest>

Returns: L<Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig>

Parameters:

=over 4

=item * C<insight_type_config> - L<Google::Cloud::Recommender::V1::InsightTypeConfig::InsightTypeConfig>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<validate_only> - C<bool>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
