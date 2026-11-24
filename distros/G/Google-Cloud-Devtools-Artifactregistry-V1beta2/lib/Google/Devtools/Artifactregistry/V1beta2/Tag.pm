package Google::Devtools::Artifactregistry::V1beta2::Tag;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::FieldMask };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvZGV2dG9vbHMvYXJ0aWZhY3RyZWdpc3RyeS92MWJldGEyL3RhZy5wcm90bxIo
Z29vZ2xlLmRldnRvb2xzLmFydGlmYWN0cmVnaXN0cnkudjFiZXRhMhoZZ29vZ2xlL2FwaS9y
ZXNvdXJjZS5wcm90bxogZ29vZ2xlL3Byb3RvYnVmL2ZpZWxkX21hc2sucHJvdG8iwAEKA1Rh
ZxISCgRuYW1lGAEgASgJUgRuYW1lEhgKB3ZlcnNpb24YAiABKAlSB3ZlcnNpb246igHqQYYB
CiNhcnRpZmFjdHJlZ2lzdHJ5Lmdvb2dsZWFwaXMuY29tL1RhZxJfcHJvamVjdHMve3Byb2pl
Y3R9L2xvY2F0aW9ucy97bG9jYXRpb259L3JlcG9zaXRvcmllcy97cmVwb3NpdG9yeX0vcGFj
a2FnZXMve3BhY2thZ2V9L3RhZ3Mve3RhZ30ifQoPTGlzdFRhZ3NSZXF1ZXN0EhYKBnBhcmVu
dBgBIAEoCVIGcGFyZW50EhYKBmZpbHRlchgEIAEoCVIGZmlsdGVyEhsKCXBhZ2Vfc2l6ZRgC
IAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuIn0KEExpc3RU
YWdzUmVzcG9uc2USQQoEdGFncxgBIAMoCzItLmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJl
Z2lzdHJ5LnYxYmV0YTIuVGFnUgR0YWdzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4
dFBhZ2VUb2tlbiIjCg1HZXRUYWdSZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWUiggEKEENy
ZWF0ZVRhZ1JlcXVlc3QSFgoGcGFyZW50GAEgASgJUgZwYXJlbnQSFQoGdGFnX2lkGAIgASgJ
UgV0YWdJZBI/CgN0YWcYAyABKAsyLS5nb29nbGUuZGV2dG9vbHMuYXJ0aWZhY3RyZWdpc3Ry
eS52MWJldGEyLlRhZ1IDdGFnIpABChBVcGRhdGVUYWdSZXF1ZXN0Ej8KA3RhZxgBIAEoCzIt
Lmdvb2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTIuVGFnUgN0YWcSOwoL
dXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrUgp1cGRhdGVN
YXNrIiYKEERlbGV0ZVRhZ1JlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZUKMAgosY29tLmdv
b2dsZS5kZXZ0b29scy5hcnRpZmFjdHJlZ2lzdHJ5LnYxYmV0YTJCCFRhZ1Byb3RvUAFaVWNs
b3VkLmdvb2dsZS5jb20vZ28vYXJ0aWZhY3RyZWdpc3RyeS9hcGl2MWJldGEyL2FydGlmYWN0
cmVnaXN0cnlwYjthcnRpZmFjdHJlZ2lzdHJ5cGKqAiVHb29nbGUuQ2xvdWQuQXJ0aWZhY3RS
ZWdpc3RyeS5WMUJldGEyygIlR29vZ2xlXENsb3VkXEFydGlmYWN0UmVnaXN0cnlcVjFiZXRh
MuoCKEdvb2dsZTo6Q2xvdWQ6OkFydGlmYWN0UmVnaXN0cnk6OlYxYmV0YTJKkR0KBhIEDgB1
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMQoJCgIDABID
EgAjCgkKAgMBEgMTACoKCAoBCBIDFQBCCgkKAgglEgMVAEIKCAoBCBIDFgBsCgkKAggLEgMW
AGwKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAApCgkKAggIEgMYACkKCAoBCBIDGQBF
CgkKAggBEgMZAEUKCAoBCBIDGgBCCgkKAggpEgMaAEIKCAoBCBIDGwBBCgkKAggtEgMbAEEK
cAoCBAASBB8AMQEaZCBUYWdzIHBvaW50IHRvIGEgdmVyc2lvbiBhbmQgcmVwcmVzZW50IGFu
IGFsdGVybmF0aXZlIG5hbWUgdGhhdCBjYW4gYmUgdXNlZAogdG8gYWNjZXNzIHRoZSB2ZXJz
aW9uLgoKCgoDBAABEgMfCAsKCwoDBAAHEgQgAiMECg0KBQQAB50IEgQgAiMECqQCCgQEAAIA
EgMqAhIalgIgVGhlIG5hbWUgb2YgdGhlIHRhZywgZm9yIGV4YW1wbGU6CiAicHJvamVjdHMv
cDEvbG9jYXRpb25zL3VzLWNlbnRyYWwxL3JlcG9zaXRvcmllcy9yZXBvMS9wYWNrYWdlcy9w
a2cxL3RhZ3MvdGFnMSIuCiBJZiB0aGUgcGFja2FnZSBwYXJ0IGNvbnRhaW5zIHNsYXNoZXMs
IHRoZSBzbGFzaGVzIGFyZSBlc2NhcGVkLgogVGhlIHRhZyBwYXJ0IGNhbiBvbmx5IGhhdmUg
Y2hhcmFjdGVycyBpbiBbYS16QS1aMC05XC0uX346QF0sIGFueXRoaW5nIGVsc2UKIG11c3Qg
YmUgVVJMIGVuY29kZWQuCgoMCgUEAAIABRIDKgIICgwKBQQAAgABEgMqCQ0KDAoFBAACAAMS
AyoQEQr0AQoEBAACARIDMAIVGuYBIFRoZSBuYW1lIG9mIHRoZSB2ZXJzaW9uIHRoZSB0YWcg
cmVmZXJzIHRvLCBmb3IgZXhhbXBsZToKICJwcm9qZWN0cy9wMS9sb2NhdGlvbnMvdXMtY2Vu
dHJhbDEvcmVwb3NpdG9yaWVzL3JlcG8xL3BhY2thZ2VzL3BrZzEvdmVyc2lvbnMvc2hhMjU2
OjUyNDM4MTEiCiBJZiB0aGUgcGFja2FnZSBvciB2ZXJzaW9uIElEIHBhcnRzIGNvbnRhaW4g
c2xhc2hlcywgdGhlIHNsYXNoZXMgYXJlCiBlc2NhcGVkLgoKDAoFBAACAQUSAzACCAoMCgUE
AAIBARIDMAkQCgwKBQQAAgEDEgMwExQKJwoCBAESBDQASAEaGyBUaGUgcmVxdWVzdCB0byBs
aXN0IHRhZ3MuCgoKCgMEAQESAzQIFwpJCgQEAQIAEgM2AhQaPCBUaGUgbmFtZSBvZiB0aGUg
cGFyZW50IHJlc291cmNlIHdob3NlIHRhZ3Mgd2lsbCBiZSBsaXN0ZWQuCgoMCgUEAQIABRID
NgIICgwKBQQBAgABEgM2CQ8KDAoFBAECAAMSAzYSEwrqAgoEBAECARIDQQIUGtwCIEFuIGV4
cHJlc3Npb24gZm9yIGZpbHRlcmluZyB0aGUgcmVzdWx0cyBvZiB0aGUgcmVxdWVzdC4gRmls
dGVyIHJ1bGVzIGFyZQogY2FzZSBpbnNlbnNpdGl2ZS4gVGhlIGZpZWxkcyBlbGlnaWJsZSBm
b3IgZmlsdGVyaW5nIGFyZToKCiAgICogYHZlcnNpb25gCgogIEFuIGV4YW1wbGUgb2YgdXNp
bmcgYSBmaWx0ZXI6CgogICAqIGB2ZXJzaW9uPSJwcm9qZWN0cy9wMS9sb2NhdGlvbnMvdXMt
Y2VudHJhbDEvcmVwb3NpdG9yaWVzL3JlcG8xL3BhY2thZ2VzL3BrZzEvdmVyc2lvbnMvMS4w
ImAKICAgLS0+IFRhZ3MgdGhhdCBhcmUgYXBwbGllZCB0byB0aGUgdmVyc2lvbiBgMS4wYCBp
biBwYWNrYWdlIGBwa2cxYC4KCgwKBQQBAgEFEgNBAggKDAoFBAECAQESA0EJDwoMCgUEAQIB
AxIDQRITClEKBAQBAgISA0QCFhpEIFRoZSBtYXhpbXVtIG51bWJlciBvZiB0YWdzIHRvIHJl
dHVybi4gTWF4aW11bSBwYWdlIHNpemUgaXMgMTAsMDAwLgoKDAoFBAECAgUSA0QCBwoMCgUE
AQICARIDRAgRCgwKBQQBAgIDEgNEFBUKVwoEBAECAxIDRwIYGkogVGhlIG5leHRfcGFnZV90
b2tlbiB2YWx1ZSByZXR1cm5lZCBmcm9tIGEgcHJldmlvdXMgbGlzdCByZXF1ZXN0LCBpZiBh
bnkuCgoMCgUEAQIDBRIDRwIICgwKBQQBAgMBEgNHCRMKDAoFBAECAwMSA0cWFwotCgIEAhIE
SwBSARohIFRoZSByZXNwb25zZSBmcm9tIGxpc3RpbmcgdGFncy4KCgoKAwQCARIDSwgYCiEK
BAQCAgASA00CGBoUIFRoZSB0YWdzIHJldHVybmVkLgoKDAoFBAICAAQSA00CCgoMCgUEAgIA
BhIDTQsOCgwKBQQCAgABEgNNDxMKDAoFBAICAAMSA00WFwpqCgQEAgIBEgNRAh0aXSBUaGUg
dG9rZW4gdG8gcmV0cmlldmUgdGhlIG5leHQgcGFnZSBvZiB0YWdzLCBvciBlbXB0eSBpZiB0
aGVyZSBhcmUgbm8KIG1vcmUgdGFncyB0byByZXR1cm4uCgoMCgUEAgIBBRIDUQIICgwKBQQC
AgEBEgNRCRgKDAoFBAICAQMSA1EbHAosCgIEAxIEVQBYARogIFRoZSByZXF1ZXN0IHRvIHJl
dHJpZXZlIGEgdGFnLgoKCgoDBAMBEgNVCBUKLwoEBAMCABIDVwISGiIgVGhlIG5hbWUgb2Yg
dGhlIHRhZyB0byByZXRyaWV2ZS4KCgwKBQQDAgAFEgNXAggKDAoFBAMCAAESA1cJDQoMCgUE
AwIAAxIDVxARCi4KAgQEEgRbAGQBGiIgVGhlIHJlcXVlc3QgdG8gY3JlYXRlIGEgbmV3IHRh
Zy4KCgoKAwQEARIDWwgYCk0KBAQEAgASA10CFBpAIFRoZSBuYW1lIG9mIHRoZSBwYXJlbnQg
cmVzb3VyY2Ugd2hlcmUgdGhlIHRhZyB3aWxsIGJlIGNyZWF0ZWQuCgoMCgUEBAIABRIDXQII
CgwKBQQEAgABEgNdCQ8KDAoFBAQCAAMSA10SEwo1CgQEBAIBEgNgAhQaKCBUaGUgdGFnIGlk
IHRvIHVzZSBmb3IgdGhpcyByZXBvc2l0b3J5LgoKDAoFBAQCAQUSA2ACCAoMCgUEBAIBARID
YAkPCgwKBQQEAgEDEgNgEhMKJQoEBAQCAhIDYwIOGhggVGhlIHRhZyB0byBiZSBjcmVhdGVk
LgoKDAoFBAQCAgYSA2MCBQoMCgUEBAICARIDYwYJCgwKBQQEAgIDEgNjDA0KNAoCBAUSBGcA
bwEaKCBUaGUgcmVxdWVzdCB0byBjcmVhdGUgb3IgdXBkYXRlIGEgdGFnLgoKCgoDBAUBEgNn
CBgKQAoEBAUCABIDaQIOGjMgVGhlIHRhZyB0aGF0IHJlcGxhY2VzIHRoZSByZXNvdXJjZSBv
biB0aGUgc2VydmVyLgoKDAoFBAUCAAYSA2kCBQoMCgUEBQIAARIDaQYJCgwKBQQFAgADEgNp
DA0KtgEKBAQFAgESA24CLBqoASBUaGUgdXBkYXRlIG1hc2sgYXBwbGllcyB0byB0aGUgcmVz
b3VyY2UuIEZvciB0aGUgYEZpZWxkTWFza2AgZGVmaW5pdGlvbiwKIHNlZQogaHR0cHM6Ly9k
ZXZlbG9wZXJzLmdvb2dsZS5jb20vcHJvdG9jb2wtYnVmZmVycy9kb2NzL3JlZmVyZW5jZS9n
b29nbGUucHJvdG9idWYjZmllbGRtYXNrCgoMCgUEBQIBBhIDbgIbCgwKBQQFAgEBEgNuHCcK
DAoFBAUCAQMSA24qKwoqCgIEBhIEcgB1ARoeIFRoZSByZXF1ZXN0IHRvIGRlbGV0ZSBhIHRh
Zy4KCgoKAwQGARIDcggYCi0KBAQGAgASA3QCEhogIFRoZSBuYW1lIG9mIHRoZSB0YWcgdG8g
ZGVsZXRlLgoKDAoFBAYCAAUSA3QCCAoMCgUEBgIAARIDdAkNCgwKBQQGAgADEgN0EBFiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Devtools::Artifactregistry::V1beta2::Tag::Tag ===
    # Fields for Tag
    # Field: name Type: 9 ()
    # Field: version Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsRequest ===
    # Fields for ListTagsRequest
    # Field: parent Type: 9 ()
    # Field: filter Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsResponse ===
    # Fields for ListTagsResponse
    # Field: tags Type: 11 (.google.devtools.artifactregistry.v1beta2.Tag)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Tag::GetTagRequest ===
    # Fields for GetTagRequest
    # Field: name Type: 9 ()

