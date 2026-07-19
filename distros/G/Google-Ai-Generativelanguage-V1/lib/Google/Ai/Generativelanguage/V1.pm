package Google::Ai::Generativelanguage::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1::GenerativeService;

our $VERSION = '0.02';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    # Resolve credentials: use passed credentials object if it implements get_token, or default to ADC
    my $auth = $self->credentials;
    if (!$auth || !eval { $auth->can('get_token') }) {
        $auth = Google::Auth->default();
    }
    my $token = $auth->get_token();

    my $target = 'generativelanguage.googleapis.com';
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
        # Default high-performance HTTP/2 gRPC client
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}

sub generate_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::GenerateContentResponse';
    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.GenerativeService',
        method         => 'GenerateContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub embed_content {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::EmbedContentResponse';
    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.GenerativeService',
        method         => 'EmbedContent',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_embed_contents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::BatchEmbedContentsResponse';
    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.GenerativeService',
        method         => 'BatchEmbedContents',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub count_tokens {
    my ($self, %params) = @_;

    my $request_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensRequest';
    my $request = eval { $request_class->new(\%params) } || eval { $request_class->new(%params) } || ($request_class->can('encode') ? $request_class->encode(\%params) : \%params);

    my $response_class = 'Google::Ai::Generativelanguage::V1::GenerativeService::CountTokensResponse';
    my $response = $self->transport->call({
        service        => 'google.ai.generativelanguage.v1.GenerativeService',
        method         => 'CountTokens',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Ai::Generativelanguage::V1

__END__

=head1 NAME

Google::Ai::Generativelanguage::V1 - Auto-generated client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1;
    use Google::Auth;

    # Initialize Application Default Credentials (ADC) or explicit Google Auth
    my $auth = Google::Auth->default();
    my $client = Google::Ai::Generativelanguage::V1->new( credentials => $auth );

    # Execute service methods
    my $res = $client->some_method( %params );

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers client library for Google Cloud Services, built on top of high-performance gRPC and Protocol Buffers!

It provides seamless integration with Google Cloud Application Default Credentials (ADC), support for both HTTP/2 gRPC and REST transports, and fully typed RPC method dispatching.

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Ai::Generativelanguage::V1->new(
        credentials => $auth,       # Optional: Google::Auth object (defaults to ADC)
        transport   => 'grpc',     # Optional: 'grpc' (default) or 'rest'
    );

=head1 METHODS

The following RPC methods are available in this client:

=over 4

=head2 METHODS

The following RPC methods are available in this client:

=over 4

=item * B<generate_content>

Calls the RPC method C<GenerateContent> on the service. Takes a hash of parameters representing the request.

=item * B<embed_content>

Calls the RPC method C<EmbedContent> on the service. Takes a hash of parameters representing the request.

=item * B<batch_embed_contents>

Calls the RPC method C<BatchEmbedContents> on the service. Takes a hash of parameters representing the request.

=item * B<count_tokens>

Calls the RPC method C<CountTokens> on the service. Takes a hash of parameters representing the request.

=back



=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
