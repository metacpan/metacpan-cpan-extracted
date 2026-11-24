package Google::Cloud::Devtools::Cloudbuild::V1;

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
1; # End of Google::Cloud::Devtools::Cloudbuild::V1

__END__

=head1 NAME

Google::Cloud::Devtools::Cloudbuild::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Devtools::Cloudbuild::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Devtools::Cloudbuild::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Devtools::Cloudbuild::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Devtools::Cloudbuild::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/devtools/cloudbuild/v1/cloudbuild.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Devtools::Cloudbuild::V1->new(
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

    my $response = $client->create_build(
        parent                   => $parent,
        project_id               => $project_id,
        build                    => $build,
    );

Calls the RPC method C<CreateBuild> on C<google.devtools.cloudbuild.v1.CloudBuild>.

Request: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::CreateBuildRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<project_id> - C<string>

=item * C<build> - L<Google::Devtools::Cloudbuild::V1::Cloudbuild::Build>

=back

=item * B<get_build>

    my $response = $client->get_build(
        name                     => $name,
        project_id               => $project_id,
        id                       => $id,
    );

Calls the RPC method C<GetBuild> on C<google.devtools.cloudbuild.v1.CloudBuild>.

Request: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildRequest>

Returns: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::Build>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<project_id> - C<string>

=item * C<id> - C<string>

=back

=item * B<cancel_build>

    my $response = $client->cancel_build(
        name                     => $name,
        project_id               => $project_id,
        id                       => $id,
    );

Calls the RPC method C<CancelBuild> on C<google.devtools.cloudbuild.v1.CloudBuild>.

Request: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::CancelBuildRequest>

Returns: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::Build>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<project_id> - C<string>

=item * C<id> - C<string>

=back

=item * B<get_build_trigger>

    my $response = $client->get_build_trigger(
        name                     => $name,
        project_id               => $project_id,
        trigger_id               => $trigger_id,
    );

Calls the RPC method C<GetBuildTrigger> on C<google.devtools.cloudbuild.v1.CloudBuild>.

Request: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::GetBuildTriggerRequest>

Returns: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::BuildTrigger>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<project_id> - C<string>

=item * C<trigger_id> - C<string>

=back

=item * B<delete_build_trigger>

    my $response = $client->delete_build_trigger(
        name                     => $name,
        project_id               => $project_id,
        trigger_id               => $trigger_id,
    );

Calls the RPC method C<DeleteBuildTrigger> on C<google.devtools.cloudbuild.v1.CloudBuild>.

Request: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::DeleteBuildTriggerRequest>

Returns: L<Google::Protobuf::Empty::Empty>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<project_id> - C<string>

=item * C<trigger_id> - C<string>

=back

=item * B<get_worker_pool>

    my $response = $client->get_worker_pool(
        name                     => $name,
    );

Calls the RPC method C<GetWorkerPool> on C<google.devtools.cloudbuild.v1.CloudBuild>.

Request: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::GetWorkerPoolRequest>

Returns: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::WorkerPool>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_default_service_account>

    my $response = $client->get_default_service_account(
        name                     => $name,
    );

Calls the RPC method C<GetDefaultServiceAccount> on C<google.devtools.cloudbuild.v1.CloudBuild>.

Request: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::GetDefaultServiceAccountRequest>

Returns: L<Google::Devtools::Cloudbuild::V1::Cloudbuild::DefaultServiceAccount>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
