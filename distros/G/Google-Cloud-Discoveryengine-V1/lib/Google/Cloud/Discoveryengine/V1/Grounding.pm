package Google::Cloud::Discoveryengine::V1::Grounding;

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
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2dyb3VuZGluZy5wcm90bxIfZ29v
Z2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlv
ci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byLLAQoNR3JvdW5kaW5nRmFjdBIb
CglmYWN0X3RleHQYASABKAlSCGZhY3RUZXh0El4KCmF0dHJpYnV0ZXMYAiADKAsyPi5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxLkdyb3VuZGluZ0ZhY3QuQXR0cmlidXRlc0Vu
dHJ5UgphdHRyaWJ1dGVzGj0KD0F0dHJpYnV0ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIU
CgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIsQCCglGYWN0Q2h1bmsSHQoKY2h1bmtfdGV4dBgB
IAEoCVIJY2h1bmtUZXh0EhYKBnNvdXJjZRgCIAEoCVIGc291cmNlEhQKBWluZGV4GAQgASgF
UgVpbmRleBJnCg9zb3VyY2VfbWV0YWRhdGEYAyADKAsyPi5nb29nbGUuY2xvdWQuZGlzY292
ZXJ5ZW5naW5lLnYxLkZhY3RDaHVuay5Tb3VyY2VNZXRhZGF0YUVudHJ5Ug5zb3VyY2VNZXRh
ZGF0YRIQCgN1cmkYBSABKAlSA3VyaRIUCgV0aXRsZRgGIAEoCVIFdGl0bGUSFgoGZG9tYWlu
GAcgASgJUgZkb21haW4aQQoTU291cmNlTWV0YWRhdGFFbnRyeRIQCgNrZXkYASABKAlSA2tl
eRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBQoECCiNjb20uZ29vZ2xlLmNsb3VkLmRpc2Nv
dmVyeWVuZ2luZS52MUIOR3JvdW5kaW5nUHJvdG9QAVpNY2xvdWQuZ29vZ2xlLmNvbS9nby9k
aXNjb3ZlcnllbmdpbmUvYXBpdjEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5l
cGKiAg9ESVNDT1ZFUllFTkdJTkWqAh9Hb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYx
ygIfR29vZ2xlXENsb3VkXERpc2NvdmVyeUVuZ2luZVxWMeoCIkdvb2dsZTo6Q2xvdWQ6OkRp
c2NvdmVyeUVuZ2luZTo6VjFKwxAKBhIEDgBCAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAy
MDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZl
cnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUg
ZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWlu
IGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcv
bGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBs
YXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRl
ciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lU
SE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHBy
ZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5n
dWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUg
TGljZW5zZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoBCBIDFQA8CgkK
AgglEgMVADwKCAoBCBIDFgBkCgkKAggLEgMWAGQKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoB
CBIDGAAvCgkKAggIEgMYAC8KCAoBCBIDGQA8CgkKAggBEgMZADwKCAoBCBIDGgAtCgkKAggk
EgMaAC0KCAoBCBIDGwA8CgkKAggpEgMbADwKCAoBCBIDHAA7CgkKAggtEgMcADsKHQoCBAAS
BB8AJwEaESBHcm91bmRpbmcgRmFjdC4KCgoKAwQAARIDHwgVCkwKBAQAAgASAyECFxo/IFRl
eHQgY29udGVudCBvZiB0aGUgZmFjdC4gQ2FuIGJlIGF0IG1vc3QgMTBLIGNoYXJhY3RlcnMg
bG9uZy4KCgwKBQQAAgAFEgMhAggKDAoFBAACAAESAyEJEgoMCgUEAAIAAxIDIRUWCsABCgQE
AAIBEgMmAiUasgEgQXR0cmlidXRlcyBhc3NvY2lhdGVkIHdpdGggdGhlIGZhY3QuCiBDb21t
b24gYXR0cmlidXRlcyBpbmNsdWRlIGBzb3VyY2VgIChpbmRpY2F0aW5nIHdoZXJlIHRoZSBm
YWN0IHdhcyBzb3VyY2VkCiBmcm9tKSwgYGF1dGhvcmAgKGluZGljYXRpbmcgdGhlIGF1dGhv
ciBvZiB0aGUgZmFjdCksIGFuZCBzbyBvbi4KCgwKBQQAAgEGEgMmAhUKDAoFBAACAQESAyYW
IAoMCgUEAAIBAxIDJiMkChkKAgQBEgQqAEIBGg0gRmFjdCBDaHVuay4KCgoKAwQBARIDKggR
ClIKBAQBAgASAywCGBpFIFRleHQgY29udGVudCBvZiB0aGUgZmFjdCBjaHVuay4gQ2FuIGJl
IGF0IG1vc3QgMTBLIGNoYXJhY3RlcnMgbG9uZy4KCgwKBQQBAgAFEgMsAggKDAoFBAECAAES
AywJEwoMCgUEAQIAAxIDLBYXCugBCgQEAQIBEgMyAhQa2gEgU291cmNlIGZyb20gd2hpY2gg
dGhpcyBmYWN0IGNodW5rIHdhcyByZXRyaWV2ZWQuIElmIGl0IHdhcyByZXRyaWV2ZWQKIGZy
b20gdGhlIEdyb3VuZGluZ0ZhY3RzIHByb3ZpZGVkIGluIHRoZSByZXF1ZXN0IHRoZW4gdGhp
cyBmaWVsZCB3aWxsCiBjb250YWluIHRoZSBpbmRleCBvZiB0aGUgc3BlY2lmaWMgZmFjdCBm
cm9tIHdoaWNoIHRoaXMgY2h1bmsgd2FzCiByZXRyaWV2ZWQuCgoMCgUEAQIBBRIDMgIICgwK
BQQBAgEBEgMyCQ8KDAoFBAECAQMSAzISEwpUCgQEAQICEgM1AhIaRyBUaGUgaW5kZXggb2Yg
dGhpcyBjaHVuay4gQ3VycmVudGx5LCBvbmx5IHVzZWQgZm9yIHRoZSBzdHJlYW1pbmcgbW9k
ZS4KCgwKBQQBAgIFEgM1AgcKDAoFBAECAgESAzUIDQoMCgUEAQICAxIDNRARCkYKBAQBAgMS
AzgCKho5IE1vcmUgZmluZS1ncmFpbmVkIGluZm9ybWF0aW9uIGZvciB0aGUgc291cmNlIHJl
ZmVyZW5jZS4KCgwKBQQBAgMGEgM4AhUKDAoFBAECAwESAzgWJQoMCgUEAQIDAxIDOCgpCiUK
BAQBAgQSAzsCERoYIFRoZSBVUkkgb2YgdGhlIHNvdXJjZS4KCgwKBQQBAgQFEgM7AggKDAoF
BAECBAESAzsJDAoMCgUEAQIEAxIDOw8QCicKBAQBAgUSAz4CExoaIFRoZSB0aXRsZSBvZiB0
aGUgc291cmNlLgoKDAoFBAECBQUSAz4CCAoMCgUEAQIFARIDPgkOCgwKBQQBAgUDEgM+ERIK
KAoEBAECBhIDQQIUGhsgVGhlIGRvbWFpbiBvZiB0aGUgc291cmNlLgoKDAoFBAECBgUSA0EC
CAoMCgUEAQIGARIDQQkPCgwKBQQBAgYDEgNBEhNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::Grounding::GroundingFact ===
    # Fields for GroundingFact
    # Field: fact_text Type: 9 ()
    # Field: attributes Type: 11 (.google.cloud.discoveryengine.v1.GroundingFact.AttributesEntry)

