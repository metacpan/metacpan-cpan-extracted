package Google::Cloud::Eventarc::V1::Channel;

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
CiZnb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvY2hhbm5lbC5wcm90bxIYZ29vZ2xlLmNsb3Vk
LmV2ZW50YXJjLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGltZXN0YW1wLnByb3RvIsQG
CgdDaGFubmVsEhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIVCgN1aWQYAiABKAlCA+BBA1ID
dWlkEkAKC2NyZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID
4EEDUgpjcmVhdGVUaW1lEkAKC3VwZGF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEDUgp1cGRhdGVUaW1lEhoKCHByb3ZpZGVyGAcgASgJUghwcm92aWRl
chIoCgxwdWJzdWJfdG9waWMYCCABKAlCA+BBA0gAUgtwdWJzdWJUb3BpYxJCCgVzdGF0ZRgJ
IAEoDjInLmdvb2dsZS5jbG91ZC5ldmVudGFyYy52MS5DaGFubmVsLlN0YXRlQgPgQQNSBXN0
YXRlEi4KEGFjdGl2YXRpb25fdG9rZW4YCiABKAlCA+BBA1IPYWN0aXZhdGlvblRva2VuElEK
D2NyeXB0b19rZXlfbmFtZRgLIAEoCUIp4EEB+kEjCiFjbG91ZGttcy5nb29nbGVhcGlzLmNv
bS9DcnlwdG9LZXlSDWNyeXB0b0tleU5hbWUSKAoNc2F0aXNmaWVzX3B6cxgMIAEoCEID4EED
UgxzYXRpc2ZpZXNQenMSSgoGbGFiZWxzGA0gAygLMi0uZ29vZ2xlLmNsb3VkLmV2ZW50YXJj
LnYxLkNoYW5uZWwuTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzGjkKC0xhYmVsc0VudHJ5EhAK
A2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiRQoFU3RhdGUSFQoR
U1RBVEVfVU5TUEVDSUZJRUQQABILCgdQRU5ESU5HEAESCgoGQUNUSVZFEAISDAoISU5BQ1RJ
VkUQAzpz6kFwCh9ldmVudGFyYy5nb29nbGVhcGlzLmNvbS9DaGFubmVsEjpwcm9qZWN0cy97
cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY2hhbm5lbHMve2NoYW5uZWx9KghjaGFu
bmVsczIHY2hhbm5lbEILCgl0cmFuc3BvcnRCvAEKHGNvbS5nb29nbGUuY2xvdWQuZXZlbnRh
cmMudjFCDENoYW5uZWxQcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL2V2ZW50YXJjL2Fw
aXYxL2V2ZW50YXJjcGI7ZXZlbnRhcmNwYqoCGEdvb2dsZS5DbG91ZC5FdmVudGFyYy5WMcoC
GEdvb2dsZVxDbG91ZFxFdmVudGFyY1xWMeoCG0dvb2dsZTo6Q2xvdWQ6OkV2ZW50YXJjOjpW
MUq4IwoGEgQOAH4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAhCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAApCggKAQgSAxYANQoJCgIIJRID
FgA1CggKAQgSAxcATwoJCgIICxIDFwBPCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkA
LQoJCgIICBIDGQAtCggKAQgSAxoANQoJCgIIARIDGgA1CggKAQgSAxsANQoJCgIIKRIDGwA1
CggKAQgSAxwANAoJCgIILRIDHAA0CpsCCgIEABIEIgB+ARqOAiBBIHJlcHJlc2VudGF0aW9u
IG9mIHRoZSBDaGFubmVsIHJlc291cmNlLgogQSBDaGFubmVsIGlzIGEgcmVzb3VyY2Ugb24g
d2hpY2ggZXZlbnQgcHJvdmlkZXJzIHB1Ymxpc2ggdGhlaXIgZXZlbnRzLgogVGhlIHB1Ymxp
c2hlZCBldmVudHMgYXJlIGRlbGl2ZXJlZCB0aHJvdWdoIHRoZSB0cmFuc3BvcnQgYXNzb2Np
YXRlZCB3aXRoIHRoZQogY2hhbm5lbC4gTm90ZSB0aGF0IGEgY2hhbm5lbCBpcyBhc3NvY2lh
dGVkIHdpdGggZXhhY3RseSBvbmUgZXZlbnQgcHJvdmlkZXIuCgoKCgMEAAESAyIIDwoLCgME
AAcSBCMCKAQKDQoFBAAHnQgSBCMCKAQKQAoEBAAEABIEKwJEAxoyIFN0YXRlIGxpc3RzIGFs
bCB0aGUgcG9zc2libGUgc3RhdGVzIG9mIGEgQ2hhbm5lbAoKDAoFBAAEAAESAysHDAo1CgYE
AAQAAgASAy0EGhomIERlZmF1bHQgdmFsdWUuIFRoaXMgdmFsdWUgaXMgdW51c2VkLgoKDgoH
BAAEAAIAARIDLQQVCg4KBwQABAACAAISAy0YGQrrAQoGBAAEAAIBEgMyBBAa2wEgVGhlIFBF
TkRJTkcgc3RhdGUgaW5kaWNhdGVzIHRoYXQgYSBDaGFubmVsIGhhcyBiZWVuIGNyZWF0ZWQg
c3VjY2Vzc2Z1bGx5CiBhbmQgdGhlcmUgaXMgYSBuZXcgYWN0aXZhdGlvbiB0b2tlbiBhdmFp
bGFibGUgZm9yIHRoZSBzdWJzY3JpYmVyIHRvIHVzZQogdG8gY29udmV5IHRoZSBDaGFubmVs
IHRvIHRoZSBwcm92aWRlciBpbiBvcmRlciB0byBjcmVhdGUgYSBDb25uZWN0aW9uLgoKDgoH
BAAEAAIBARIDMgQLCg4KBwQABAACAQISAzIODwrHAQoGBAAEAAICEgM4BA8atwEgVGhlIEFD
VElWRSBzdGF0ZSBpbmRpY2F0ZXMgdGhhdCBhIENoYW5uZWwgaGFzIGJlZW4gc3VjY2Vzc2Z1
bGx5CiBjb25uZWN0ZWQgd2l0aCB0aGUgZXZlbnQgcHJvdmlkZXIuCiBBbiBBQ1RJVkUgQ2hh
bm5lbCBpcyByZWFkeSB0byByZWNlaXZlIGFuZCByb3V0ZSBldmVudHMgZnJvbSB0aGUKIGV2
ZW50IHByb3ZpZGVyLgoKDgoHBAAEAAICARIDOAQKCg4KBwQABAACAgISAzgNDgqgAwoGBAAE
AAIDEgNDBBEakAMgVGhlIElOQUNUSVZFIHN0YXRlIGluZGljYXRlcyB0aGF0IHRoZSBDaGFu
bmVsIGNhbm5vdCByZWNlaXZlIGV2ZW50cwogcGVybWFuZW50bHkuIFRoZXJlIGFyZSB0d28g
cG9zc2libGUgY2FzZXMgdGhpcyBzdGF0ZSBjYW4gaGFwcGVuOgoKIDEuIFRoZSBTYWFTIHBy
b3ZpZGVyIGRpc2Nvbm5lY3RlZCBmcm9tIHRoaXMgQ2hhbm5lbC4KIDIuIFRoZSBDaGFubmVs
IGFjdGl2YXRpb24gdG9rZW4gaGFzIGV4cGlyZWQgYnV0IHRoZSBTYWFTIHByb3ZpZGVyCiAg
ICB3YXNuJ3QgY29ubmVjdGVkLgoKIFRvIHJlLWVzdGFibGlzaCBhIENvbm5lY3Rpb24gd2l0
aCBhIHByb3ZpZGVyLCB0aGUgc3Vic2NyaWJlcgogc2hvdWxkIGNyZWF0ZSBhIG5ldyBDaGFu
bmVsIGFuZCBnaXZlIGl0IHRvIHRoZSBwcm92aWRlci4KCg4KBwQABAACAwESA0MEDAoOCgcE
AAQAAgMCEgNDDxAKxgEKBAQAAgASA0kCOxq4ASBSZXF1aXJlZC4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIGNoYW5uZWwuIE11c3QgYmUgdW5pcXVlIHdpdGhpbiB0aGUKIGxvY2F0aW9u
IG9uIHRoZSBwcm9qZWN0IGFuZCBtdXN0IGJlIGluCiBgcHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2NoYW5uZWxzL3tjaGFubmVsX2lkfWAgZm9ybWF0LgoKDAoF
BAACAAUSA0kCCAoMCgUEAAIAARIDSQkNCgwKBQQAAgADEgNJEBEKDAoFBAACAAgSA0kSOgoP
CggEAAIACJwIABIDSRM5Cq8BCgQEAAIBEgNOAj0aoQEgT3V0cHV0IG9ubHkuIFNlcnZlciBh
c3NpZ25lZCB1bmlxdWUgaWRlbnRpZmllciBmb3IgdGhlIGNoYW5uZWwuIFRoZSB2YWx1ZQog
aXMgYSBVVUlENCBzdHJpbmcgYW5kIGd1YXJhbnRlZWQgdG8gcmVtYWluIHVuY2hhbmdlZCB1
bnRpbCB0aGUgcmVzb3VyY2UgaXMKIGRlbGV0ZWQuCgoMCgUEAAIBBRIDTgIICgwKBQQAAgEB
EgNOCQwKDAoFBAACAQMSA04PEAoMCgUEAAIBCBIDThE8Cg8KCAQAAgEInAgAEgNOEjsKLwoE
BAACAhIEUQJSMhohIE91dHB1dCBvbmx5LiBUaGUgY3JlYXRpb24gdGltZS4KCgwKBQQAAgIG
EgNRAhsKDAoFBAACAgESA1EcJwoMCgUEAAICAxIDUSorCgwKBQQAAgIIEgNSBjEKDwoIBAAC
AgicCAASA1IHMAo0CgQEAAIDEgRVAlYyGiYgT3V0cHV0IG9ubHkuIFRoZSBsYXN0LW1vZGlm
aWVkIHRpbWUuCgoMCgUEAAIDBhIDVQIbCgwKBQQAAgMBEgNVHCcKDAoFBAACAwMSA1UqKwoM
CgUEAAIDCBIDVgYxCg8KCAQAAgMInAgAEgNWBzAKggIKBAQAAgQSA1wCFhr0ASBUaGUgbmFt
ZSBvZiB0aGUgZXZlbnQgcHJvdmlkZXIgKGUuZy4gRXZlbnRhcmMgU2FhUyBwYXJ0bmVyKSBh
c3NvY2lhdGVkCiB3aXRoIHRoZSBjaGFubmVsLiBUaGlzIHByb3ZpZGVyIHdpbGwgYmUgZ3Jh
bnRlZCBwZXJtaXNzaW9ucyB0byBwdWJsaXNoCiBldmVudHMgdG8gdGhlIGNoYW5uZWwuIEZv
cm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vcHJvdmlk
ZXJzL3twcm92aWRlcl9pZH1gLgoKDAoFBAACBAUSA1wCCAoMCgUEAAIEARIDXAkRCgwKBQQA
AgQDEgNcFBUKDAoEBAAIABIEXgJjAwoMCgUEAAgAARIDXggRCroBCgQEAAIFEgNiBEgarAEg
T3V0cHV0IG9ubHkuIFRoZSBuYW1lIG9mIHRoZSBQdWIvU3ViIHRvcGljIGNyZWF0ZWQgYW5k
IG1hbmFnZWQgYnkKIEV2ZW50YXJjIHN5c3RlbSBhcyBhIHRyYW5zcG9ydCBmb3IgdGhlIGV2
ZW50IGRlbGl2ZXJ5LiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L3RvcGljcy97dG9w
aWNfaWR9YC4KCgwKBQQAAgUFEgNiBAoKDAoFBAACBQESA2ILFwoMCgUEAAIFAxIDYhobCgwK
BQQAAgUIEgNiHEcKDwoIBAACBQicCAASA2IdRgozCgQEAAIGEgNmAj4aJiBPdXRwdXQgb25s
eS4gVGhlIHN0YXRlIG9mIGEgQ2hhbm5lbC4KCgwKBQQAAgYGEgNmAgcKDAoFBAACBgESA2YI
DQoMCgUEAAIGAxIDZhARCgwKBQQAAgYIEgNmEj0KDwoIBAACBgicCAASA2YTPAqSAQoEBAAC
BxIDagJLGoQBIE91dHB1dCBvbmx5LiBUaGUgYWN0aXZhdGlvbiB0b2tlbiBmb3IgdGhlIGNo
YW5uZWwuIFRoZSB0b2tlbiBtdXN0IGJlIHVzZWQKIGJ5IHRoZSBwcm92aWRlciB0byByZWdp
c3RlciB0aGUgY2hhbm5lbCBmb3IgcHVibGlzaGluZy4KCgwKBQQAAgcFEgNqAggKDAoFBAAC
BwESA2oJGQoMCgUEAAIHAxIDahweCgwKBQQAAgcIEgNqH0oKDwoIBAACBwicCAASA2ogSQrM
AQoEBAACCBIEcQJ2BBq9ASBPcHRpb25hbC4gUmVzb3VyY2UgbmFtZSBvZiBhIEtNUyBjcnlw
dG8ga2V5IChtYW5hZ2VkIGJ5IHRoZSB1c2VyKSB1c2VkIHRvCiBlbmNyeXB0L2RlY3J5cHQg
dGhlaXIgZXZlbnQgZGF0YS4KCiBJdCBtdXN0IG1hdGNoIHRoZSBwYXR0ZXJuCiBgcHJvamVj
dHMvKi9sb2NhdGlvbnMvKi9rZXlSaW5ncy8qL2NyeXB0b0tleXMvKmAuCgoMCgUEAAIIBRID
cQIICgwKBQQAAggBEgNxCRgKDAoFBAACCAMSA3EbHQoNCgUEAAIICBIEcR52AwoPCggEAAII
CJwIABIDcgQqCg8KBwQAAggInwgSBHMEdQUKbwoEBAACCRIDegJGGmIgT3V0cHV0IG9ubHku
IFdoZXRoZXIgb3Igbm90IHRoaXMgQ2hhbm5lbCBzYXRpc2ZpZXMgdGhlIHJlcXVpcmVtZW50
cyBvZgogcGh5c2ljYWwgem9uZSBzZXBhcmF0aW9uCgoMCgUEAAIJBRIDegIGCgwKBQQAAgkB
EgN6BxQKDAoFBAACCQMSA3oXGQoMCgUEAAIJCBIDehpFCg8KCAQAAgkInAgAEgN6G0QKKQoE
BAACChIDfQJLGhwgT3B0aW9uYWwuIFJlc291cmNlIGxhYmVscy4KCgwKBQQAAgoGEgN9AhUK
DAoFBAACCgESA30WHAoMCgUEAAIKAxIDfR8hCgwKBQQAAgoIEgN9IkoKDwoIBAACCgicCAAS
A30jSWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::V1::Channel::Channel ===
    # Fields for Channel
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: provider Type: 9 ()
    # Field: pubsub_topic Type: 9 ()
    # Field: state Type: 14 (.google.cloud.eventarc.v1.Channel.State)
    # Field: activation_token Type: 9 ()
    # Field: crypto_key_name Type: 9 ()
    # Field: satisfies_pzs Type: 8 ()
    # Field: labels Type: 11 (.google.cloud.eventarc.v1.Channel.LabelsEntry)

