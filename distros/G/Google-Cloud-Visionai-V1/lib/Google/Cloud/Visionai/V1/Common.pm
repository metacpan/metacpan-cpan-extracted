package Google::Cloud::Visionai::V1::Common;

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
CiVnb29nbGUvY2xvdWQvdmlzaW9uYWkvdjEvY29tbW9uLnByb3RvEhhnb29nbGUuY2xvdWQu
dmlzaW9uYWkudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9h
cGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iowYK
B0NsdXN0ZXISFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEkAKC2NyZWF0ZV90aW1lGAIgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0
ZV90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgp1cGRhdGVU
aW1lEkUKBmxhYmVscxgEIAMoCzItLmdvb2dsZS5jbG91ZC52aXNpb25haS52MS5DbHVzdGVy
LkxhYmVsc0VudHJ5UgZsYWJlbHMSVAoLYW5ub3RhdGlvbnMYBSADKAsyMi5nb29nbGUuY2xv
dWQudmlzaW9uYWkudjEuQ2x1c3Rlci5Bbm5vdGF0aW9uc0VudHJ5Ugthbm5vdGF0aW9ucxJB
ChpkYXRhcGxhbmVfc2VydmljZV9lbmRwb2ludBgGIAEoCUID4EEDUhhkYXRhcGxhbmVTZXJ2
aWNlRW5kcG9pbnQSQgoFc3RhdGUYByABKA4yJy5nb29nbGUuY2xvdWQudmlzaW9uYWkudjEu
Q2x1c3Rlci5TdGF0ZUID4EEDUgVzdGF0ZRIiCgpwc2NfdGFyZ2V0GAggASgJQgPgQQNSCXBz
Y1RhcmdldBo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEo
CVIFdmFsdWU6AjgBGj4KEEFubm90YXRpb25zRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoF
dmFsdWUYAiABKAlSBXZhbHVlOgI4ASJWCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAA
EhAKDFBST1ZJU0lPTklORxABEgsKB1JVTk5JTkcQAhIMCghTVE9QUElORxADEgkKBUVSUk9S
EAQ6YOpBXQofdmlzaW9uYWkuZ29vZ2xlYXBpcy5jb20vQ2x1c3RlchI6cHJvamVjdHMve3By
b2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2NsdXN0ZXJzL3tjbHVzdGVyfSLVAgoRT3Bl
cmF0aW9uTWV0YWRhdGESQAoLY3JlYXRlX3RpbWUYASABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQNSB2VuZFRpbWUSGwoGdGFyZ2V0GAMgASgJQgPgQQNS
BnRhcmdldBIXCgR2ZXJiGAQgASgJQgPgQQNSBHZlcmISKgoOc3RhdHVzX21lc3NhZ2UYBSAB
KAlCA+BBA1INc3RhdHVzTWVzc2FnZRI6ChZyZXF1ZXN0ZWRfY2FuY2VsbGF0aW9uGAYgASgI
QgPgQQNSFXJlcXVlc3RlZENhbmNlbGxhdGlvbhIkCgthcGlfdmVyc2lvbhgHIAEoCUID4EED
UgphcGlWZXJzaW9uIiQKCUdjc1NvdXJjZRIXCgR1cmlzGAEgAygJQgPgQQJSBHVyaXNCuwEK
HGNvbS5nb29nbGUuY2xvdWQudmlzaW9uYWkudjFCC0NvbW1vblByb3RvUAFaOGNsb3VkLmdv
b2dsZS5jb20vZ28vdmlzaW9uYWkvYXBpdjEvdmlzaW9uYWlwYjt2aXNpb25haXBiqgIYR29v
Z2xlLkNsb3VkLlZpc2lvbkFJLlYxygIYR29vZ2xlXENsb3VkXFZpc2lvbkFJXFYx6gIbR29v
Z2xlOjpDbG91ZDo6VmlzaW9uQUk6OlYxSuAfCgYSBA4AdwEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMC
EgMUACkKCAoBCBIDFgA1CgkKAgglEgMWADUKCAoBCBIDFwBPCgkKAggLEgMXAE8KCAoBCBID
GAAiCgkKAggKEgMYACIKCAoBCBIDGQAsCgkKAggIEgMZACwKCAoBCBIDGgA1CgkKAggBEgMa
ADUKCAoBCBIDGwA1CgkKAggpEgMbADUKCAoBCBIDHAA0CgkKAggtEgMcADQKNAoCBAASBB8A
UwEaKCBNZXNzYWdlIGRlc2NyaWJpbmcgdGhlIENsdXN0ZXIgb2JqZWN0LgoKCgoDBAABEgMf
CA8KCwoDBAAHEgQgAiMECg0KBQQAB50IEgQgAiMECjEKBAQABAASBCYCNwMaIyBUaGUgY3Vy
cmVudCBzdGF0ZSBvZiB0aGUgY2x1c3Rlci4KCgwKBQQABAABEgMmBwwKGQoGBAAEAAIAEgMo
BBoaCiBOb3Qgc2V0LgoKDgoHBAAEAAIAARIDKAQVCg4KBwQABAACAAISAygYGQpPCgYEAAQA
AgESAysEFRpAIFRoZSBQUk9WSVNJT05JTkcgc3RhdGUgaW5kaWNhdGVzIHRoZSBjbHVzdGVy
IGlzIGJlaW5nIGNyZWF0ZWQuCgoOCgcEAAQAAgEBEgMrBBAKDgoHBAAEAAIBAhIDKxMUCl8K
BgQABAACAhIDLwQQGlAgVGhlIFJVTk5JTkcgc3RhdGUgaW5kaWNhdGVzIHRoZSBjbHVzdGVy
IGhhcyBiZWVuIGNyZWF0ZWQgYW5kIGlzIGZ1bGx5CiB1c2FibGUuCgoOCgcEAAQAAgIBEgMv
BAsKDgoHBAAEAAICAhIDLw4PCksKBgQABAACAxIDMgQRGjwgVGhlIFNUT1BQSU5HIHN0YXRl
IGluZGljYXRlcyB0aGUgY2x1c3RlciBpcyBiZWluZyBkZWxldGVkLgoKDgoHBAAEAAIDARID
MgQMCg4KBwQABAACAwISAzIPEApmCgYEAAQAAgQSAzYEDhpXIFRoZSBFUlJPUiBzdGF0ZSBp
bmRpY2F0ZXMgdGhlIGNsdXN0ZXIgaXMgdW51c2FibGUuIEl0IHdpbGwgYmUKIGF1dG9tYXRp
Y2FsbHkgZGVsZXRlZC4KCg4KBwQABAACBAESAzYECQoOCgcEAAQAAgQCEgM2DA0KMQoEBAAC
ABIDOgI+GiQgT3V0cHV0IG9ubHkuIE5hbWUgb2YgdGhlIHJlc291cmNlLgoKDAoFBAACAAUS
AzoCCAoMCgUEAAIAARIDOgkNCgwKBQQAAgADEgM6EBEKDAoFBAACAAgSAzoSPQoPCggEAAIA
CJwIABIDOhM8CjIKBAQAAgESBD0CPjIaJCBPdXRwdXQgb25seS4gVGhlIGNyZWF0ZSB0aW1l
c3RhbXAuCgoMCgUEAAIBBhIDPQIbCgwKBQQAAgEBEgM9HCcKDAoFBAACAQMSAz0qKwoMCgUE
AAIBCBIDPgYxCg8KCAQAAgEInAgAEgM+BzAKMgoEBAACAhIEQQJCMhokIE91dHB1dCBvbmx5
LiBUaGUgdXBkYXRlIHRpbWVzdGFtcC4KCgwKBQQAAgIGEgNBAhsKDAoFBAACAgESA0EcJwoM
CgUEAAICAxIDQSorCgwKBQQAAgIIEgNCBjEKDwoIBAACAgicCAASA0IHMAooCgQEAAIDEgNF
AiEaGyBMYWJlbHMgYXMga2V5IHZhbHVlIHBhaXJzCgoMCgUEAAIDBhIDRQIVCgwKBQQAAgMB
EgNFFhwKDAoFBAACAwMSA0UfIApVCgQEAAIEEgNIAiYaSCBBbm5vdGF0aW9ucyB0byBhbGxv
dyBjbGllbnRzIHRvIHN0b3JlIHNtYWxsIGFtb3VudHMgb2YgYXJiaXRyYXJ5IGRhdGEuCgoM
CgUEAAIEBhIDSAIVCgwKBQQAAgQBEgNIFiEKDAoFBAACBAMSA0gkJQpDCgQEAAIFEgRLAkwy
GjUgT3V0cHV0IG9ubHkuIFRoZSBETlMgbmFtZSBvZiB0aGUgZGF0YSBwbGFuZSBzZXJ2aWNl
CgoMCgUEAAIFBRIDSwIICgwKBQQAAgUBEgNLCSMKDAoFBAACBQMSA0smJwoMCgUEAAIFCBID
TAYxCg8KCAQAAgUInAgAEgNMBzAKPQoEBAACBhIDTwI+GjAgT3V0cHV0IG9ubHkuIFRoZSBj
dXJyZW50IHN0YXRlIG9mIHRoZSBjbHVzdGVyLgoKDAoFBAACBgYSA08CBwoMCgUEAAIGARID
TwgNCgwKBQQAAgYDEgNPEBEKDAoFBAACBggSA08SPQoPCggEAAIGCJwIABIDTxM8Ck8KBAQA
AgcSA1ICRBpCIE91dHB1dCBvbmx5LiBUaGUgcHJpdmF0ZSBzZXJ2aWNlIGNvbm5lY3Rpb24g
c2VydmljZSB0YXJnZXQgbmFtZS4KCgwKBQQAAgcFEgNSAggKDAoFBAACBwESA1IJEwoMCgUE
AAIHAxIDUhYXCgwKBQQAAgcIEgNSGEMKDwoIBAACBwicCAASA1IZQgpECgIEARIEVgBxARo4
IFJlcHJlc2VudHMgdGhlIG1ldGFkYXRhIG9mIHRoZSBsb25nLXJ1bm5pbmcgb3BlcmF0aW9u
LgoKCgoDBAEBEgNWCBkKQAoEBAECABIEWAJZMhoyIE91dHB1dCBvbmx5LiBUaGUgdGltZSB0
aGUgb3BlcmF0aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAECAAYSA1gCGwoMCgUEAQIAARIDWBwn
CgwKBQQBAgADEgNYKisKDAoFBAECAAgSA1kGMQoPCggEAQIACJwIABIDWQcwCkUKBAQBAgES
BFwCXTIaNyBPdXRwdXQgb25seS4gVGhlIHRpbWUgdGhlIG9wZXJhdGlvbiBmaW5pc2hlZCBy
dW5uaW5nLgoKDAoFBAECAQYSA1wCGwoMCgUEAQIBARIDXBwkCgwKBQQBAgEDEgNcJygKDAoF
BAECAQgSA10GMQoPCggEAQIBCJwIABIDXQcwClkKBAQBAgISA2ACQBpMIE91dHB1dCBvbmx5
LiBTZXJ2ZXItZGVmaW5lZCByZXNvdXJjZSBwYXRoIGZvciB0aGUgdGFyZ2V0IG9mIHRoZSBv
cGVyYXRpb24uCgoMCgUEAQICBRIDYAIICgwKBQQBAgIBEgNgCQ8KDAoFBAECAgMSA2ASEwoM
CgUEAQICCBIDYBQ/Cg8KCAQBAgIInAgAEgNgFT4KRwoEBAECAxIDYwI+GjogT3V0cHV0IG9u
bHkuIE5hbWUgb2YgdGhlIHZlcmIgZXhlY3V0ZWQgYnkgdGhlIG9wZXJhdGlvbi4KCgwKBQQB
AgMFEgNjAggKDAoFBAECAwESA2MJDQoMCgUEAQIDAxIDYxARCgwKBQQBAgMIEgNjEj0KDwoI
BAECAwicCAASA2MTPApLCgQEAQIEEgNmAkgaPiBPdXRwdXQgb25seS4gSHVtYW4tcmVhZGFi
bGUgc3RhdHVzIG9mIHRoZSBvcGVyYXRpb24sIGlmIGFueS4KCgwKBQQBAgQFEgNmAggKDAoF
BAECBAESA2YJFwoMCgUEAQIEAxIDZhobCgwKBQQBAgQIEgNmHEcKDwoIBAECBAicCAASA2Yd
RgqaAgoEBAECBRIDbQJOGowCIE91dHB1dCBvbmx5LiBJZGVudGlmaWVzIHdoZXRoZXIgdGhl
IHVzZXIgaGFzIHJlcXVlc3RlZCBjYW5jZWxsYXRpb24KIG9mIHRoZSBvcGVyYXRpb24uIE9w
ZXJhdGlvbnMgdGhhdCBoYXZlIHN1Y2Nlc3NmdWxseSBiZWVuIGNhbmNlbGxlZAogaGF2ZSBb
T3BlcmF0aW9uLmVycm9yXVtdIHZhbHVlIHdpdGggYQogW2dvb2dsZS5ycGMuU3RhdHVzLmNv
ZGVdW2dvb2dsZS5ycGMuU3RhdHVzLmNvZGVdIG9mIDEsIGNvcnJlc3BvbmRpbmcgdG8KIGBD
b2RlLkNBTkNFTExFRGAuCgoMCgUEAQIFBRIDbQIGCgwKBQQBAgUBEgNtBx0KDAoFBAECBQMS
A20gIQoMCgUEAQIFCBIDbSJNCg8KCAQBAgUInAgAEgNtI0wKRAoEBAECBhIDcAJFGjcgT3V0
cHV0IG9ubHkuIEFQSSB2ZXJzaW9uIHVzZWQgdG8gc3RhcnQgdGhlIG9wZXJhdGlvbi4KCgwK
BQQBAgYFEgNwAggKDAoFBAECBgESA3AJFAoMCgUEAQIGAxIDcBcYCgwKBQQBAgYIEgNwGUQK
DwoIBAECBgicCAASA3AaQwpGCgIEAhIEdAB3ARo6IFRoZSBHb29nbGUgQ2xvdWQgU3RvcmFn
ZSBsb2NhdGlvbiBmb3IgdGhlIGlucHV0IGNvbnRlbnQuCgoKCgMEAgESA3QIEQpECgQEAgIA
EgN2AkQaNyBSZXF1aXJlZC4gUmVmZXJlbmNlcyB0byBhIEdvb2dsZSBDbG91ZCBTdG9yYWdl
IHBhdGhzLgoKDAoFBAICAAQSA3YCCgoMCgUEAgIABRIDdgsRCgwKBQQCAgABEgN2EhYKDAoF
BAICAAMSA3YZGgoMCgUEAgIACBIDdhtDCg8KCAQCAgAInAgAEgN2HEJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Visionai::V1::Common::Cluster ===
    # Fields for Cluster
    # Field: name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: labels Type: 11 (.google.cloud.visionai.v1.Cluster.LabelsEntry)
    # Field: annotations Type: 11 (.google.cloud.visionai.v1.Cluster.AnnotationsEntry)
    # Field: dataplane_service_endpoint Type: 9 ()
    # Field: state Type: 14 (.google.cloud.visionai.v1.Cluster.State)
    # Field: psc_target Type: 9 ()

