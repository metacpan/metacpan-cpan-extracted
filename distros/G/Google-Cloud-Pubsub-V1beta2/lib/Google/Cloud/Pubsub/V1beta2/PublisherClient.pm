package Google::Cloud::Pubsub::V1beta2::PublisherClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Pubsub::V1beta2::Pubsub;

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

    my $target = 'pubsub/v1beta2.googleapis.com:443';
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

sub create_topic {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::Topic';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Pubsub::V1beta2::Pubsub::Topic';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.pubsub.v1beta2.Publisher/CreateTopic',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'CreateTopic',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub publish {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::PublishRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Pubsub::V1beta2::Pubsub::PublishResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.pubsub.v1beta2.Publisher/Publish',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'Publish',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_topic {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::GetTopicRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Pubsub::V1beta2::Pubsub::Topic';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.pubsub.v1beta2.Publisher/GetTopic',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'GetTopic',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_topics {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::ListTopicsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.pubsub.v1beta2.Publisher/ListTopics',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'ListTopics',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_topic_subscriptions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.pubsub.v1beta2.Publisher/ListTopicSubscriptions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'ListTopicSubscriptions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_topic {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::DeleteTopicRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Protobuf::Empty::Empty';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.pubsub.v1beta2.Publisher/DeleteTopic',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Publisher',
        method         => 'DeleteTopic',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Pubsub::V1beta2::PublisherClient

__END__

=head1 NAME

Google::Cloud::Pubsub::V1beta2::PublisherClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Pubsub::V1beta2::PublisherClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Pubsub::V1beta2::PublisherClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Pubsub::V1beta2::PublisherClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Pubsub::V1beta2::PublisherClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/pubsub/v1beta2/pubsub.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Pubsub::V1beta2::PublisherClient->new(
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

=item * B<create_topic>

    my $response = $client->create_topic(
        name                     => $name,
    );

Calls the RPC method C<CreateTopic> on C<google.pubsub.v1beta2.Publisher>.

Request: L<Google::Pubsub::V1beta2::Pubsub::Topic>

Returns: L<Google::Pubsub::V1beta2::Pubsub::Topic>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<publish>

    my $response = $client->publish(
        topic                    => $topic,
        messages                 => [ ... ],
    );

Calls the RPC method C<Publish> on C<google.pubsub.v1beta2.Publisher>.

Request: L<Google::Pubsub::V1beta2::Pubsub::PublishRequest>

Returns: L<Google::Pubsub::V1beta2::Pubsub::PublishResponse>

Parameters:

=over 4

=item * C<topic> - C<string>

=item * C<messages> - ArrayRef of L<Google::Pubsub::V1beta2::Pubsub::PubsubMessage>

=back

=item * B<get_topic>

    my $response = $client->get_topic(
        topic                    => $topic,
    );

Calls the RPC method C<GetTopic> on C<google.pubsub.v1beta2.Publisher>.

Request: L<Google::Pubsub::V1beta2::Pubsub::GetTopicRequest>

Returns: L<Google::Pubsub::V1beta2::Pubsub::Topic>

Parameters:

=over 4

=item * C<topic> - C<string>

=back

=item * B<list_topics>

    my $response = $client->list_topics(
        project                  => $project,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListTopics> on C<google.pubsub.v1beta2.Publisher>.

Request: L<Google::Pubsub::V1beta2::Pubsub::ListTopicsRequest>

Returns: L<Google::Pubsub::V1beta2::Pubsub::ListTopicsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_topic_subscriptions>

    my $response = $client->list_topic_subscriptions(
        topic                    => $topic,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListTopicSubscriptions> on C<google.pubsub.v1beta2.Publisher>.

Request: L<Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsRequest>

Returns: L<Google::Pubsub::V1beta2::Pubsub::ListTopicSubscriptionsResponse>

Parameters:

=over 4

=item * C<topic> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<delete_topic>

    my $response = $client->delete_topic(
        topic                    => $topic,
    );

Calls the RPC method C<DeleteTopic> on C<google.pubsub.v1beta2.Publisher>.

Request: L<Google::Pubsub::V1beta2::Pubsub::DeleteTopicRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<topic> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
