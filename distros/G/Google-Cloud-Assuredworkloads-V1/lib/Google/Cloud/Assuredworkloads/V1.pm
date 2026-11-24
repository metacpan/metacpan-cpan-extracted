package Google::Cloud::Assuredworkloads::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Assuredworkloads::V1::Assuredworkloads;

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

    my $request_class = 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::CreateWorkloadRequest';
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
            path           => '/google.cloud.assuredworkloads.v1.AssuredWorkloadsService/CreateWorkload',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.assuredworkloads.v1.AssuredWorkloadsService',
        method         => 'CreateWorkload',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub list_violations {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListViolationsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListViolationsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.assuredworkloads.v1.AssuredWorkloadsService/ListViolations',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.assuredworkloads.v1.AssuredWorkloadsService',
        method         => 'ListViolations',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_violation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::GetViolationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.assuredworkloads.v1.AssuredWorkloadsService/GetViolation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.assuredworkloads.v1.AssuredWorkloadsService',
        method         => 'GetViolation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub acknowledge_violation {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::AcknowledgeViolationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Assuredworkloads::V1::Assuredworkloads::AcknowledgeViolationResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.assuredworkloads.v1.AssuredWorkloadsService/AcknowledgeViolation',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.assuredworkloads.v1.AssuredWorkloadsService',
        method         => 'AcknowledgeViolation',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Assuredworkloads::V1

__END__

=head1 NAME

Google::Cloud::Assuredworkloads::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Assuredworkloads::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Assuredworkloads::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Assuredworkloads::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Assuredworkloads::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/assuredworkloads/v1/assuredworkloads.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Assuredworkloads::V1->new(
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

Calls the RPC method C<CreateWorkload> on C<google.cloud.assuredworkloads.v1.AssuredWorkloadsService>.

Request: L<Google::Cloud::Assuredworkloads::V1::Assuredworkloads::CreateWorkloadRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<workload> - L<Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Workload>

=item * C<external_id> - C<string>

=back

=item * B<list_violations>

    my $response = $client->list_violations(
        parent                   => $parent,
        interval                 => $interval,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
    );

Calls the RPC method C<ListViolations> on C<google.cloud.assuredworkloads.v1.AssuredWorkloadsService>.

Request: L<Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListViolationsRequest>

Returns: L<Google::Cloud::Assuredworkloads::V1::Assuredworkloads::ListViolationsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<interval> - L<Google::Cloud::Assuredworkloads::V1::Assuredworkloads::TimeWindow>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=back

=item * B<get_violation>

    my $response = $client->get_violation(
        name                     => $name,
    );

Calls the RPC method C<GetViolation> on C<google.cloud.assuredworkloads.v1.AssuredWorkloadsService>.

Request: L<Google::Cloud::Assuredworkloads::V1::Assuredworkloads::GetViolationRequest>

Returns: L<Google::Cloud::Assuredworkloads::V1::Assuredworkloads::Violation>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<acknowledge_violation>

    my $response = $client->acknowledge_violation(
        name                     => $name,
        comment                  => $comment,
        non_compliant_org_policy => $non_compliant_org_policy,
    );

Calls the RPC method C<AcknowledgeViolation> on C<google.cloud.assuredworkloads.v1.AssuredWorkloadsService>.

Request: L<Google::Cloud::Assuredworkloads::V1::Assuredworkloads::AcknowledgeViolationRequest>

Returns: L<Google::Cloud::Assuredworkloads::V1::Assuredworkloads::AcknowledgeViolationResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<comment> - C<string>

=item * C<non_compliant_org_policy> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
