package Google::Actions::Sdk::V2::Conversation::Scene;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Conversation::Prompt };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3NjZW5lLnByb3RvEiJnb29n
bGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uGjZnb29nbGUvYWN0aW9ucy9zZGsvdjIv
Y29udmVyc2F0aW9uL3Byb21wdC9wcm9tcHQucHJvdG8aHGdvb2dsZS9wcm90b2J1Zi9zdHJ1
Y3QucHJvdG8irAMKBFNsb3QSRQoEbW9kZRgBIAEoDjIxLmdvb2dsZS5hY3Rpb25zLnNkay52
Mi5jb252ZXJzYXRpb24uU2xvdC5TbG90TW9kZVIEbW9kZRJLCgZzdGF0dXMYAiABKA4yMy5n
b29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uLlNsb3QuU2xvdFN0YXR1c1IGc3Rh
dHVzEiwKBXZhbHVlGAMgASgLMhYuZ29vZ2xlLnByb3RvYnVmLlZhbHVlUgV2YWx1ZRIYCgd1
cGRhdGVkGAQgASgIUgd1cGRhdGVkEkIKBnByb21wdBgFIAEoCzIqLmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5jb252ZXJzYXRpb24uUHJvbXB0UgZwcm9tcHQiPAoIU2xvdE1vZGUSFAoQTU9E
RV9VTlNQRUNJRklFRBAAEgwKCE9QVElPTkFMEAESDAoIUkVRVUlSRUQQAiJGCgpTbG90U3Rh
dHVzEhQKEFNMT1RfVU5TUEVDSUZJRUQQABIJCgVFTVBUWRABEgsKB0lOVkFMSUQQAhIKCgZG
SUxMRUQQAypQChFTbG90RmlsbGluZ1N0YXR1cxIPCgtVTlNQRUNJRklFRBAAEg8KC0lOSVRJ
QUxJWkVEEAESDgoKQ09MTEVDVElORxACEgkKBUZJTkFMEARChgEKJmNvbS5nb29nbGUuYWN0
aW9ucy5zZGsudjIuY29udmVyc2F0aW9uQgpTY2VuZVByb3RvUAFaTmdvb2dsZS5nb2xhbmcu
b3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uO2Nv
bnZlcnNhdGlvbkq5FwoGEgQOAFsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29v
Z2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAy
LjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQg
aW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5
IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNl
cy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBh
Z3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBM
aWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdB
UlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3Ig
aW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdv
dmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNl
LgoKCAoBAhIDEAArCgkKAgMAEgMSAEAKCQoCAwESAxMAJgoICgEIEgMVAGUKCQoCCAsSAxUA
ZQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXACsKCQoCCAgSAxcAKwoICgEIEgMYAD8K
CQoCCAESAxgAPwo8CgIFABIEGwAnARowIFJlcHJlc2VudHMgdGhlIGN1cnJlbnQgc3RhdHVz
IG9mIHNsb3QgZmlsbGluZy4KCgoKAwUAARIDGwUWCkQKBAUAAgASAx0CEho3IEZhbGxiYWNr
IHZhbHVlIHdoZW4gdGhlIHVzYWdlIGZpZWxkIGlzIG5vdCBwb3B1bGF0ZWQuCgoMCgUFAAIA
ARIDHQINCgwKBQUAAgACEgMdEBEKUAoEBQACARIDIAISGkMgVGhlIHNsb3RzIGhhdmUgYmVl
biBpbml0aWFsaXplZCBidXQgc2xvdCBmaWxsaW5nIGhhcyBub3Qgc3RhcnRlZC4KCgwKBQUA
AgEBEgMgAg0KDAoFBQACAQISAyAQEQozCgQFAAICEgMjAhEaJiBUaGUgc2xvdCB2YWx1ZXMg
YXJlIGJlaW5nIGNvbGxlY3RlZC4KCgwKBQUAAgIBEgMjAgwKDAoFBQACAgISAyMPEAo/CgQF
AAIDEgMmAgwaMiBBbGwgc2xvdCB2YWx1ZXMgYXJlIGZpbmFsIGFuZCBjYW5ub3QgYmUgY2hh
bmdlZC4KCgwKBQUAAgMBEgMmAgcKDAoFBQACAwISAyYKCwogCgIEABIEKgBbARoUIFJlcHJl
c2VudHMgYSBzbG90LgoKCgoDBAABEgMqCAwKUQoEBAAEABIELAI1AxpDIFJlcHJlc2VudHMg
dGhlIG1vZGUgb2YgYSBzbG90LCB0aGF0IGlzLCBpZiBpdCBpcyByZXF1aXJlZCBvciBub3Qu
CgoMCgUEAAQAARIDLAcPCkYKBgQABAACABIDLgQZGjcgRmFsbGJhY2sgdmFsdWUgd2hlbiB0
aGUgdXNhZ2UgZmllbGQgaXMgbm90IHBvcHVsYXRlZC4KCg4KBwQABAACAAESAy4EFAoOCgcE
AAQAAgACEgMuFxgKUgoGBAAEAAIBEgMxBBEaQyBJbmRpY2F0ZXMgdGhhdCB0aGUgc2xvdCBp
cyBub3QgcmVxdWlyZWQgdG8gY29tcGxldGUgc2xvdCBmaWxsaW5nLgoKDgoHBAAEAAIBARID
MQQMCg4KBwQABAACAQISAzEPEApOCgYEAAQAAgISAzQEERo/IEluZGljYXRlcyB0aGF0IHRo
ZSBzbG90IGlzIHJlcXVpcmVkIHRvIGNvbXBsZXRlIHNsb3QgZmlsbGluZy4KCg4KBwQABAAC
AgESAzQEDAoOCgcEAAQAAgICEgM0DxAKMAoEBAAEARIEOAJHAxoiIFJlcHJlc2VudHMgdGhl
IHN0YXR1cyBvZiBhIHNsb3QuCgoMCgUEAAQBARIDOAcRCkYKBgQABAECABIDOgQZGjcgRmFs
bGJhY2sgdmFsdWUgd2hlbiB0aGUgdXNhZ2UgZmllbGQgaXMgbm90IHBvcHVsYXRlZC4KCg4K
BwQABAECAAESAzoEFAoOCgcEAAQBAgACEgM6FxgKeAoGBAAEAQIBEgM+BA4aaSBJbmRpY2F0
ZXMgdGhhdCB0aGUgc2xvdCBkb2VzIG5vdCBoYXZlIGFueSB2YWx1ZXMuIFRoaXMgc3RhdHVz
IGNhbm5vdCBiZQogbW9kaWZpZWQgdGhyb3VnaCB0aGUgcmVzcG9uc2UuCgoOCgcEAAQBAgEB
EgM+BAkKDgoHBAAEAQIBAhIDPgwNCmgKBgQABAECAhIDQgQQGlkgSW5kaWNhdGVzIHRoYXQg
dGhlIHNsb3QgdmFsdWUgaXMgaW52YWxpZC4gVGhpcyBzdGF0dXMgY2FuIGJlIHNldAogdGhy
b3VnaCB0aGUgcmVzcG9uc2UuCgoOCgcEAAQBAgIBEgNCBAsKDgoHBAAEAQICAhIDQg4PCmsK
BgQABAECAxIDRgQPGlwgSW5kaWNhdGVzIHRoYXQgdGhlIHNsb3QgaGFzIGEgdmFsdWUuIFRo
aXMgc3RhdHVzIGNhbm5vdCBiZSBtb2RpZmllZAogdGhyb3VnaCB0aGUgcmVzcG9uc2UuCgoO
CgcEAAQBAgMBEgNGBAoKDgoHBAAEAQIDAhIDRg0OClQKBAQAAgASA0oCFBpHIFRoZSBtb2Rl
IG9mIHRoZSBzbG90IChyZXF1aXJlZCBvciBvcHRpb25hbCkuIENhbiBiZSBzZXQgYnkgZGV2
ZWxvcGVyLgoKDAoFBAACAAYSA0oCCgoMCgUEAAIAARIDSgsPCgwKBQQAAgADEgNKEhMKJgoE
BAACARIDTQIYGhkgVGhlIHN0YXR1cyBvZiB0aGUgc2xvdC4KCgwKBQQAAgEGEgNNAgwKDAoF
BAACAQESA00NEwoMCgUEAAIBAxIDTRYXCnIKBAQAAgISA1ECIhplIFRoZSB2YWx1ZSBvZiB0
aGUgc2xvdC4gQ2hhbmdpbmcgdGhpcyB2YWx1ZSBpbiB0aGUgcmVzcG9uc2UsIHdpbGwKIG1v
ZGlmeSB0aGUgdmFsdWUgaW4gc2xvdCBmaWxsaW5nLgoKDAoFBAACAgYSA1ECFwoMCgUEAAIC
ARIDURgdCgwKBQQAAgIDEgNRICEKZAoEBAACAxIDVQITGlcgSW5kaWNhdGVzIGlmIHRoZSBz
bG90IHZhbHVlIHdhcyBjb2xsZWN0ZWQgb24gdGhlIGxhc3QgdHVybi4KIFRoaXMgZmllbGQg
aXMgcmVhZC1vbmx5LgoKDAoFBAACAwUSA1UCBgoMCgUEAAIDARIDVQcOCgwKBQQAAgMDEgNV
ERIK1QEKBAQAAgQSA1oCFBrHASBPcHRpb25hbC4gVGhpcyBwcm9tcHQgaXMgc2VudCB0byB0
aGUgdXNlciB3aGVuIG5lZWRlZCB0byBmaWxsIGEgcmVxdWlyZWQKIHNsb3QuIFRoaXMgcHJv
bXB0IG92ZXJyaWRlcyB0aGUgZXhpc3RpbmcgcHJvbXB0IGRlZmluZWQgaW4gdGhlIGNvbnNv
bGUuCiBUaGlzIGZpZWxkIGlzIG5vdCBpbmNsdWRlZCBpbiB0aGUgd2ViaG9vayByZXF1ZXN0
LgoKDAoFBAACBAYSA1oCCAoMCgUEAAIEARIDWgkPCgwKBQQAAgQDEgNaEhNiBnByb3RvMw==

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Scene::Slot ===
    # Fields for Slot
    # Field: mode Type: 14 (.google.actions.sdk.v2.conversation.Slot.SlotMode)
    # Field: status Type: 14 (.google.actions.sdk.v2.conversation.Slot.SlotStatus)
    # Field: value Type: 11 (.google.protobuf.Value)
    # Field: updated Type: 8 ()
    # Field: prompt Type: 11 (.google.actions.sdk.v2.conversation.Prompt)

