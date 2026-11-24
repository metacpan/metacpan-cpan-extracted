package Google::Cloud::Agentregistry::V1::Endpoint;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Agentregistry::V1::Properties };
    eval { require Google::Protobuf::Struct };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYWdlbnRyZWdpc3RyeS92MS9lbmRwb2ludC5wcm90bxIdZ29vZ2xl
LmNsb3VkLmFnZW50cmVnaXN0cnkudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aLmdvb2dsZS9jbG91ZC9hZ2VudHJlZ2lz
dHJ5L3YxL3Byb3BlcnRpZXMucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1Y3QucHJvdG8a
H2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8igAYKCEVuZHBvaW50EhcKBG5hbWUY
ASABKAlCA+BBCFIEbmFtZRIkCgtlbmRwb2ludF9pZBgIIAEoCUID4EEDUgplbmRwb2ludElk
EiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EEDUgtkaXNwbGF5TmFtZRIlCgtkZXNjcmlwdGlv
bhgDIAEoCUID4EEDUgtkZXNjcmlwdGlvbhJNCgppbnRlcmZhY2VzGAQgAygLMiguZ29vZ2xl
LmNsb3VkLmFnZW50cmVnaXN0cnkudjEuSW50ZXJmYWNlQgPgQQJSCmludGVyZmFjZXMSQAoL
Y3JlYXRlX3RpbWUYBSABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNy
ZWF0ZVRpbWUSQAoLdXBkYXRlX3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0
YW1wQgPgQQNSCnVwZGF0ZVRpbWUSXAoKYXR0cmlidXRlcxgHIAMoCzI3Lmdvb2dsZS5jbG91
ZC5hZ2VudHJlZ2lzdHJ5LnYxLkVuZHBvaW50LkF0dHJpYnV0ZXNFbnRyeUID4EEDUgphdHRy
aWJ1dGVzGlYKD0F0dHJpYnV0ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRItCgV2YWx1ZRgC
IAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSBXZhbHVlOgI4ATrcAepB2AEKJWFnZW50
cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vRW5kcG9pbnQSPHByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9lbmRwb2ludHMve2VuZHBvaW50fRJccHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FpQXBwbGljYXRpb25zL3thaV9hcHBsaWNh
dGlvbn0vZW5kcG9pbnRzL3tlbmRwb2ludH0qCWVuZHBvaW50czIIZW5kcG9pbnRC4AEKIWNv
bS5nb29nbGUuY2xvdWQuYWdlbnRyZWdpc3RyeS52MUINRW5kcG9pbnRQcm90b1ABWkdjbG91
ZC5nb29nbGUuY29tL2dvL2FnZW50cmVnaXN0cnkvYXBpdjEvYWdlbnRyZWdpc3RyeXBiO2Fn
ZW50cmVnaXN0cnlwYqoCHUdvb2dsZS5DbG91ZC5BZ2VudFJlZ2lzdHJ5LlYxygIdR29vZ2xl
XENsb3VkXEFnZW50UmVnaXN0cnlcVjHqAiBHb29nbGU6OkNsb3VkOjpBZ2VudFJlZ2lzdHJ5
OjpWMUqlEQoGEgQOAEsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAmCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA4CgkKAgMDEgMVACYKCQoC
AwQSAxYAKQoICgEIEgMYADoKCQoCCCUSAxgAOgoICgEIEgMZAF4KCQoCCAsSAxkAXgoICgEI
EgMaACIKCQoCCAoSAxoAIgoICgEIEgMbAC4KCQoCCAgSAxsALgoICgEIEgMcADoKCQoCCAES
AxwAOgoICgEIEgMdADoKCQoCCCkSAx0AOgoICgEIEgMeADkKCQoCCC0SAx4AOQolCgIEABIE
IQBLARoZIFJlcHJlc2VudHMgYW4gRW5kcG9pbnQuCgoKCgMEAAESAyEIEAoLCgMEAAcSBCIC
KAQKDQoFBAAHnQgSBCICKAQKhgEKBAQAAgASAywCPRp5IElkZW50aWZpZXIuIFRoZSByZXNv
dXJjZSBuYW1lIG9mIHRoZSBFbmRwb2ludC4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0
fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9lbmRwb2ludHMve2VuZHBvaW50fWAuCgoMCgUEAAIA
BRIDLAIICgwKBQQAAgABEgMsCQ0KDAoFBAACAAMSAywQEQoMCgUEAAIACBIDLBI8Cg8KCAQA
AgAInAgAEgMsEzsKTgoEBAACARIDLwJFGkEgT3V0cHV0IG9ubHkuIEEgc3RhYmxlLCBnbG9i
YWxseSB1bmlxdWUgaWRlbnRpZmllciBmb3IgRW5kcG9pbnQuCgoMCgUEAAIBBRIDLwIICgwK
BQQAAgEBEgMvCRQKDAoFBAACAQMSAy8XGAoMCgUEAAIBCBIDLxlECg8KCAQAAgEInAgAEgMv
GkMKOgoEBAACAhIDMgJGGi0gT3V0cHV0IG9ubHkuIERpc3BsYXkgbmFtZSBmb3IgdGhlIEVu
ZHBvaW50LgoKDAoFBAACAgUSAzICCAoMCgUEAAICARIDMgkVCgwKBQQAAgIDEgMyGBkKDAoF
BAACAggSAzIaRQoPCggEAAICCJwIABIDMhtECjcKBAQAAgMSAzUCRRoqIE91dHB1dCBvbmx5
LiBEZXNjcmlwdGlvbiBvZiBhbiBFbmRwb2ludC4KCgwKBQQAAgMFEgM1AggKDAoFBAACAwES
AzUJFAoMCgUEAAIDAxIDNRcYCgwKBQQAAgMIEgM1GUQKDwoIBAACAwicCAASAzUaQwpBCgQE
AAIEEgM4Ak0aNCBSZXF1aXJlZC4gVGhlIGNvbm5lY3Rpb24gZGV0YWlscyBmb3IgdGhlIEVu
ZHBvaW50LgoKDAoFBAACBAQSAzgCCgoMCgUEAAIEBhIDOAsUCgwKBQQAAgQBEgM4FR8KDAoF
BAACBAMSAzgiIwoMCgUEAAIECBIDOCRMCg8KCAQAAgQInAgAEgM4JUsKKQoEBAACBRIEOwI8
MhobIE91dHB1dCBvbmx5LiBDcmVhdGUgdGltZS4KCgwKBQQAAgUGEgM7AhsKDAoFBAACBQES
AzscJwoMCgUEAAIFAxIDOyorCgwKBQQAAgUIEgM8BjEKDwoIBAACBQicCAASAzwHMAopCgQE
AAIGEgQ/AkAyGhsgT3V0cHV0IG9ubHkuIFVwZGF0ZSB0aW1lLgoKDAoFBAACBgYSAz8CGwoM
CgUEAAIGARIDPxwnCgwKBQQAAgYDEgM/KisKDAoFBAACBggSA0AGMQoPCggEAAIGCJwIABID
QAcwCvsBCgQEAAIHEgRJAkoyGuwBIE91dHB1dCBvbmx5LiBBdHRyaWJ1dGVzIG9mIHRoZSBF
bmRwb2ludC4KCiBWYWxpZCB2YWx1ZXM6CgogICogYGFnZW50cmVnaXN0cnkuZ29vZ2xlYXBp
cy5jb20vc3lzdGVtL1J1bnRpbWVSZWZlcmVuY2VgOgogICAgeyJ1cmkiOiAiLy8uLi4ifSAt
IHRoZSBVUkkgb2YgdGhlIHVuZGVybHlpbmcgcmVzb3VyY2UgaG9zdGluZyB0aGUKICAgIEVu
ZHBvaW50LCBmb3IgZXhhbXBsZSwgdGhlIEdLRSBEZXBsb3ltZW50LgoKDAoFBAACBwYSA0kC
JQoMCgUEAAIHARIDSSYwCgwKBQQAAgcDEgNJMzQKDAoFBAACBwgSA0oGMQoPCggEAAIHCJwI
ABIDSgcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Agentregistry::V1::Endpoint::Endpoint ===
    # Fields for Endpoint
    # Field: name Type: 9 ()
    # Field: endpoint_id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: interfaces Type: 11 (.google.cloud.agentregistry.v1.Interface)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: attributes Type: 11 (.google.cloud.agentregistry.v1.Endpoint.AttributesEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Agentregistry::V1::Endpoint - Compiled Protocol Buffers messages for google/cloud/agentregistry/v1/endpoint.proto

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::Endpoint;

    my $msg = Google::Cloud::Agentregistry::V1::Endpoint::Endpoint->new({
        name => $name,
        endpoint_id => $endpoint_id,
        display_name => $display_name,
        description => $description,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Agentregistry::V1::Endpoint::Endpoint->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/agentregistry/v1/endpoint.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Agentregistry::V1::Endpoint::Endpoint

Represents an Endpoint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the Endpoint.
Format: `projects/{project}/locations/{location}/endpoints/{endpoint}`.

=item * C<< $msg->endpoint_id() >> / C<< $msg->endpoint_id($value) >>

Type: C<String>

Output only. A stable, globally unique identifier for Endpoint.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. Display name for the Endpoint.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. Description of an Endpoint.

=item * C<< $msg->interfaces() >> / C<< $msg->interfaces($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Properties::Interface>)

Required. The connection details for the Endpoint.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Create time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Update time.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Agentregistry::V1::Endpoint::Endpoint::AttributesEntry>)

Output only. Attributes of the Endpoint.

Valid values:

 * `agentregistry.googleapis.com/system/RuntimeReference`:
   {"uri": "//..."} - the URI of the underlying resource hosting the
   Endpoint, for example, the GKE Deployment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Agentregistry::V1::Endpoint::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
