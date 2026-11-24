package Google::Cloud::Spanner::Auth::V1::UsersServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Spanner::Auth::V1::Authentication;
use Google::Spanner::Auth::V1::SpannerUsers;

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

    my $target = 'spanner.googleapis.com:443';
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

sub create_user {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Auth::V1::SpannerUsers::CreateUserRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.auth.v1.UsersService/CreateUser',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'CreateUser',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_user {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Auth::V1::SpannerUsers::UpdateUserRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Auth::V1::SpannerUsers::User';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.auth.v1.UsersService/UpdateUser',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'UpdateUser',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_user {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Auth::V1::SpannerUsers::GetUserRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Auth::V1::SpannerUsers::User';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.auth.v1.UsersService/GetUser',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'GetUser',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_users {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Auth::V1::SpannerUsers::ListUsersRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.auth.v1.UsersService/ListUsers',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'ListUsers',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_user {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Auth::V1::SpannerUsers::DeleteUserRequest';
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
            path           => '/google.spanner.auth.v1.UsersService/DeleteUser',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'DeleteUser',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_roles {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Auth::V1::SpannerUsers::ListRolesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.auth.v1.UsersService/ListRoles',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'ListRoles',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_role {
    my ($self, %params) = @_;

    my $request_class = 'Google::Spanner::Auth::V1::SpannerUsers::GetRoleRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Spanner::Auth::V1::SpannerUsers::Role';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.spanner.auth.v1.UsersService/GetRole',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.spanner.auth.v1.UsersService',
        method         => 'GetRole',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Spanner::Auth::V1::UsersServiceClient

__END__

=head1 NAME

Google::Cloud::Spanner::Auth::V1::UsersServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Spanner::Auth::V1::UsersServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Spanner::Auth::V1::UsersServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Spanner::Auth::V1::UsersServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Spanner::Auth::V1::UsersServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/spanner/auth/v1/authentication.proto>

=item * C<googleapis/google/spanner/auth/v1/spanner_users.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Spanner::Auth::V1::UsersServiceClient->new(
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

=item * B<create_user>

    my $response = $client->create_user(
        user                     => $user,
    );

Calls the RPC method C<CreateUser> on C<google.spanner.auth.v1.UsersService>.

Request: L<Google::Spanner::Auth::V1::SpannerUsers::CreateUserRequest>

Returns: L<Google::Spanner::Auth::V1::SpannerUsers::CreateUserResponse>

Parameters:

=over 4

=item * C<user> - L<Google::Spanner::Auth::V1::SpannerUsers::User>

=back

=item * B<update_user>

    my $response = $client->update_user(
        user                     => $user,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateUser> on C<google.spanner.auth.v1.UsersService>.

Request: L<Google::Spanner::Auth::V1::SpannerUsers::UpdateUserRequest>

Returns: L<Google::Spanner::Auth::V1::SpannerUsers::User>

Parameters:

=over 4

=item * C<user> - L<Google::Spanner::Auth::V1::SpannerUsers::User>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=item * B<get_user>

    my $response = $client->get_user(
        name                     => $name,
    );

Calls the RPC method C<GetUser> on C<google.spanner.auth.v1.UsersService>.

Request: L<Google::Spanner::Auth::V1::SpannerUsers::GetUserRequest>

Returns: L<Google::Spanner::Auth::V1::SpannerUsers::User>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_users>

    my $response = $client->list_users(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListUsers> on C<google.spanner.auth.v1.UsersService>.

Request: L<Google::Spanner::Auth::V1::SpannerUsers::ListUsersRequest>

Returns: L<Google::Spanner::Auth::V1::SpannerUsers::ListUsersResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<delete_user>

    my $response = $client->delete_user(
        name                     => $name,
    );

Calls the RPC method C<DeleteUser> on C<google.spanner.auth.v1.UsersService>.

Request: L<Google::Spanner::Auth::V1::SpannerUsers::DeleteUserRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_roles>

    my $response = $client->list_roles(
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListRoles> on C<google.spanner.auth.v1.UsersService>.

Request: L<Google::Spanner::Auth::V1::SpannerUsers::ListRolesRequest>

Returns: L<Google::Spanner::Auth::V1::SpannerUsers::ListRolesResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<get_role>

    my $response = $client->get_role(
        name                     => $name,
    );

Calls the RPC method C<GetRole> on C<google.spanner.auth.v1.UsersService>.

Request: L<Google::Spanner::Auth::V1::SpannerUsers::GetRoleRequest>

Returns: L<Google::Spanner::Auth::V1::SpannerUsers::Role>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
