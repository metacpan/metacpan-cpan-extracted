package Google::Cloud::Developers::Knowledge::V1::DeveloperKnowledgeClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Developers::Knowledge::V1::Developerknowledge;

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

    my $target = 'developerknowledge.googleapis.com:443';
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

sub search_document_chunks {
    my ($self, %params) = @_;

    my $request_class = 'Google::Developers::Knowledge::V1::Developerknowledge::SearchDocumentChunksRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Developers::Knowledge::V1::Developerknowledge::SearchDocumentChunksResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.developers.knowledge.v1.DeveloperKnowledge/SearchDocumentChunks',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.developers.knowledge.v1.DeveloperKnowledge',
        method         => 'SearchDocumentChunks',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_document {
    my ($self, %params) = @_;

    my $request_class = 'Google::Developers::Knowledge::V1::Developerknowledge::GetDocumentRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Developers::Knowledge::V1::Developerknowledge::Document';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.developers.knowledge.v1.DeveloperKnowledge/GetDocument',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.developers.knowledge.v1.DeveloperKnowledge',
        method         => 'GetDocument',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_get_documents {
    my ($self, %params) = @_;

    my $request_class = 'Google::Developers::Knowledge::V1::Developerknowledge::BatchGetDocumentsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Developers::Knowledge::V1::Developerknowledge::BatchGetDocumentsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.developers.knowledge.v1.DeveloperKnowledge/BatchGetDocuments',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.developers.knowledge.v1.DeveloperKnowledge',
        method         => 'BatchGetDocuments',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub answer_query {
    my ($self, %params) = @_;

    my $request_class = 'Google::Developers::Knowledge::V1::Developerknowledge::AnswerQueryRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Developers::Knowledge::V1::Developerknowledge::AnswerQueryResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.developers.knowledge.v1.DeveloperKnowledge/AnswerQuery',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.developers.knowledge.v1.DeveloperKnowledge',
        method         => 'AnswerQuery',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Developers::Knowledge::V1::DeveloperKnowledgeClient

__END__

=head1 NAME

Google::Cloud::Developers::Knowledge::V1::DeveloperKnowledgeClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Developers::Knowledge::V1::DeveloperKnowledgeClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Developers::Knowledge::V1::DeveloperKnowledgeClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Developers::Knowledge::V1::DeveloperKnowledgeClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Developers::Knowledge::V1::DeveloperKnowledgeClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/developers/knowledge/v1/developerknowledge.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Developers::Knowledge::V1::DeveloperKnowledgeClient->new(
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

=item * B<search_document_chunks>

    my $response = $client->search_document_chunks(
        query                    => $query,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<SearchDocumentChunks> on C<google.developers.knowledge.v1.DeveloperKnowledge>.

Request: L<Google::Developers::Knowledge::V1::Developerknowledge::SearchDocumentChunksRequest>

Returns: L<Google::Developers::Knowledge::V1::Developerknowledge::SearchDocumentChunksResponse>

Parameters:

=over 4

=item * C<query> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<get_document>

    my $response = $client->get_document(
        name                     => $name,
        view                     => $view,
    );

Calls the RPC method C<GetDocument> on C<google.developers.knowledge.v1.DeveloperKnowledge>.

Request: L<Google::Developers::Knowledge::V1::Developerknowledge::GetDocumentRequest>

Returns: L<Google::Developers::Knowledge::V1::Developerknowledge::Document>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<view> - L<Google::Developers::Knowledge::V1::Developerknowledge::DocumentView>

=back

=item * B<batch_get_documents>

    my $response = $client->batch_get_documents(
        names                    => [ ... ],
        view                     => $view,
    );

Calls the RPC method C<BatchGetDocuments> on C<google.developers.knowledge.v1.DeveloperKnowledge>.

Request: L<Google::Developers::Knowledge::V1::Developerknowledge::BatchGetDocumentsRequest>

Returns: L<Google::Developers::Knowledge::V1::Developerknowledge::BatchGetDocumentsResponse>

Parameters:

=over 4

=item * C<names> - ArrayRef of C<string>

=item * C<view> - L<Google::Developers::Knowledge::V1::Developerknowledge::DocumentView>

=back

=item * B<answer_query>

    my $response = $client->answer_query(
        query                    => $query,
        filter                   => $filter,
    );

Calls the RPC method C<AnswerQuery> on C<google.developers.knowledge.v1.DeveloperKnowledge>.

Request: L<Google::Developers::Knowledge::V1::Developerknowledge::AnswerQueryRequest>

Returns: L<Google::Developers::Knowledge::V1::Developerknowledge::AnswerQueryResponse>

Parameters:

=over 4

=item * C<query> - C<string>

=item * C<filter> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
