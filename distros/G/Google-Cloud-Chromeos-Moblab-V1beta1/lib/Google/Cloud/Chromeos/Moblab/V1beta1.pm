package Google::Cloud::Chromeos::Moblab::V1beta1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Chromeos::Moblab::V1beta1::Resources;
use Google::Chromeos::Moblab::V1beta1::BuildService;
use Google::Chromeos::Moblab::V1beta1::TestService;

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

    my $target = 'chromeosmoblab.googleapis.com:443';
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

sub list_build_targets {
    my ($self, %params) = @_;

    my $request_class = 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.chromeos.moblab.v1beta1.BuildService/ListBuildTargets',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.chromeos.moblab.v1beta1.BuildService',
        method         => 'ListBuildTargets',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_models {
    my ($self, %params) = @_;

    my $request_class = 'Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.chromeos.moblab.v1beta1.BuildService/ListModels',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.chromeos.moblab.v1beta1.BuildService',
        method         => 'ListModels',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_session {
    my ($self, %params) = @_;

    my $request_class = 'Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Chromeos::Moblab::V1beta1::Resources::Session';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.chromeos.moblab.v1beta1.TestService/CreateSession',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'CreateSession',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_session {
    my ($self, %params) = @_;

    my $request_class = 'Google::Chromeos::Moblab::V1beta1::TestService::GetSessionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Chromeos::Moblab::V1beta1::Resources::Session';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.chromeos.moblab.v1beta1.TestService/GetSession',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'GetSession',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_sessions {
    my ($self, %params) = @_;

    my $request_class = 'Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.chromeos.moblab.v1beta1.TestService/ListSessions',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'ListSessions',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_test_efforts {
    my ($self, %params) = @_;

    my $request_class = 'Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.chromeos.moblab.v1beta1.TestService/ListTestEfforts',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'ListTestEfforts',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub cancel_test_effort {
    my ($self, %params) = @_;

    my $request_class = 'Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.chromeos.moblab.v1beta1.TestService/CancelTestEffort',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'CancelTestEffort',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_test_effort {
    my ($self, %params) = @_;

    my $request_class = 'Google::Chromeos::Moblab::V1beta1::TestService::CreateTestEffortRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Chromeos::Moblab::V1beta1::Resources::TestEffort';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.chromeos.moblab.v1beta1.TestService/CreateTestEffort',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.chromeos.moblab.v1beta1.TestService',
        method         => 'CreateTestEffort',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Chromeos::Moblab::V1beta1

__END__

=head1 NAME

Google::Cloud::Chromeos::Moblab::V1beta1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Chromeos::Moblab::V1beta1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Chromeos::Moblab::V1beta1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Chromeos::Moblab::V1beta1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Chromeos::Moblab::V1beta1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/chromeos/moblab/v1beta1/build_service.proto>

=item * C<googleapis/google/chromeos/moblab/v1beta1/resources.proto>

=item * C<googleapis/google/chromeos/moblab/v1beta1/test_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Chromeos::Moblab::V1beta1->new(
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

=item * B<list_build_targets>

    my $response = $client->list_build_targets(
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListBuildTargets> on C<google.chromeos.moblab.v1beta1.BuildService>.

Request: L<Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsRequest>

Returns: L<Google::Chromeos::Moblab::V1beta1::BuildService::ListBuildTargetsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<list_models>

    my $response = $client->list_models(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListModels> on C<google.chromeos.moblab.v1beta1.BuildService>.

Request: L<Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsRequest>

Returns: L<Google::Chromeos::Moblab::V1beta1::BuildService::ListModelsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=item * B<create_session>

    my $response = $client->create_session(
        session                  => $session,
        session_id               => $session_id,
    );

Calls the RPC method C<CreateSession> on C<google.chromeos.moblab.v1beta1.TestService>.

Request: L<Google::Chromeos::Moblab::V1beta1::TestService::CreateSessionRequest>

Returns: L<Google::Chromeos::Moblab::V1beta1::Resources::Session>

Parameters:

=over 4

=item * C<session> - L<Google::Chromeos::Moblab::V1beta1::Resources::Session>

=item * C<session_id> - C<string>

=back

=item * B<get_session>

    my $response = $client->get_session(
        name                     => $name,
    );

Calls the RPC method C<GetSession> on C<google.chromeos.moblab.v1beta1.TestService>.

Request: L<Google::Chromeos::Moblab::V1beta1::TestService::GetSessionRequest>

Returns: L<Google::Chromeos::Moblab::V1beta1::Resources::Session>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<list_sessions>

    my $response = $client->list_sessions(
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListSessions> on C<google.chromeos.moblab.v1beta1.TestService>.

Request: L<Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsRequest>

Returns: L<Google::Chromeos::Moblab::V1beta1::TestService::ListSessionsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<list_test_efforts>

    my $response = $client->list_test_efforts(
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListTestEfforts> on C<google.chromeos.moblab.v1beta1.TestService>.

Request: L<Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsRequest>

Returns: L<Google::Chromeos::Moblab::V1beta1::TestService::ListTestEffortsResponse>

Parameters:

=over 4

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<cancel_test_effort>

    my $response = $client->cancel_test_effort(
        name                     => $name,
    );

Calls the RPC method C<CancelTestEffort> on C<google.chromeos.moblab.v1beta1.TestService>.

Request: L<Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortRequest>

Returns: L<Google::Chromeos::Moblab::V1beta1::TestService::CancelTestEffortResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<create_test_effort>

    my $response = $client->create_test_effort(
        test_effort              => $test_effort,
        test_effort_id           => $test_effort_id,
    );

Calls the RPC method C<CreateTestEffort> on C<google.chromeos.moblab.v1beta1.TestService>.

Request: L<Google::Chromeos::Moblab::V1beta1::TestService::CreateTestEffortRequest>

Returns: L<Google::Chromeos::Moblab::V1beta1::Resources::TestEffort>

Parameters:

=over 4

=item * C<test_effort> - L<Google::Chromeos::Moblab::V1beta1::Resources::TestEffort>

=item * C<test_effort_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
