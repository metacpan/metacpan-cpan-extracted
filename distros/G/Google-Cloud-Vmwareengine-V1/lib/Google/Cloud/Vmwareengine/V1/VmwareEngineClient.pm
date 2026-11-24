package Google::Cloud::Vmwareengine::V1::VmwareEngineClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Vmwareengine::V1::VmwareengineResources;
use Google::Cloud::Vmwareengine::V1::Vmwareengine;

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

    my $target = 'vmwareengine.googleapis.com:443';
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

sub list_private_clouds {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateCloudsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateCloudsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.vmwareengine.v1.VmwareEngine/ListPrivateClouds',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.vmwareengine.v1.VmwareEngine',
        method         => 'ListPrivateClouds',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_dns_forwarding {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateDnsForwardingRequest';
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
            path           => '/google.cloud.vmwareengine.v1.VmwareEngine/UpdateDnsForwarding',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.vmwareengine.v1.VmwareEngine',
        method         => 'UpdateDnsForwarding',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Vmwareengine::V1::VmwareEngineClient

__END__

=head1 NAME

Google::Cloud::Vmwareengine::V1::VmwareEngineClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Vmwareengine::V1::VmwareEngineClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Vmwareengine::V1::VmwareEngineClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Vmwareengine::V1::VmwareEngineClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Vmwareengine::V1::VmwareEngineClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/vmwareengine/v1/vmwareengine.proto>

=item * C<googleapis/google/cloud/vmwareengine/v1/vmwareengine_resources.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Vmwareengine::V1::VmwareEngineClient->new(
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

=item * B<list_private_clouds>

    my $response = $client->list_private_clouds(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListPrivateClouds> on C<google.cloud.vmwareengine.v1.VmwareEngine>.

Request: L<Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateCloudsRequest>

Returns: L<Google::Cloud::Vmwareengine::V1::Vmwareengine::ListPrivateCloudsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<update_dns_forwarding>

    my $response = $client->update_dns_forwarding(
        dns_forwarding           => $dns_forwarding,
        update_mask              => $update_mask,
        request_id               => $request_id,
    );

Calls the RPC method C<UpdateDnsForwarding> on C<google.cloud.vmwareengine.v1.VmwareEngine>.

Request: L<Google::Cloud::Vmwareengine::V1::Vmwareengine::UpdateDnsForwardingRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<dns_forwarding> - L<Google::Cloud::Vmwareengine::V1::VmwareengineResources::DnsForwarding>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<request_id> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
