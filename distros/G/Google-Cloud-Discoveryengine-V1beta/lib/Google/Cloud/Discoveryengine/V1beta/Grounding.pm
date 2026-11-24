package Google::Cloud::Discoveryengine::V1beta::Grounding;

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
CjNnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9ncm91bmRpbmcucHJvdG8S
I2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGh9nb29nbGUvYXBpL2ZpZWxk
X2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvIq0BCg9Hcm91bmRp
bmdDb25maWcSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1lOoAB6kF9Ci5kaXNjb3Zlcnllbmdp
bmUuZ29vZ2xlYXBpcy5jb20vR3JvdW5kaW5nQ29uZmlnEktwcm9qZWN0cy97cHJvamVjdH0v
bG9jYXRpb25zL3tsb2NhdGlvbn0vZ3JvdW5kaW5nQ29uZmlncy97Z3JvdW5kaW5nX2NvbmZp
Z30izwEKDUdyb3VuZGluZ0ZhY3QSGwoJZmFjdF90ZXh0GAEgASgJUghmYWN0VGV4dBJiCgph
dHRyaWJ1dGVzGAIgAygLMkIuZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEu
R3JvdW5kaW5nRmFjdC5BdHRyaWJ1dGVzRW50cnlSCmF0dHJpYnV0ZXMaPQoPQXR0cmlidXRl
c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEiyAIK
CUZhY3RDaHVuaxIdCgpjaHVua190ZXh0GAEgASgJUgljaHVua1RleHQSFgoGc291cmNlGAIg
ASgJUgZzb3VyY2USFAoFaW5kZXgYBCABKAVSBWluZGV4EmsKD3NvdXJjZV9tZXRhZGF0YRgD
IAMoCzJCLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhLkZhY3RDaHVuay5T
b3VyY2VNZXRhZGF0YUVudHJ5Ug5zb3VyY2VNZXRhZGF0YRIQCgN1cmkYBSABKAlSA3VyaRIU
CgV0aXRsZRgGIAEoCVIFdGl0bGUSFgoGZG9tYWluGAcgASgJUgZkb21haW4aQQoTU291cmNl
TWV0YWRhdGFFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6
AjgBQpUCCidjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGFCDkdyb3Vu
ZGluZ1Byb3RvUAFaUWNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYx
YmV0YS9kaXNjb3ZlcnllbmdpbmVwYjtkaXNjb3ZlcnllbmdpbmVwYqICD0RJU0NPVkVSWUVO
R0lORaoCI0dvb2dsZS5DbG91ZC5EaXNjb3ZlcnlFbmdpbmUuVjFCZXRhygIjR29vZ2xlXENs
b3VkXERpc2NvdmVyeUVuZ2luZVxWMWJldGHqAiZHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlF
bmdpbmU6OlYxYmV0YUrxEgoGEgQOAE4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAsCgkKAgMAEgMSACkKCQoCAwESAxMAIwoICgEIEgMVAEAKCQoCCCUS
AxUAQAoICgEIEgMWAGgKCQoCCAsSAxYAaAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMY
AC8KCQoCCAgSAxgALwoICgEIEgMZAEAKCQoCCAESAxkAQAoICgEIEgMaAC0KCQoCCCQSAxoA
LQoICgEIEgMbAEAKCQoCCCkSAxsAQAoICgEIEgMcAD8KCQoCCC0SAxwAPwomCgIEABIEHwAo
ARoaIEdyb3VuZGluZyBjb25maWd1cmF0aW9uLgoKCgoDBAABEgMfCBcKCwoDBAAHEgQgAiME
Cg0KBQQAB50IEgQgAiMECpIBCgQEAAIAEgMnAjsahAEgUmVxdWlyZWQuIE5hbWUgb2YgdGhl
IEdyb3VuZGluZ0NvbmZpZywgb2YgdGhlIGZvcm0KIGBwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vZ3JvdW5kaW5nQ29uZmlncy97Z3JvdW5kaW5nX2NvbmZpZ31g
LgoKDAoFBAACAAUSAycCCAoMCgUEAAIAARIDJwkNCgwKBQQAAgADEgMnEBEKDAoFBAACAAgS
AycSOgoPCggEAAIACJwIABIDJxM5Ch0KAgQBEgQrADMBGhEgR3JvdW5kaW5nIEZhY3QuCgoK
CgMEAQESAysIFQpMCgQEAQIAEgMtAhcaPyBUZXh0IGNvbnRlbnQgb2YgdGhlIGZhY3QuIENh
biBiZSBhdCBtb3N0IDEwSyBjaGFyYWN0ZXJzIGxvbmcuCgoMCgUEAQIABRIDLQIICgwKBQQB
AgABEgMtCRIKDAoFBAECAAMSAy0VFgrAAQoEBAECARIDMgIlGrIBIEF0dHJpYnV0ZXMgYXNz
b2NpYXRlZCB3aXRoIHRoZSBmYWN0LgogQ29tbW9uIGF0dHJpYnV0ZXMgaW5jbHVkZSBgc291
cmNlYCAoaW5kaWNhdGluZyB3aGVyZSB0aGUgZmFjdCB3YXMgc291cmNlZAogZnJvbSksIGBh
dXRob3JgIChpbmRpY2F0aW5nIHRoZSBhdXRob3Igb2YgdGhlIGZhY3QpLCBhbmQgc28gb24u
CgoMCgUEAQIBBhIDMgIVCgwKBQQBAgEBEgMyFiAKDAoFBAECAQMSAzIjJAoZCgIEAhIENgBO
ARoNIEZhY3QgQ2h1bmsuCgoKCgMEAgESAzYIEQpSCgQEAgIAEgM4AhgaRSBUZXh0IGNvbnRl
bnQgb2YgdGhlIGZhY3QgY2h1bmsuIENhbiBiZSBhdCBtb3N0IDEwSyBjaGFyYWN0ZXJzIGxv
bmcuCgoMCgUEAgIABRIDOAIICgwKBQQCAgABEgM4CRMKDAoFBAICAAMSAzgWFwroAQoEBAIC
ARIDPgIUGtoBIFNvdXJjZSBmcm9tIHdoaWNoIHRoaXMgZmFjdCBjaHVuayB3YXMgcmV0cmll
dmVkLiBJZiBpdCB3YXMgcmV0cmlldmVkCiBmcm9tIHRoZSBHcm91bmRpbmdGYWN0cyBwcm92
aWRlZCBpbiB0aGUgcmVxdWVzdCB0aGVuIHRoaXMgZmllbGQgd2lsbAogY29udGFpbiB0aGUg
aW5kZXggb2YgdGhlIHNwZWNpZmljIGZhY3QgZnJvbSB3aGljaCB0aGlzIGNodW5rIHdhcwog
cmV0cmlldmVkLgoKDAoFBAICAQUSAz4CCAoMCgUEAgIBARIDPgkPCgwKBQQCAgEDEgM+EhMK
VAoEBAICAhIDQQISGkcgVGhlIGluZGV4IG9mIHRoaXMgY2h1bmsuIEN1cnJlbnRseSwgb25s
eSB1c2VkIGZvciB0aGUgc3RyZWFtaW5nIG1vZGUuCgoMCgUEAgICBRIDQQIHCgwKBQQCAgIB
EgNBCA0KDAoFBAICAgMSA0EQEQpGCgQEAgIDEgNEAioaOSBNb3JlIGZpbmUtZ3JhaW5lZCBp
bmZvcm1hdGlvbiBmb3IgdGhlIHNvdXJjZSByZWZlcmVuY2UuCgoMCgUEAgIDBhIDRAIVCgwK
BQQCAgMBEgNEFiUKDAoFBAICAwMSA0QoKQolCgQEAgIEEgNHAhEaGCBUaGUgVVJJIG9mIHRo
ZSBzb3VyY2UuCgoMCgUEAgIEBRIDRwIICgwKBQQCAgQBEgNHCQwKDAoFBAICBAMSA0cPEAon
CgQEAgIFEgNKAhMaGiBUaGUgdGl0bGUgb2YgdGhlIHNvdXJjZS4KCgwKBQQCAgUFEgNKAggK
DAoFBAICBQESA0oJDgoMCgUEAgIFAxIDShESCigKBAQCAgYSA00CFBobIFRoZSBkb21haW4g
b2YgdGhlIHNvdXJjZS4KCgwKBQQCAgYFEgNNAggKDAoFBAICBgESA00JDwoMCgUEAgIGAxID
TRITYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingConfig ===
    # Fields for GroundingConfig
    # Field: name Type: 9 ()

