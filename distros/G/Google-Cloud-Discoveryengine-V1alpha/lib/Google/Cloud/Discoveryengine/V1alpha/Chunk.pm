package Google::Cloud::Discoveryengine::V1alpha::Chunk;

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
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvY2h1bmsucHJvdG8SJGdv
b2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYRofZ29vZ2xlL2FwaS9maWVsZF9i
ZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxocZ29vZ2xlL3Byb3Rv
YnVmL3N0cnVjdC5wcm90byKmCQoFQ2h1bmsSEgoEbmFtZRgBIAEoCVIEbmFtZRIOCgJpZBgC
IAEoCVICaWQSGAoHY29udGVudBgDIAEoCVIHY29udGVudBIxCg9yZWxldmFuY2Vfc2NvcmUY
CCABKAFCA+BBA0gAUg5yZWxldmFuY2VTY29yZYgBARJpChFkb2N1bWVudF9tZXRhZGF0YRgF
IAEoCzI8Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5DaHVuay5Eb2N1
bWVudE1ldGFkYXRhUhBkb2N1bWVudE1ldGFkYXRhEkwKE2Rlcml2ZWRfc3RydWN0X2RhdGEY
BCABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0QgPgQQNSEWRlcml2ZWRTdHJ1Y3REYXRh
ElEKCXBhZ2Vfc3BhbhgGIAEoCzI0Lmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5DaHVuay5QYWdlU3BhblIIcGFnZVNwYW4SZQoOY2h1bmtfbWV0YWRhdGEYByABKAsy
OS5nb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuQ2h1bmsuQ2h1bmtNZXRh
ZGF0YUID4EEDUg1jaHVua01ldGFkYXRhGnQKEERvY3VtZW50TWV0YWRhdGESEAoDdXJpGAEg
ASgJUgN1cmkSFAoFdGl0bGUYAiABKAlSBXRpdGxlEjgKC3N0cnVjdF9kYXRhGAMgASgLMhcu
Z29vZ2xlLnByb3RvYnVmLlN0cnVjdFIKc3RydWN0RGF0YRpECghQYWdlU3BhbhIdCgpwYWdl
X3N0YXJ0GAEgASgFUglwYWdlU3RhcnQSGQoIcGFnZV9lbmQYAiABKAVSB3BhZ2VFbmQaswEK
DUNodW5rTWV0YWRhdGESVAoPcHJldmlvdXNfY2h1bmtzGAEgAygLMisuZ29vZ2xlLmNsb3Vk
LmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkNodW5rUg5wcmV2aW91c0NodW5rcxJMCgtuZXh0
X2NodW5rcxgCIAMoCzIrLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5D
aHVua1IKbmV4dENodW5rczqyAupBrgIKJGRpc2NvdmVyeWVuZ2luZS5nb29nbGVhcGlzLmNv
bS9DaHVuaxJ1cHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2RhdGFT
dG9yZXMve2RhdGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9L2RvY3VtZW50cy97ZG9jdW1l
bnR9L2NodW5rcy97Y2h1bmt9Eo4BcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9j
YXRpb259L2NvbGxlY3Rpb25zL3tjb2xsZWN0aW9ufS9kYXRhU3RvcmVzL3tkYXRhX3N0b3Jl
fS9icmFuY2hlcy97YnJhbmNofS9kb2N1bWVudHMve2RvY3VtZW50fS9jaHVua3Mve2NodW5r
fUISChBfcmVsZXZhbmNlX3Njb3JlQpYCCihjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVu
Z2luZS52MWFscGhhQgpDaHVua1Byb3RvUAFaUmNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292
ZXJ5ZW5naW5lL2FwaXYxYWxwaGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5l
cGKiAg9ESVNDT1ZFUllFTkdJTkWqAiRHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYx
QWxwaGHKAiRHb29nbGVcQ2xvdWRcRGlzY292ZXJ5RW5naW5lXFYxYWxwaGHqAidHb29nbGU6
OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxYWxwaGFK3yAKBhIEDgB2AQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALQoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCQoCAwISAxQAJgoICgEIEgMWAEEKCQoCCCUSAxYAQQoICgEIEgMXAGkKCQoCCAsSAxcA
aQoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZACsKCQoCCAgSAxkAKwoICgEIEgMaAEEK
CQoCCAESAxoAQQoICgEIEgMbAC0KCQoCCCQSAxsALQoICgEIEgMcAEEKCQoCCCkSAxwAQQoI
CgEIEgMdAEAKCQoCCC0SAx0AQAp0CgIEABIEIQB2ARpoIENodW5rIGNhcHR1cmVzIGFsbCBy
YXcgbWV0YWRhdGEgaW5mb3JtYXRpb24gb2YgaXRlbXMgdG8gYmUgcmVjb21tZW5kZWQgb3IK
IHNlYXJjaGVkIGluIHRoZSBjaHVuayBtb2RlLgoKCgoDBAABEgMhCA0KCwoDBAAHEgQiAiYE
Cg0KBQQAB50IEgQiAiYECmEKBAQAAwASBCoCNgMaUyBEb2N1bWVudCBtZXRhZGF0YSBjb250
YWlucyB0aGUgaW5mb3JtYXRpb24gb2YgdGhlIGRvY3VtZW50IG9mIHRoZSBjdXJyZW50CiBj
aHVuay4KCgwKBQQAAwABEgMqChoKJQoGBAADAAIAEgMsBBMaFiBVcmkgb2YgdGhlIGRvY3Vt
ZW50LgoKDgoHBAADAAIABRIDLAQKCg4KBwQAAwACAAESAywLDgoOCgcEAAMAAgADEgMsERIK
JwoGBAADAAIBEgMvBBUaGCBUaXRsZSBvZiB0aGUgZG9jdW1lbnQuCgoOCgcEAAMAAgEFEgMv
BAoKDgoHBAADAAIBARIDLwsQCg4KBwQAAwACAQMSAy8TFArYAQoGBAADAAICEgM1BCsayAEg
RGF0YSByZXByZXNlbnRhdGlvbi4KIFRoZSBzdHJ1Y3R1cmVkIEpTT04gZGF0YSBmb3IgdGhl
IGRvY3VtZW50LiBJdCBzaG91bGQgY29uZm9ybSB0byB0aGUKIHJlZ2lzdGVyZWQgW1NjaGVt
YV1bZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLlNjaGVtYV0gb3IgYW4K
IGBJTlZBTElEX0FSR1VNRU5UYCBlcnJvciBpcyB0aHJvd24uCgoOCgcEAAMAAgIGEgM1BBoK
DgoHBAADAAICARIDNRsmCg4KBwQAAwACAgMSAzUpKgonCgQEAAMBEgQ5Aj8DGhkgUGFnZSBz
cGFuIG9mIHRoZSBjaHVuay4KCgwKBQQAAwEBEgM5ChIKLQoGBAADAQIAEgM7BBkaHiBUaGUg
c3RhcnQgcGFnZSBvZiB0aGUgY2h1bmsuCgoOCgcEAAMBAgAFEgM7BAkKDgoHBAADAQIAARID
OwoUCg4KBwQAAwECAAMSAzsXGAorCgYEAAMBAgESAz4EFxocIFRoZSBlbmQgcGFnZSBvZiB0
aGUgY2h1bmsuCgoOCgcEAAMBAgEFEgM+BAkKDgoHBAADAQIBARIDPgoSCg4KBwQAAwECAQMS
Az4VFgqoAQoEBAADAhIERAJSAxqZASBNZXRhZGF0YSBvZiB0aGUgY3VycmVudCBjaHVuay4g
VGhpcyBmaWVsZCBpcyBvbmx5IHBvcHVsYXRlZCBvbgogW1NlYXJjaFNlcnZpY2UuU2VhcmNo
XVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2VhcmNoU2VydmljZS5T
ZWFyY2hdCiBBUEkuCgoMCgUEAAMCARIDRAoXCvcCCgYEAAMCAgASA0oEJxrnAiBUaGUgcHJl
dmlvdXMgY2h1bmtzIG9mIHRoZSBjdXJyZW50IGNodW5rLiBUaGUgbnVtYmVyIGlzIGNvbnRy
b2xsZWQgYnkKIFtTZWFyY2hSZXF1ZXN0LkNvbnRlbnRTZWFyY2hTcGVjLkNodW5rU3BlYy5u
dW1fcHJldmlvdXNfY2h1bmtzXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxw
aGEuU2VhcmNoUmVxdWVzdC5Db250ZW50U2VhcmNoU3BlYy5DaHVua1NwZWMubnVtX3ByZXZp
b3VzX2NodW5rc10uCiBUaGlzIGZpZWxkIGlzIG9ubHkgcG9wdWxhdGVkIG9uCiBbU2VhcmNo
U2VydmljZS5TZWFyY2hdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYS5T
ZWFyY2hTZXJ2aWNlLlNlYXJjaF0KIEFQSS4KCg4KBwQAAwICAAQSA0oEDAoOCgcEAAMCAgAG
EgNKDRIKDgoHBAADAgIAARIDShMiCg4KBwQAAwICAAMSA0olJgrrAgoGBAADAgIBEgNRBCMa
2wIgVGhlIG5leHQgY2h1bmtzIG9mIHRoZSBjdXJyZW50IGNodW5rLiBUaGUgbnVtYmVyIGlz
IGNvbnRyb2xsZWQgYnkKIFtTZWFyY2hSZXF1ZXN0LkNvbnRlbnRTZWFyY2hTcGVjLkNodW5r
U3BlYy5udW1fbmV4dF9jaHVua3NdW2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFh
bHBoYS5TZWFyY2hSZXF1ZXN0LkNvbnRlbnRTZWFyY2hTcGVjLkNodW5rU3BlYy5udW1fbmV4
dF9jaHVua3NdLgogVGhpcyBmaWVsZCBpcyBvbmx5IHBvcHVsYXRlZCBvbgogW1NlYXJjaFNl
cnZpY2UuU2VhcmNoXVtnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuU2Vh
cmNoU2VydmljZS5TZWFyY2hdCiBBUEkuCgoOCgcEAAMCAgEEEgNRBAwKDgoHBAADAgIBBhID
UQ0SCg4KBwQAAwICAQESA1ETHgoOCgcEAAMCAgEDEgNRISIKqwIKBAQAAgASA1oCEhqdAiBU
aGUgZnVsbCByZXNvdXJjZSBuYW1lIG9mIHRoZSBjaHVuay4KIEZvcm1hdDoKIGBwcm9qZWN0
cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29sbGVjdGlvbnMve2NvbGxlY3Rp
b259L2RhdGFTdG9yZXMve2RhdGFfc3RvcmV9L2JyYW5jaGVzL3ticmFuY2h9L2RvY3VtZW50
cy97ZG9jdW1lbnRfaWR9L2NodW5rcy97Y2h1bmtfaWR9YC4KCiBUaGlzIGZpZWxkIG11c3Qg
YmUgYSBVVEYtOCBlbmNvZGVkIHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEwMjQK
IGNoYXJhY3RlcnMuCgoMCgUEAAIABRIDWgIICgwKBQQAAgABEgNaCQ0KDAoFBAACAAMSA1oQ
EQo0CgQEAAIBEgNdAhAaJyBVbmlxdWUgY2h1bmsgSUQgb2YgdGhlIGN1cnJlbnQgY2h1bmsu
CgoMCgUEAAIBBRIDXQIICgwKBQQAAgEBEgNdCQsKDAoFBAACAQMSA10ODwpECgQEAAICEgNg
AhUaNyBDb250ZW50IGlzIGEgc3RyaW5nIGZyb20gYSBkb2N1bWVudCAocGFyc2VkIGNvbnRl
bnQpLgoKDAoFBAACAgUSA2ACCAoMCgUEAAICARIDYAkQCgwKBQQAAgIDEgNgExQK2gEKBAQA
AgMSBGYCZzIaywEgT3V0cHV0IG9ubHkuIFJlcHJlc2VudHMgdGhlIHJlbGV2YW5jZSBzY29y
ZSBiYXNlZCBvbiBzaW1pbGFyaXR5LgogSGlnaGVyIHNjb3JlIGluZGljYXRlcyBoaWdoZXIg
Y2h1bmsgcmVsZXZhbmNlLgogVGhlIHNjb3JlIGlzIGluIHJhbmdlIFstMS4wLCAxLjBdLgog
T25seSBwb3B1bGF0ZWQgb24gW1NlYXJjaFNlcnZpY2UuU2VhcmNoUmVzcG9uc2VdW10uCgoM
CgUEAAIDBBIDZgIKCgwKBQQAAgMFEgNmCxEKDAoFBAACAwESA2YSIQoMCgUEAAIDAxIDZiQl
CgwKBQQAAgMIEgNnBjEKDwoIBAACAwicCAASA2cHMAo/CgQEAAIEEgNqAikaMiBNZXRhZGF0
YSBvZiB0aGUgZG9jdW1lbnQgZnJvbSB0aGUgY3VycmVudCBjaHVuay4KCgwKBQQAAgQGEgNq
AhIKDAoFBAACBAESA2oTJAoMCgUEAAIEAxIDaicoCn4KBAQAAgUSBG4CbzIacCBPdXRwdXQg
b25seS4gVGhpcyBmaWVsZCBpcyBPVVRQVVRfT05MWS4KIEl0IGNvbnRhaW5zIGRlcml2ZWQg
ZGF0YSB0aGF0IGFyZSBub3QgaW4gdGhlIG9yaWdpbmFsIGlucHV0IGRvY3VtZW50LgoKDAoF
BAACBQYSA24CGAoMCgUEAAIFARIDbhksCgwKBQQAAgUDEgNuLzAKDAoFBAACBQgSA28GMQoP
CggEAAIFCJwIABIDbwcwCiYKBAQAAgYSA3ICGRoZIFBhZ2Ugc3BhbiBvZiB0aGUgY2h1bmsu
CgoMCgUEAAIGBhIDcgIKCgwKBQQAAgYBEgNyCxQKDAoFBAACBgMSA3IXGAo6CgQEAAIHEgN1
Ak8aLSBPdXRwdXQgb25seS4gTWV0YWRhdGEgb2YgdGhlIGN1cnJlbnQgY2h1bmsuCgoMCgUE
AAIHBhIDdQIPCgwKBQQAAgcBEgN1EB4KDAoFBAACBwMSA3UhIgoMCgUEAAIHCBIDdSNOCg8K
CAQAAgcInAgAEgN1JE1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk ===
    # Fields for Chunk
    # Field: name Type: 9 ()
    # Field: id Type: 9 ()
    # Field: content Type: 9 ()
    # Field: relevance_score Type: 1 ()
    # Field: document_metadata Type: 11 (.google.cloud.discoveryengine.v1alpha.Chunk.DocumentMetadata)
    # Field: derived_struct_data Type: 11 (.google.protobuf.Struct)
    # Field: page_span Type: 11 (.google.cloud.discoveryengine.v1alpha.Chunk.PageSpan)
    # Field: chunk_metadata Type: 11 (.google.cloud.discoveryengine.v1alpha.Chunk.ChunkMetadata)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Chunk - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/chunk.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::Chunk;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk->new({
        name => $name,
        id => $id,
        content => $content,
        relevance_score => $relevance_score,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/chunk.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk

