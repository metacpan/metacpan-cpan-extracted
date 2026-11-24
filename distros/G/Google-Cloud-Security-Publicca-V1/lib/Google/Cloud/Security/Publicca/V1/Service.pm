package Google::Cloud::Security::Publicca::V1::Service;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Security::Publicca::V1::Resources };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvc2VjdXJpdHkvcHVibGljY2EvdjEvc2VydmljZS5wcm90bxIhZ29v
Z2xlLmNsb3VkLnNlY3VyaXR5LnB1YmxpY2NhLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25z
LnByb3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxoxZ29vZ2xlL2Nsb3VkL3Nl
Y3VyaXR5L3B1YmxpY2NhL3YxL3Jlc291cmNlcy5wcm90byLbAQofQ3JlYXRlRXh0ZXJuYWxB
Y2NvdW50S2V5UmVxdWVzdBJKCgZwYXJlbnQYASABKAlCMuBBAvpBLBIqcHVibGljY2EuZ29v
Z2xlYXBpcy5jb20vRXh0ZXJuYWxBY2NvdW50S2V5UgZwYXJlbnQSbAoUZXh0ZXJuYWxfYWNj
b3VudF9rZXkYAiABKAsyNS5nb29nbGUuY2xvdWQuc2VjdXJpdHkucHVibGljY2EudjEuRXh0
ZXJuYWxBY2NvdW50S2V5QgPgQQJSEmV4dGVybmFsQWNjb3VudEtleTL9AgohUHVibGljQ2Vy
dGlmaWNhdGVBdXRob3JpdHlTZXJ2aWNlEooCChhDcmVhdGVFeHRlcm5hbEFjY291bnRLZXkS
Qi5nb29nbGUuY2xvdWQuc2VjdXJpdHkucHVibGljY2EudjEuQ3JlYXRlRXh0ZXJuYWxBY2Nv
dW50S2V5UmVxdWVzdBo1Lmdvb2dsZS5jbG91ZC5zZWN1cml0eS5wdWJsaWNjYS52MS5FeHRl
cm5hbEFjY291bnRLZXkic4LT5JMCTyI3L3YxL3twYXJlbnQ9cHJvamVjdHMvKi9sb2NhdGlv
bnMvKn0vZXh0ZXJuYWxBY2NvdW50S2V5czoUZXh0ZXJuYWxfYWNjb3VudF9rZXnaQRtwYXJl
bnQsZXh0ZXJuYWxfYWNjb3VudF9rZXkaS8pBF3B1YmxpY2NhLmdvb2dsZWFwaXMuY29t0kEu
aHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybULqAQolY29t
Lmdvb2dsZS5jbG91ZC5zZWN1cml0eS5wdWJsaWNjYS52MUIMU2VydmljZVByb3RvUAFaQWNs
b3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHkvcHVibGljY2EvYXBpdjEvcHVibGljY2FwYjtw
dWJsaWNjYXBiqgIhR29vZ2xlLkNsb3VkLlNlY3VyaXR5LlB1YmxpY0NBLlYxygIhR29vZ2xl
XENsb3VkXFNlY3VyaXR5XFB1YmxpY0NBXFYx6gIlR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHk6
OlB1YmxpY0NBOjpWMUqiEAoGEgQOAEkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAqCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMD
EgMVACMKCQoCAwQSAxYAOwoICgEIEgMYAD4KCQoCCCUSAxgAPgoICgEIEgMZAFgKCQoCCAsS
AxkAWAoICgEIEgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAC0KCQoCCAgSAxsALQoICgEIEgMc
AD4KCQoCCAESAxwAPgoICgEIEgMdAD8KCQoCCCkSAx0APwoICgEIEgMeAD4KCQoCCC0SAx4A
Pgq0AQoCBgASBCMAMwEapwEgTWFuYWdlcyB0aGUgcmVzb3VyY2VzIHJlcXVpcmVkIGZvciBB
Q01FIFtleHRlcm5hbCBhY2NvdW50CiBiaW5kaW5nXShodHRwczovL3Rvb2xzLmlldGYub3Jn
L2h0bWwvcmZjODU1NSNzZWN0aW9uLTcuMy40KSBmb3IKIHRoZSBwdWJsaWMgY2VydGlmaWNh
dGUgYXV0aG9yaXR5IHNlcnZpY2UuCgoKCgMGAAESAyMIKQoKCgMGAAMSAyQCPwoMCgUGAAOZ
CBIDJAI/CgsKAwYAAxIEJQImNwoNCgUGAAOaCBIEJQImNwqAAQoEBgACABIEKwIyAxpyIENy
ZWF0ZXMgYSBuZXcKIFtFeHRlcm5hbEFjY291bnRLZXldW2dvb2dsZS5jbG91ZC5zZWN1cml0
eS5wdWJsaWNjYS52MS5FeHRlcm5hbEFjY291bnRLZXldCiBib3VuZCB0byB0aGUgcHJvamVj
dC4KCgwKBQYAAgABEgMrBh4KDAoFBgACAAISAysfPgoMCgUGAAIAAxIDLA8hCg0KBQYAAgAE
EgQtBDAGChEKCQYAAgAEsMq8IhIELQQwBgoMCgUGAAIABBIDMQRJCg8KCAYAAgAEmwgAEgMx
BEkKfAoCBAASBDgASQEacCBDcmVhdGVzIGEgbmV3CiBbRXh0ZXJuYWxBY2NvdW50S2V5XVtn
b29nbGUuY2xvdWQuc2VjdXJpdHkucHVibGljY2EudjEuRXh0ZXJuYWxBY2NvdW50S2V5XSBp
bgogYSBnaXZlbiBwcm9qZWN0LgoKCgoDBAABEgM4CCcKyQEKBAQAAgASBDwCQQQaugEgUmVx
dWlyZWQuIFRoZSBwYXJlbnQgcmVzb3VyY2Ugd2hlcmUgdGhpcyBleHRlcm5hbF9hY2NvdW50
X2tleSB3aWxsIGJlCiBjcmVhdGVkLiBGb3JtYXQ6IHByb2plY3RzL1twcm9qZWN0X2lkXS9s
b2NhdGlvbnMvW2xvY2F0aW9uXS4gQXQgcHJlc2VudAogb25seSB0aGUgImdsb2JhbCIgbG9j
YXRpb24gaXMgc3VwcG9ydGVkLgoKDAoFBAACAAUSAzwCCAoMCgUEAAIAARIDPAkPCgwKBQQA
AgADEgM8EhMKDQoFBAACAAgSBDwUQQMKDwoIBAACAAicCAASAz0EKgoPCgcEAAIACJ8IEgQ+
BEAFCqMCCgQEAAIBEgRHAkgvGpQCIFJlcXVpcmVkLiBUaGUgZXh0ZXJuYWwgYWNjb3VudCBr
ZXkgdG8gY3JlYXRlLiBUaGlzIGZpZWxkIG9ubHkgZXhpc3RzIHRvCiBmdXR1cmUtcHJvb2Yg
dGhlIEFQSS4gQXQgcHJlc2VudCwgYWxsIGZpZWxkcyBpbiBFeHRlcm5hbEFjY291bnRLZXkg
YXJlCiBvdXRwdXQgb25seSBhbmQgYWxsIHZhbHVlcyBhcmUgaWdub3JlZC4gRm9yIHRoZSBw
dXJwb3NlIG9mIHRoZQogQ3JlYXRlRXh0ZXJuYWxBY2NvdW50S2V5UmVxdWVzdCwgc2V0IGl0
IHRvIGEgZGVmYXVsdC9lbXB0eSB2YWx1ZS4KCgwKBQQAAgEGEgNHAhQKDAoFBAACAQESA0cV
KQoMCgUEAAIBAxIDRywtCgwKBQQAAgEIEgNIBi4KDwoIBAACAQicCAASA0gHLWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Security::Publicca::V1::Service::CreateExternalAccountKeyRequest ===
    # Fields for CreateExternalAccountKeyRequest
    # Field: parent Type: 9 ()
    # Field: external_account_key Type: 11 (.google.cloud.security.publicca.v1.ExternalAccountKey)