# Enum: Channel::State
our $Channel_STATE_UNSPECIFIED = 0;
our $Channel_PENDING = 1;
our $Channel_ACTIVE = 2;
our $Channel_INACTIVE = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::V1::Channel - Compiled Protocol Buffers messages for google/cloud/eventarc/v1/channel.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::V1::Channel;

    my $msg = Google::Cloud::Eventarc::V1::Channel::Channel->new({
        name => $name,
        uid => $uid,
        create_time => $create_time,
        update_time => $update_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::V1::Channel::Channel->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/v1/channel.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::V1::Channel::Channel

A representation of the Channel resource.
A Channel is a resource on which event providers publish their events.
The published events are delivered through the transport associated with the
channel. Note that a channel is associated with exactly one event provider.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The resource name of the channel. Must be unique within the
location on the project and must be in
`projects/{project}/locations/{location}/channels/{channel_id}` format.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server assigned unique identifier for the channel. The value
is a UUID4 string and guaranteed to remain unchanged until the resource is
deleted.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last-modified time.

=item * C<< $msg->provider() >> / C<< $msg->provider($value) >>

Type: C<String>

The name of the event provider (e.g. Eventarc SaaS partner) associated
with the channel. This provider will be granted permissions to publish
events to the channel. Format:
`projects/{project}/locations/{location}/providers/{provider_id}`.

=item * C<< $msg->pubsub_topic() >> / C<< $msg->pubsub_topic($value) >>

Type: C<String>

Output only. The name of the Pub/Sub topic created and managed by
Eventarc system as a transport for the event delivery. Format:
`projects/{project}/topics/{topic_id}`.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Eventarc::V1::Channel::State>)

Output only. The state of a Channel.

=item * C<< $msg->activation_token() >> / C<< $msg->activation_token($value) >>

Type: C<String>

Output only. The activation token for the channel. The token must be used
by the provider to register the channel for publishing.

=item * C<< $msg->crypto_key_name() >> / C<< $msg->crypto_key_name($value) >>

Type: C<String>

Optional. Resource name of a KMS crypto key (managed by the user) used to
encrypt/decrypt their event data.

It must match the pattern
`projects/*/locations/*/keyRings/*/cryptoKeys/*`.

=item * C<< $msg->satisfies_pzs() >> / C<< $msg->satisfies_pzs($value) >>

Type: C<Bool>

Output only. Whether or not this Channel satisfies the requirements of
physical zone separation

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::Channel::Channel::LabelsEntry>)

Optional. Resource labels.

=back

=head3 Enum: Channel::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<ACTIVE> => C<2>

=item * C<INACTIVE> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::V1::Channel::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
