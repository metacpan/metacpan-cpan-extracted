package Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Ck9nb29nbGUvYWN0aW9ucy9zZGsvdjIvaW50ZXJhY3Rpb25tb2RlbC9wcm9tcHQvY29udGVu
dC9zdGF0aWNfbWVkaWFfcHJvbXB0LnByb3RvEi1nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50
ZXJhY3Rpb25tb2RlbC5wcm9tcHQaT2dvb2dsZS9hY3Rpb25zL3Nkay92Mi9pbnRlcmFjdGlv
bm1vZGVsL3Byb21wdC9jb250ZW50L3N0YXRpY19pbWFnZV9wcm9tcHQucHJvdG8aHmdvb2ds
ZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90byL+BQoRU3RhdGljTWVkaWFQcm9tcHQSaQoKbWVk
aWFfdHlwZRgIIAEoDjJKLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5pbnRlcmFjdGlvbm1vZGVs
LnByb21wdC5TdGF0aWNNZWRpYVByb21wdC5NZWRpYVR5cGVSCW1lZGlhVHlwZRI8CgxzdGFy
dF9vZmZzZXQYBSABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SC3N0YXJ0T2Zmc2V0
Eo4BChdvcHRpb25hbF9tZWRpYV9jb250cm9scxgGIAMoDjJWLmdvb2dsZS5hY3Rpb25zLnNk
ay52Mi5pbnRlcmFjdGlvbm1vZGVsLnByb21wdC5TdGF0aWNNZWRpYVByb21wdC5PcHRpb25h
bE1lZGlhQ29udHJvbHNSFW9wdGlvbmFsTWVkaWFDb250cm9scxJfCg1tZWRpYV9vYmplY3Rz
GAcgAygLMjouZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0aW9ubW9kZWwucHJvbXB0
Lk1lZGlhT2JqZWN0UgxtZWRpYU9iamVjdHMSbAoLcmVwZWF0X21vZGUYCSABKA4ySy5nb29n
bGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5wcm9tcHQuU3RhdGljTWVkaWFQ
cm9tcHQuUmVwZWF0TW9kZVIKcmVwZWF0TW9kZSJICglNZWRpYVR5cGUSGgoWTUVESUFfVFlQ
RV9VTlNQRUNJRklFRBAAEgkKBUFVRElPEAESFAoQTUVESUFfU1RBVFVTX0FDSxACIlkKFU9w
dGlvbmFsTWVkaWFDb250cm9scxInCiNPUFRJT05BTF9NRURJQV9DT05UUk9MU19VTlNQRUNJ
RklFRBAAEgoKBlBBVVNFRBABEgsKB1NUT1BQRUQQAiI7CgpSZXBlYXRNb2RlEhsKF1JFUEVB
VF9NT0RFX1VOU1BFQ0lGSUVEEAASBwoDT0ZGEAESBwoDQUxMEAIipgEKC01lZGlhT2JqZWN0
EhIKBG5hbWUYASABKAlSBG5hbWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9u
EhAKA3VybBgDIAEoCVIDdXJsEk8KBWltYWdlGAQgASgLMjkuZ29vZ2xlLmFjdGlvbnMuc2Rr
LnYyLmludGVyYWN0aW9ubW9kZWwucHJvbXB0Lk1lZGlhSW1hZ2VSBWltYWdlIscBCgpNZWRp
YUltYWdlElgKBWxhcmdlGAEgASgLMkAuZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmludGVyYWN0
aW9ubW9kZWwucHJvbXB0LlN0YXRpY0ltYWdlUHJvbXB0SABSBWxhcmdlElYKBGljb24YAiAB
KAsyQC5nb29nbGUuYWN0aW9ucy5zZGsudjIuaW50ZXJhY3Rpb25tb2RlbC5wcm9tcHQuU3Rh
dGljSW1hZ2VQcm9tcHRIAFIEaWNvbkIHCgVpbWFnZUKiAQoxY29tLmdvb2dsZS5hY3Rpb25z
LnNkay52Mi5pbnRlcmFjdGlvbm1vZGVsLnByb21wdEIWU3RhdGljTWVkaWFQcm9tcHRQcm90
b1ABWlNnb29nbGUuZ29sYW5nLm9yZy9nZW5wcm90by9nb29nbGVhcGlzL2FjdGlvbnMvc2Rr
L3YyL2ludGVyYWN0aW9ubW9kZWwvcHJvbXB0O3Byb21wdErEGgoGEgQOAG8BCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA2CgkKAgMAEgMSAFkKCQoCAwES
AxMAKAoICgEIEgMVAGoKCQoCCAsSAxUAagoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMX
ADcKCQoCCAgSAxcANwoICgEIEgMYAEoKCQoCCAESAxgASgplCgIEABIEHABTARpZIENvbnRh
aW5zIGluZm9ybWF0aW9uIGFib3V0IHRoZSBtZWRpYSwgc3VjaCBhcyBuYW1lLCBkZXNjcmlw
dGlvbiwgdXJsLCBldGMuCiBOZXh0IGlkOiAxMQoKCgoDBAABEgMcCBkKLAoEBAAEABIEHgIn
AxoeIE1lZGlhIHR5cGUgb2YgdGhpcyByZXNwb25zZS4KCgwKBQQABAABEgMeBxAKIgoGBAAE
AAIAEgMgBB8aEyBVTlNQRUNJRklFRCB2YWx1ZQoKDgoHBAAEAAIAARIDIAQaCg4KBwQABAAC
AAISAyAdHgocCgYEAAQAAgESAyMEDhoNIEF1ZGlvIGZpbGUuCgoOCgcEAAQAAgEBEgMjBAkK
DgoHBAAEAAIBAhIDIwwNCj8KBgQABAACAhIDJgQZGjAgUmVzcG9uc2UgdG8gYWNrbm93bGVk
Z2UgYSBtZWRpYSBzdGF0dXMgcmVwb3J0LgoKDgoHBAAEAAICARIDJgQUCg4KBwQABAACAgIS
AyYXGApPCgQEAAQBEgQqAjMDGkEgTWVkaWEgY29udHJvbCB0eXBlcyB0aGUgbWVkaWEgcmVz
cG9uc2UgY2FuIHN1cHBvcnRlZCBvcHRpb25hbGx5CgoMCgUEAAQBARIDKgccCiIKBgQABAEC
ABIDLAQsGhMgVW5zcGVjaWZpZWQgdmFsdWUKCg4KBwQABAECAAESAywEJwoOCgcEAAQBAgAC
EgMsKisKRAoGBAAEAQIBEgMvBA8aNSBQYXVzZWQgZXZlbnQuIFRyaWdnZXJlZCB3aGVuIHVz
ZXIgcGF1c2VzIHRoZSBtZWRpYS4KCg4KBwQABAECAQESAy8ECgoOCgcEAAQBAgECEgMvDQ4K
WgoGBAAEAQICEgMyBBAaSyBTdG9wcGVkIGV2ZW50LiBUcmlnZ2VyZWQgd2hlbiB1c2VyIGV4
aXQgb3V0IDNwIHNlc3Npb24gZHVyaW5nIG1lZGlhIHBsYXkuCgoOCgcEAAQBAgIBEgMyBAsK
DgoHBAAEAQICAhIDMg4PCkUKBAQABAISBDYCQAMaNyBUaGUgdHlwZXMgb2YgcmVwZWF0IG1v
ZGUgZm9yIGEgbGlzdCBvZiBtZWRpYSBvYmplY3RzLgoKDAoFBAAEAgESAzYHEQojCgYEAAQC
AgASAzgEIBoUIEVxdWl2YWxlbnQgdG8gT0ZGLgoKDgoHBAAEAgIAARIDOAQbCg4KBwQABAIC
AAISAzgeHwpHCgYEAAQCAgESAzsEDBo4IEVuZCBtZWRpYSBzZXNzaW9uIGF0IHRoZSBlbmQg
b2YgdGhlIGxhc3QgbWVkaWEgb2JqZWN0LgoKDgoHBAAEAgIBARIDOwQHCg4KBwQABAICAQIS
AzsKCwpzCgYEAAQCAgISAz8EDBpkIExvb3AgdG8gdGhlIGJlZ2lubmluZyBvZiB0aGUgZmly
c3QgbWVkaWEgb2JqZWN0IHdoZW4gdGhlIGVuZCBvZiB0aGUgbGFzdAogbWVkaWEgb2JqZWN0
IGlzIHJlYWNoZWQuCgoOCgcEAAQCAgIBEgM/BAcKDgoHBAAEAgICAhIDPwoLCisKBAQAAgAS
A0MCGxoeIE1lZGlhIHR5cGUgb2YgdGhpcyByZXNwb25zZS4KCgwKBQQAAgAGEgNDAgsKDAoF
BAACAAESA0MMFgoMCgUEAAIAAxIDQxkaCjYKBAQAAgESA0YCLBopIFN0YXJ0IG9mZnNldCBv
ZiB0aGUgZmlyc3QgbWVkaWEgb2JqZWN0LgoKDAoFBAACAQYSA0YCGgoMCgUEAAIBARIDRhsn
CgwKBQQAAgEDEgNGKisK7wEKBAQAAgISA0wCPRrhASBPcHRpb25hbCBtZWRpYSBjb250cm9s
IHR5cGVzIHRoaXMgbWVkaWEgcmVzcG9uc2Ugc2Vzc2lvbiBjYW4gc3VwcG9ydC4KIElmIHNl
dCwgcmVxdWVzdCB3aWxsIGJlIG1hZGUgdG8gM3Agd2hlbiBhIGNlcnRhaW4gbWVkaWEgZXZl
bnQgaGFwcGVucy4KIElmIG5vdCBzZXQsIDNwIG11c3Qgc3RpbGwgaGFuZGxlIHR3byBkZWZh
dWx0IGNvbnRyb2wgdHlwZSwgRklOSVNIRUQgYW5kCiBGQUlMRUQuCgoMCgUEAAICBBIDTAIK
CgwKBQQAAgIGEgNMCyAKDAoFBAACAgESA0whOAoMCgUEAAICAxIDTDs8CiUKBAQAAgMSA08C
KRoYIExpc3Qgb2YgbWVkaWEgb2JqZWN0cy4KCgwKBQQAAgMEEgNPAgoKDAoFBAACAwYSA08L
FgoMCgUEAAIDARIDTxckCgwKBQQAAgMDEgNPJygKOQoEBAACBBIDUgIdGiwgUmVwZWF0IG1v
ZGUgZm9yIHRoZSBsaXN0IG9mIE1lZGlhIE9iamVjdHMuCgoMCgUEAAIEBhIDUgIMCgwKBQQA
AgQBEgNSDRgKDAoFBAACBAMSA1IbHAovCgIEARIEVgBiARojIFJlcHJlc2VudHMgYSBzaW5n
bGUgbWVkaWEgb2JqZWN0LgoKCgoDBAEBEgNWCBMKKQoEBAECABIDWAISGhwgTmFtZSBvZiB0
aGlzIG1lZGlhIG9iamVjdC4KCgwKBQQBAgAFEgNYAggKDAoFBAECAAESA1gJDQoMCgUEAQIA
AxIDWBARCjAKBAQBAgESA1sCGRojIERlc2NyaXB0aW9uIG9mIHRoaXMgbWVkaWEgb2JqZWN0
LgoKDAoFBAECAQUSA1sCCAoMCgUEAQIBARIDWwkUCgwKBQQBAgEDEgNbFxgKNQoEBAECAhID
XgIRGiggVGhlIHVybCBwb2ludGluZyB0byB0aGUgbWVkaWEgY29udGVudC4KCgwKBQQBAgIF
EgNeAggKDAoFBAECAgESA14JDAoMCgUEAQICAxIDXg8QCjEKBAQBAgMSA2ECFxokIEltYWdl
IHRvIHNob3cgd2l0aCB0aGUgbWVkaWEgY2FyZC4KCgwKBQQBAgMGEgNhAgwKDAoFBAECAwES
A2ENEgoMCgUEAQIDAxIDYRUWCjUKAgQCEgRlAG8BGikgSW1hZ2UgdG8gYmUgc2hvd24gaW5z
aWRlIGEgTWVkaWFQcm9tcHQuCgoKCgMEAgESA2UIEgo3CgQEAggAEgRnAm4DGikgT25seSBv
bmUgdHlwZSBvZiBNZWRpYUltYWdlIGlzIGFsbG93ZWQuCgoMCgUEAggAARIDZwgNCkIKBAQC
AgASA2kEIBo1IEEgbGFyZ2UgaW1hZ2UsIHN1Y2ggYXMgdGhlIGNvdmVyIG9mIHRoZSBhbGJ1
bSwgZXRjLgoKDAoFBAICAAYSA2kEFQoMCgUEAgIAARIDaRYbCgwKBQQCAgADEgNpHh8KYwoE
BAICARIDbQQfGlYgQSBzbWFsbCBpbWFnZSBpY29uIGRpc3BsYXllZCBvbiB0aGUgcmlnaHQg
ZnJvbSB0aGUgdGl0bGUuCiBJdCdzIHJlc2l6ZWQgdG8gMzZ4MzYgZHAuCgoMCgUEAgIBBhID
bQQVCgwKBQQCAgEBEgNtFhoKDAoFBAICAQMSA20dHmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::StaticMediaPrompt ===
    # Fields for StaticMediaPrompt
    # Field: media_type Type: 14 (.google.actions.sdk.v2.interactionmodel.prompt.StaticMediaPrompt.MediaType)
    # Field: start_offset Type: 11 (.google.protobuf.Duration)
    # Field: optional_media_controls Type: 14 (.google.actions.sdk.v2.interactionmodel.prompt.StaticMediaPrompt.OptionalMediaControls)
    # Field: media_objects Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.MediaObject)
    # Field: repeat_mode Type: 14 (.google.actions.sdk.v2.interactionmodel.prompt.StaticMediaPrompt.RepeatMode)