# Enum: Cluster::State
our $Cluster_STATE_UNSPECIFIED = 0;
our $Cluster_PROVISIONING = 1;
our $Cluster_RUNNING = 2;
our $Cluster_STOPPING = 3;
our $Cluster_ERROR = 4;

# === Message: Google::Cloud::Visionai::V1::Common::OperationMetadata ===
    # Fields for OperationMetadata
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)
    # Field: target Type: 9 ()
    # Field: verb Type: 9 ()
    # Field: status_message Type: 9 ()
    # Field: requested_cancellation Type: 8 ()
    # Field: api_version Type: 9 ()

# === Message: Google::Cloud::Visionai::V1::Common::GcsSource ===
    # Fields for GcsSource
    # Field: uris Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Visionai::V1::Common - Compiled Protocol Buffers messages for google/cloud/visionai/v1/common.proto

=head1 SYNOPSIS

    use Google::Cloud::Visionai::V1::Common;

    my $msg = Google::Cloud::Visionai::V1::Common::Cluster->new({
        name => $name,
        create_time => $create_time,
        update_time => $update_time,
        labels => $labels,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Visionai::V1::Common::Cluster->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/visionai/v1/common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Visionai::V1::Common::Cluster

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

Type: C<Message> (L<Google::Cloud::Visionai::V1::Common::Cluster::LabelsEntry>)

Labels as key value pairs

=item * C<< $msg->annotations() >> / C<< $msg->annotations($value) >>

Type: C<Message> (L<Google::Cloud::Visionai::V1::Common::Cluster::AnnotationsEntry>)

Annotations to allow clients to store small amounts of arbitrary data.

=item * C<< $msg->dataplane_service_endpoint() >> / C<< $msg->dataplane_service_endpoint($value) >>

Type: C<String>

Output only. The DNS name of the data plane service

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Visionai::V1::Cluster::State>)

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

=head2 Google::Cloud::Visionai::V1::Common::OperationMetadata

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
have [Operation.error][] value with a
[google.rpc.Status.code][google.rpc.Status.code] of 1, corresponding to
`Code.CANCELLED`.

=item * C<< $msg->api_version() >> / C<< $msg->api_version($value) >>

Type: C<String>

Output only. API version used to start the operation.

=back

=head2 Google::Cloud::Visionai::V1::Common::GcsSource

The Google Cloud Storage location for the input content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->uris() >> / C<< $msg->uris($value) >>

Type: C<String>

Required. References to a Google Cloud Storage paths.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Visionai::V1::Common::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
