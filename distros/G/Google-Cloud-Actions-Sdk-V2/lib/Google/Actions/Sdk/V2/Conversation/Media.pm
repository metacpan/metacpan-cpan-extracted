package Google::Actions::Sdk::V2::Conversation::Media;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Actions::Sdk::V2::Conversation::Image };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Cj1nb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L21l
ZGlhLnByb3RvEiJnb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uGj1nb29nbGUv
YWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9jb250ZW50L2ltYWdlLnByb3Rv
Gh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8ijQQKBU1lZGlhElIKCm1lZGlhX3R5
cGUYCCABKA4yMy5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uLk1lZGlhLk1l
ZGlhVHlwZVIJbWVkaWFUeXBlEjwKDHN0YXJ0X29mZnNldBgFIAEoCzIZLmdvb2dsZS5wcm90
b2J1Zi5EdXJhdGlvblILc3RhcnRPZmZzZXQSdwoXb3B0aW9uYWxfbWVkaWFfY29udHJvbHMY
BiADKA4yPy5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uLk1lZGlhLk9wdGlv
bmFsTWVkaWFDb250cm9sc1IVb3B0aW9uYWxNZWRpYUNvbnRyb2xzElQKDW1lZGlhX29iamVj
dHMYByADKAsyLy5nb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uLk1lZGlhT2Jq
ZWN0UgxtZWRpYU9iamVjdHMiSAoJTWVkaWFUeXBlEhoKFk1FRElBX1RZUEVfVU5TUEVDSUZJ
RUQQABIJCgVBVURJTxABEhQKEE1FRElBX1NUQVRVU19BQ0sQAiJZChVPcHRpb25hbE1lZGlh
Q29udHJvbHMSJwojT1BUSU9OQUxfTUVESUFfQ09OVFJPTFNfVU5TUEVDSUZJRUQQABIKCgZQ
QVVTRUQQARILCgdTVE9QUEVEEAIimwEKC01lZGlhT2JqZWN0EhIKBG5hbWUYASABKAlSBG5h
bWUSIAoLZGVzY3JpcHRpb24YAiABKAlSC2Rlc2NyaXB0aW9uEhAKA3VybBgDIAEoCVIDdXJs
EkQKBWltYWdlGAQgASgLMi4uZ29vZ2xlLmFjdGlvbnMuc2RrLnYyLmNvbnZlcnNhdGlvbi5N
ZWRpYUltYWdlUgVpbWFnZSKZAQoKTWVkaWFJbWFnZRJBCgVsYXJnZRgBIAEoCzIpLmdvb2ds
ZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24uSW1hZ2VIAFIFbGFyZ2USPwoEaWNvbhgC
IAEoCzIpLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb24uSW1hZ2VIAFIEaWNv
bkIHCgVpbWFnZUKGAQomY29tLmdvb2dsZS5hY3Rpb25zLnNkay52Mi5jb252ZXJzYXRpb25C
Ck1lZGlhUHJvdG9QAVpOZ29vZ2xlLmdvbGFuZy5vcmcvZ2VucHJvdG8vZ29vZ2xlYXBpcy9h
Y3Rpb25zL3Nkay92Mi9jb252ZXJzYXRpb247Y29udmVyc2F0aW9uSqYWCgYSBA4AYAEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACsKCQoCAwASAxIARwoJ
CgIDARIDEwAoCggKAQgSAxUAZQoJCgIICxIDFQBlCggKAQgSAxYAIgoJCgIIChIDFgAiCggK
AQgSAxcAKwoJCgIICBIDFwArCggKAQgSAxgAPwoJCgIIARIDGAA/CnYKAgQAEgQcAEQBGmog
UmVwcmVzZW50cyBvbmUgbWVkaWEgb2JqZWN0LgogQ29udGFpbnMgaW5mb3JtYXRpb24gYWJv
dXQgdGhlIG1lZGlhLCBzdWNoIGFzIG5hbWUsIGRlc2NyaXB0aW9uLCB1cmwsIGV0Yy4KCgoK
AwQAARIDHAgNCiwKBAQABAASBB4CJwMaHiBNZWRpYSB0eXBlIG9mIHRoaXMgcmVzcG9uc2Uu
CgoMCgUEAAQAARIDHgcQCigKBgQABAACABIDIAQfGhkgVW5zcGVjaWZpZWQgbWVkaWEgdHlw
ZS4KCg4KBwQABAACAAESAyAEGgoOCgcEAAQAAgACEgMgHR4KHAoGBAAEAAIBEgMjBA4aDSBB
dWRpbyBmaWxlLgoKDgoHBAAEAAIBARIDIwQJCg4KBwQABAACAQISAyMMDQo/CgYEAAQAAgIS
AyYEGRowIFJlc3BvbnNlIHRvIGFja25vd2xlZGdlIGEgbWVkaWEgc3RhdHVzIHJlcG9ydC4K
Cg4KBwQABAACAgESAyYEFAoOCgcEAAQAAgICEgMmFxgKSwoEBAAEARIEKgI0Axo9IE9wdGlv
bmFsIG1lZGlhIGNvbnRyb2wgdHlwZXMgdGhlIG1lZGlhIHJlc3BvbnNlIGNhbiBzdXBwb3J0
CgoMCgUEAAQBARIDKgccCiIKBgQABAECABIDLAQsGhMgVW5zcGVjaWZpZWQgdmFsdWUKCg4K
BwQABAECAAESAywEJwoOCgcEAAQBAgACEgMsKisKRAoGBAAEAQIBEgMvBA8aNSBQYXVzZWQg
ZXZlbnQuIFRyaWdnZXJlZCB3aGVuIHVzZXIgcGF1c2VzIHRoZSBtZWRpYS4KCg4KBwQABAEC
AQESAy8ECgoOCgcEAAQBAgECEgMvDQ4KXwoGBAAEAQICEgMzBBAaUCBTdG9wcGVkIGV2ZW50
LiBUcmlnZ2VyZWQgd2hlbiB1c2VyIGV4aXRzIG91dCBvZiAzcCBzZXNzaW9uIGR1cmluZyBt
ZWRpYQogcGxheS4KCg4KBwQABAECAgESAzMECwoOCgcEAAQBAgICEgMzDg8KGgoEBAACABID
NwIbGg0gTWVkaWEgdHlwZS4KCgwKBQQAAgAGEgM3AgsKDAoFBAACAAESAzcMFgoMCgUEAAIA
AxIDNxkaCjYKBAQAAgESAzoCLBopIFN0YXJ0IG9mZnNldCBvZiB0aGUgZmlyc3QgbWVkaWEg
b2JqZWN0LgoKDAoFBAACAQYSAzoCGgoMCgUEAAIBARIDOhsnCgwKBQQAAgEDEgM6KisK7wEK
BAQAAgISA0ACPRrhASBPcHRpb25hbCBtZWRpYSBjb250cm9sIHR5cGVzIHRoaXMgbWVkaWEg
cmVzcG9uc2Ugc2Vzc2lvbiBjYW4gc3VwcG9ydC4KIElmIHNldCwgcmVxdWVzdCB3aWxsIGJl
IG1hZGUgdG8gM3Agd2hlbiBhIGNlcnRhaW4gbWVkaWEgZXZlbnQgaGFwcGVucy4KIElmIG5v
dCBzZXQsIDNwIG11c3Qgc3RpbGwgaGFuZGxlIHR3byBkZWZhdWx0IGNvbnRyb2wgdHlwZSwg
RklOSVNIRUQgYW5kCiBGQUlMRUQuCgoMCgUEAAICBBIDQAIKCgwKBQQAAgIGEgNACyAKDAoF
BAACAgESA0AhOAoMCgUEAAICAxIDQDs8CiQKBAQAAgMSA0MCKRoXIExpc3Qgb2YgTWVkaWEg
T2JqZWN0cwoKDAoFBAACAwQSA0MCCgoMCgUEAAIDBhIDQwsWCgwKBQQAAgMBEgNDFyQKDAoF
BAACAwMSA0MnKAouCgIEARIERwBTARoiIFJlcHJlc2VudHMgYSBzaW5nbGUgbWVkaWEgb2Jq
ZWN0CgoKCgMEAQESA0cIEwopCgQEAQIAEgNJAhIaHCBOYW1lIG9mIHRoaXMgbWVkaWEgb2Jq
ZWN0LgoKDAoFBAECAAUSA0kCCAoMCgUEAQIAARIDSQkNCgwKBQQBAgADEgNJEBEKMAoEBAEC
ARIDTAIZGiMgRGVzY3JpcHRpb24gb2YgdGhpcyBtZWRpYSBvYmplY3QuCgoMCgUEAQIBBRID
TAIICgwKBQQBAgEBEgNMCRQKDAoFBAECAQMSA0wXGAo1CgQEAQICEgNPAhEaKCBUaGUgdXJs
IHBvaW50aW5nIHRvIHRoZSBtZWRpYSBjb250ZW50LgoKDAoFBAECAgUSA08CCAoMCgUEAQIC
ARIDTwkMCgwKBQQBAgIDEgNPDxAKMQoEBAECAxIDUgIXGiQgSW1hZ2UgdG8gc2hvdyB3aXRo
IHRoZSBtZWRpYSBjYXJkLgoKDAoFBAECAwYSA1ICDAoMCgUEAQIDARIDUg0SCgwKBQQBAgMD
EgNSFRYKMAoCBAISBFYAYAEaJCBJbWFnZSB0byBzaG93IHdpdGggdGhlIG1lZGlhIGNhcmQu
CgoKCgMEAgESA1YIEgoWCgQEAggAEgRYAl8DGgggSW1hZ2UuCgoMCgUEAggAARIDWAgNCkIK
BAQCAgASA1oEFBo1IEEgbGFyZ2UgaW1hZ2UsIHN1Y2ggYXMgdGhlIGNvdmVyIG9mIHRoZSBh
bGJ1bSwgZXRjLgoKDAoFBAICAAYSA1oECQoMCgUEAgIAARIDWgoPCgwKBQQCAgADEgNaEhMK
YwoEBAICARIDXgQTGlYgQSBzbWFsbCBpbWFnZSBpY29uIGRpc3BsYXllZCBvbiB0aGUgcmln
aHQgZnJvbSB0aGUgdGl0bGUuCiBJdCdzIHJlc2l6ZWQgdG8gMzZ4MzYgZHAuCgoMCgUEAgIB
BhIDXgQJCgwKBQQCAgEBEgNeCg4KDAoFBAICAQMSA14REmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Media::Media ===
    # Fields for Media
    # Field: media_type Type: 14 (.google.actions.sdk.v2.conversation.Media.MediaType)
    # Field: start_offset Type: 11 (.google.protobuf.Duration)
    # Field: optional_media_controls Type: 14 (.google.actions.sdk.v2.conversation.Media.OptionalMediaControls)
    # Field: media_objects Type: 11 (.google.actions.sdk.v2.conversation.MediaObject)