# === Message: Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingFact ===
    # Fields for GroundingFact
    # Field: fact_text Type: 9 ()
    # Field: attributes Type: 11 (.google.cloud.discoveryengine.v1beta.GroundingFact.AttributesEntry)

# === Message: Google::Cloud::Discoveryengine::V1beta::Grounding::FactChunk ===
    # Fields for FactChunk
    # Field: chunk_text Type: 9 ()
    # Field: source Type: 9 ()
    # Field: index Type: 5 ()
    # Field: source_metadata Type: 11 (.google.cloud.discoveryengine.v1beta.FactChunk.SourceMetadataEntry)
    # Field: uri Type: 9 ()
    # Field: title Type: 9 ()
    # Field: domain Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::Grounding - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/grounding.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::Grounding;

    my $msg = Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingConfig->new({
        name => $name,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/grounding.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingConfig

Grounding configuration.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. Name of the GroundingConfig, of the form
`projects/{project}/locations/{location}/groundingConfigs/{grounding_config}`.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingFact

Grounding Fact.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fact_text() >> / C<< $msg->fact_text($value) >>

Type: C<String>

Text content of the fact. Can be at most 10K characters long.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Grounding::GroundingFact::AttributesEntry>)

Attributes associated with the fact.
Common attributes include `source` (indicating where the fact was sourced
from), `author` (indicating the author of the fact), and so on.

=back

=head2 Google::Cloud::Discoveryengine::V1beta::Grounding::FactChunk

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

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::Grounding::FactChunk::SourceMetadataEntry>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::Grounding::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
