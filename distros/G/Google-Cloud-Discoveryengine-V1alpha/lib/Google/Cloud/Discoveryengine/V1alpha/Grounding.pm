package Google::Cloud::Discoveryengine::V1alpha::Grounding;

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
CjRnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYWxwaGEvZ3JvdW5kaW5nLnByb3Rv
EiRnb29nbGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEaH2dvb2dsZS9hcGkvZmll
bGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8i0AEKDUdyb3Vu
ZGluZ0ZhY3QSGwoJZmFjdF90ZXh0GAEgASgJUghmYWN0VGV4dBJjCgphdHRyaWJ1dGVzGAIg
AygLMkMuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWFscGhhLkdyb3VuZGluZ0Zh
Y3QuQXR0cmlidXRlc0VudHJ5UgphdHRyaWJ1dGVzGj0KD0F0dHJpYnV0ZXNFbnRyeRIQCgNr
ZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBIokCCglGYWN0Q2h1bmsS
HQoKY2h1bmtfdGV4dBgBIAEoCVIJY2h1bmtUZXh0EhYKBnNvdXJjZRgCIAEoCVIGc291cmNl
EhQKBWluZGV4GAQgASgFUgVpbmRleBJsCg9zb3VyY2VfbWV0YWRhdGEYAyADKAsyQy5nb29n
bGUuY2xvdWQuZGlzY292ZXJ5ZW5naW5lLnYxYWxwaGEuRmFjdENodW5rLlNvdXJjZU1ldGFk
YXRhRW50cnlSDnNvdXJjZU1ldGFkYXRhGkEKE1NvdXJjZU1ldGFkYXRhRW50cnkSEAoDa2V5
GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AUKaAgooY29tLmdvb2dsZS5j
bG91ZC5kaXNjb3ZlcnllbmdpbmUudjFhbHBoYUIOR3JvdW5kaW5nUHJvdG9QAVpSY2xvdWQu
Z29vZ2xlLmNvbS9nby9kaXNjb3ZlcnllbmdpbmUvYXBpdjFhbHBoYS9kaXNjb3Zlcnllbmdp
bmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVOR0lORaoCJEdvb2dsZS5DbG91
ZC5EaXNjb3ZlcnlFbmdpbmUuVjFBbHBoYcoCJEdvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdp
bmVcVjFhbHBoYeoCJ0dvb2dsZTo6Q2xvdWQ6OkRpc2NvdmVyeUVuZ2luZTo6VjFhbHBoYUrL
DgoGEgQOADkBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAt
CgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVAEEKCQoCCCUSAxUAQQoICgEIEgMWAGkK
CQoCCAsSAxYAaQoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAC8KCQoCCAgSAxgALwoI
CgEIEgMZAEEKCQoCCAESAxkAQQoICgEIEgMaAC0KCQoCCCQSAxoALQoICgEIEgMbAEEKCQoC
CCkSAxsAQQoICgEIEgMcAEAKCQoCCC0SAxwAQAodCgIEABIEHwAnARoRIEdyb3VuZGluZyBG
YWN0LgoKCgoDBAABEgMfCBUKTAoEBAACABIDIQIXGj8gVGV4dCBjb250ZW50IG9mIHRoZSBm
YWN0LiBDYW4gYmUgYXQgbW9zdCAxMEsgY2hhcmFjdGVycyBsb25nLgoKDAoFBAACAAUSAyEC
CAoMCgUEAAIAARIDIQkSCgwKBQQAAgADEgMhFRYKwAEKBAQAAgESAyYCJRqyASBBdHRyaWJ1
dGVzIGFzc29jaWF0ZWQgd2l0aCB0aGUgZmFjdC4KIENvbW1vbiBhdHRyaWJ1dGVzIGluY2x1
ZGUgYHNvdXJjZWAgKGluZGljYXRpbmcgd2hlcmUgdGhlIGZhY3Qgd2FzIHNvdXJjZWQKIGZy
b20pLCBgYXV0aG9yYCAoaW5kaWNhdGluZyB0aGUgYXV0aG9yIG9mIHRoZSBmYWN0KSwgYW5k
IHNvIG9uLgoKDAoFBAACAQYSAyYCFQoMCgUEAAIBARIDJhYgCgwKBQQAAgEDEgMmIyQKGQoC
BAESBCoAOQEaDSBGYWN0IENodW5rLgoKCgoDBAEBEgMqCBEKUgoEBAECABIDLAIYGkUgVGV4
dCBjb250ZW50IG9mIHRoZSBmYWN0IGNodW5rLiBDYW4gYmUgYXQgbW9zdCAxMEsgY2hhcmFj
dGVycyBsb25nLgoKDAoFBAECAAUSAywCCAoMCgUEAQIAARIDLAkTCgwKBQQBAgADEgMsFhcK
6AEKBAQBAgESAzICFBraASBTb3VyY2UgZnJvbSB3aGljaCB0aGlzIGZhY3QgY2h1bmsgd2Fz
IHJldHJpZXZlZC4gSWYgaXQgd2FzIHJldHJpZXZlZAogZnJvbSB0aGUgR3JvdW5kaW5nRmFj
dHMgcHJvdmlkZWQgaW4gdGhlIHJlcXVlc3QgdGhlbiB0aGlzIGZpZWxkIHdpbGwKIGNvbnRh
aW4gdGhlIGluZGV4IG9mIHRoZSBzcGVjaWZpYyBmYWN0IGZyb20gd2hpY2ggdGhpcyBjaHVu
ayB3YXMKIHJldHJpZXZlZC4KCgwKBQQBAgEFEgMyAggKDAoFBAECAQESAzIJDwoMCgUEAQIB
AxIDMhITClQKBAQBAgISAzUCEhpHIFRoZSBpbmRleCBvZiB0aGlzIGNodW5rLiBDdXJyZW50
bHksIG9ubHkgdXNlZCBmb3IgdGhlIHN0cmVhbWluZyBtb2RlLgoKDAoFBAECAgUSAzUCBwoM
CgUEAQICARIDNQgNCgwKBQQBAgIDEgM1EBEKRgoEBAECAxIDOAIqGjkgTW9yZSBmaW5lLWdy
YWluZWQgaW5mb3JtYXRpb24gZm9yIHRoZSBzb3VyY2UgcmVmZXJlbmNlLgoKDAoFBAECAwYS
AzgCFQoMCgUEAQIDARIDOBYlCgwKBQQBAgMDEgM4KCliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1alpha::Grounding::GroundingFact ===
    # Fields for GroundingFact
    # Field: fact_text Type: 9 ()
    # Field: attributes Type: 11 (.google.cloud.discoveryengine.v1alpha.GroundingFact.AttributesEntry)

