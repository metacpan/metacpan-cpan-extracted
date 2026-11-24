package Google::Ai::Generativelanguage::V1beta3::DiscussServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1beta3::Citation;
use Google::Ai::Generativelanguage::V1beta3::Safety;
use Google::Ai::Generativelanguage::V1beta3::Permission;
use Google::Ai::Generativelanguage::V1beta3::Model;
use Google::Ai::Generativelanguage::V1beta3::TunedModel;
use Google::Ai::Generativelanguage::V1beta3::DiscussService;
use Google::Ai::Generativelanguage::V1beta3::TextService;
use Google::Ai::Generativelanguage::V1beta3::PermissionService;
use Google::Ai::Generativelanguage::V1beta3::ModelService;

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

    my $target = 'generativelanguage.googleapis.com:443';
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

sub generate_message {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.DiscussService/GenerateMessage',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.DiscussService',
        method         => 'GenerateMessage',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_message_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.ai.generativelanguage.v1beta3.DiscussService/CountMessageTokens',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1beta3.DiscussService',
        method         => 'CountMessageTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1beta3::DiscussServiceClient

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1beta3::DiscussServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1beta3::DiscussServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Ai::Generativelanguage::V1beta3::DiscussServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Ai::Generativelanguage::V1beta3::DiscussServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Ai::Generativelanguage::V1beta3::DiscussServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/ai/generativelanguage/v1beta3/citation.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/discuss_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/model.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/model_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/permission.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/permission_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/safety.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/text_service.proto>

=item * C<googleapis/google/ai/generativelanguage/v1beta3/tuned_model.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Ai::Generativelanguage::V1beta3::DiscussServiceClient->new(
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

=item * B<generate_message>

    my $response = $client->generate_message(
        model                    => $model,
        prompt                   => $prompt,
        temperature              => $temperature,
        candidate_count          => $candidate_count,
        top_p                    => $top_p,
        top_k                    => $top_k,
    );

Calls the RPC method C<GenerateMessage> on C<google.ai.generativelanguage.v1beta3.DiscussService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::DiscussService::GenerateMessageResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta3::DiscussService::MessagePrompt>

=item * C<temperature> - C<float>

=item * C<candidate_count> - C<int32>

=item * C<top_p> - C<float>

=item * C<top_k> - C<int32>

=back

=item * B<count_message_tokens>

    my $response = $client->count_message_tokens(
        model                    => $model,
        prompt                   => $prompt,
    );

Calls the RPC method C<CountMessageTokens> on C<google.ai.generativelanguage.v1beta3.DiscussService>.

Request: L<Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensRequest>

Returns: L<Google::Ai::Generativelanguage::V1beta3::DiscussService::CountMessageTokensResponse>

Parameters:

=over 4

=item * C<model> - C<string>

=item * C<prompt> - L<Google::Ai::Generativelanguage::V1beta3::DiscussService::MessagePrompt>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
