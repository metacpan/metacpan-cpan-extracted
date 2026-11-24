package Google::Cloud::Webrisk::V1beta1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Webrisk::V1beta1::Webrisk;

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

    my $target = 'webrisk.googleapis.com:443';
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

sub compute_threat_list_diff {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1/ComputeThreatListDiff',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1',
        method         => 'ComputeThreatListDiff',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_uris {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1/SearchUris',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1',
        method         => 'SearchUris',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub search_hashes {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1/SearchHashes',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1',
        method         => 'SearchHashes',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Webrisk::V1beta1

__END__

=head1 NAME

Google::Cloud::Webrisk::V1beta1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Webrisk::V1beta1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Webrisk::V1beta1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Webrisk::V1beta1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Webrisk::V1beta1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/webrisk/v1beta1/webrisk.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Webrisk::V1beta1->new(
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

=item * B<compute_threat_list_diff>

    my $response = $client->compute_threat_list_diff(
        threat_type              => $threat_type,
        version_token            => $version_token,
        constraints              => $constraints,
    );

Calls the RPC method C<ComputeThreatListDiff> on C<google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1>.

Request: L<Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffRequest>

Returns: L<Google::Cloud::Webrisk::V1beta1::Webrisk::ComputeThreatListDiffResponse>

Parameters:

=over 4

=item * C<threat_type> - L<Google::Cloud::Webrisk::V1beta1::Webrisk::ThreatType>

=item * C<version_token> - C<bytes>

=item * C<constraints> - L<Google::Cloud::Webrisk::V1beta1::Webrisk::Constraints>

=back

=item * B<search_uris>

    my $response = $client->search_uris(
        uri                      => $uri,
        threat_types             => [ ... ],
    );

Calls the RPC method C<SearchUris> on C<google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1>.

Request: L<Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisRequest>

Returns: L<Google::Cloud::Webrisk::V1beta1::Webrisk::SearchUrisResponse>

Parameters:

=over 4

=item * C<uri> - C<string>

=item * C<threat_types> - ArrayRef of L<Google::Cloud::Webrisk::V1beta1::Webrisk::ThreatType>

=back

=item * B<search_hashes>

    my $response = $client->search_hashes(
        hash_prefix              => $hash_prefix,
        threat_types             => [ ... ],
    );

Calls the RPC method C<SearchHashes> on C<google.cloud.webrisk.v1beta1.WebRiskServiceV1Beta1>.

Request: L<Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesRequest>

Returns: L<Google::Cloud::Webrisk::V1beta1::Webrisk::SearchHashesResponse>

Parameters:

=over 4

=item * C<hash_prefix> - C<bytes>

=item * C<threat_types> - ArrayRef of L<Google::Cloud::Webrisk::V1beta1::Webrisk::ThreatType>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