# Enum: StaticMediaPrompt::MediaType
our $StaticMediaPrompt_MEDIA_TYPE_UNSPECIFIED = 0;
our $StaticMediaPrompt_AUDIO = 1;
our $StaticMediaPrompt_MEDIA_STATUS_ACK = 2;

# Enum: StaticMediaPrompt::OptionalMediaControls
our $StaticMediaPrompt_OPTIONAL_MEDIA_CONTROLS_UNSPECIFIED = 0;
our $StaticMediaPrompt_PAUSED = 1;
our $StaticMediaPrompt_STOPPED = 2;

# Enum: StaticMediaPrompt::RepeatMode
our $StaticMediaPrompt_REPEAT_MODE_UNSPECIFIED = 0;
our $StaticMediaPrompt_OFF = 1;
our $StaticMediaPrompt_ALL = 2;

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaObject ===
    # Fields for MediaObject
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: url Type: 9 ()
    # Field: image Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.MediaImage)

# === Message: Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaImage ===
    # Fields for MediaImage
    # Field: large Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticImagePrompt)
    # Field: icon Type: 11 (.google.actions.sdk.v2.interactionmodel.prompt.StaticImagePrompt)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt - Compiled Protocol Buffers messages for google/actions/sdk/v2/interactionmodel/prompt/content/static_media_prompt.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt;

    my $msg = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::StaticMediaPrompt->new({
        media_type => $media_type,
        start_offset => $start_offset,
        optional_media_controls => $optional_media_controls,
        media_objects => $media_objects,
    });

    # Read or update a field
    my $val = $msg->media_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::StaticMediaPrompt->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/interactionmodel/prompt/content/static_media_prompt.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::StaticMediaPrompt

