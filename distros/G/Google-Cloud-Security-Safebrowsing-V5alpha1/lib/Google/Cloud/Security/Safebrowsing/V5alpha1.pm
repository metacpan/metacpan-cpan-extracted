package Google::Cloud::Security::Safebrowsing::V5alpha1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Security::Safebrowsing::V5alpha1::Safebrowsing;

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

    my $target = 'safebrowsing.googleapis.com:443';
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

sub search_hashes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::SearchHashesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::SearchHashesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.security.safebrowsing.v5alpha1.SafeBrowsing/SearchHashes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.security.safebrowsing.v5alpha1.SafeBrowsing',
        method         => 'SearchHashes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_hash_list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::GetHashListRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::HashList';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.security.safebrowsing.v5alpha1.SafeBrowsing/GetHashList',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.security.safebrowsing.v5alpha1.SafeBrowsing',
        method         => 'GetHashList',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_hash_lists {
    my ($self, %params) = @_;

    my $request_class = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::ListHashListsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::ListHashListsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.security.safebrowsing.v5alpha1.SafeBrowsing/ListHashLists',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.security.safebrowsing.v5alpha1.SafeBrowsing',
        method         => 'ListHashLists',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub batch_get_hash_lists {
    my ($self, %params) = @_;

    my $request_class = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::BatchGetHashListsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Security::Safebrowsing::V5alpha1::Safebrowsing::BatchGetHashListsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.security.safebrowsing.v5alpha1.SafeBrowsing/BatchGetHashLists',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.security.safebrowsing.v5alpha1.SafeBrowsing',
        method         => 'BatchGetHashLists',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Security::Safebrowsing::V5alpha1

__END__

=head1 NAME

Google::Cloud::Security::Safebrowsing::V5alpha1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Security::Safebrowsing::V5alpha1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Security::Safebrowsing::V5alpha1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Security::Safebrowsing::V5alpha1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Security::Safebrowsing::V5alpha1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/security/safebrowsing/v5alpha1/safebrowsing.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Security::Safebrowsing::V5alpha1->new(
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

=item * B<search_hashes>

    my $response = $client->search_hashes(
        hash_prefixes            => [ ... ],
        filter                   => $filter,
    );

Calls the RPC method C<SearchHashes> on C<google.security.safebrowsing.v5alpha1.SafeBrowsing>.

Request: L<Google::Security::Safebrowsing::V5alpha1::Safebrowsing::SearchHashesRequest>

Returns: L<Google::Security::Safebrowsing::V5alpha1::Safebrowsing::SearchHashesResponse>

Parameters:

=over 4

=item * C<hash_prefixes> - ArrayRef of C<bytes>

=item * C<filter> - C<string>

=back

=item * B<get_hash_list>

    my $response = $client->get_hash_list(
        name                     => $name,
        version                  => $version,
        size_constraints         => $size_constraints,
    );

Calls the RPC method C<GetHashList> on C<google.security.safebrowsing.v5alpha1.SafeBrowsing>.

Request: L<Google::Security::Safebrowsing::V5alpha1::Safebrowsing::GetHashListRequest>

Returns: L<Google::Security::Safebrowsing::V5alpha1::Safebrowsing::HashList>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<version> - C<bytes>

=item * C<size_constraints> - L<Google::Security::Safebrowsing::V5alpha1::Safebrowsing::SizeConstraints>

=back

=item * B<list_hash_lists>

    my $response = $client->list_hash_lists(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListHashLists> on C<google.security.safebrowsing.v5alpha1.SafeBrowsing>.

Request: L<Google::Security::Safebrowsing::V5alpha1::Safebrowsing::ListHashListsRequest>

Returns: L<Google::Security::Safebrowsing::V5alpha1::Safebrowsing::ListHashListsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<batch_get_hash_lists>

    my $response = $client->batch_get_hash_lists(
        names                    => [ ... ],
        version                  => [ ... ],
        size_constraints         => $size_constraints,
    );

Calls the RPC method C<BatchGetHashLists> on C<google.security.safebrowsing.v5alpha1.SafeBrowsing>.

Request: L<Google::Security::Safebrowsing::V5alpha1::Safebrowsing::BatchGetHashListsRequest>

Returns: L<Google::Security::Safebrowsing::V5alpha1::Safebrowsing::BatchGetHashListsResponse>

Parameters:

=over 4

=item * C<names> - ArrayRef of C<string>

=item * C<version> - ArrayRef of C<bytes>

=item * C<size_constraints> - L<Google::Security::Safebrowsing::V5alpha1::Safebrowsing::SizeConstraints>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
