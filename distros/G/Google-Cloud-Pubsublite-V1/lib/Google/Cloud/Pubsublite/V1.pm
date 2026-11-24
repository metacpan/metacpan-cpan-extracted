package Google::Cloud::Pubsublite::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Pubsublite::V1::Common;
use Google::Cloud::Pubsublite::V1::TopicStats;
use Google::Cloud::Pubsublite::V1::Publisher;
use Google::Cloud::Pubsublite::V1::Cursor;
use Google::Cloud::Pubsublite::V1::Subscriber;
use Google::Cloud::Pubsublite::V1::Admin;

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

    my $target = 'pubsublite.googleapis.com:443';
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

    my $request_class = 'Google::Cloud::Pubsublite::V1::Admin::CreateTopicRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Pubsublite::V1::Common::Topic';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.pubsublite.v1.AdminService/CreateTopic',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.pubsublite.v1.AdminService',
        method         => 'CreateTopic',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub streaming_commit_cursor {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.pubsublite.v1.CursorService/StreamingCommitCursor',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.pubsublite.v1.CursorService',
        method         => 'StreamingCommitCursor',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub commit_cursor {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Pubsublite::V1::Cursor::CommitCursorRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Pubsublite::V1::Cursor::CommitCursorResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.pubsublite.v1.CursorService/CommitCursor',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.pubsublite.v1.CursorService',
        method         => 'CommitCursor',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub publish {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Pubsublite::V1::Publisher::PublishRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Pubsublite::V1::Publisher::PublishResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.pubsublite.v1.PublisherService/Publish',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.pubsublite.v1.PublisherService',
        method         => 'Publish',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub subscribe {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Pubsublite::V1::Subscriber::SubscribeRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Pubsublite::V1::Subscriber::SubscribeResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.pubsublite.v1.SubscriberService/Subscribe',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.pubsublite.v1.SubscriberService',
        method         => 'Subscribe',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub assign_partitions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignment';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.pubsublite.v1.PartitionAssignmentService/AssignPartitions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.pubsublite.v1.PartitionAssignmentService',
        method         => 'AssignPartitions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub compute_message_stats {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.pubsublite.v1.TopicStatsService/ComputeMessageStats',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.pubsublite.v1.TopicStatsService',
        method         => 'ComputeMessageStats',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Pubsublite::V1

__END__

=head1 NAME

Google::Cloud::Pubsublite::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Pubsublite::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Pubsublite::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Pubsublite::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Pubsublite::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/pubsublite/v1/admin.proto>

=item * C<googleapis/google/cloud/pubsublite/v1/common.proto>

=item * C<googleapis/google/cloud/pubsublite/v1/cursor.proto>

=item * C<googleapis/google/cloud/pubsublite/v1/publisher.proto>

=item * C<googleapis/google/cloud/pubsublite/v1/subscriber.proto>

=item * C<googleapis/google/cloud/pubsublite/v1/topic_stats.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Pubsublite::V1->new(
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
        parent                   => $parent,
        topic                    => $topic,
        topic_id                 => $topic_id,
    );

Calls the RPC method C<CreateTopic> on C<google.cloud.pubsublite.v1.AdminService>.

Request: L<Google::Cloud::Pubsublite::V1::Admin::CreateTopicRequest>

Returns: L<Google::Cloud::Pubsublite::V1::Common::Topic>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<topic> - L<Google::Cloud::Pubsublite::V1::Common::Topic>

=item * C<topic_id> - C<string>

=back

=item * B<streaming_commit_cursor>

    my $response = $client->streaming_commit_cursor();

Calls the RPC method C<StreamingCommitCursor> on C<google.cloud.pubsublite.v1.CursorService>.

Request: L<Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorRequest>

Returns: L<Google::Cloud::Pubsublite::V1::Cursor::StreamingCommitCursorResponse>

=item * B<commit_cursor>

    my $response = $client->commit_cursor(
        subscription             => $subscription,
        partition                => $partition,
        cursor                   => $cursor,
    );

Calls the RPC method C<CommitCursor> on C<google.cloud.pubsublite.v1.CursorService>.

Request: L<Google::Cloud::Pubsublite::V1::Cursor::CommitCursorRequest>

Returns: L<Google::Cloud::Pubsublite::V1::Cursor::CommitCursorResponse>

Parameters:

=over 4

=item * C<subscription> - C<string>

=item * C<partition> - C<int64>

=item * C<cursor> - L<Google::Cloud::Pubsublite::V1::Common::Cursor>

=back

=item * B<publish>

    my $response = $client->publish();

Calls the RPC method C<Publish> on C<google.cloud.pubsublite.v1.PublisherService>.

Request: L<Google::Cloud::Pubsublite::V1::Publisher::PublishRequest>

Returns: L<Google::Cloud::Pubsublite::V1::Publisher::PublishResponse>

=item * B<subscribe>

    my $response = $client->subscribe();

Calls the RPC method C<Subscribe> on C<google.cloud.pubsublite.v1.SubscriberService>.

Request: L<Google::Cloud::Pubsublite::V1::Subscriber::SubscribeRequest>

Returns: L<Google::Cloud::Pubsublite::V1::Subscriber::SubscribeResponse>

=item * B<assign_partitions>

    my $response = $client->assign_partitions();

Calls the RPC method C<AssignPartitions> on C<google.cloud.pubsublite.v1.PartitionAssignmentService>.

Request: L<Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignmentRequest>

Returns: L<Google::Cloud::Pubsublite::V1::Subscriber::PartitionAssignment>

=item * B<compute_message_stats>

    my $response = $client->compute_message_stats(
        topic                    => $topic,
        partition                => $partition,
        start_cursor             => $start_cursor,
        end_cursor               => $end_cursor,
    );

Calls the RPC method C<ComputeMessageStats> on C<google.cloud.pubsublite.v1.TopicStatsService>.

Request: L<Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsRequest>

Returns: L<Google::Cloud::Pubsublite::V1::TopicStats::ComputeMessageStatsResponse>

Parameters:

=over 4

=item * C<topic> - C<string>

=item * C<partition> - C<int64>

=item * C<start_cursor> - L<Google::Cloud::Pubsublite::V1::Common::Cursor>

=item * C<end_cursor> - L<Google::Cloud::Pubsublite::V1::Common::Cursor>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
