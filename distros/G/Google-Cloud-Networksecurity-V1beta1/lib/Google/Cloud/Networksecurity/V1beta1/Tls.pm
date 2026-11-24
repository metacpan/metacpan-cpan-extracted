package Google::Cloud::Networksecurity::V1beta1::Tls;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvbmV0d29ya3NlY3VyaXR5L3YxYmV0YTEvdGxzLnByb3RvEiRnb29n
bGUuY2xvdWQubmV0d29ya3NlY3VyaXR5LnYxYmV0YTEaH2dvb2dsZS9hcGkvZmllbGRfYmVo
YXZpb3IucHJvdG8iMgoMR3JwY0VuZHBvaW50EiIKCnRhcmdldF91cmkYASABKAlCA+BBAlIJ
dGFyZ2V0VXJpIvsBCgxWYWxpZGF0aW9uQ0ESWQoNZ3JwY19lbmRwb2ludBgCIAEoCzIyLmdv
b2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5HcnBjRW5kcG9pbnRIAFIMZ3Jw
Y0VuZHBvaW50EocBCh1jZXJ0aWZpY2F0ZV9wcm92aWRlcl9pbnN0YW5jZRgDIAEoCzJBLmdv
b2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMS5DZXJ0aWZpY2F0ZVByb3ZpZGVy
SW5zdGFuY2VIAFIbY2VydGlmaWNhdGVQcm92aWRlckluc3RhbmNlQgYKBHR5cGUiSwobQ2Vy
dGlmaWNhdGVQcm92aWRlckluc3RhbmNlEiwKD3BsdWdpbl9pbnN0YW5jZRgBIAEoCUID4EEC
Ug5wbHVnaW5JbnN0YW5jZSKCAgoTQ2VydGlmaWNhdGVQcm92aWRlchJZCg1ncnBjX2VuZHBv
aW50GAIgASgLMjIuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLkdycGNF
bmRwb2ludEgAUgxncnBjRW5kcG9pbnQShwEKHWNlcnRpZmljYXRlX3Byb3ZpZGVyX2luc3Rh
bmNlGAMgASgLMkEuZ29vZ2xlLmNsb3VkLm5ldHdvcmtzZWN1cml0eS52MWJldGExLkNlcnRp
ZmljYXRlUHJvdmlkZXJJbnN0YW5jZUgAUhtjZXJ0aWZpY2F0ZVByb3ZpZGVySW5zdGFuY2VC
BgoEdHlwZUKCAgooY29tLmdvb2dsZS5jbG91ZC5uZXR3b3Jrc2VjdXJpdHkudjFiZXRhMUII
VGxzUHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9uZXR3b3Jrc2VjdXJpdHkvYXBpdjFi
ZXRhMS9uZXR3b3Jrc2VjdXJpdHlwYjtuZXR3b3Jrc2VjdXJpdHlwYqoCJEdvb2dsZS5DbG91
ZC5OZXR3b3JrU2VjdXJpdHkuVjFCZXRhMcoCJEdvb2dsZVxDbG91ZFxOZXR3b3JrU2VjdXJp
dHlcVjFiZXRhMeoCJ0dvb2dsZTo6Q2xvdWQ6Ok5ldHdvcmtTZWN1cml0eTo6VjFiZXRhMUrW
FgoGEgQOAE0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAt
CgkKAgMAEgMSACkKCAoBCBIDFABBCgkKAgglEgMUAEEKCAoBCBIDFQBpCgkKAggLEgMVAGkK
CAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwApCgkKAggIEgMXACkKCAoBCBIDGABBCgkK
AggBEgMYAEEKCAoBCBIDGQBBCgkKAggpEgMZAEEKCAoBCBIDGgBACgkKAggtEgMaAEAKMQoC
BAASBB0AIQEaJSBTcGVjaWZpY2F0aW9uIG9mIHRoZSBHUlBDIEVuZHBvaW50LgoKCgoDBAAB
EgMdCBQKeQoEBAACABIDIAJBGmwgUmVxdWlyZWQuIFRoZSB0YXJnZXQgVVJJIG9mIHRoZSBn
UlBDIGVuZHBvaW50LiBPbmx5IFVEUyBwYXRoIGlzIHN1cHBvcnRlZCwKIGFuZCBzaG91bGQg
c3RhcnQgd2l0aCAidW5peDoiLgoKDAoFBAACAAUSAyACCAoMCgUEAAIAARIDIAkTCgwKBQQA
AgADEgMgFhcKDAoFBAACAAgSAyAYQAoPCggEAAIACJwIABIDIBk/CpYBCgIEARIEJQAxARqJ
ASBTcGVjaWZpY2F0aW9uIG9mIFZhbGlkYXRpb25DQS4gRGVmaW5lcyB0aGUgbWVjaGFuaXNt
IHRvIG9idGFpbiB0aGUKIENlcnRpZmljYXRlIEF1dGhvcml0eSBjZXJ0aWZpY2F0ZSB0byB2
YWxpZGF0ZSB0aGUgcGVlciBjZXJ0aWZpY2F0ZS4KCgoKAwQBARIDJQgUClMKBAQBCAASBCcC
MAMaRSBUaGUgdHlwZSBvZiBjZXJ0aWZpY2F0ZSBwcm92aWRlciB3aGljaCBwcm92aWRlcyB0
aGUgQ0EgY2VydGlmaWNhdGUuCgoMCgUEAQgAARIDJwgMCmMKBAQBAgASAyoEIxpWIGdSUEMg
c3BlY2lmaWMgY29uZmlndXJhdGlvbiB0byBhY2Nlc3MgdGhlIGdSUEMgc2VydmVyIHRvCiBv
YnRhaW4gdGhlIENBIGNlcnRpZmljYXRlLgoKDAoFBAECAAYSAyoEEAoMCgUEAQIAARIDKhEe
CgwKBQQBAgADEgMqISIKpQEKBAQBAgESAy8EQhqXASBUaGUgY2VydGlmaWNhdGUgcHJvdmlk
ZXIgaW5zdGFuY2Ugc3BlY2lmaWNhdGlvbiB0aGF0IHdpbGwgYmUgcGFzc2VkIHRvCiB0aGUg
ZGF0YSBwbGFuZSwgd2hpY2ggd2lsbCBiZSB1c2VkIHRvIGxvYWQgbmVjZXNzYXJ5IGNyZWRl
bnRpYWwKIGluZm9ybWF0aW9uLgoKDAoFBAECAQYSAy8EHwoMCgUEAQIBARIDLyA9CgwKBQQB
AgEDEgMvQEEKwgIKAgQCEgQ3ADwBGrUCIFNwZWNpZmljYXRpb24gb2YgYSBUTFMgY2VydGlm
aWNhdGUgcHJvdmlkZXIgaW5zdGFuY2UuIFdvcmtsb2FkcyBtYXkgaGF2ZSBvbmUKIG9yIG1v
cmUgQ2VydGlmaWNhdGVQcm92aWRlciBpbnN0YW5jZXMgKHBsdWdpbnMpIGFuZCBvbmUgb2Yg
dGhlbSBpcyBlbmFibGVkCiBhbmQgY29uZmlndXJlZCBieSBzcGVjaWZ5aW5nIHRoaXMgbWVz
c2FnZS4gV29ya2xvYWRzIHVzZSB0aGUgdmFsdWVzIGZyb20gdGhpcwogbWVzc2FnZSB0byBs
b2NhdGUgYW5kIGxvYWQgdGhlIENlcnRpZmljYXRlUHJvdmlkZXIgaW5zdGFuY2UgY29uZmln
dXJhdGlvbi4KCgoKAwQCARIDNwgjCt4BCgQEAgIAEgM7AkYa0AEgUmVxdWlyZWQuIFBsdWdp
biBpbnN0YW5jZSBuYW1lLCB1c2VkIHRvIGxvY2F0ZSBhbmQgbG9hZCBDZXJ0aWZpY2F0ZVBy
b3ZpZGVyCiBpbnN0YW5jZSBjb25maWd1cmF0aW9uLiBTZXQgdG8gImdvb2dsZV9jbG91ZF9w
cml2YXRlX3NwaWZmZSIgdG8gdXNlCiBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgU2VydmljZSBj
ZXJ0aWZpY2F0ZSBwcm92aWRlciBpbnN0YW5jZS4KCgwKBQQCAgAFEgM7AggKDAoFBAICAAES
AzsJGAoMCgUEAgIAAxIDOxscCgwKBQQCAgAIEgM7HUUKDwoIBAICAAicCAASAzseRAqXAQoC
BAMSBEAATQEaigEgU3BlY2lmaWNhdGlvbiBvZiBjZXJ0aWZpY2F0ZSBwcm92aWRlci4gRGVm
aW5lcyB0aGUgbWVjaGFuaXNtIHRvIG9idGFpbiB0aGUKIGNlcnRpZmljYXRlIGFuZCBwcml2
YXRlIGtleSBmb3IgcGVlciB0byBwZWVyIGF1dGhlbnRpY2F0aW9uLgoKCgoDBAMBEgNACBsK
YwoEBAMIABIEQwJMAxpVIFRoZSB0eXBlIG9mIGNlcnRpZmljYXRlIHByb3ZpZGVyIHdoaWNo
IHByb3ZpZGVzIHRoZSBjZXJ0aWZpY2F0ZXMgYW5kCiBwcml2YXRlIGtleXMuCgoMCgUEAwgA
ARIDQwgMCmkKBAQDAgASA0YEIxpcIGdSUEMgc3BlY2lmaWMgY29uZmlndXJhdGlvbiB0byBh
Y2Nlc3MgdGhlIGdSUEMgc2VydmVyIHRvCiBvYnRhaW4gdGhlIGNlcnQgYW5kIHByaXZhdGUg
a2V5LgoKDAoFBAMCAAYSA0YEEAoMCgUEAwIAARIDRhEeCgwKBQQDAgADEgNGISIKpQEKBAQD
AgESA0sEQhqXASBUaGUgY2VydGlmaWNhdGUgcHJvdmlkZXIgaW5zdGFuY2Ugc3BlY2lmaWNh
dGlvbiB0aGF0IHdpbGwgYmUgcGFzc2VkIHRvCiB0aGUgZGF0YSBwbGFuZSwgd2hpY2ggd2ls
bCBiZSB1c2VkIHRvIGxvYWQgbmVjZXNzYXJ5IGNyZWRlbnRpYWwKIGluZm9ybWF0aW9uLgoK
DAoFBAMCAQYSA0sEHwoMCgUEAwIBARIDSyA9CgwKBQQDAgEDEgNLQEFiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Networksecurity::V1beta1::Tls::GrpcEndpoint ===
    # Fields for GrpcEndpoint
    # Field: target_uri Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::Tls::ValidationCA ===
    # Fields for ValidationCA
    # Field: grpc_endpoint Type: 11 (.google.cloud.networksecurity.v1beta1.GrpcEndpoint)
    # Field: certificate_provider_instance Type: 11 (.google.cloud.networksecurity.v1beta1.CertificateProviderInstance)

