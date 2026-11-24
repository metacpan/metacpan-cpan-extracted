package Google::Ai::Generativelanguage::V1::Content;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvYWkvZ2VuZXJhdGl2ZWxhbmd1YWdlL3YxL2NvbnRlbnQucHJvdG8SH2dvb2ds
ZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aHmdvb2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90byJfCgdDb250ZW50EjsKBXBh
cnRzGAEgAygLMiUuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFnZS52MS5QYXJ0UgVwYXJ0
cxIXCgRyb2xlGAIgASgJQgPgQQFSBHJvbGUi2AEKBFBhcnQSFAoEdGV4dBgCIAEoCUgAUgR0
ZXh0EkgKC2lubGluZV9kYXRhGAMgASgLMiUuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5ndWFn
ZS52MS5CbG9iSABSCmlubGluZURhdGESXAoOdmlkZW9fbWV0YWRhdGEYDiABKAsyLi5nb29n
bGUuYWkuZ2VuZXJhdGl2ZWxhbmd1YWdlLnYxLlZpZGVvTWV0YWRhdGFCA+BBAUgBUg12aWRl
b01ldGFkYXRhQgYKBGRhdGFCCgoIbWV0YWRhdGEiNwoEQmxvYhIbCgltaW1lX3R5cGUYASAB
KAlSCG1pbWVUeXBlEhIKBGRhdGEYAiABKAxSBGRhdGEiqAEKDVZpZGVvTWV0YWRhdGESQQoM
c3RhcnRfb2Zmc2V0GAEgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQgPgQQFSC3N0
YXJ0T2Zmc2V0Ej0KCmVuZF9vZmZzZXQYAiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRp
b25CA+BBAVIJZW5kT2Zmc2V0EhUKA2ZwcxgDIAEoAUID4EEBUgNmcHMifAoSTW9kYWxpdHlU
b2tlbkNvdW50EkUKCG1vZGFsaXR5GAEgASgOMikuZ29vZ2xlLmFpLmdlbmVyYXRpdmVsYW5n
dWFnZS52MS5Nb2RhbGl0eVIIbW9kYWxpdHkSHwoLdG9rZW5fY291bnQYAiABKAVSCnRva2Vu
Q291bnQqXQoITW9kYWxpdHkSGAoUTU9EQUxJVFlfVU5TUEVDSUZJRUQQABIICgRURVhUEAES
CQoFSU1BR0UQAhIJCgVWSURFTxADEgkKBUFVRElPEAQSDAoIRE9DVU1FTlQQBUKQAQojY29t
Lmdvb2dsZS5haS5nZW5lcmF0aXZlbGFuZ3VhZ2UudjFCDENvbnRlbnRQcm90b1ABWlljbG91
ZC5nb29nbGUuY29tL2dvL2FpL2dlbmVyYXRpdmVsYW5ndWFnZS9hcGl2MS9nZW5lcmF0aXZl
bGFuZ3VhZ2VwYjtnZW5lcmF0aXZlbGFuZ3VhZ2VwYkqnHwoGEgQOAH8BCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMA
KAoICgEIEgMVAHAKCQoCCAsSAxUAcAoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXAC0K
CQoCCAgSAxcALQoICgEIEgMYADwKCQoCCAESAxgAPAojCgIFABIEGwAtARoXIENvbnRlbnQg
UGFydCBtb2RhbGl0eQoKCgoDBQABEgMbBQ0KJAoEBQACABIDHQIbGhcgVW5zcGVjaWZpZWQg
bW9kYWxpdHkuCgoMCgUFAAIAARIDHQIWCgwKBQUAAgACEgMdGRoKGgoEBQACARIDIAILGg0g
UGxhaW4gdGV4dC4KCgwKBQUAAgEBEgMgAgYKDAoFBQACAQISAyAJCgoVCgQFAAICEgMjAgwa
CCBJbWFnZS4KCgwKBQUAAgIBEgMjAgcKDAoFBQACAgISAyMKCwoVCgQFAAIDEgMmAgwaCCBW
aWRlby4KCgwKBQUAAgMBEgMmAgcKDAoFBQACAwISAyYKCwoVCgQFAAIEEgMpAgwaCCBBdWRp
by4KCgwKBQUAAgQBEgMpAgcKDAoFBQACBAISAykKCwoiCgQFAAIFEgMsAg8aFSBEb2N1bWVu
dCwgZS5nLiBQREYuCgoMCgUFAAIFARIDLAIKCgwKBQUAAgUCEgMsDQ4KhwIKAgQAEgQ0AD4B
GvoBIFRoZSBiYXNlIHN0cnVjdHVyZWQgZGF0YXR5cGUgY29udGFpbmluZyBtdWx0aS1wYXJ0
IGNvbnRlbnQgb2YgYSBtZXNzYWdlLgoKIEEgYENvbnRlbnRgIGluY2x1ZGVzIGEgYHJvbGVg
IGZpZWxkIGRlc2lnbmF0aW5nIHRoZSBwcm9kdWNlciBvZiB0aGUgYENvbnRlbnRgCiBhbmQg
YSBgcGFydHNgIGZpZWxkIGNvbnRhaW5pbmcgbXVsdGktcGFydCBkYXRhIHRoYXQgY29udGFp
bnMgdGhlIGNvbnRlbnQgb2YKIHRoZSBtZXNzYWdlIHR1cm4uCgoKCgMEAAESAzQIDwpmCgQE
AAIAEgM3AhoaWSBPcmRlcmVkIGBQYXJ0c2AgdGhhdCBjb25zdGl0dXRlIGEgc2luZ2xlIG1l
c3NhZ2UuIFBhcnRzIG1heSBoYXZlIGRpZmZlcmVudAogTUlNRSB0eXBlcy4KCgwKBQQAAgAE
EgM3AgoKDAoFBAACAAYSAzcLDwoMCgUEAAIAARIDNxAVCgwKBQQAAgADEgM3GBkKrQEKBAQA
AgESAz0COxqfASBPcHRpb25hbC4gVGhlIHByb2R1Y2VyIG9mIHRoZSBjb250ZW50LiBNdXN0
IGJlIGVpdGhlciAndXNlcicgb3IgJ21vZGVsJy4KCiBVc2VmdWwgdG8gc2V0IGZvciBtdWx0
aS10dXJuIGNvbnZlcnNhdGlvbnMsIG90aGVyd2lzZSBjYW4gYmUgbGVmdCBibGFuawogb3Ig
dW5zZXQuCgoMCgUEAAIBBRIDPQIICgwKBQQAAgEBEgM9CQ0KDAoFBAACAQMSAz0QEQoMCgUE
AAIBCBIDPRI6Cg8KCAQAAgEInAgAEgM9EzkK7QIKAgQBEgRHAFYBGuACIEEgZGF0YXR5cGUg
Y29udGFpbmluZyBtZWRpYSB0aGF0IGlzIHBhcnQgb2YgYSBtdWx0aS1wYXJ0IGBDb250ZW50
YCBtZXNzYWdlLgoKIEEgYFBhcnRgIGNvbnNpc3RzIG9mIGRhdGEgd2hpY2ggaGFzIGFuIGFz
c29jaWF0ZWQgZGF0YXR5cGUuIEEgYFBhcnRgIGNhbiBvbmx5CiBjb250YWluIG9uZSBvZiB0
aGUgYWNjZXB0ZWQgdHlwZXMgaW4gYFBhcnQuZGF0YWAuCgogQSBgUGFydGAgbXVzdCBoYXZl
IGEgZml4ZWQgSUFOQSBNSU1FIHR5cGUgaWRlbnRpZnlpbmcgdGhlIHR5cGUgYW5kIHN1YnR5
cGUKIG9mIHRoZSBtZWRpYSBpZiB0aGUgYGlubGluZV9kYXRhYCBmaWVsZCBpcyBmaWxsZWQg
d2l0aCByYXcgYnl0ZXMuCgoKCgMEAQESA0cIDAoMCgQEAQgAEgRIAk4DCgwKBQQBCAABEgNI
CAwKGwoEBAECABIDSgQUGg4gSW5saW5lIHRleHQuCgoMCgUEAQIABRIDSgQKCgwKBQQBAgAB
EgNKCw8KDAoFBAECAAMSA0oSEwoiCgQEAQIBEgNNBBkaFSBJbmxpbmUgbWVkaWEgYnl0ZXMu
CgoMCgUEAQIBBhIDTQQICgwKBQQBAgEBEgNNCRQKDAoFBAECAQMSA00XGAo1CgQEAQgBEgRR
AlUDGicgQ29udHJvbHMgZXh0cmEgcHJlcHJvY2Vzc2luZyBvZiBkYXRhLgoKDAoFBAEIAQES
A1EIEAqPAQoEBAECAhIDVARPGoEBIE9wdGlvbmFsLiBWaWRlbyBtZXRhZGF0YS4gVGhlIG1l
dGFkYXRhIHNob3VsZCBvbmx5IGJlIHNwZWNpZmllZCB3aGlsZSB0aGUKIHZpZGVvIGRhdGEg
aXMgcHJlc2VudGVkIGluIGlubGluZV9kYXRhIG9yIGZpbGVfZGF0YS4KCgwKBQQBAgIGEgNU
BBEKDAoFBAECAgESA1QSIAoMCgUEAQICAxIDVCMlCgwKBQQBAgIIEgNUJk4KDwoIBAECAgic
CAASA1QnTQpcCgIEAhIEWwBnARpQIFJhdyBtZWRpYSBieXRlcy4KCiBUZXh0IHNob3VsZCBu
b3QgYmUgc2VudCBhcyByYXcgYnl0ZXMsIHVzZSB0aGUgJ3RleHQnIGZpZWxkLgoKCgoDBAIB
EgNbCAwKyQIKBAQCAgASA2MCFxq7AiBUaGUgSUFOQSBzdGFuZGFyZCBNSU1FIHR5cGUgb2Yg
dGhlIHNvdXJjZSBkYXRhLgogRXhhbXBsZXM6CiAgIC0gaW1hZ2UvcG5nCiAgIC0gaW1hZ2Uv
anBlZwogSWYgYW4gdW5zdXBwb3J0ZWQgTUlNRSB0eXBlIGlzIHByb3ZpZGVkLCBhbiBlcnJv
ciB3aWxsIGJlIHJldHVybmVkLiBGb3IgYQogY29tcGxldGUgbGlzdCBvZiBzdXBwb3J0ZWQg
dHlwZXMsIHNlZSBbU3VwcG9ydGVkIGZpbGUKIGZvcm1hdHNdKGh0dHBzOi8vYWkuZ29vZ2xl
LmRldi9nZW1pbmktYXBpL2RvY3MvcHJvbXB0aW5nX3dpdGhfbWVkaWEjc3VwcG9ydGVkX2Zp
bGVfZm9ybWF0cykuCgoMCgUEAgIABRIDYwIICgwKBQQCAgABEgNjCRIKDAoFBAICAAMSA2MV
FgorCgQEAgIBEgNmAhEaHiBSYXcgYnl0ZXMgZm9yIG1lZGlhIGZvcm1hdHMuCgoMCgUEAgIB
BRIDZgIHCgwKBQQCAgEBEgNmCAwKDAoFBAICAQMSA2YPEAo5CgIEAxIEagB2ARotIE1ldGFk
YXRhIGRlc2NyaWJlcyB0aGUgaW5wdXQgdmlkZW8gY29udGVudC4KCgoKAwQDARIDaggVCjgK
BAQDAgASBGwCbS8aKiBPcHRpb25hbC4gVGhlIHN0YXJ0IG9mZnNldCBvZiB0aGUgdmlkZW8u
CgoMCgUEAwIABhIDbAIaCgwKBQQDAgABEgNsGycKDAoFBAMCAAMSA2wqKwoMCgUEAwIACBID
bQYuCg8KCAQDAgAInAgAEgNtBy0KNgoEBAMCARIEcAJxLxooIE9wdGlvbmFsLiBUaGUgZW5k
IG9mZnNldCBvZiB0aGUgdmlkZW8uCgoMCgUEAwIBBhIDcAIaCgwKBQQDAgEBEgNwGyUKDAoF
BAMCAQMSA3AoKQoMCgUEAwIBCBIDcQYuCg8KCAQDAgEInAgAEgNxBy0KmAEKBAQDAgISA3UC
OhqKASBPcHRpb25hbC4gVGhlIGZyYW1lIHJhdGUgb2YgdGhlIHZpZGVvIHNlbnQgdG8gdGhl
IG1vZGVsLiBJZiBub3Qgc3BlY2lmaWVkLAogdGhlIGRlZmF1bHQgdmFsdWUgd2lsbCBiZSAx
LjAuIFRoZSBmcHMgcmFuZ2UgaXMgKDAuMCwgMjQuMF0uCgoMCgUEAwICBRIDdQIICgwKBQQD
AgIBEgN1CQwKDAoFBAMCAgMSA3UPEAoMCgUEAwICCBIDdRE5Cg8KCAQDAgIInAgAEgN1EjgK
QwoCBAQSBHkAfwEaNyBSZXByZXNlbnRzIHRva2VuIGNvdW50aW5nIGluZm8gZm9yIGEgc2lu
Z2xlIG1vZGFsaXR5LgoKCgoDBAQBEgN5CBoKPQoEBAQCABIDewIYGjAgVGhlIG1vZGFsaXR5
IGFzc29jaWF0ZWQgd2l0aCB0aGlzIHRva2VuIGNvdW50LgoKDAoFBAQCAAYSA3sCCgoMCgUE
BAIAARIDewsTCgwKBQQEAgADEgN7FhcKIAoEBAQCARIDfgIYGhMgTnVtYmVyIG9mIHRva2Vu
cy4KCgwKBQQEAgEFEgN+AgcKDAoFBAQCAQESA34IEwoMCgUEBAIBAxIDfhYXYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Ai::Generativelanguage::V1::Content::Content ===
    # Fields for Content
    # Field: parts Type: 11 (.google.ai.generativelanguage.v1.Part)
    # Field: role Type: 9 ()

