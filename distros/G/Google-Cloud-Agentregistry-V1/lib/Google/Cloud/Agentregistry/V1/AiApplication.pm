package Google::Cloud::Agentregistry::V1::AiApplication;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::FieldInfo };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Apphub::V1::Application };
    eval { require Google::Cloud::Apphub::V1::Attributes };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvYWdlbnRyZWdpc3RyeS92MS9haV9hcHBsaWNhdGlvbi5wcm90bxId
Z29vZ2xlLmNsb3VkLmFnZW50cmVnaXN0cnkudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aG2dvb2dsZS9hcGkvZmllbGRfaW5mby5wcm90bxoZZ29vZ2xlL2FwaS9yZXNv
dXJjZS5wcm90bxooZ29vZ2xlL2Nsb3VkL2FwcGh1Yi92MS9hcHBsaWNhdGlvbi5wcm90bxon
Z29vZ2xlL2Nsb3VkL2FwcGh1Yi92MS9hdHRyaWJ1dGVzLnByb3RvGh9nb29nbGUvcHJvdG9i
dWYvdGltZXN0YW1wLnByb3RvIoAGCg1BaUFwcGxpY2F0aW9uEhcKBG5hbWUYASABKAlCA+BB
CFIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAVILZGlzcGxheU5hbWUSJQoLZGVz
Y3JpcHRpb24YAyABKAlCA+BBAVILZGVzY3JpcHRpb24SHQoDdWlkGAQgASgJQgvijM/XCAII
AeBBA1IDdWlkEkAKC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz
dGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnBy
b3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEk0KBXN0YXRlGAcgASgOMjIuZ29v
Z2xlLmNsb3VkLmFnZW50cmVnaXN0cnkudjEuQWlBcHBsaWNhdGlvbi5TdGF0ZUID4EEDUgVz
dGF0ZRJHCgphdHRyaWJ1dGVzGAggASgLMiIuZ29vZ2xlLmNsb3VkLmFwcGh1Yi52MS5BdHRy
aWJ1dGVzQgPgQQFSCmF0dHJpYnV0ZXMSaQoWYXBwbGljYXRpb25fcHJvcGVydGllcxgJIAEo
CzItLmdvb2dsZS5jbG91ZC5hcHBodWIudjEuQXBwbGljYXRpb25Qcm9wZXJ0aWVzQgPgQQNS
FWFwcGxpY2F0aW9uUHJvcGVydGllcyJGCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAA
EgwKCENSRUFUSU5HEAESCgoGQUNUSVZFEAISDAoIREVMRVRJTkcQAzqYAepBlAEKKmFnZW50
cmVnaXN0cnkuZ29vZ2xlYXBpcy5jb20vQWlBcHBsaWNhdGlvbhJHcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FpQXBwbGljYXRpb25zL3thaV9hcHBsaWNhdGlv
bn0qDmFpQXBwbGljYXRpb25zMg1haUFwcGxpY2F0aW9uQuUBCiFjb20uZ29vZ2xlLmNsb3Vk
LmFnZW50cmVnaXN0cnkudjFCEkFpQXBwbGljYXRpb25Qcm90b1ABWkdjbG91ZC5nb29nbGUu
Y29tL2dvL2FnZW50cmVnaXN0cnkvYXBpdjEvYWdlbnRyZWdpc3RyeXBiO2FnZW50cmVnaXN0
cnlwYqoCHUdvb2dsZS5DbG91ZC5BZ2VudFJlZ2lzdHJ5LlYxygIdR29vZ2xlXENsb3VkXEFn
ZW50UmVnaXN0cnlcVjHqAiBHb29nbGU6OkNsb3VkOjpBZ2VudFJlZ2lzdHJ5OjpWMUqtFQoG
EgQOAF0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAmCgkK
AgMAEgMSACkKCQoCAwESAxMAJQoJCgIDAhIDFAAjCgkKAgMDEgMVADIKCQoCAwQSAxYAMQoJ
CgIDBRIDFwApCggKAQgSAxkAOgoJCgIIJRIDGQA6CggKAQgSAxoAXgoJCgIICxIDGgBeCggK
AQgSAxsAIgoJCgIIChIDGwAiCggKAQgSAxwAMwoJCgIICBIDHAAzCggKAQgSAx0AOgoJCgII
ARIDHQA6CggKAQgSAx4AOgoJCgIIKRIDHgA6CggKAQgSAx8AOQoJCgIILRIDHwA5CisKAgQA
EgQiAF0BGh8gUmVwcmVzZW50cyBhbiBBSSBBcHBsaWNhdGlvbi4KCgoKAwQAARIDIggVCgsK
AwQABxIEIwIoBAoNCgUEAAedCBIEIwIoBAo6CgQEAAQAEgQrAjcDGiwgVGhlIGxpZmVjeWNs
ZSBzdGF0ZXMgb2YgYW4gQUkgQXBwbGljYXRpb24uCgoMCgUEAAQAARIDKwcMCjUKBgQABAAC
ABIDLQQaGiYgRGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoOCgcEAAQA
AgABEgMtBBUKDgoHBAAEAAIAAhIDLRgZCj4KBgQABAACARIDMAQRGi8gVGhlIHJlc291cmNl
IGlzIGJlaW5nIHByb3Zpc2lvbmVkIG9yIGNyZWF0ZWQuCgoOCgcEAAQAAgEBEgMwBAwKDgoH
BAAEAAIBAhIDMA8QCjoKBgQABAACAhIDMwQPGisgVGhlIHJlc291cmNlIGlzIGFjdGl2ZSBh
bmQgcmVhZHkgZm9yIHVzZS4KCg4KBwQABAACAgESAzMECgoOCgcEAAQAAgICEgMzDQ4KQQoG
BAAEAAIDEgM2BBEaMiBUaGUgcmVzb3VyY2UgaXMgaW4gdGhlIHByb2Nlc3Mgb2YgYmVpbmcg
ZGVsZXRlZC4KCg4KBwQABAACAwESAzYEDAoOCgcEAAQAAgMCEgM2DxAKlAEKBAQAAgASAzwC
PRqGASBJZGVudGlmaWVyLiBSZXNvdXJjZSBuYW1lIG9mIHRoZSBBSSBBcHBsaWNhdGlvbi4K
IEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWlB
cHBsaWNhdGlvbnMve2FpX2FwcGxpY2F0aW9ufWAKCgwKBQQAAgAFEgM8AggKDAoFBAACAAES
AzwJDQoMCgUEAAIAAxIDPBARCgwKBQQAAgAIEgM8EjwKDwoIBAACAAicCAASAzwTOwpCCgQE
AAIBEgM/AkMaNSBPcHRpb25hbC4gVXNlci1kZWZpbmVkIG5hbWUgZm9yIHRoZSBBSSBBcHBs
aWNhdGlvbi4KCgwKBQQAAgEFEgM/AggKDAoFBAACAQESAz8JFQoMCgUEAAIBAxIDPxgZCgwK
BQQAAgEIEgM/GkIKDwoIBAACAQicCAASAz8bQQpICgQEAAICEgNCAkIaOyBPcHRpb25hbC4g
VXNlci1kZWZpbmVkIGRlc2NyaXB0aW9uIG9mIHRoZSBBSSBBcHBsaWNhdGlvbi4KCgwKBQQA
AgIFEgNCAggKDAoFBAACAgESA0IJFAoMCgUEAAICAxIDQhcYCgwKBQQAAgIIEgNCGUEKDwoI
BAACAgicCAASA0IaQApaCgQEAAIDEgRFAkgEGkwgT3V0cHV0IG9ubHkuIFVuaXZlcnNhbGx5
IHVuaXF1ZSBpZGVudGlmaWVyIChVVUlENCkgZm9yIHRoZSBBSSBBcHBsaWNhdGlvbi4KCgwK
BQQAAgMFEgNFAggKDAoFBAACAwESA0UJDAoMCgUEAAIDAxIDRQ8QCg0KBQQAAgMIEgRFEUgD
ChIKCwQAAgMIzPH5igEBEgNGBCoKDwoIBAACAwicCAASA0cELQorCgQEAAIEEgRLAkwyGh0g
T3V0cHV0IG9ubHkuIENyZWF0aW9uIHRpbWUuCgoMCgUEAAIEBhIDSwIbCgwKBQQAAgQBEgNL
HCcKDAoFBAACBAMSA0sqKwoMCgUEAAIECBIDTAYxCg8KCAQAAgQInAgAEgNMBzAKLgoEBAAC
BRIETwJQMhogIE91dHB1dCBvbmx5LiBMYXN0IHVwZGF0ZSB0aW1lLgoKDAoFBAACBQYSA08C
GwoMCgUEAAIFARIDTxwnCgwKBQQAAgUDEgNPKisKDAoFBAACBQgSA1AGMQoPCggEAAIFCJwI
ABIDUAcwCkQKBAQAAgYSA1MCPho3IE91dHB1dCBvbmx5LiBUaGUgY3VycmVudCBzdGF0ZSBv
ZiB0aGUgQUkgQXBwbGljYXRpb24uCgoMCgUEAAIGBhIDUwIHCgwKBQQAAgYBEgNTCA0KDAoF
BAACBgMSA1MQEQoMCgUEAAIGCBIDUxI9Cg8KCAQAAgYInAgAEgNTEzwKNwoEBAACBxIEVgJX
LxopIE9wdGlvbmFsLiBDb25zdW1lciBwcm92aWRlZCBhdHRyaWJ1dGVzLgoKDAoFBAACBwYS
A1YCIwoMCgUEAAIHARIDViQuCgwKBQQAAgcDEgNWMTIKDAoFBAACBwgSA1cGLgoPCggEAAIH
CJwIABIDVwctCm0KBAQAAggSBFsCXDIaXyBPdXRwdXQgb25seS4gUHJvcGVydGllcyBvZiBh
biB1bmRlcmx5aW5nIGNsb3VkIHJlc291cmNlIHRoYXQgY2FuIGNvbXByaXNlCiBhbiBBSSBB
cHBsaWNhdGlvbi4KCgwKBQQAAggGEgNbAi4KDAoFBAACCAESA1svRQoMCgUEAAIIAxIDW0hJ
CgwKBQQAAggIEgNcBjEKDwoIBAACCAicCAASA1wHMGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Agentregistry::V1::AiApplication::AiApplication ===
    # Fields for AiApplication
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: state Type: 14 (.google.cloud.agentregistry.v1.AiApplication.State)
    # Field: attributes Type: 11 (.google.cloud.apphub.v1.Attributes)
    # Field: application_properties Type: 11 (.google.cloud.apphub.v1.ApplicationProperties)