# === Message: Google::Cloud::Discoveryengine::V1alpha::Grounding::FactChunk ===
    # Fields for FactChunk
    # Field: chunk_text Type: 9 ()
    # Field: source Type: 9 ()
    # Field: index Type: 5 ()
    # Field: source_metadata Type: 11 (.google.cloud.discoveryengine.v1alpha.FactChunk.SourceMetadataEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1alpha::Grounding - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1alpha/grounding.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1alpha::Grounding;

    my $msg = Google::Cloud::Discoveryengine::V1alpha::Grounding::GroundingFact->new({
        fact_text => $fact_text,
        attributes => $attributes,
    });

    # Read or update a field
    my $val = $msg->fact_text();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1alpha::Grounding::GroundingFact->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1alpha/grounding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1alpha::Grounding::GroundingFact

Grounding Fact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fact_text() >> / C<< $msg->fact_text($value) >>

Type: C<String>

Text content of the fact. Can be at most 10K characters long.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Grounding::GroundingFact::AttributesEntry>)

Attributes associated with the fact.
Common attributes include `source` (indicating where the fact was sourced
from), `author` (indicating the author of the fact), and so on.

=back

=head2 Google::Cloud::Discoveryengine::V1alpha::Grounding::FactChunk

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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1alpha::Grounding::FactChunk::SourceMetadataEntry>)

More fine-grained information for the source reference.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1alpha::Grounding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