Chunk captures all raw metadata information of items to be recommended or
searched in the chunk mode.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The full resource name of the chunk.
Format:
`projects/{project}/locations/{location}/collections/{collection}/dataStores/{data_store}/branches/{branch}/documents/{document_id}/chunks/{chunk_id}`.

This field must be a UTF-8 encoded string with a length limit of 1024
characters.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Unique chunk ID of the current chunk.

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Content is a string from a document (parsed content).

=item * C<< $msg->relevance_score() >> / C<< $msg->relevance_score($value) >>

Type: C<Double>

Output only. Represents the relevance score based on similarity.
Higher score indicates higher chunk relevance.
The score is in range [-1.0, 1.0].
Only populated on [SearchService.SearchResponse][].

=item * C<< $msg->document_metadata() >> / C<< $msg->document_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::DocumentMetadata>)

Metadata of the document from the current chunk.

=item * C<< $msg->derived_struct_data() >> / C<< $msg->derived_struct_data($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. This field is OUTPUT_ONLY.
It contains derived data that are not in the original input document.

=item * C<< $msg->page_span() >> / C<< $msg->page_span($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::PageSpan>)

Page span of the chunk.

=item * C<< $msg->chunk_metadata() >> / C<< $msg->chunk_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Chunk::Chunk::ChunkMetadata>)

Output only. Metadata of the current chunk.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::Chunk::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
