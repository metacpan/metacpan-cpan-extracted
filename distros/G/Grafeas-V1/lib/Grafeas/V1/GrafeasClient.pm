package Grafeas::V1::GrafeasClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Grafeas::V1::Common;
use Grafeas::V1::Risk;
use Grafeas::V1::Cvss;
use Grafeas::V1::Image;
use Grafeas::V1::Severity;
use Grafeas::V1::Deployment;
use Grafeas::V1::Provenance;
use Grafeas::V1::Vex;
use Grafeas::V1::Attestation;
use Grafeas::V1::Package;
use Grafeas::V1::SlsaProvenanceZeroTwo;
use Grafeas::V1::IntotoProvenance;
use Grafeas::V1::Discovery;
use Grafeas::V1::Secret;
use Grafeas::V1::SlsaProvenance;
use Grafeas::V1::Compliance;
use Grafeas::V1::Vulnerability;
use Grafeas::V1::Upgrade;
use Grafeas::V1::IntotoStatement;
use Grafeas::V1::Build;
use Grafeas::V1::Sbom;
use Grafeas::V1::DsseAttestation;
use Grafeas::V1::Grafeas;

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

    my $target = 'containeranalysis.googleapis.com:443';
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

sub get_occurrence {
    my ($self, %params) = @_;

    my $request_class = 'Grafeas::V1::Grafeas::GetOccurrenceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Grafeas::V1::Grafeas::Occurrence';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/grafeas.v1.Grafeas/GetOccurrence',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'grafeas.v1.Grafeas',
        method         => 'GetOccurrence',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Grafeas::V1::GrafeasClient

__END__

=head1 NAME

Grafeas::V1::GrafeasClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Grafeas::V1::GrafeasClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Grafeas::V1::GrafeasClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Grafeas::V1::GrafeasClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Grafeas::V1::GrafeasClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/grafeas/v1/attestation.proto>

=item * C<googleapis/grafeas/v1/build.proto>

=item * C<googleapis/grafeas/v1/common.proto>

=item * C<googleapis/grafeas/v1/compliance.proto>

=item * C<googleapis/grafeas/v1/cvss.proto>

=item * C<googleapis/grafeas/v1/deployment.proto>

=item * C<googleapis/grafeas/v1/discovery.proto>

=item * C<googleapis/grafeas/v1/dsse_attestation.proto>

=item * C<googleapis/grafeas/v1/grafeas.proto>

=item * C<googleapis/grafeas/v1/image.proto>

=item * C<googleapis/grafeas/v1/intoto_provenance.proto>

=item * C<googleapis/grafeas/v1/intoto_statement.proto>

=item * C<googleapis/grafeas/v1/package.proto>

=item * C<googleapis/grafeas/v1/provenance.proto>

=item * C<googleapis/grafeas/v1/risk.proto>

=item * C<googleapis/grafeas/v1/sbom.proto>

=item * C<googleapis/grafeas/v1/secret.proto>

=item * C<googleapis/grafeas/v1/severity.proto>

=item * C<googleapis/grafeas/v1/slsa_provenance.proto>

=item * C<googleapis/grafeas/v1/slsa_provenance_zero_two.proto>

=item * C<googleapis/grafeas/v1/upgrade.proto>

=item * C<googleapis/grafeas/v1/vex.proto>

=item * C<googleapis/grafeas/v1/vulnerability.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Grafeas::V1::GrafeasClient->new(
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

=item * B<get_occurrence>

    my $response = $client->get_occurrence(
        name                     => $name,
    );

Calls the RPC method C<GetOccurrence> on C<grafeas.v1.Grafeas>.

Request: L<Grafeas::V1::Grafeas::GetOccurrenceRequest>

Returns: L<Grafeas::V1::Grafeas::Occurrence>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