# === Message: Google::Ai::Generativelanguage::V1::Content::Part ===
    # Fields for Part
    # Field: text Type: 9 ()
    # Field: inline_data Type: 11 (.google.ai.generativelanguage.v1.Blob)
    # Field: video_metadata Type: 11 (.google.ai.generativelanguage.v1.VideoMetadata)

# === Message: Google::Ai::Generativelanguage::V1::Content::Blob ===
    # Fields for Blob
    # Field: mime_type Type: 9 ()
    # Field: data Type: 12 ()

# === Message: Google::Ai::Generativelanguage::V1::Content::VideoMetadata ===
    # Fields for VideoMetadata
    # Field: start_offset Type: 11 (.google.protobuf.Duration)
    # Field: end_offset Type: 11 (.google.protobuf.Duration)
    # Field: fps Type: 1 ()

# === Message: Google::Ai::Generativelanguage::V1::Content::ModalityTokenCount ===
    # Fields for ModalityTokenCount
    # Field: modality Type: 14 (.google.ai.generativelanguage.v1.Modality)
    # Field: token_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Ai::Generativelanguage::V1::Content - Compiled Protocol Buffers messages for google/ai/generativelanguage/v1/content.proto

=head1 SYNOPSIS

    use Google::Ai::Generativelanguage::V1::Content;

    my $msg = Google::Ai::Generativelanguage::V1::Content::Content->new({
        parts => $parts,
        role => $role,
    });

    # Read or update a field
    my $val = $msg->parts();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Ai::Generativelanguage::V1::Content::Content->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/ai/generativelanguage/v1/content.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Ai::Generativelanguage::V1::Content::Content