# === Service Client: Google::Cloud::Security::Publicca::V1::Service::PublicCertificateAuthorityServiceClient ===
package Google::Cloud::Security::Publicca::V1::Service::PublicCertificateAuthorityServiceClient;

=pod

=head2 Service Client: Google::Cloud::Security::Publicca::V1::Service::PublicCertificateAuthorityServiceClient

Client stub representing the remote C<PublicCertificateAuthorityService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<security.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'security.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub create_external_account_key {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Security::Publicca::V1::Service::CreateExternalAccountKeyRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.security.publicca.v1.PublicCertificateAuthorityService',
        method         => 'CreateExternalAccountKey',
        request        => $req,
        response_class => 'Google::Cloud::Security::Publicca::V1::Resources::ExternalAccountKey',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Security::Publicca::V1::Service - Compiled Protocol Buffers messages for google/cloud/security/publicca/v1/service.proto

=head1 SYNOPSIS

    use Google::Cloud::Security::Publicca::V1::Service;

    my $msg = Google::Cloud::Security::Publicca::V1::Service::CreateExternalAccountKeyRequest->new({
        parent => $parent,
        external_account_key => $external_account_key,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Security::Publicca::V1::Service::CreateExternalAccountKeyRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/security/publicca/v1/service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Security::Publicca::V1::Service::CreateExternalAccountKeyRequest

Creates a new
[ExternalAccountKey][google.cloud.security.publicca.v1.ExternalAccountKey] in
a given project.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The parent resource where this external_account_key will be
created. Format: projects/[project_id]/locations/[location]. At present
only the "global" location is supported.

=item * C<< $msg->external_account_key() >> / C<< $msg->external_account_key($value) >>

Type: C<Message> (L<Google::Cloud::Security::Publicca::V1::Resources::ExternalAccountKey>)

Required. The external account key to create. This field only exists to
future-proof the API. At present, all fields in ExternalAccountKey are
output only and all values are ignored. For the purpose of the
CreateExternalAccountKeyRequest, set it to a default/empty value.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Security::Publicca::V1::Service::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