# === Message: Google::Cloud::Networksecurity::V1beta1::Tls::CertificateProviderInstance ===
    # Fields for CertificateProviderInstance
    # Field: plugin_instance Type: 9 ()

# === Message: Google::Cloud::Networksecurity::V1beta1::Tls::CertificateProvider ===
    # Fields for CertificateProvider
    # Field: grpc_endpoint Type: 11 (.google.cloud.networksecurity.v1beta1.GrpcEndpoint)
    # Field: certificate_provider_instance Type: 11 (.google.cloud.networksecurity.v1beta1.CertificateProviderInstance)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Networksecurity::V1beta1::Tls - Compiled Protocol Buffers messages for google/cloud/networksecurity/v1beta1/tls.proto

=head1 SYNOPSIS

    use Google::Cloud::Networksecurity::V1beta1::Tls;

    my $msg = Google::Cloud::Networksecurity::V1beta1::Tls::GrpcEndpoint->new({
        target_uri => $target_uri,
    });

    # Read or update a field
    my $val = $msg->target_uri();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Networksecurity::V1beta1::Tls::GrpcEndpoint->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/networksecurity/v1beta1/tls.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Networksecurity::V1beta1::Tls::GrpcEndpoint

Specification of the GRPC Endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target_uri() >> / C<< $msg->target_uri($value) >>