# === Message: Google::Devtools::Artifactregistry::V1beta2::Tag::CreateTagRequest ===
    # Fields for CreateTagRequest
    # Field: parent Type: 9 ()
    # Field: tag_id Type: 9 ()
    # Field: tag Type: 11 (.google.devtools.artifactregistry.v1beta2.Tag)

# === Message: Google::Devtools::Artifactregistry::V1beta2::Tag::UpdateTagRequest ===
    # Fields for UpdateTagRequest
    # Field: tag Type: 11 (.google.devtools.artifactregistry.v1beta2.Tag)
    # Field: update_mask Type: 11 (.google.protobuf.FieldMask)

# === Message: Google::Devtools::Artifactregistry::V1beta2::Tag::DeleteTagRequest ===
    # Fields for DeleteTagRequest
    # Field: name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Devtools::Artifactregistry::V1beta2::Tag - Compiled Protocol Buffers messages for google/devtools/artifactregistry/v1beta2/tag.proto

=head1 SYNOPSIS

    use Google::Devtools::Artifactregistry::V1beta2::Tag;

    my $msg = Google::Devtools::Artifactregistry::V1beta2::Tag::Tag->new({
        name => $name,
        version => $version,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Devtools::Artifactregistry::V1beta2::Tag::Tag->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/devtools/artifactregistry/v1beta2/tag.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Devtools::Artifactregistry::V1beta2::Tag::Tag

Tags point to a version and represent an alternative name that can be used
to access the version.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the tag, for example:
"projects/p1/locations/us-central1/repositories/repo1/packages/pkg1/tags/tag1".
If the package part contains slashes, the slashes are escaped.
The tag part can only have characters in [a-zA-Z0-9\-._~:@], anything else
must be URL encoded.

=item * C<< $msg->version() >> / C<< $msg->version($value) >>

Type: C<String>

The name of the version the tag refers to, for example:
"projects/p1/locations/us-central1/repositories/repo1/packages/pkg1/versions/sha256:5243811"
If the package or version ID parts contain slashes, the slashes are
escaped.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsRequest

The request to list tags.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource whose tags will be listed.

=item * C<< $msg->filter() >> / C<< $msg->filter($value) >>

Type: C<String>

An expression for filtering the results of the request. Filter rules are
case insensitive. The fields eligible for filtering are:

  * `version`

 An example of using a filter:

  * `version="projects/p1/locations/us-central1/repositories/repo1/packages/pkg1/versions/1.0"`
  --> Tags that are applied to the version `1.0` in package `pkg1`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of tags to return. Maximum page size is 10,000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

The next_page_token value returned from a previous list request, if any.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Tag::ListTagsResponse

The response from listing tags.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tags() >> / C<< $msg->tags($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Tag::Tag>)

The tags returned.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

The token to retrieve the next page of tags, or empty if there are no
more tags to return.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Tag::GetTagRequest

The request to retrieve a tag.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the tag to retrieve.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Tag::CreateTagRequest

The request to create a new tag.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

The name of the parent resource where the tag will be created.

=item * C<< $msg->tag_id() >> / C<< $msg->tag_id($value) >>

Type: C<String>

The tag id to use for this repository.

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Tag::Tag>)

The tag to be created.

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Tag::UpdateTagRequest

The request to create or update a tag.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tag() >> / C<< $msg->tag($value) >>

Type: C<Message> (L<Google::Devtools::Artifactregistry::V1beta2::Tag::Tag>)

The tag that replaces the resource on the server.

=item * C<< $msg->update_mask() >> / C<< $msg->update_mask($value) >>

Type: C<Message> (L<Google::Protobuf::FieldMask::FieldMask>)

The update mask applies to the resource. For the `FieldMask` definition,
see
https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask

=back

=head2 Google::Devtools::Artifactregistry::V1beta2::Tag::DeleteTagRequest

The request to delete a tag.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the tag to delete.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Devtools::Artifactregistry::V1beta2::Tag::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