The base structured datatype containing multi-part content of a message.

A `Content` includes a `role` field designating the producer of the `Content`
and a `parts` field containing multi-part data that contains the content of
the message turn.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parts() >> / C<< $msg->parts($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1::Content::Part>)

Ordered `Parts` that constitute a single message. Parts may have different
MIME types.

=item * C<< $msg->role() >> / C<< $msg->role($value) >>

Type: C<String>

Optional. The producer of the content. Must be either 'user' or 'model'.

Useful to set for multi-turn conversations, otherwise can be left blank
or unset.

=back

=head2 Google::Ai::Generativelanguage::V1::Content::Part

A datatype containing media that is part of a multi-part `Content` message.

A `Part` consists of data which has an associated datatype. A `Part` can only
contain one of the accepted types in `Part.data`.

A `Part` must have a fixed IANA MIME type identifying the type and subtype
of the media if the `inline_data` field is filled with raw bytes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<String>

Inline text.

=item * C<< $msg->inline_data() >> / C<< $msg->inline_data($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1::Content::Blob>)

Inline media bytes.

=item * C<< $msg->video_metadata() >> / C<< $msg->video_metadata($value) >>

Type: C<Message> (L<Google::Ai::Generativelanguage::V1::Content::VideoMetadata>)

Optional. Video metadata. The metadata should only be specified while the
video data is presented in inline_data or file_data.

