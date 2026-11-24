package Google::Cloud::Securityposture::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Securityposture::V1::OrgPolicyConfig;
use Google::Cloud::Securityposture::V1::ShaCustomConfig;
use Google::Cloud::Securityposture::V1::OrgPolicyConstraints;
use Google::Cloud::Securityposture::V1::ShaConstraints;
use Google::Cloud::Securityposture::V1::Securityposture;

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

    my $target = 'securityposture.googleapis.com:443';
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

sub list_postures {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securityposture::V1::Securityposture::ListPosturesRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securityposture::V1::Securityposture::ListPosturesResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securityposture.v1.SecurityPosture/ListPostures',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securityposture.v1.SecurityPosture',
        method         => 'ListPostures',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Securityposture::V1

__END__

=head1 NAME

Google::Cloud::Securityposture::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Securityposture::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Securityposture::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Securityposture::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Securityposture::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/securityposture/v1/org_policy_config.proto>

=item * C<googleapis/google/cloud/securityposture/v1/org_policy_constraints.proto>

=item * C<googleapis/google/cloud/securityposture/v1/securityposture.proto>

=item * C<googleapis/google/cloud/securityposture/v1/sha_constraints.proto>

=item * C<googleapis/google/cloud/securityposture/v1/sha_custom_config.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Securityposture::V1->new(
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

=item * B<list_postures>

    my $response = $client->list_postures(
        parent                   => $parent,
        page_size                => $page_size,
        page_token               => $page_token,
    );

Calls the RPC method C<ListPostures> on C<google.cloud.securityposture.v1.SecurityPosture>.

Request: L<Google::Cloud::Securityposture::V1::Securityposture::ListPosturesRequest>

Returns: L<Google::Cloud::Securityposture::V1::Securityposture::ListPosturesResponse>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<page_size> - C<int32>

=item * C<page_token> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