# Enum: Slot::SlotMode
our $Slot_MODE_UNSPECIFIED = 0;
our $Slot_OPTIONAL = 1;
our $Slot_REQUIRED = 2;

# Enum: Slot::SlotStatus
our $Slot_SLOT_UNSPECIFIED = 0;
our $Slot_EMPTY = 1;
our $Slot_INVALID = 2;
our $Slot_FILLED = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Scene - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/scene.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Scene;

    my $msg = Google::Actions::Sdk::V2::Conversation::Scene::Slot->new({
        mode => $mode,
        status => $status,
        value => $value,
        updated => $updated,
    });

    # Read or update a field
    my $val = $msg->mode();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Scene::Slot->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/scene.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Scene::Slot

Represents a slot.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mode() >> / C<< $msg->mode($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Conversation::Slot::SlotMode>)

The mode of the slot (required or optional). Can be set by developer.

=item * C<< $msg->status() >> / C<< $msg->status($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Conversation::Slot::SlotStatus>)

The status of the slot.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Value>)

The value of the slot. Changing this value in the response, will
modify the value in slot filling.

=item * C<< $msg->updated() >> / C<< $msg->updated($value) >>

Type: C<Bool>

Indicates if the slot value was collected on the last turn.
This field is read-only.

=item * C<< $msg->prompt() >> / C<< $msg->prompt($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Prompt::Prompt>)

Optional. This prompt is sent to the user when needed to fill a required
slot. This prompt overrides the existing prompt defined in the console.
This field is not included in the webhook request.

=back

=head3 Enum: Slot::SlotMode

=over 4

=item * C<MODE_UNSPECIFIED> => C<0>

=item * C<OPTIONAL> => C<1>

=item * C<REQUIRED> => C<2>

=back

=head3 Enum: Slot::SlotStatus

=over 4

=item * C<SLOT_UNSPECIFIED> => C<0>

=item * C<EMPTY> => C<1>

=item * C<INVALID> => C<2>

=item * C<FILLED> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Scene::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
