package Google::Cloud::Visionai::V1alpha1::Common;

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
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjFhbHBoYTEvY29tbW9uLnByb3RvEh5nb29nbGUu
Y2xvdWQudmlzaW9uYWkudjFhbHBoYTEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3Rh
bXAucHJvdG8itQYKB0NsdXN0ZXISFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEkAKC2NyZWF0
ZV90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVU
aW1lEkAKC3VwZGF0ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgp1cGRhdGVUaW1lEksKBmxhYmVscxgEIAMoCzIzLmdvb2dsZS5jbG91ZC52aXNpb25h
aS52MWFscGhhMS5DbHVzdGVyLkxhYmVsc0VudHJ5UgZsYWJlbHMSWgoLYW5ub3RhdGlvbnMY
BSADKAsyOC5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQ2x1c3Rlci5Bbm5vdGF0
aW9uc0VudHJ5Ugthbm5vdGF0aW9ucxJBChpkYXRhcGxhbmVfc2VydmljZV9lbmRwb2ludBgG
IAEoCUID4EEDUhhkYXRhcGxhbmVTZXJ2aWNlRW5kcG9pbnQSSAoFc3RhdGUYByABKA4yLS5n
b29nbGUuY2xvdWQudmlzaW9uYWkudjFhbHBoYTEuQ2x1c3Rlci5TdGF0ZUID4EEDUgVzdGF0
ZRIiCgpwc2NfdGFyZ2V0GAggASgJQgPgQQNSCXBzY1RhcmdldBo5CgtMYWJlbHNFbnRyeRIQ
CgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGj4KEEFubm90YXRp
b25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASJW
CgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEhAKDFBST1ZJU0lPTklORxABEgsKB1JV
Tk5JTkcQAhIMCghTVE9QUElORxADEgkKBUVSUk9SEAQ6YOpBXQofdmlzaW9uYWkuZ29vZ2xl
YXBpcy5jb20vQ2x1c3RlchI6cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRp
b259L2NsdXN0ZXJzL3tjbHVzdGVyfSLVAgoRT3BlcmF0aW9uTWV0YWRhdGESQAoLY3JlYXRl
X3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRp
bWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNS
B2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNSBnRhcmdldBIXCgR2ZXJiGAQgASgJQgPg
QQNSBHZlcmISKgoOc3RhdHVzX21lc3NhZ2UYBSABKAlCA+BBA1INc3RhdHVzTWVzc2FnZRI6
ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0aW9uGAYgASgIQgPgQQNSFXJlcXVlc3RlZENhbmNlbGxh
dGlvbhIkCgthcGlfdmVyc2lvbhgHIAEoCUID4EEDUgphcGlWZXJzaW9uIiQKCUdjc1NvdXJj
ZRIXCgR1cmlzGAEgAygJQgPgQQJSBHVyaXNC2QEKImNvbS5nb29nbGUuY2xvdWQudmlzaW9u
YWkudjFhbHBoYTFCC0NvbW1vblByb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vdmlzaW9u
YWkvYXBpdjFhbHBoYTEvdmlzaW9uYWlwYjt2aXNpb25haXBiqgIeR29vZ2xlLkNsb3VkLlZp
c2lvbkFJLlYxQWxwaGExygIeR29vZ2xlXENsb3VkXFZpc2lvbkFJXFYxYWxwaGEx6gIhR29v
Z2xlOjpDbG91ZDo6VmlzaW9uQUk6OlYxYWxwaGExStofCgYSBA4AcQEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAj
CgkKAgMCEgMUACkKCAoBCBIDFgA7CgkKAgglEgMWADsKCAoBCBIDFwBVCgkKAggLEgMXAFUK
CAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQAsCgkKAggIEgMZACwKCAoBCBIDGgA7CgkK
AggBEgMaADsKCAoBCBIDGwA7CgkKAggpEgMbADsKCAoBCBIDHAA6CgkKAggtEgMcADoKNAoC
BAASBB8AUAEaKCBNZXNzYWdlIGRlc2NyaWJpbmcgdGhlIENsdXN0ZXIgb2JqZWN0LgoKCgoD
BAABEgMfCA8KCwoDBAAHEgQgAiMECg0KBQQAB50IEgQgAiMECjEKBAQABAASBCYCNwMaIyBU
aGUgY3VycmVudCBzdGF0ZSBvZiB0aGUgY2x1c3Rlci4KCgwKBQQABAABEgMmBwwKGQoGBAAE
AAIAEgMoBBoaCiBOb3Qgc2V0LgoKDgoHBAAEAAIAARIDKAQVCg4KBwQABAACAAISAygYGQpP
CgYEAAQAAgESAysEFRpAIFRoZSBQUk9WSVNJT05JTkcgc3RhdGUgaW5kaWNhdGVzIHRoZSBj
bHVzdGVyIGlzIGJlaW5nIGNyZWF0ZWQuCgoOCgcEAAQAAgEBEgMrBBAKDgoHBAAEAAIBAhID
KxMUCl8KBgQABAACAhIDLwQQGlAgVGhlIFJVTk5JTkcgc3RhdGUgaW5kaWNhdGVzIHRoZSBj
bHVzdGVyIGhhcyBiZWVuIGNyZWF0ZWQgYW5kIGlzIGZ1bGx5CiB1c2FibGUuCgoOCgcEAAQA
AgIBEgMvBAsKDgoHBAAEAAICAhIDLw4PCksKBgQABAACAxIDMgQRGjwgVGhlIFNUT1BQSU5H
IHN0YXRlIGluZGljYXRlcyB0aGUgY2x1c3RlciBpcyBiZWluZyBkZWxldGVkLgoKDgoHBAAE
AAIDARIDMgQMCg4KBwQABAACAwISAzIPEApmCgYEAAQAAgQSAzYEDhpXIFRoZSBFUlJPUiBz
dGF0ZSBpbmRpY2F0ZXMgdGhlIGNsdXN0ZXIgaXMgdW51c2FibGUuIEl0IHdpbGwgYmUKIGF1
dG9tYXRpY2FsbHkgZGVsZXRlZC4KCg4KBwQABAACBAESAzYECQoOCgcEAAQAAgQCEgM2DA0K
MQoEBAACABIDOgI+GiQgT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHJlc291cmNlLgoKDAoF
BAACAAUSAzoCCAoMCgUEAAIAARIDOgkNCgwKBQQAAgADEgM6EBEKDAoFBAACAAgSAzoSPQoP
CggEAAIACJwIABIDOhM8CjEKBAQAAgESAz0CWBokIE91dHB1dCBvbmx5LiBUaGUgY3JlYXRl
IHRpbWVzdGFtcC4KCgwKBQQAAgEGEgM9AhsKDAoFBAACAQESAz0cJwoMCgUEAAIBAxIDPSor
CgwKBQQAAgEIEgM9LFcKDwoIBAACAQicCAASAz0tVgoxCgQEAAICEgNAAlgaJCBPdXRwdXQg
b25seS4gVGhlIHVwZGF0ZSB0aW1lc3RhbXAuCgoMCgUEAAICBhIDQAIbCgwKBQQAAgIBEgNA
HCcKDAoFBAACAgMSA0AqKwoMCgUEAAICCBIDQCxXCg8KCAQAAgIInAgAEgNALVYKKAoEBAAC
AxIDQwIhGhsgTGFiZWxzIGFzIGtleSB2YWx1ZSBwYWlycwoKDAoFBAACAwYSA0MCFQoMCgUE
AAIDARIDQxYcCgwKBQQAAgMDEgNDHyAKVQoEBAACBBIDRgImGkggQW5ub3RhdGlvbnMgdG8g
YWxsb3cgY2xpZW50cyB0byBzdG9yZSBzbWFsbCBhbW91bnRzIG9mIGFyYml0cmFyeSBkYXRh
LgoKDAoFBAACBAYSA0YCFQoMCgUEAAIEARIDRhYhCgwKBQQAAgQDEgNGJCUKQgoEBAACBRID
SQJUGjUgT3V0cHV0IG9ubHkuIFRoZSBETlMgbmFtZSBvZiB0aGUgZGF0YSBwbGFuZSBzZXJ2
aWNlCgoMCgUEAAIFBRIDSQIICgwKBQQAAgUBEgNJCSMKDAoFBAACBQMSA0kmJwoMCgUEAAIF
CBIDSShTCg8KCAQAAgUInAgAEgNJKVIKPQoEBAACBhIDTAI+GjAgT3V0cHV0IG9ubHkuIFRo
ZSBjdXJyZW50IHN0YXRlIG9mIHRoZSBjbHVzdGVyLgoKDAoFBAACBgYSA0wCBwoMCgUEAAIG
ARIDTAgNCgwKBQQAAgYDEgNMEBEKDAoFBAACBggSA0wSPQoPCggEAAIGCJwIABIDTBM8Ck8K
BAQAAgcSA08CRBpCIE91dHB1dCBvbmx5LiBUaGUgcHJpdmF0ZSBzZXJ2aWNlIGNvbm5lY3Rp
b24gc2VydmljZSB0YXJnZXQgbmFtZS4KCgwKBQQAAgcFEgNPAggKDAoFBAACBwESA08JEwoM
CgUEAAIHAxIDTxYXCgwKBQQAAgcIEgNPGEMKDwoIBAACBwicCAASA08ZQgpECgIEARIEUwBr
ARo4IFJlcHJlc2VudHMgdGhlIG1ldGFkYXRhIG9mIHRoZSBsb25nLXJ1bm5pbmcgb3BlcmF0
aW9uLgoKCgoDBAEBEgNTCBkKPwoEBAECABIDVQJYGjIgT3V0cHV0IG9ubHkuIFRoZSB0aW1l
IHRoZSBvcGVyYXRpb24gd2FzIGNyZWF0ZWQuCgoMCgUEAQIABhIDVQIbCgwKBQQBAgABEgNV
HCcKDAoFBAECAAMSA1UqKwoMCgUEAQIACBIDVSxXCg8KCAQBAgAInAgAEgNVLVYKRAoEBAEC
ARIDWAJVGjcgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIHRoZSBvcGVyYXRpb24gZmluaXNoZWQg
cnVubmluZy4KCgwKBQQBAgEGEgNYAhsKDAoFBAECAQESA1gcJAoMCgUEAQIBAxIDWCcoCgwK
BQQBAgEIEgNYKVQKDwoIBAECAQicCAASA1gqUwpZCgQEAQICEgNbAkAaTCBPdXRwdXQgb25s
eS4gU2VydmVyLWRlZmluZWQgcmVzb3VyY2UgcGF0aCBmb3IgdGhlIHRhcmdldCBvZiB0aGUg
b3BlcmF0aW9uLgoKDAoFBAECAgUSA1sCCAoMCgUEAQICARIDWwkPCgwKBQQBAgIDEgNbEhMK
DAoFBAECAggSA1sUPwoPCggEAQICCJwIABIDWxU+CkcKBAQBAgMSA14CPho6IE91dHB1dCBv
bmx5LiBOYW1lIG9mIHRoZSB2ZXJiIGV4ZWN1dGVkIGJ5IHRoZSBvcGVyYXRpb24uCgoMCgUE
AQIDBRIDXgIICgwKBQQBAgMBEgNeCQ0KDAoFBAECAwMSA14QEQoMCgUEAQIDCBIDXhI9Cg8K
CAQBAgMInAgAEgNeEzwKSwoEBAECBBIDYQJIGj4gT3V0cHV0IG9ubHkuIEh1bWFuLXJlYWRh
YmxlIHN0YXR1cyBvZiB0aGUgb3BlcmF0aW9uLCBpZiBhbnkuCgoMCgUEAQIEBRIDYQIICgwK
BQQBAgQBEgNhCRcKDAoFBAECBAMSA2EaGwoMCgUEAQIECBIDYRxHCg8KCAQBAgQInAgAEgNh
HUYKmQIKBAQBAgUSA2cCThqLAiBPdXRwdXQgb25seS4gSWRlbnRpZmllcyB3aGV0aGVyIHRo
ZSB1c2VyIGhhcyByZXF1ZXN0ZWQgY2FuY2VsbGF0aW9uCiBvZiB0aGUgb3BlcmF0aW9uLiBP
cGVyYXRpb25zIHRoYXQgaGF2ZSBzdWNjZXNzZnVsbHkgYmVlbiBjYW5jZWxsZWQKIGhhdmUg
W09wZXJhdGlvbi5lcnJvcl1bXSB2YWx1ZSB3aXRoIGEgW2dvb2dsZS5ycGMuU3RhdHVzLmNv
ZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIDEsCiBjb3JyZXNwb25kaW5nIHRvIGBD
b2RlLkNBTkNFTExFRGAuCgoMCgUEAQIFBRIDZwIGCgwKBQQBAgUBEgNnBx0KDAoFBAECBQMS
A2cgIQoMCgUEAQIFCBIDZyJNCg8KCAQBAgUInAgAEgNnI0wKRAoEBAECBhIDagJFGjcgT3V0
cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCgwK
BQQBAgYFEgNqAggKDAoFBAECBgESA2oJFAoMCgUEAQIGAxIDahcYCgwKBQQBAgYIEgNqGUQK
DwoIBAECBgicCAASA2oaQwpGCgIEAhIEbgBxARo6IFRoZSBHb29nbGUgQ2xvdWQgU3RvcmFn
ZSBsb2NhdGlvbiBmb3IgdGhlIGlucHV0IGNvbnRlbnQuCgoKCgMEAgESA24IEQpECgQEAgIA
EgNwAkQaNyBSZXF1aXJlZC4gUmVmZXJlbmNlcyB0byBhIEdvb2dsZSBDbG91ZCBTdG9yYWdl
IHBhdGhzLgoKDAoFBAICAAQSA3ACCgoMCgUEAgIABRIDcAsRCgwKBQQCAgABEgNwEhYKDAoF
BAICAAMSA3AZGgoMCgUEAgIACBIDcBtDCg8KCAQCAgAInAgAEgNwHEJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1alpha1::Common::Cluster ===
    # Fields for Cluster
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1alpha1.Cluster.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.visionai.v1alpha1.Cluster.AnnotationsEntry)
    # Field: dataplane_service_endpoint Type: 9 ()
    # Field: state Type: 14 (.google.cloud.visionai.v1alpha1.Cluster.State)
    # Field: psc_target Type: 9 ()

