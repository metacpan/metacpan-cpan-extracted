package Google::Cloud::Apptopology::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Apptopology::V1::Graph;
use Google::Cloud::Apptopology::V1::Query;
use Google::Cloud::Apptopology::V1::Schema;
use Google::Cloud::Apptopology::V1::Service;

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

    my $target = 'apptopology.googleapis.com:443';
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

sub generate_discovered_resources_topology {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apptopology.v1.AppTopology/GenerateDiscoveredResourcesTopology',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apptopology.v1.AppTopology',
        method         => 'GenerateDiscoveredResourcesTopology',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_schema {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apptopology::V1::Service::GetSchemaRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apptopology::V1::Schema::Schema';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apptopology.v1.AppTopology/GetSchema',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apptopology.v1.AppTopology',
        method         => 'GetSchema',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_domain {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Apptopology::V1::Service::GetDomainRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Apptopology::V1::Schema::Domain';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.apptopology.v1.AppTopology/GetDomain',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.apptopology.v1.AppTopology',
        method         => 'GetDomain',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Apptopology::V1

__END__

=head1 NAME

Google::Cloud::Apptopology::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Apptopology::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Apptopology::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Apptopology::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Apptopology::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/apptopology/v1/graph.proto>

=item * C<googleapis/google/cloud/apptopology/v1/query.proto>

=item * C<googleapis/google/cloud/apptopology/v1/schema.proto>

=item * C<googleapis/google/cloud/apptopology/v1/service.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Apptopology::V1->new(
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

=item * B<generate_discovered_resources_topology>

    my $response = $client->generate_discovered_resources_topology(
        name                     => $name,
        topology_domains         => [ ... ],
    );

Calls the RPC method C<GenerateDiscoveredResourcesTopology> on C<google.cloud.apptopology.v1.AppTopology>.

Request: L<Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyRequest>

Returns: L<Google::Cloud::Apptopology::V1::Service::GenerateDiscoveredResourcesTopologyResponse>

Parameters:

=over 4

=item * C<name> - C<string>

=item * C<topology_domains> - ArrayRef of C<string>

=back

=item * B<get_schema>

    my $response = $client->get_schema(
        name                     => $name,
    );

Calls the RPC method C<GetSchema> on C<google.cloud.apptopology.v1.AppTopology>.

Request: L<Google::Cloud::Apptopology::V1::Service::GetSchemaRequest>

Returns: L<Google::Cloud::Apptopology::V1::Schema::Schema>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<get_domain>

    my $response = $client->get_domain(
        name                     => $name,
    );

Calls the RPC method C<GetDomain> on C<google.cloud.apptopology.v1.AppTopology>.

Request: L<Google::Cloud::Apptopology::V1::Service::GetDomainRequest>

Returns: L<Google::Cloud::Apptopology::V1::Schema::Domain>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