# Enum: Media::MediaType
our $Media_MEDIA_TYPE_UNSPECIFIED = 0;
our $Media_AUDIO = 1;
our $Media_MEDIA_STATUS_ACK = 2;

# Enum: Media::OptionalMediaControls
our $Media_OPTIONAL_MEDIA_CONTROLS_UNSPECIFIED = 0;
our $Media_PAUSED = 1;
our $Media_STOPPED = 2;

# === Message: Google::Actions::Sdk::V2::Conversation::Media::MediaObject ===
    # Fields for MediaObject
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: url Type: 9 ()
    # Field: image Type: 11 (.google.actions.sdk.v2.conversation.MediaImage)

# === Message: Google::Actions::Sdk::V2::Conversation::Media::MediaImage ===
    # Fields for MediaImage
    # Field: large Type: 11 (.google.actions.sdk.v2.conversation.Image)
    # Field: icon Type: 11 (.google.actions.sdk.v2.conversation.Image)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Media - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/content/media.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Media;

    my $msg = Google::Actions::Sdk::V2::Conversation::Media::Media->new({
        media_type => $media_type,
        start_offset => $start_offset,
        optional_media_controls => $optional_media_controls,
        media_objects => $media_objects,
    });

    # Read or update a field
    my $val = $msg->media_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Media::Media->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/content/media.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Media::Media

