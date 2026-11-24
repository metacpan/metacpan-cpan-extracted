package Google::Cloud::Support::V2;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Support::V2::Escalation;
use Google::Cloud::Support::V2::SupportEventSubscription;
use Google::Cloud::Support::V2::Actor;
use Google::Cloud::Support::V2::SupportEventSubscriptionService;
use Google::Cloud::Support::V2::Comment;
use Google::Cloud::Support::V2::Case;
use Google::Cloud::Support::V2::Attachment;
use Google::Cloud::Support::V2::CommentService;
use Google::Cloud::Support::V2::CaseService;
use Google::Cloud::Support::V2::AttachmentService;

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

    my $request_class = 'Google::Cloud::Support::V2::AttachmentService::ListAttachmentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2::AttachmentService::ListAttachmentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2.CaseAttachmentService/ListAttachments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2.CaseAttachmentService',
        method         => 'ListAttachments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_case {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Support::V2::CaseService::GetCaseRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2::Case::Case';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2.CaseService/GetCase',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2.CaseService',
        method         => 'GetCase',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_case_classifications {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Support::V2::CaseService::SearchCaseClassificationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2::CaseService::SearchCaseClassificationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2.CaseService/SearchCaseClassifications',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2.CaseService',
        method         => 'SearchCaseClassifications',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_comments {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Support::V2::CommentService::ListCommentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2::CommentService::ListCommentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2.CommentService/ListComments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2.CommentService',
        method         => 'ListComments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_support_event_subscription {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Support::V2::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.support.v2.SupportEventSubscriptionService/CreateSupportEventSubscription',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.support.v2.SupportEventSubscriptionService',
        method         => 'CreateSupportEventSubscription',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Support::V2

__END__

=head1 NAME

Google::Cloud::Support::V2 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Support::V2;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Support::V2->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Support::V2->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Support::V2> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/support/v2/actor.proto>

=item * C<googleapis/google/cloud/support/v2/attachment.proto>

=item * C<googleapis/google/cloud/support/v2/attachment_service.proto>

=item * C<googleapis/google/cloud/support/v2/case.proto>

=item * C<googleapis/google/cloud/support/v2/case_service.proto>

=item * C<googleapis/google/cloud/support/v2/comment.proto>

=item * C<googleapis/google/cloud/support/v2/comment_service.proto>

=item * C<googleapis/google/cloud/support/v2/escalation.proto>

=item * C<googleapis/google/cloud/support/v2/support_event_subscription.proto>

=item * C<googleapis/google/cloud/support/v2/support_event_subscription_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Support::V2->new(
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

Calls the RPC method C<ListAttachments> on C<google.cloud.support.v2.CaseAttachmentService>.

Request: L<Google::Cloud::Support::V2::AttachmentService::ListAttachmentsRequest>

Returns: L<Google::Cloud::Support::V2::AttachmentService::ListAttachmentsResponse>

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

Calls the RPC method C<GetCase> on C<google.cloud.support.v2.CaseService>.

Request: L<Google::Cloud::Support::V2::CaseService::GetCaseRequest>

Returns: L<Google::Cloud::Support::V2::Case::Case>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<search_case_classifications>

    my $response = $client->search_case_classifications(
        query                    => $query,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<SearchCaseClassifications> on C<google.cloud.support.v2.CaseService>.

Request: L<Google::Cloud::Support::V2::CaseService::SearchCaseClassificationsRequest>

Returns: L<Google::Cloud::Support::V2::CaseService::SearchCaseClassificationsResponse>

Parameters:

=over 4

=item * C<query> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<list_comments>

    my $response = $client->list_comments(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListComments> on C<google.cloud.support.v2.CommentService>.

Request: L<Google::Cloud::Support::V2::CommentService::ListCommentsRequest>

Returns: L<Google::Cloud::Support::V2::CommentService::ListCommentsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_support_event_subscription>

    my $response = $client->create_support_event_subscription(
        parent                   => $parent,
        support_event_subscription => $support_event_subscription,
    );

Calls the RPC method C<CreateSupportEventSubscription> on C<google.cloud.support.v2.SupportEventSubscriptionService>.

Request: L<Google::Cloud::Support::V2::SupportEventSubscriptionService::CreateSupportEventSubscriptionRequest>

Returns: L<Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<support_event_subscription> - L<Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
