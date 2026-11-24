package Google::Cloud::Compute::V1::RolloutsClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Compute::V1::Compute;

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

    my $target = 'compute/v1.googleapis.com:443';
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

sub advance {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::AdvanceRolloutRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Rollouts/Advance',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Rollouts',
        method         => 'Advance',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub cancel {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::CancelRolloutRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Rollouts/Cancel',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Rollouts',
        method         => 'Cancel',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::DeleteRolloutRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Rollouts/Delete',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Rollouts',
        method         => 'Delete',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::GetRolloutRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Rollout';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Rollouts/Get',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Rollouts',
        method         => 'Get',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ListRolloutsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::RolloutsListResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Rollouts/List',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Rollouts',
        method         => 'List',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub pause {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::PauseRolloutRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Rollouts/Pause',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Rollouts',
        method         => 'Pause',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub resume {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Compute::V1::Compute::ResumeRolloutRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Compute::V1::Compute::Operation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.compute.v1.Rollouts/Resume',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.compute.v1.Rollouts',
        method         => 'Resume',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Compute::V1::RolloutsClient

__END__

=head1 NAME

Google::Cloud::Compute::V1::RolloutsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Compute::V1::RolloutsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Compute::V1::RolloutsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Compute::V1::RolloutsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Compute::V1::RolloutsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/compute/v1/compute.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Compute::V1::RolloutsClient->new(
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

=item * B<advance>

    my $response = $client->advance(
        current_wave_number      => $current_wave_number,
        project                  => $project,
        request_id               => $request_id,
        rollout                  => $rollout,
    );

Calls the RPC method C<Advance> on C<google.cloud.compute.v1.Rollouts>.

Request: L<Google::Cloud::Compute::V1::Compute::AdvanceRolloutRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<current_wave_number> - C<int64>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<rollout> - C<string>

=back

=item * B<cancel>

    my $response = $client->cancel(
        project                  => $project,
        request_id               => $request_id,
        rollback                 => $rollback,
        rollout                  => $rollout,
    );

Calls the RPC method C<Cancel> on C<google.cloud.compute.v1.Rollouts>.

Request: L<Google::Cloud::Compute::V1::Compute::CancelRolloutRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<rollback> - C<bool>

=item * C<rollout> - C<string>

=back

=item * B<delete>

    my $response = $client->delete(
        project                  => $project,
        request_id               => $request_id,
        rollout                  => $rollout,
    );

Calls the RPC method C<Delete> on C<google.cloud.compute.v1.Rollouts>.

Request: L<Google::Cloud::Compute::V1::Compute::DeleteRolloutRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<rollout> - C<string>

=back

=item * B<get>

    my $response = $client->get(
        project                  => $project,
        rollout                  => $rollout,
    );

Calls the RPC method C<Get> on C<google.cloud.compute.v1.Rollouts>.

Request: L<Google::Cloud::Compute::V1::Compute::GetRolloutRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Rollout>

Parameters:

=over 4

=item * C<project> - C<string>

=item * C<rollout> - C<string>

=back

=item * B<list>

    my $response = $client->list(
        filter                   => $filter,
        max_results              => $max_results,
        order_by                 => $order_by,
        page_token               => $page_token,
        project                  => $project,
    );

Calls the RPC method C<List> on C<google.cloud.compute.v1.Rollouts>.

Request: L<Google::Cloud::Compute::V1::Compute::ListRolloutsRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::RolloutsListResponse>

Parameters:

=over 4

=item * C<filter> - C<string>

=item * C<max_results> - C<uint32>

=item * C<order_by> - C<string>

=item * C<page_token> - C<string>

=item * C<project> - C<string>

=back

=item * B<pause>

    my $response = $client->pause(
        etag                     => $etag,
        project                  => $project,
        request_id               => $request_id,
        rollout                  => $rollout,
    );

Calls the RPC method C<Pause> on C<google.cloud.compute.v1.Rollouts>.

Request: L<Google::Cloud::Compute::V1::Compute::PauseRolloutRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<etag> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<rollout> - C<string>

=back

=item * B<resume>

    my $response = $client->resume(
        etag                     => $etag,
        project                  => $project,
        request_id               => $request_id,
        rollout                  => $rollout,
    );

Calls the RPC method C<Resume> on C<google.cloud.compute.v1.Rollouts>.

Request: L<Google::Cloud::Compute::V1::Compute::ResumeRolloutRequest>

Returns: L<Google::Cloud::Compute::V1::Compute::Operation>

Parameters:

=over 4

=item * C<etag> - C<string>

=item * C<project> - C<string>

=item * C<request_id> - C<string>

=item * C<rollout> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