# Enum: Cluster::State
our $Cluster_STATE_UNSPECIFIED = 0;
our $Cluster_PROVISIONING = 1;
our $Cluster_RUNNING = 2;
our $Cluster_STOPPING = 3;
our $Cluster_ERROR = 4;

# === Message: Google::Cloud::Visionai::V1alpha1::Common::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Cloud::Visionai::V1alpha1::Common::GcsSource ===
    # Fields for GcsSource
    # Field: uris Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1alpha1::Common - Compiled Protocol Buffers messages for google/cloud/visionai/v1alpha1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1alpha1::Common;

    my $msg = Google::Cloud::Visionai::V1alpha1::Common::Cluster->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1alpha1::Common::Cluster->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1alpha1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1alpha1::Common::Cluster

Message describing the Cluster object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Name of the resource.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The create timestamp.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The update timestamp.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::Common::Cluster::LabelsEntry>)

Labels as key value pairs

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1alpha1::Common::Cluster::AnnotationsEntry>)

Annotations to allow clients to store small amounts of arbitrary data.

=item * C<< $msg->dataplane_service_endpoint() >> / C<< $msg->dataplane_service_endpoint($value) >>

Type: C<String>

Output only. The DNS name of the data plane service

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Visionai::V1alpha1::Cluster::State>)

