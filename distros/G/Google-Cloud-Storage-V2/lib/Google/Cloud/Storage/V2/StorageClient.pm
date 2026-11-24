package Google::Cloud::Storage::V2::StorageClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Storage::V2::Storage;

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

    my $target = 'storage.googleapis.com:443';
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

sub delete_bucket {
    my ($self, %params) = @_;

    my $request_class = 'Google::Storage::V2::Storage::DeleteBucketRequest';
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
            path           => '/google.storage.v2.Storage/DeleteBucket',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.storage.v2.Storage',
        method         => 'DeleteBucket',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_bucket {
    my ($self, %params) = @_;

    my $request_class = 'Google::Storage::V2::Storage::GetBucketRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Storage::V2::Storage::Bucket';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.storage.v2.Storage/GetBucket',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.storage.v2.Storage',
        method         => 'GetBucket',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_bucket {
    my ($self, %params) = @_;

    my $request_class = 'Google::Storage::V2::Storage::CreateBucketRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Storage::V2::Storage::Bucket';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.storage.v2.Storage/CreateBucket',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.storage.v2.Storage',
        method         => 'CreateBucket',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_buckets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Storage::V2::Storage::ListBucketsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Storage::V2::Storage::ListBucketsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.storage.v2.Storage/ListBuckets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.storage.v2.Storage',
        method         => 'ListBuckets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub lock_bucket_retention_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Storage::V2::Storage::LockBucketRetentionPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Storage::V2::Storage::Bucket';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.storage.v2.Storage/LockBucketRetentionPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.storage.v2.Storage',
        method         => 'LockBucketRetentionPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_iam_policy {
    my ($self, %params) = @_;

    my $request_class = 'Google::Iam::V1::IamPolicy::GetIamPolicyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Iam::V1::Policy::Policy';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.storage.v2.Storage/GetIamPolicy',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.storage.v2.Storage',
        method         => 'GetIamPolicy',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub move_object {
    my ($self, %params) = @_;

    my $request_class = 'Google::Storage::V2::Storage::MoveObjectRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Storage::V2::Storage::Object';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.storage.v2.Storage/MoveObject',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.storage.v2.Storage',
        method         => 'MoveObject',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Storage::V2::StorageClient

__END__

=head1 NAME

Google::Cloud::Storage::V2::StorageClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Storage::V2::StorageClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Storage::V2::StorageClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Storage::V2::StorageClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Storage::V2::StorageClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/storage/v2/storage.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Storage::V2::StorageClient->new(
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

=item * B<delete_bucket>

    my $response = $client->delete_bucket(
        name                     => $name,
        if_metageneration_match  => $if_metageneration_match,
        if_metageneration_not_match => $if_metageneration_not_match,
    );

Calls the RPC method C<DeleteBucket> on C<google.storage.v2.Storage>.

Request: L<Google::Storage::V2::Storage::DeleteBucketRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<if_metageneration_match> - C<int64>

=item * C<if_metageneration_not_match> - C<int64>

=back

=item * B<get_bucket>

    my $response = $client->get_bucket(
        name                     => $name,
        if_metageneration_match  => $if_metageneration_match,
        if_metageneration_not_match => $if_metageneration_not_match,
        read_mask                => $read_mask,
    );

Calls the RPC method C<GetBucket> on C<google.storage.v2.Storage>.

Request: L<Google::Storage::V2::Storage::GetBucketRequest>

Returns: L<Google::Storage::V2::Storage::Bucket>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<if_metageneration_match> - C<int64>

=item * C<if_metageneration_not_match> - C<int64>

=item * C<read_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<create_bucket>

    my $response = $client->create_bucket(
        parent                   => $parent,
        bucket                   => $bucket,
        bucket_id                => $bucket_id,
        predefined_acl           => $predefined_acl,
        predefined_default_object_acl => $predefined_default_object_acl,
        enable_object_retention  => $enable_object_retention,
    );

Calls the RPC method C<CreateBucket> on C<google.storage.v2.Storage>.

Request: L<Google::Storage::V2::Storage::CreateBucketRequest>

Returns: L<Google::Storage::V2::Storage::Bucket>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<bucket> - L<Google::Storage::V2::Storage::Bucket>

=item * C<bucket_id> - C<string>

=item * C<predefined_acl> - C<string>

=item * C<predefined_default_object_acl> - C<string>

=item * C<enable_object_retention> - C<bool>

=back

=item * B<list_buckets>

    my $response = $client->list_buckets(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        prefix                   => $prefix,
        read_mask                => $read_mask,
        return_partial_success   => $return_partial_success,
    );

Calls the RPC method C<ListBuckets> on C<google.storage.v2.Storage>.

Request: L<Google::Storage::V2::Storage::ListBucketsRequest>

Returns: L<Google::Storage::V2::Storage::ListBucketsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<prefix> - C<string>

=item * C<read_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<return_partial_success> - C<bool>

=back

=item * B<lock_bucket_retention_policy>

    my $response = $client->lock_bucket_retention_policy(
        bucket                   => $bucket,
        if_metageneration_match  => $if_metageneration_match,
    );

Calls the RPC method C<LockBucketRetentionPolicy> on C<google.storage.v2.Storage>.

Request: L<Google::Storage::V2::Storage::LockBucketRetentionPolicyRequest>

Returns: L<Google::Storage::V2::Storage::Bucket>

Parameters:

=over 4

=item * C<bucket> - C<string>

=item * C<if_metageneration_match> - C<int64>

=back

=item * B<get_iam_policy>

    my $response = $client->get_iam_policy();

Calls the RPC method C<GetIamPolicy> on C<google.storage.v2.Storage>.

Request: L<Google::Iam::V1::IamPolicy::GetIamPolicyRequest>

Returns: L<Google::Iam::V1::Policy::Policy>

=item * B<move_object>

    my $response = $client->move_object(
        bucket                   => $bucket,
        source_object            => $source_object,
        destination_object       => $destination_object,
        if_source_generation_match => $if_source_generation_match,
        if_source_generation_not_match => $if_source_generation_not_match,
        if_source_metageneration_match => $if_source_metageneration_match,
        if_source_metageneration_not_match => $if_source_metageneration_not_match,
        if_generation_match      => $if_generation_match,
        if_generation_not_match  => $if_generation_not_match,
        if_metageneration_match  => $if_metageneration_match,
        if_metageneration_not_match => $if_metageneration_not_match,
    );

Calls the RPC method C<MoveObject> on C<google.storage.v2.Storage>.

Request: L<Google::Storage::V2::Storage::MoveObjectRequest>

Returns: L<Google::Storage::V2::Storage::Object>

Parameters:

=over 4

=item * C<bucket> - C<string>

=item * C<source_object> - C<string>

=item * C<destination_object> - C<string>

=item * C<if_source_generation_match> - C<int64>

=item * C<if_source_generation_not_match> - C<int64>

=item * C<if_source_metageneration_match> - C<int64>

=item * C<if_source_metageneration_not_match> - C<int64>

=item * C<if_generation_match> - C<int64>

=item * C<if_generation_not_match> - C<int64>

=item * C<if_metageneration_match> - C<int64>

=item * C<if_metageneration_not_match> - C<int64>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