=back

=head2 Google::Ai::Generativelanguage::V1::Content::Blob

Raw media bytes.

Text should not be sent as raw bytes, use the 'text' field.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mime_type() >> / C<< $msg->mime_type($value) >>

Type: C<String>

The IANA standard MIME type of the source data.
Examples:
  - image/png
  - image/jpeg
If an unsupported MIME type is provided, an error will be returned. For a
complete list of supported types, see [Supported file
formats](https://ai.google.dev/gemini-api/docs/prompting_with_media#supported_file_formats).

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Bytes>

Raw bytes for media formats.

=back

=head2 Google::Ai::Generativelanguage::V1::Content::VideoMetadata

Metadata describes the input video content.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_offset() >> / C<< $msg->start_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The start offset of the video.

=item * C<< $msg->end_offset() >> / C<< $msg->end_offset($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The end offset of the video.

=item * C<< $msg->fps() >> / C<< $msg->fps($value) >>

Type: C<Double>

Optional. The frame rate of the video sent to the model. If not specified,
the default value will be 1.0. The fps range is (0.0, 24.0].

=back

=head2 Google::Ai::Generativelanguage::V1::Content::ModalityTokenCount

Represents token counting info for a single modality.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->modality() >> / C<< $msg->modality($value) >>

Type: C<Enum> (L<Google::Ai::Generativelanguage::V1::Modality>)

The modality associated with this token count.

=item * C<< $msg->token_count() >> / C<< $msg->token_count($value) >>

Type: C<Int32>

Number of tokens.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Ai::Generativelanguage::V1::Content::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