# === Message: Google::Cloud::Discoveryengine::V1::Grounding::FactChunk ===
    # Fields for FactChunk
    # Field: chunk_text Type: 9 ()
    # Field: source Type: 9 ()
    # Field: index Type: 5 ()
    # Field: source_metadata Type: 11 (.google.cloud.discoveryengine.v1.FactChunk.SourceMetadataEntry)
    # Field: uri Type: 9 ()
    # Field: title Type: 9 ()
    # Field: domain Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::Grounding - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/grounding.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::Grounding;

    my $msg = Google::Cloud::Discoveryengine::V1::Grounding::GroundingFact->new({
        fact_text => $fact_text,
        attributes => $attributes,
    });

    # Read or update a field
    my $val = $msg->fact_text();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::Grounding::GroundingFact->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/grounding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::Grounding::GroundingFact

Grounding Fact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fact_text() >> / C<< $msg->fact_text($value) >>

Type: C<String>

Text content of the fact. Can be at most 10K characters long.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Grounding::GroundingFact::AttributesEntry>)

Attributes associated with the fact.
Common attributes include `source` (indicating where the fact was sourced
from), `author` (indicating the author of the fact), and so on.

=back

=head2 Google::Cloud::Discoveryengine::V1::Grounding::FactChunk

Fact Chunk.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->chunk_text() >> / C<< $msg->chunk_text($value) >>

Type: C<String>

Text content of the fact chunk. Can be at most 10K characters long.

=item * C<< $msg->source() >> / C<< $msg->source($value) >>

Type: C<String>

Source from which this fact chunk was retrieved. If it was retrieved
from the GroundingFacts provided in the request then this field will
contain the index of the specific fact from which this chunk was
retrieved.

=item * C<< $msg->index() >> / C<< $msg->index($value) >>

Type: C<Int32>

The index of this chunk. Currently, only used for the streaming mode.

=item * C<< $msg->source_metadata() >> / C<< $msg->source_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::Grounding::FactChunk::SourceMetadataEntry>)

More fine-grained information for the source reference.

=item * C<< $msg->uri() >> / C<< $msg->uri($value) >>

Type: C<String>

The URI of the source.

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

The title of the source.

=item * C<< $msg->domain() >> / C<< $msg->domain($value) >>

Type: C<String>

The domain of the source.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::Grounding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
