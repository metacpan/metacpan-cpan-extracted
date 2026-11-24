package Google::Cloud::Securitycenter::V1beta1::SecurityCenterClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Cloud::Securitycenter::V1beta1::RunAssetDiscoveryResponse;
use Google::Cloud::Securitycenter::V1beta1::Source;
use Google::Cloud::Securitycenter::V1beta1::SecurityMarks;
use Google::Cloud::Securitycenter::V1beta1::OrganizationSettings;
use Google::Cloud::Securitycenter::V1beta1::Asset;
use Google::Cloud::Securitycenter::V1beta1::Finding;
use Google::Cloud::Securitycenter::V1beta1::SecuritycenterService;

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

    my $target = 'securitycenter.googleapis.com:443';
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

sub create_source {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::CreateSourceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1beta1::Source::Source';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1beta1.SecurityCenter/CreateSource',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1beta1.SecurityCenter',
        method         => 'CreateSource',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub get_source {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GetSourceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1beta1::Source::Source';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1beta1.SecurityCenter/GetSource',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1beta1.SecurityCenter',
        method         => 'GetSource',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub update_source {
    my ($self, %params) = @_;

    my $request_class = 'Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateSourceRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Cloud::Securitycenter::V1beta1::Source::Source';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.cloud.securitycenter.v1beta1.SecurityCenter/UpdateSource',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.cloud.securitycenter.v1beta1.SecurityCenter',
        method         => 'UpdateSource',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Securitycenter::V1beta1::SecurityCenterClient

__END__

=head1 NAME

Google::Cloud::Securitycenter::V1beta1::SecurityCenterClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1beta1::SecurityCenterClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Securitycenter::V1beta1::SecurityCenterClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Securitycenter::V1beta1::SecurityCenterClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Securitycenter::V1beta1::SecurityCenterClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/cloud/securitycenter/v1beta1/asset.proto>

=item * C<googleapis/google/cloud/securitycenter/v1beta1/finding.proto>

=item * C<googleapis/google/cloud/securitycenter/v1beta1/organization_settings.proto>

=item * C<googleapis/google/cloud/securitycenter/v1beta1/run_asset_discovery_response.proto>

=item * C<googleapis/google/cloud/securitycenter/v1beta1/security_marks.proto>

=item * C<googleapis/google/cloud/securitycenter/v1beta1/securitycenter_service.proto>

=item * C<googleapis/google/cloud/securitycenter/v1beta1/source.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Securitycenter::V1beta1::SecurityCenterClient->new(
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

=item * B<create_source>

    my $response = $client->create_source(
        parent                   => $parent,
        source                   => $source,
    );

Calls the RPC method C<CreateSource> on C<google.cloud.securitycenter.v1beta1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::CreateSourceRequest>

Returns: L<Google::Cloud::Securitycenter::V1beta1::Source::Source>

Parameters:

=over 4

=item * C<parent> - C<string>

=item * C<source> - L<Google::Cloud::Securitycenter::V1beta1::Source::Source>

=back

=item * B<get_source>

    my $response = $client->get_source(
        name                     => $name,
    );

Calls the RPC method C<GetSource> on C<google.cloud.securitycenter.v1beta1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::GetSourceRequest>

Returns: L<Google::Cloud::Securitycenter::V1beta1::Source::Source>

Parameters:

=over 4

=item * C<name> - C<string>

=back

=item * B<update_source>

    my $response = $client->update_source(
        source                   => $source,
        update_mask              => $update_mask,
    );

Calls the RPC method C<UpdateSource> on C<google.cloud.securitycenter.v1beta1.SecurityCenter>.

Request: L<Google::Cloud::Securitycenter::V1beta1::SecuritycenterService::UpdateSourceRequest>

Returns: L<Google::Cloud::Securitycenter::V1beta1::Source::Source>

Parameters:

=over 4

=item * C<source> - L<Google::Cloud::Securitycenter::V1beta1::Source::Source>

=item * C<update_mask> - L<Google::Protobuf::FieldMask::FieldMask>

=back

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
