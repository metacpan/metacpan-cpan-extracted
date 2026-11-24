package Google::Cloud::Appengine::V1beta::ApplicationsClient;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);

use Protobuf;
use Google::Api::Common;
use Google::Appengine::V1beta::Domain;
use Google::Appengine::V1beta::NetworkSettings;
use Google::Appengine::V1beta::Firewall;
use Google::Appengine::V1beta::DomainMapping;
use Google::Appengine::V1beta::Certificate;
use Google::Appengine::V1beta::Operation;
use Google::Appengine::V1beta::Service;
use Google::Appengine::V1beta::Instance;
use Google::Appengine::V1beta::Location;
use Google::Appengine::V1beta::AppYaml;
use Google::Appengine::V1beta::Application;
use Google::Appengine::V1beta::Deploy;
use Google::Appengine::V1beta::Version;
use Google::Appengine::V1beta::Appengine;
use Google::Appengine::V1beta::AuditData;

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

    my $target = 'appengine.googleapis.com:443';
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

sub get_application {
    my ($self, %params) = @_;

    my $request_class = 'Google::Appengine::V1beta::Appengine::GetApplicationRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Appengine::V1beta::Application::Application';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.appengine.v1beta.Applications/GetApplication',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.appengine.v1beta.Applications',
        method         => 'GetApplication',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}

sub create_ingress_rule {
    my ($self, %params) = @_;

    my $request_class = 'Google::Appengine::V1beta::Appengine::CreateIngressRuleRequest';
    my $request = eval { $request_class->new(\%params) };
    my $new_err = $@;
    if (!$request) {
        $request = eval { $request_class->new(%params) };
        $new_err ||= $@;
    }
    if (!$request) {
        croak 'Failed to construct ' . $request_class . ': ' . ($new_err || 'unknown error');
    }

    my $response_class = 'Google::Appengine::V1beta::Firewall::FirewallRule';
    if (eval { $self->transport->isa('Google::Cloud::REST::Client') }) {
        return $self->transport->call({
            http_method    => 'POST',
            path           => '/google.appengine.v1beta.Applications/CreateIngressRule',
            request        => $request,
            response_class => $response_class,
        });
    }

    my $response = $self->transport->call({
        service        => 'google.appengine.v1beta.Applications',
        method         => 'CreateIngressRule',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
1; # End of Google::Cloud::Appengine::V1beta::ApplicationsClient

__END__

=head1 NAME

Google::Cloud::Appengine::V1beta::ApplicationsClient - Client library for Google Cloud Services

=head1 SYNOPSIS

    use Google::Cloud::Appengine::V1beta::ApplicationsClient;
    use Google::Auth;

    my $auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my $grpc_client = Google::Cloud::Appengine::V1beta::ApplicationsClient->new(
        credentials => $auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my $rest_client = Google::Cloud::Appengine::V1beta::ApplicationsClient->new(
        credentials => $auth,
        transport   => 'rest',
    );

    # Execute service methods
    my $res = $grpc_client->some_method( %params );

=head1 DESCRIPTION

C<Google::Cloud::Appengine::V1beta::ApplicationsClient> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

=head1 SOURCE

Generated from the following Protocol Buffers schemas:

=over 4

=item * C<googleapis/google/appengine/v1beta/app_yaml.proto>

=item * C<googleapis/google/appengine/v1beta/appengine.proto>

=item * C<googleapis/google/appengine/v1beta/application.proto>

=item * C<googleapis/google/appengine/v1beta/audit_data.proto>

=item * C<googleapis/google/appengine/v1beta/certificate.proto>

=item * C<googleapis/google/appengine/v1beta/deploy.proto>

=item * C<googleapis/google/appengine/v1beta/domain.proto>

=item * C<googleapis/google/appengine/v1beta/domain_mapping.proto>

=item * C<googleapis/google/appengine/v1beta/firewall.proto>

=item * C<googleapis/google/appengine/v1beta/instance.proto>

=item * C<googleapis/google/appengine/v1beta/location.proto>

=item * C<googleapis/google/appengine/v1beta/network_settings.proto>

=item * C<googleapis/google/appengine/v1beta/operation.proto>

=item * C<googleapis/google/appengine/v1beta/service.proto>

=item * C<googleapis/google/appengine/v1beta/version.proto>



=back

=head1 CONSTRUCTOR

=head2 new

    my $client = Google::Cloud::Appengine::V1beta::ApplicationsClient->new(
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

=item * B<get_application>

    my $response = $client->get_application();

Calls the RPC method C<GetApplication> on C<google.appengine.v1beta.Applications>.

Request: L<Google::Appengine::V1beta::Appengine::GetApplicationRequest>

Returns: L<Google::Appengine::V1beta::Application::Application>

=item * B<create_ingress_rule>

    my $response = $client->create_ingress_rule();

Calls the RPC method C<CreateIngressRule> on C<google.appengine.v1beta.Applications>.

Request: L<Google::Appengine::V1beta::Appengine::CreateIngressRuleRequest>

Returns: L<Google::Appengine::V1beta::Firewall::FirewallRule>

=back



=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