Output only. The current state of the cluster.

=item * C<< $msg->psc_target() >> / C<< $msg->psc_target($value) >>

Type: C<String>

Output only. The private service connection service target name.

=back

=head3 Enum: Cluster::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PROVISIONING> => C<1>

=item * C<RUNNING> => C<2>

=item * C<STOPPING> => C<3>

=item * C<ERROR> => C<4>

=back

=head2 Google::Cloud::Visionai::V1alpha1::Common::OperationMetadata

Represents the metadata of the long-running operation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation was created.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time the operation finished running.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

Output only. Server-defined resource path for the target of the operation.

=item * C<< $msg->verb() >> / C<< $msg->verb($value) >>

Type: C<String>

Output only. Name of the verb executed by the operation.

=item * C<< $msg->status_message() >> / C<< $msg->status_message($value) >>

Type: C<String>

Output only. Human-readable status of the operation, if any.

=item * C<< $msg->requested_cancellation() >> / C<< $msg->requested_cancellation($value) >>

Type: C<Bool>

Output only. Identifies whether the user has requested cancellation
of the operation. Operations that have successfully been cancelled
have [Operation.error][] value with a [google.rpc.Status.code][google.rpc.Status.code] of 1,
corresponding to `Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head2 Google::Cloud::Visionai::V1alpha1::Common::GcsSource

The Google Cloud Storage location for the input content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uris() >> / C<< $msg->uris($value) >>

Type: C<String>

Required. References to a Google Cloud Storage paths.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1alpha1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
