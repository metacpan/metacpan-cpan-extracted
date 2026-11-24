package Google::Cloud::Pubsub::V1beta2::SubscriberClient;

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

sub create_subscription {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::Subscription';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Pubsub::V1beta2::Pubsub::Subscription';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.pubsub.v1beta2.Subscriber/CreateSubscription',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'CreateSubscription',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_subscription {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::GetSubscriptionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Pubsub::V1beta2::Pubsub::Subscription';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.pubsub.v1beta2.Subscriber/GetSubscription',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'GetSubscription',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_subscriptions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.pubsub.v1beta2.Subscriber/ListSubscriptions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'ListSubscriptions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_subscription {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::DeleteSubscriptionRequest';
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
            path           => '/google.pubsub.v1beta2.Subscriber/DeleteSubscription',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'DeleteSubscription',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub modify_ack_deadline {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::ModifyAckDeadlineRequest';
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
            path           => '/google.pubsub.v1beta2.Subscriber/ModifyAckDeadline',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'ModifyAckDeadline',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub acknowledge {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::AcknowledgeRequest';
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
            path           => '/google.pubsub.v1beta2.Subscriber/Acknowledge',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'Acknowledge',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub pull {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::PullRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Pubsub::V1beta2::Pubsub::PullResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.pubsub.v1beta2.Subscriber/Pull',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'Pull',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub modify_push_config {
    my ($self, %params) = @_;

    my $request_class = 'Google::Pubsub::V1beta2::Pubsub::ModifyPushConfigRequest';
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
            path           => '/google.pubsub.v1beta2.Subscriber/ModifyPushConfig',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.pubsub.v1beta2.Subscriber',
        method         => 'ModifyPushConfig',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Pubsub::V1beta2::SubscriberClient

__END__

=head1 NAME

Google::Cloud::Pubsub::V1beta2::SubscriberClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Pubsub::V1beta2::SubscriberClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Pubsub::V1beta2::SubscriberClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Pubsub::V1beta2::SubscriberClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Pubsub::V1beta2::SubscriberClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/pubsub/v1beta2/pubsub.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Pubsub::V1beta2::SubscriberClient->new(
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

=item * B<create_subscription>

    my $response = $client->create_subscription(
        name                     => $name,
        topic                    => $topic,
        push_config              => $push_config,
        ack_deadline_seconds     => $ack_deadline_seconds,
    );

Calls the RPC method C<CreateSubscription> on C<google.pubsub.v1beta2.Subscriber>.

Request: L<Google::Pubsub::V1beta2::Pubsub::Subscription>

Returns: L<Google::Pubsub::V1beta2::Pubsub::Subscription>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<topic> - C<string>

=item * C<push_config> - L<Google::Pubsub::V1beta2::Pubsub::PushConfig>

=item * C<ack_deadline_seconds> - C<int32>

=back

=item * B<get_subscription>

    my $response = $client->get_subscription(
        subscription             => $subscription,
    );

Calls the RPC method C<GetSubscription> on C<google.pubsub.v1beta2.Subscriber>.

Request: L<Google::Pubsub::V1beta2::Pubsub::GetSubscriptionRequest>

Returns: L<Google::Pubsub::V1beta2::Pubsub::Subscription>

Parameters:

=over 4

=item * C<subscription> - C<string>

=back

=item * B<list_subscriptions>

    my $response = $client->list_subscriptions(
        project                  => $project,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListSubscriptions> on C<google.pubsub.v1beta2.Subscriber>.

Request: L<Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsRequest>

Returns: L<Google::Pubsub::V1beta2::Pubsub::ListSubscriptionsResponse>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<delete_subscription>

    my $response = $client->delete_subscription(
        subscription             => $subscription,
    );

Calls the RPC method C<DeleteSubscription> on C<google.pubsub.v1beta2.Subscriber>.

Request: L<Google::Pubsub::V1beta2::Pubsub::DeleteSubscriptionRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<subscription> - C<string>

=back

=item * B<modify_ack_deadline>

    my $response = $client->modify_ack_deadline(
        subscription             => $subscription,
        ack_id                   => $ack_id,
        ack_deadline_seconds     => $ack_deadline_seconds,
    );

Calls the RPC method C<ModifyAckDeadline> on C<google.pubsub.v1beta2.Subscriber>.

Request: L<Google::Pubsub::V1beta2::Pubsub::ModifyAckDeadlineRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<subscription> - C<string>

=item * C<ack_id> - C<string>

=item * C<ack_deadline_seconds> - C<int32>

=back

=item * B<acknowledge>

    my $response = $client->acknowledge(
        subscription             => $subscription,
        ack_ids                  => [ ... ],
    );

Calls the RPC method C<Acknowledge> on C<google.pubsub.v1beta2.Subscriber>.

Request: L<Google::Pubsub::V1beta2::Pubsub::AcknowledgeRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<subscription> - C<string>

=item * C<ack_ids> - ArrayRef of C<string>

=back

=item * B<pull>

    my $response = $client->pull(
        subscription             => $subscription,
        return_immediately       => $return_immediately,
        max_messages             => $max_messages,
    );

Calls the RPC method C<Pull> on C<google.pubsub.v1beta2.Subscriber>.

Request: L<Google::Pubsub::V1beta2::Pubsub::PullRequest>

Returns: L<Google::Pubsub::V1beta2::Pubsub::PullResponse>

Parameters:

=over 4

=item * C<subscription> - C<string>

=item * C<return_immediately> - C<bool>

=item * C<max_messages> - C<int32>

=back

=item * B<modify_push_config>

    my $response = $client->modify_push_config(
        subscription             => $subscription,
        push_config              => $push_config,
    );

Calls the RPC method C<ModifyPushConfig> on C<google.pubsub.v1beta2.Subscriber>.

Request: L<Google::Pubsub::V1beta2::Pubsub::ModifyPushConfigRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<subscription> - C<string>

=item * C<push_config> - L<Google::Pubsub::V1beta2::Pubsub::PushConfig>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
