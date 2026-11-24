package Google::Cloud::Assuredworkloads::V1beta1::AssuredWorkloadsServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads;
use Google::Cloud::Assuredworkloads::V1beta1::AssuredworkloadsService;

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

    my $target = 'assuredworkloads.googleapis.com:443';
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

sub create_workload {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::CreateWorkloadRequest';
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
            path           => '/google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService/CreateWorkload',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'CreateWorkload',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_workload {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::GetWorkloadRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService/GetWorkload',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'GetWorkload',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub analyze_workload_move {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService/AnalyzeWorkloadMove',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'AnalyzeWorkloadMove',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_workloads {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService/ListWorkloads',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService',
        method         => 'ListWorkloads',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Assuredworkloads::V1beta1::AssuredWorkloadsServiceClient

__END__

=head1 NAME

Google::Cloud::Assuredworkloads::V1beta1::AssuredWorkloadsServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Assuredworkloads::V1beta1::AssuredWorkloadsServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Assuredworkloads::V1beta1::AssuredWorkloadsServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Assuredworkloads::V1beta1::AssuredWorkloadsServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Assuredworkloads::V1beta1::AssuredWorkloadsServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/assuredworkloads/v1beta1/assuredworkloads.proto>

=item * C<googleapis/google/cloud/assuredworkloads/v1beta1/assuredworkloads_service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Assuredworkloads::V1beta1::AssuredWorkloadsServiceClient->new(
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

=item * B<create_workload>

    my $response = $client->create_workload(
        parent                   => $parent,
        workload                 => $workload,
        external_id              => $external_id,
    );

Calls the RPC method C<CreateWorkload> on C<google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService>.

Request: L<Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::CreateWorkloadRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<workload> - L<Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload>

=item * C<external_id> - C<string>

=back

=item * B<get_workload>

    my $response = $client->get_workload(
        name                     => $name,
    );

Calls the RPC method C<GetWorkload> on C<google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService>.

Request: L<Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::GetWorkloadRequest>

Returns: L<Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::Workload>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<analyze_workload_move>

    my $response = $client->analyze_workload_move(
        target                   => $target,
    );

Calls the RPC method C<AnalyzeWorkloadMove> on C<google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService>.

Request: L<Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveRequest>

Returns: L<Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::AnalyzeWorkloadMoveResponse>

Parameters:

=over 4

=item * C<target> - C<string>

=back

=item * B<list_workloads>

    my $response = $client->list_workloads(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListWorkloads> on C<google.cloud.assuredworkloads.v1beta1.AssuredWorkloadsService>.

Request: L<Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsRequest>

Returns: L<Google::Cloud::Assuredworkloads::V1beta1::Assuredworkloads::ListWorkloadsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
