package Google::Cloud::Networkmanagement::V1::ReachabilityServiceClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Networkmanagement::V1::VpcFlowLogsConfig;
use Google::Cloud::Networkmanagement::V1::Trace;
use Google::Cloud::Networkmanagement::V1::ConnectivityTest;
use Google::Cloud::Networkmanagement::V1::Reachability;
use Google::Cloud::Networkmanagement::V1::VpcFlowLogs;

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

    my $target = 'networkmanagement.googleapis.com:443';
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

sub list_connectivity_tests {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.networkmanagement.v1.ReachabilityService/ListConnectivityTests',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networkmanagement.v1.ReachabilityService',
        method         => 'ListConnectivityTests',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_connectivity_test {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Networkmanagement::V1::Reachability::UpdateConnectivityTestRequest';
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
            path           => '/google.cloud.networkmanagement.v1.ReachabilityService/UpdateConnectivityTest',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.networkmanagement.v1.ReachabilityService',
        method         => 'UpdateConnectivityTest',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Networkmanagement::V1::ReachabilityServiceClient

__END__

=head1 NAME

Google::Cloud::Networkmanagement::V1::ReachabilityServiceClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Networkmanagement::V1::ReachabilityServiceClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Networkmanagement::V1::ReachabilityServiceClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Networkmanagement::V1::ReachabilityServiceClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Networkmanagement::V1::ReachabilityServiceClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/networkmanagement/v1/connectivity_test.proto>

=item * C<googleapis/google/cloud/networkmanagement/v1/reachability.proto>

=item * C<googleapis/google/cloud/networkmanagement/v1/trace.proto>

=item * C<googleapis/google/cloud/networkmanagement/v1/vpc_flow_logs.proto>

=item * C<googleapis/google/cloud/networkmanagement/v1/vpc_flow_logs_config.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Networkmanagement::V1::ReachabilityServiceClient->new(
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

=item * B<list_connectivity_tests>

    my $response = $client->list_connectivity_tests(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
        filter                   => $filter,
        order_by                 => $order_by,
    );

Calls the RPC method C<ListConnectivityTests> on C<google.cloud.networkmanagement.v1.ReachabilityService>.

Request: L<Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsRequest>

Returns: L<Google::Cloud::Networkmanagement::V1::Reachability::ListConnectivityTestsResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=item * C<filter> - C<string>

=item * C<order_by> - C<string>

=back

=item * B<update_connectivity_test>

    my $response = $client->update_connectivity_test(
        update_mask              => $update_mask,
        resource                 => $resource,
    );

Calls the RPC method C<UpdateConnectivityTest> on C<google.cloud.networkmanagement.v1.ReachabilityService>.

Request: L<Google::Cloud::Networkmanagement::V1::Reachability::UpdateConnectivityTestRequest>

Returns: L<Google::Longrunning::Operations::Operation>

Parameters:

=over 4

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=item * C<resource> - L<Google::Cloud::Networkmanagement::V1::ConnectivityTest::ConnectivityTest>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