Type: C<String>

Required. The target URI of the gRPC endpoint. Only UDS path is supported,
and should start with "unix:".

=back

=head2 Google::Cloud::Networksecurity::V1beta1::Tls::ValidationCA

Specification of ValidationCA. Defines the mechanism to obtain the
Certificate Authority certificate to validate the peer certificate.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->grpc_endpoint() >> / C<< $msg->grpc_endpoint($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::Tls::GrpcEndpoint>)

gRPC specific configuration to access the gRPC server to
obtain the CA certificate.

=item * C<< $msg->certificate_provider_instance() >> / C<< $msg->certificate_provider_instance($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::Tls::CertificateProviderInstance>)

The certificate provider instance specification that will be passed to
the data plane, which will be used to load necessary credential
information.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::Tls::CertificateProviderInstance

Specification of a TLS certificate provider instance. Workloads may have one
or more CertificateProvider instances (plugins) and one of them is enabled
and configured by specifying this message. Workloads use the values from this
message to locate and load the CertificateProvider instance configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->plugin_instance() >> / C<< $msg->plugin_instance($value) >>

Type: C<String>

Required. Plugin instance name, used to locate and load CertificateProvider
instance configuration. Set to "google_cloud_private_spiffe" to use
Certificate Authority Service certificate provider instance.

=back

=head2 Google::Cloud::Networksecurity::V1beta1::Tls::CertificateProvider

Specification of certificate provider. Defines the mechanism to obtain the
certificate and private key for peer to peer authentication.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->grpc_endpoint() >> / C<< $msg->grpc_endpoint($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::Tls::GrpcEndpoint>)

gRPC specific configuration to access the gRPC server to
obtain the cert and private key.

=item * C<< $msg->certificate_provider_instance() >> / C<< $msg->certificate_provider_instance($value) >>

Type: C<Message> (L<Google::Cloud::Networksecurity::V1beta1::Tls::CertificateProviderInstance>)

The certificate provider instance specification that will be passed to
the data plane, which will be used to load necessary credential
information.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Networksecurity::V1beta1::Tls::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