Contains information about the media, such as name, description, url, etc.
Next id: 11

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->media_type() >> / C<< $msg->media_type($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaType>)

Media type of this response.

=item * C<< $msg->start_offset() >> / C<< $msg->start_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Start offset of the first media object.

=item * C<< $msg->optional_media_controls() >> / C<< $msg->optional_media_controls($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::OptionalMediaControls>)

Optional media control types this media response session can support.
If set, request will be made to 3p when a certain media event happens.
If not set, 3p must still handle two default control type, FINISHED and
FAILED.

=item * C<< $msg->media_objects() >> / C<< $msg->media_objects($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaObject>)

List of media objects.

=item * C<< $msg->repeat_mode() >> / C<< $msg->repeat_mode($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::RepeatMode>)

Repeat mode for the list of Media Objects.

=back

=head3 Enum: StaticMediaPrompt::MediaType

=over 4

=item * C<MEDIA_TYPE_UNSPECIFIED> => C<0>

=item * C<AUDIO> => C<1>

=item * C<MEDIA_STATUS_ACK> => C<2>

=back

=head3 Enum: StaticMediaPrompt::OptionalMediaControls

=over 4

=item * C<OPTIONAL_MEDIA_CONTROLS_UNSPECIFIED> => C<0>

=item * C<PAUSED> => C<1>

=item * C<STOPPED> => C<2>

=back

=head3 Enum: StaticMediaPrompt::RepeatMode

=over 4

=item * C<REPEAT_MODE_UNSPECIFIED> => C<0>

=item * C<OFF> => C<1>

=item * C<ALL> => C<2>

=back

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaObject

Represents a single media object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Name of this media object.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Description of this media object.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

The url pointing to the media content.

=item * C<< $msg->image() >> / C<< $msg->image($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaImage>)

Image to show with the media card.

=back

=head2 Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::MediaImage

Image to be shown inside a MediaPrompt.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->large() >> / C<< $msg->large($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt>)

A large image, such as the cover of the album, etc.

=item * C<< $msg->icon() >> / C<< $msg->icon($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticImagePrompt::StaticImagePrompt>)

A small image icon displayed on the right from the title.
It's resized to 36x36 dp.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Interactionmodel::Prompt::StaticMediaPrompt::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
