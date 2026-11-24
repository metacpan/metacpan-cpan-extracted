package Google::Cloud::Support::V2beta;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Support::V2beta::Content;
use Google::Cloud::Support::V2beta::Escalation;
use Google::Cloud::Support::V2beta::Actor;
use Google::Cloud::Support::V2beta::SupportEventSubscription;
use Google::Cloud::Support::V2beta::EmailMessage;
use Google::Cloud::Support::V2beta::Case;
use Google::Cloud::Support::V2beta::Attachment;
use Google::Cloud::Support::V2beta::Comment;
use Google::Cloud::Support::V2beta::SupportEventSubscriptionService;
use Google::Cloud::Support::V2beta::CaseService;
use Google::Cloud::Support::V2beta::AttachmentService;
use Google::Cloud::Support::V2beta::CommentService;
use Google::Cloud::Support::V2beta::FeedItem;
use Google::Cloud::Support::V2beta::FeedService;

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

    my $target = 'cloudsupport.googleapis.com:443';
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

sub list_attachments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2beta.CaseAttachmentService/ListAttachments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2beta.CaseAttachmentService',
        method         => 'ListAttachments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_case {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Support::V2beta::CaseService::GetCaseRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2beta::Case::Case';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2beta.CaseService/GetCase',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2beta.CaseService',
        method         => 'GetCase',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_case_classifications {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2beta.CaseService/SearchCaseClassifications',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2beta.CaseService',
        method         => 'SearchCaseClassifications',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_comments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Support::V2beta::CommentService::ListCommentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2beta::CommentService::ListCommentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2beta.CommentService/ListComments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2beta.CommentService',
        method         => 'ListComments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub show_feed {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Support::V2beta::FeedService::ShowFeedRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2beta::FeedService::ShowFeedResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2beta.FeedService/ShowFeed',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2beta.FeedService',
        method         => 'ShowFeed',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_support_event_subscription {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Support::V2beta::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2beta.SupportEventSubscriptionService/CreateSupportEventSubscription',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2beta.SupportEventSubscriptionService',
        method         => 'CreateSupportEventSubscription',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Support::V2beta

__END__

=head1 NAME

Google::Cloud::Support::V2beta - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Support::V2beta->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Support::V2beta->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Support::V2beta> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/support/v2beta/actor.proto>

=item * C<googleapis/google/cloud/support/v2beta/attachment.proto>

=item * C<googleapis/google/cloud/support/v2beta/attachment_service.proto>

=item * C<googleapis/google/cloud/support/v2beta/case.proto>

=item * C<googleapis/google/cloud/support/v2beta/case_service.proto>

=item * C<googleapis/google/cloud/support/v2beta/comment.proto>

=item * C<googleapis/google/cloud/support/v2beta/comment_service.proto>

=item * C<googleapis/google/cloud/support/v2beta/content.proto>

=item * C<googleapis/google/cloud/support/v2beta/email_message.proto>

=item * C<googleapis/google/cloud/support/v2beta/escalation.proto>

=item * C<googleapis/google/cloud/support/v2beta/feed_item.proto>

=item * C<googleapis/google/cloud/support/v2beta/feed_service.proto>

=item * C<googleapis/google/cloud/support/v2beta/support_event_subscription.proto>

=item * C<googleapis/google/cloud/support/v2beta/support_event_subscription_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Support::V2beta->new(
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

=item * B<list_attachments>

    my $response = $client->list_attachments(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListAttachments> on C<google.cloud.support.v2beta.CaseAttachmentService>.

Request: L<Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsRequest>

Returns: L<Google::Cloud::Support::V2beta::AttachmentService::ListAttachmentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_case>

    my $response = $client->get_case(
        name                     => $name,
    );

Calls the RPC method C<GetCase> on C<google.cloud.support.v2beta.CaseService>.

Request: L<Google::Cloud::Support::V2beta::CaseService::GetCaseRequest>

Returns: L<Google::Cloud::Support::V2beta::Case::Case>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<search_case_classifications>

    my $response = $client->search_case_classifications(
        query                    => $query,
        page_size                => $page_size,
        page_token               => $page_token,
        product                  => $product,
    );

Calls the RPC method C<SearchCaseClassifications> on C<google.cloud.support.v2beta.CaseService>.

Request: L<Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsRequest>

Returns: L<Google::Cloud::Support::V2beta::CaseService::SearchCaseClassificationsResponse>

Parameters:

=over 4

=item * C<query> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<product> - L<Google::Cloud::Support::V2beta::Case::Product>

=back

=item * B<list_comments>

    my $response = $client->list_comments(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListComments> on C<google.cloud.support.v2beta.CommentService>.

Request: L<Google::Cloud::Support::V2beta::CommentService::ListCommentsRequest>

Returns: L<Google::Cloud::Support::V2beta::CommentService::ListCommentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<show_feed>

    my $response = $client->show_feed(
        parent                   => $parent,
        order_by                 => $order_by,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ShowFeed> on C<google.cloud.support.v2beta.FeedService>.

Request: L<Google::Cloud::Support::V2beta::FeedService::ShowFeedRequest>

Returns: L<Google::Cloud::Support::V2beta::FeedService::ShowFeedResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<order_by> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_support_event_subscription>

    my $response = $client->create_support_event_subscription(
        parent                   => $parent,
        support_event_subscription => $support_event_subscription,
    );

Calls the RPC method C<CreateSupportEventSubscription> on C<google.cloud.support.v2beta.SupportEventSubscriptionService>.

Request: L<Google::Cloud::Support::V2beta::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest>

Returns: L<Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<support_event_subscription> - L<Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
