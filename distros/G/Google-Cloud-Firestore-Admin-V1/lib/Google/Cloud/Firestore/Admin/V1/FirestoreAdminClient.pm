package Google::Cloud::Firestore::Admin::V1::FirestoreAdminClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Firestore::Admin::V1::Location;
use Google::Firestore::Admin::V1::RealtimeUpdates;
use Google::Firestore::Admin::V1::Index;
use Google::Firestore::Admin::V1::Schedule;
use Google::Firestore::Admin::V1::Snapshot;
use Google::Firestore::Admin::V1::Database;
use Google::Firestore::Admin::V1::UserCreds;
use Google::Firestore::Admin::V1::Backup;
use Google::Firestore::Admin::V1::Field;
use Google::Firestore::Admin::V1::Operation;
use Google::Firestore::Admin::V1::FirestoreAdmin;

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

    my $target = 'firestore.googleapis.com:443';
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

sub create_index {
    my ($self, %params) = @_;

    my $request_class = 'Google::Firestore::Admin::V1::FirestoreAdmin::CreateIndexRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Longrunning::Operations::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.firestore.admin.v1.FirestoreAdmin/CreateIndex',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.firestore.admin.v1.FirestoreAdmin',
        method         => 'CreateIndex',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Firestore::Admin::V1::FirestoreAdminClient

__END__

=head1 NAME

Google::Cloud::Firestore::Admin::V1::FirestoreAdminClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Firestore::Admin::V1::FirestoreAdminClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Firestore::Admin::V1::FirestoreAdminClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Firestore::Admin::V1::FirestoreAdminClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Firestore::Admin::V1::FirestoreAdminClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/firestore/admin/v1/backup.proto>

=item * C<googleapis/google/firestore/admin/v1/database.proto>

=item * C<googleapis/google/firestore/admin/v1/field.proto>

=item * C<googleapis/google/firestore/admin/v1/firestore_admin.proto>

=item * C<googleapis/google/firestore/admin/v1/index.proto>

=item * C<googleapis/google/firestore/admin/v1/location.proto>

=item * C<googleapis/google/firestore/admin/v1/operation.proto>

=item * C<googleapis/google/firestore/admin/v1/realtime_updates.proto>

=item * C<googleapis/google/firestore/admin/v1/schedule.proto>

=item * C<googleapis/google/firestore/admin/v1/snapshot.proto>

=item * C<googleapis/google/firestore/admin/v1/user_creds.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Firestore::Admin::V1::FirestoreAdminClient->new(
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

=item * B<create_index>

    my $response = $client->create_index(
        parent                   => $parent,
        index                    => $index,
    );

Calls the RPC method C<CreateIndex> on C<google.firestore.admin.v1.FirestoreAdmin>.

Request: L<Google::Firestore::Admin::V1::FirestoreAdmin::CreateIndexRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<index> - L<Google::Firestore::Admin::V1::Index::Index>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