Represents one media object.
Contains information about the media, such as name, description, url, etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->media_type() >> / C<< $msg->media_type($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Conversation::Media::MediaType>)

Media type.

=item * C<< $msg->start_offset() >> / C<< $msg->start_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Start offset of the first media object.

=item * C<< $msg->optional_media_controls() >> / C<< $msg->optional_media_controls($value) >>

Type: C<Enum> (L<Google::Actions::Sdk::V2::Conversation::Media::OptionalMediaControls>)

Optional media control types this media response session can support.
If set, request will be made to 3p when a certain media event happens.
If not set, 3p must still handle two default control type, FINISHED and
FAILED.

=item * C<< $msg->media_objects() >> / C<< $msg->media_objects($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Media::MediaObject>)

List of Media Objects

=back

=head3 Enum: Media::MediaType

=over 4

=item * C<MEDIA_TYPE_UNSPECIFIED> => C<0>

=item * C<AUDIO> => C<1>

=item * C<MEDIA_STATUS_ACK> => C<2>

=back

=head3 Enum: Media::OptionalMediaControls

=over 4

=item * C<OPTIONAL_MEDIA_CONTROLS_UNSPECIFIED> => C<0>

=item * C<PAUSED> => C<1>

=item * C<STOPPED> => C<2>

=back

=head2 Google::Actions::Sdk::V2::Conversation::Media::MediaObject

Represents a single media object

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

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Media::MediaImage>)

Image to show with the media card.

=back

=head2 Google::Actions::Sdk::V2::Conversation::Media::MediaImage

Image to show with the media card.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->large() >> / C<< $msg->large($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Image::Image>)

A large image, such as the cover of the album, etc.

=item * C<< $msg->icon() >> / C<< $msg->icon($value) >>

Type: C<Message> (L<Google::Actions::Sdk::V2::Conversation::Image::Image>)

A small image icon displayed on the right from the title.
It's resized to 36x36 dp.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Media::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
