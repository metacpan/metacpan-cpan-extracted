package Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
Cjdnb29nbGUvY2xvdWQvdmVjdG9yc2VhcmNoL3YxYmV0YS9lbWJlZGRpbmdfY29uZmlnLnBy
b3RvEiBnb29nbGUuY2xvdWQudmVjdG9yc2VhcmNoLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90byK4AQoVVmVydGV4RW1iZWRkaW5nQ29uZmlnEh4KCG1vZGVsX2lk
GAEgASgJQgPgQQJSB21vZGVsSWQSKAoNdGV4dF90ZW1wbGF0ZRgCIAEoCUID4EEBUgx0ZXh0
VGVtcGxhdGUSVQoJdGFza190eXBlGAMgASgOMjMuZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJj
aC52MWJldGEuRW1iZWRkaW5nVGFza1R5cGVCA+BBAVIIdGFza1R5cGUq6wEKEUVtYmVkZGlu
Z1Rhc2tUeXBlEiMKH0VNQkVERElOR19UQVNLX1RZUEVfVU5TUEVDSUZJRUQQABITCg9SRVRS
SUVWQUxfUVVFUlkQARIWChJSRVRSSUVWQUxfRE9DVU1FTlQQAhIXChNTRU1BTlRJQ19TSU1J
TEFSSVRZEAMSEgoOQ0xBU1NJRklDQVRJT04QBBIOCgpDTFVTVEVSSU5HEAUSFgoSUVVFU1RJ
T05fQU5TV0VSSU5HEAYSFQoRRkFDVF9WRVJJRklDQVRJT04QBxIYChRDT0RFX1JFVFJJRVZB
TF9RVUVSWRAIQvQBCiRjb20uZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MWJldGFCFEVt
YmVkZGluZ0NvbmZpZ1Byb3RvUAFaSGNsb3VkLmdvb2dsZS5jb20vZ28vdmVjdG9yc2VhcmNo
L2FwaXYxYmV0YS92ZWN0b3JzZWFyY2hwYjt2ZWN0b3JzZWFyY2hwYqoCIEdvb2dsZS5DbG91
ZC5WZWN0b3JTZWFyY2guVjFCZXRhygIgR29vZ2xlXENsb3VkXFZlY3RvclNlYXJjaFxWMWJl
dGHqAiNHb29nbGU6OkNsb3VkOjpWZWN0b3JTZWFyY2g6OlYxYmV0YUr4FgoGEgQOAE8BCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMSACkK
CAoBCBIDFAA9CgkKAgglEgMUAD0KCAoBCBIDFQBfCgkKAggLEgMVAF8KCAoBCBIDFgAiCgkK
AggKEgMWACIKCAoBCBIDFwA1CgkKAggIEgMXADUKCAoBCBIDGAA9CgkKAggBEgMYAD0KCAoB
CBIDGQA9CgkKAggpEgMZAD0KCAoBCBIDGgA8CgkKAggtEgMaADwKQgoCBQASBB0AOAEaNiBS
ZXByZXNlbnRzIHRoZSB0YXNrIHRoZSBlbWJlZGRpbmdzIHdpbGwgYmUgdXNlZCBmb3IuCgoK
CgMFAAESAx0FFgolCgQFAAIAEgMfAiYaGCBVbnNwZWNpZmllZCB0YXNrIHR5cGUuCgoMCgUF
AAIAARIDHwIhCgwKBQUAAgACEgMfJCUKUQoEBQACARIDIgIWGkQgU3BlY2lmaWVzIHRoZSBn
aXZlbiB0ZXh0IGlzIGEgcXVlcnkgaW4gYSBzZWFyY2gvcmV0cmlldmFsIHNldHRpbmcuCgoM
CgUFAAIBARIDIgIRCgwKBQUAAgECEgMiFBUKVQoEBQACAhIDJQIZGkggU3BlY2lmaWVzIHRo
ZSBnaXZlbiB0ZXh0IGlzIGEgZG9jdW1lbnQgZnJvbSB0aGUgY29ycHVzIGJlaW5nIHNlYXJj
aGVkLgoKDAoFBQACAgESAyUCFAoMCgUFAAICAhIDJRcYCj0KBAUAAgMSAygCGhowIFNwZWNp
ZmllcyB0aGUgZ2l2ZW4gdGV4dCB3aWxsIGJlIHVzZWQgZm9yIFNUUy4KCgwKBQUAAgMBEgMo
AhUKDAoFBQACAwISAygYGQpACgQFAAIEEgMrAhUaMyBTcGVjaWZpZXMgdGhhdCB0aGUgZ2l2
ZW4gdGV4dCB3aWxsIGJlIGNsYXNzaWZpZWQuCgoMCgUFAAIEARIDKwIQCgwKBQUAAgQCEgMr
ExQKSQoEBQACBRIDLgIRGjwgU3BlY2lmaWVzIHRoYXQgdGhlIGVtYmVkZGluZ3Mgd2lsbCBi
ZSB1c2VkIGZvciBjbHVzdGVyaW5nLgoKDAoFBQACBQESAy4CDAoMCgUFAAIFAhIDLg8QClEK
BAUAAgYSAzECGRpEIFNwZWNpZmllcyB0aGF0IHRoZSBlbWJlZGRpbmdzIHdpbGwgYmUgdXNl
ZCBmb3IgcXVlc3Rpb24gYW5zd2VyaW5nLgoKDAoFBQACBgESAzECFAoMCgUFAAIGAhIDMRcY
ClAKBAUAAgcSAzQCGBpDIFNwZWNpZmllcyB0aGF0IHRoZSBlbWJlZGRpbmdzIHdpbGwgYmUg
dXNlZCBmb3IgZmFjdCB2ZXJpZmljYXRpb24uCgoMCgUFAAIHARIDNAITCgwKBQUAAgcCEgM0
FhcKTQoEBQACCBIDNwIbGkAgU3BlY2lmaWVzIHRoYXQgdGhlIGVtYmVkZGluZ3Mgd2lsbCBi
ZSB1c2VkIGZvciBjb2RlIHJldHJpZXZhbC4KCgwKBQUAAggBEgM3AhYKDAoFBQACCAISAzcZ
GgqAAQoCBAASBDwATwEadCBNZXNzYWdlIGRlc2NyaWJpbmcgdGhlIGNvbmZpZ3VyYXRpb24g
Zm9yIGdlbmVyYXRpbmcgZW1iZWRkaW5ncyBmb3IgYSB2ZWN0b3IKIGZpZWxkIHVzaW5nIFZl
cnRleCBBSSBlbWJlZGRpbmdzIEFQSS4KCgoKAwQAARIDPAgdCsIBCgQEAAIAEgNAAj8atAEg
UmVxdWlyZWQuIFJlcXVpcmVkOiBJRCBvZiB0aGUgZW1iZWRkaW5nIG1vZGVsIHRvIHVzZS4g
U2VlCiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vdmVydGV4LWFpL2dlbmVyYXRpdmUtYWkv
ZG9jcy9sZWFybi9tb2RlbHMjZW1iZWRkaW5ncy1tb2RlbHMKIGZvciB0aGUgbGlzdCBvZiBz
dXBwb3J0ZWQgbW9kZWxzLgoKDAoFBAACAAUSA0ACCAoMCgUEAAIAARIDQAkRCgwKBQQAAgAD
EgNAFBUKDAoFBAACAAgSA0AWPgoPCggEAAIACJwIABIDQBc9CvMBCgQEAAIBEgNHAkQa5QEg
T3B0aW9uYWwuIFRleHQgdGVtcGxhdGUgZm9yIHRoZSBpbnB1dCB0byB0aGUgbW9kZWwuIFRo
ZSB0ZW1wbGF0ZSBtdXN0CiBjb250YWluIG9uZSBvciBtb3JlIHJlZmVyZW5jZXMgdG8gZmll
bGRzIGluIHRoZSBEYXRhT2JqZWN0LCBlLmcuOiAiTW92aWUKIFRpdGxlOiB7dGl0bGV9IC0t
LS0gTW92aWUgUGxvdDoge3Bsb3R9Ii4KCiBSZXF1aXJlZCB3aGVuIHVzaW5nIHRoZSB0ZXh0
LW9ubHkgcGF0aC4KCgwKBQQAAgEFEgNHAggKDAoFBAACAQESA0cJFgoMCgUEAAIBAxIDRxka
CgwKBQQAAgEIEgNHG0MKDwoIBAACAQicCAASA0ccQgqEAwoEBAACAhIDTgJLGvYCIE9wdGlv
bmFsLiBPcHRpb25hbDogVGFzayB0eXBlIGZvciB0aGUgZW1iZWRkaW5ncy4gUmVxdWlyZWQg
Zm9yIHRleHQtb25seQogZW1iZWRkaW5nIG1vZGVscywgc2VlCiBodHRwczovL2RvY3MuY2xv
dWQuZ29vZ2xlLmNvbS9nZW1pbmktZW50ZXJwcmlzZS1hZ2VudC1wbGF0Zm9ybS9tb2RlbHMv
ZW1iZWRkaW5ncy90YXNrLXR5cGVzCiBOb3QgbmVlZGVkIGZvciBtdWx0aSBtb2RhbCBlbWJl
ZGRpbmcgbW9kZWxzLCBzZWUKIGh0dHBzOi8vZG9jcy5jbG91ZC5nb29nbGUuY29tL2dlbWlu
aS1lbnRlcnByaXNlLWFnZW50LXBsYXRmb3JtL21vZGVscy9lbWJlZGRpbmdzL2dldC1tdWx0
aW1vZGFsLWVtYmVkZGluZ3Mjc3BlY2lmeS10YXNrLWluc3RydWN0aW9ucwoKDAoFBAACAgYS
A04CEwoMCgUEAAICARIDThQdCgwKBQQAAgIDEgNOICEKDAoFBAACAggSA04iSgoPCggEAAIC
CJwIABIDTiNJYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig::VertexEmbeddingConfig ===
    # Fields for VertexEmbeddingConfig
    # Field: model_id Type: 9 ()
    # Field: text_template Type: 9 ()
    # Field: task_type Type: 14 (.google.cloud.vectorsearch.v1beta.EmbeddingTaskType)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig - Compiled Protocol Buffers messages for google/cloud/vectorsearch/v1beta/embedding_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig;

    my $msg = Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig::VertexEmbeddingConfig->new({
        model_id => $model_id,
        text_template => $text_template,
        task_type => $task_type,
    });

    # Read or update a field
    my $val = $msg->model_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig::VertexEmbeddingConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vectorsearch/v1beta/embedding_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig::VertexEmbeddingConfig

Message describing the configuration for generating embeddings for a vector
field using Vertex AI embeddings API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model_id() >> / C<< $msg->model_id($value) >>

Type: C<String>

Required. Required: ID of the embedding model to use. See
https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models#embeddings-models
for the list of supported models.

=item * C<< $msg->text_template() >> / C<< $msg->text_template($value) >>

Type: C<String>

Optional. Text template for the input to the model. The template must
contain one or more references to fields in the DataObject, e.g.: "Movie
Title: {title} ---- Movie Plot: {plot}".

Required when using the text-only path.

=item * C<< $msg->task_type() >> / C<< $msg->task_type($value) >>

Type: C<Enum> (L<Google::Cloud::Vectorsearch::V1beta::EmbeddingTaskType>)

Optional. Optional: Task type for the embeddings. Required for text-only
embedding models, see
https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/embeddings/task-types
Not needed for multi modal embedding models, see
https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/embeddings/get-multimodal-embeddings#specify-task-instructions

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vectorsearch::V1beta::EmbeddingConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
