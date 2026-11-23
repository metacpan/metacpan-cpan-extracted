package Google::Cloud::Build::V1::CloudBuildClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Devtools::Cloudbuild::V1::Cloudbuild;

our $VERSION = '0.05';

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

    my $target = 'cloudbuild.googleapis.com:443';
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

sub create_build {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateBuildRequest';
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
            path           => '/google.devtools.cloudbuild.v1.CloudBuild/CreateBuild',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.cloudbuild.v1.CloudBuild',
        method         => 'CreateBuild',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_build {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.devtools.cloudbuild.v1.CloudBuild/GetBuild',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.cloudbuild.v1.CloudBuild',
        method         => 'GetBuild',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub cancel_build {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::CancelBuildRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::Build';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.devtools.cloudbuild.v1.CloudBuild/CancelBuild',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.cloudbuild.v1.CloudBuild',
        method         => 'CancelBuild',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_build_trigger {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildTriggerRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.devtools.cloudbuild.v1.CloudBuild/GetBuildTrigger',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.cloudbuild.v1.CloudBuild',
        method         => 'GetBuildTrigger',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub delete_build_trigger {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteBuildTriggerRequest';
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
            path           => '/google.devtools.cloudbuild.v1.CloudBuild/DeleteBuildTrigger',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.cloudbuild.v1.CloudBuild',
        method         => 'DeleteBuildTrigger',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_worker_pool {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetWorkerPoolRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.devtools.cloudbuild.v1.CloudBuild/GetWorkerPool',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.cloudbuild.v1.CloudBuild',
        method         => 'GetWorkerPool',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_default_service_account {
    my ($self, %params) = @_;

    my $request_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::GetDefaultServiceAccountRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Devtools::Cloudbuild::V1::Cloudbuild::DefaultServiceAccount';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.devtools.cloudbuild.v1.CloudBuild/GetDefaultServiceAccount',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.devtools.cloudbuild.v1.CloudBuild',
        method         => 'GetDefaultServiceAccount',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Build::V1::CloudBuildClient

__END__

=head1 NAME

Google::Cloud::Build::V1::CloudBuildClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Build::V1::CloudBuildClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Build::V1::CloudBuildClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Build::V1::CloudBuildClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Build::V1::CloudBuildClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/devtools/cloudbuild/v1/cloudbuild.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Build::V1::CloudBuildClient->new(
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

=item * B<create_build>

Calls the RPC method C<CreateBuild> on the service. Takes a hash of parameters representing the request.

=item * B<get_build>

Calls the RPC method C<GetBuild> on the service. Takes a hash of parameters representing the request.

=item * B<cancel_build>

Calls the RPC method C<CancelBuild> on the service. Takes a hash of parameters representing the request.

=item * B<get_build_trigger>

Calls the RPC method C<GetBuildTrigger> on the service. Takes a hash of parameters representing the request.

=item * B<delete_build_trigger>

Calls the RPC method C<DeleteBuildTrigger> on the service. Takes a hash of parameters representing the request.

=item * B<get_worker_pool>

Calls the RPC method C<GetWorkerPool> on the service. Takes a hash of parameters representing the request.

=item * B<get_default_service_account>

Calls the RPC method C<GetDefaultServiceAccount> on the service. Takes a hash of parameters representing the request.

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