# Enum: AiApplication::State
our $AiApplication_STATE_UNSPECIFIED = 0;
our $AiApplication_CREATING = 1;
our $AiApplication_ACTIVE = 2;
our $AiApplication_DELETING = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Agentregistry::V1::AiApplication - Compiled Protocol Buffers messages for google/cloud/agentregistry/v1/ai_application.proto

=head1 SYNOPSIS

    use Google::Cloud::Agentregistry::V1::AiApplication;

    my $msg = Google::Cloud::Agentregistry::V1::AiApplication::AiApplication->new({
        name => $name,
        display_name => $display_name,
        description => $description,
        uid => $uid,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Agentregistry::V1::AiApplication::AiApplication->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/agentregistry/v1/ai_application.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Agentregistry::V1::AiApplication::AiApplication

Represents an AI Application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. Resource name of the AI Application.
Format:
`projects/{project}/locations/{location}/aiApplications/{ai_application}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. User-defined name for the AI Application.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. User-defined description of the AI Application.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Universally unique identifier (UUID4) for the AI Application.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Last update time.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Agentregistry::V1::AiApplication::State>)

Output only. The current state of the AI Application.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Attributes::Attributes>)

Optional. Consumer provided attributes.

=item * C<< $msg->application_properties() >> / C<< $msg->application_properties($value) >>

Type: C<Message> (L<Google::Cloud::Apphub::V1::Application::ApplicationProperties>)

Output only. Properties of an underlying cloud resource that can comprise
an AI Application.

=back

=head3 Enum: AiApplication::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<CREATING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<DELETING> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Agentregistry::V1::AiApplication::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
