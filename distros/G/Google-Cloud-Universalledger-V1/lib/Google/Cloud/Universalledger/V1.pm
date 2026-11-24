package Google::Cloud::Universalledger::V1;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Universalledger::V1::Accounts;
use Google::Cloud::Universalledger::V1::Common;
use Google::Cloud::Universalledger::V1::StatusEvent;
use Google::Cloud::Universalledger::V1::Transactions;
use Google::Cloud::Universalledger::V1::Types;
use Google::Cloud::Universalledger::V1::Query;
use Google::Cloud::Universalledger::V1::Universalledger;

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

    my $target = 'universalledger.googleapis.com:443';
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

sub submit_transaction {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionResponse';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.universalledger.v1.UniversalLedger/SubmitTransaction',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.universalledger.v1.UniversalLedger',
        method         => 'SubmitTransaction',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Universalledger::V1

__END__

=head1 NAME

Google::Cloud::Universalledger::V1 - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Universalledger::V1;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Universalledger::V1->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Universalledger::V1->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Universalledger::V1> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/universalledger/v1/accounts.proto>

=item * C<googleapis/google/cloud/universalledger/v1/common.proto>

=item * C<googleapis/google/cloud/universalledger/v1/query.proto>

=item * C<googleapis/google/cloud/universalledger/v1/status_event.proto>

=item * C<googleapis/google/cloud/universalledger/v1/transactions.proto>

=item * C<googleapis/google/cloud/universalledger/v1/types.proto>

=item * C<googleapis/google/cloud/universalledger/v1/universalledger.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Universalledger::V1->new(
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

=item * B<submit_transaction>

    my $response = $client->submit_transaction(
        endpoint                 => $endpoint,
        serialized_signed_transaction => $serialized_signed_transaction,
    );

Calls the RPC method C<SubmitTransaction> on C<google.cloud.universalledger.v1.UniversalLedger>.

Request: L<Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionRequest>

Returns: L<Google::Cloud::Universalledger::V1::Universalledger::SubmitTransactionResponse>

Parameters:

=over 4

=item * C<endpoint> - C<string>

=item * C<serialized_signed_transaction> - C<bytes>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
