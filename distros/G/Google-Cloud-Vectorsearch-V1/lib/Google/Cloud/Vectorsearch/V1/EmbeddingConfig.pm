package Google::Cloud::Vectorsearch::V1::EmbeddingConfig;

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
CjNnb29nbGUvY2xvdWQvdmVjdG9yc2VhcmNoL3YxL2VtYmVkZGluZ19jb25maWcucHJvdG8S
HGdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8itAEKFVZlcnRleEVtYmVkZGluZ0NvbmZpZxIeCghtb2RlbF9pZBgBIAEoCUID
4EECUgdtb2RlbElkEigKDXRleHRfdGVtcGxhdGUYAiABKAlCA+BBAVIMdGV4dFRlbXBsYXRl
ElEKCXRhc2tfdHlwZRgDIAEoDjIvLmdvb2dsZS5jbG91ZC52ZWN0b3JzZWFyY2gudjEuRW1i
ZWRkaW5nVGFza1R5cGVCA+BBAVIIdGFza1R5cGUq6wEKEUVtYmVkZGluZ1Rhc2tUeXBlEiMK
H0VNQkVERElOR19UQVNLX1RZUEVfVU5TUEVDSUZJRUQQABITCg9SRVRSSUVWQUxfUVVFUlkQ
ARIWChJSRVRSSUVWQUxfRE9DVU1FTlQQAhIXChNTRU1BTlRJQ19TSU1JTEFSSVRZEAMSEgoO
Q0xBU1NJRklDQVRJT04QBBIOCgpDTFVTVEVSSU5HEAUSFgoSUVVFU1RJT05fQU5TV0VSSU5H
EAYSFQoRRkFDVF9WRVJJRklDQVRJT04QBxIYChRDT0RFX1JFVFJJRVZBTF9RVUVSWRAIQuAB
CiBjb20uZ29vZ2xlLmNsb3VkLnZlY3RvcnNlYXJjaC52MUIURW1iZWRkaW5nQ29uZmlnUHJv
dG9QAVpEY2xvdWQuZ29vZ2xlLmNvbS9nby92ZWN0b3JzZWFyY2gvYXBpdjEvdmVjdG9yc2Vh
cmNocGI7dmVjdG9yc2VhcmNocGKqAhxHb29nbGUuQ2xvdWQuVmVjdG9yU2VhcmNoLlYxygIc
R29vZ2xlXENsb3VkXFZlY3RvclNlYXJjaFxWMeoCH0dvb2dsZTo6Q2xvdWQ6OlZlY3RvclNl
YXJjaDo6VjFK+BYKBhIEDgBPAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAJQoJCgIDABIDEgApCggKAQgSAxQAOQoJCgIIJRIDFAA5CggKAQgSAxUAWwoJ
CgIICxIDFQBbCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcANQoJCgIICBIDFwA1CggK
AQgSAxgAOQoJCgIIARIDGAA5CggKAQgSAxkAOQoJCgIIKRIDGQA5CggKAQgSAxoAOAoJCgII
LRIDGgA4CkIKAgUAEgQdADgBGjYgUmVwcmVzZW50cyB0aGUgdGFzayB0aGUgZW1iZWRkaW5n
cyB3aWxsIGJlIHVzZWQgZm9yLgoKCgoDBQABEgMdBRYKJQoEBQACABIDHwImGhggVW5zcGVj
aWZpZWQgdGFzayB0eXBlLgoKDAoFBQACAAESAx8CIQoMCgUFAAIAAhIDHyQlClEKBAUAAgES
AyICFhpEIFNwZWNpZmllcyB0aGUgZ2l2ZW4gdGV4dCBpcyBhIHF1ZXJ5IGluIGEgc2VhcmNo
L3JldHJpZXZhbCBzZXR0aW5nLgoKDAoFBQACAQESAyICEQoMCgUFAAIBAhIDIhQVClUKBAUA
AgISAyUCGRpIIFNwZWNpZmllcyB0aGUgZ2l2ZW4gdGV4dCBpcyBhIGRvY3VtZW50IGZyb20g
dGhlIGNvcnB1cyBiZWluZyBzZWFyY2hlZC4KCgwKBQUAAgIBEgMlAhQKDAoFBQACAgISAyUX
GAo9CgQFAAIDEgMoAhoaMCBTcGVjaWZpZXMgdGhlIGdpdmVuIHRleHQgd2lsbCBiZSB1c2Vk
IGZvciBTVFMuCgoMCgUFAAIDARIDKAIVCgwKBQUAAgMCEgMoGBkKQAoEBQACBBIDKwIVGjMg
U3BlY2lmaWVzIHRoYXQgdGhlIGdpdmVuIHRleHQgd2lsbCBiZSBjbGFzc2lmaWVkLgoKDAoF
BQACBAESAysCEAoMCgUFAAIEAhIDKxMUCkkKBAUAAgUSAy4CERo8IFNwZWNpZmllcyB0aGF0
IHRoZSBlbWJlZGRpbmdzIHdpbGwgYmUgdXNlZCBmb3IgY2x1c3RlcmluZy4KCgwKBQUAAgUB
EgMuAgwKDAoFBQACBQISAy4PEApRCgQFAAIGEgMxAhkaRCBTcGVjaWZpZXMgdGhhdCB0aGUg
ZW1iZWRkaW5ncyB3aWxsIGJlIHVzZWQgZm9yIHF1ZXN0aW9uIGFuc3dlcmluZy4KCgwKBQUA
AgYBEgMxAhQKDAoFBQACBgISAzEXGApQCgQFAAIHEgM0AhgaQyBTcGVjaWZpZXMgdGhhdCB0
aGUgZW1iZWRkaW5ncyB3aWxsIGJlIHVzZWQgZm9yIGZhY3QgdmVyaWZpY2F0aW9uLgoKDAoF
BQACBwESAzQCEwoMCgUFAAIHAhIDNBYXCk0KBAUAAggSAzcCGxpAIFNwZWNpZmllcyB0aGF0
IHRoZSBlbWJlZGRpbmdzIHdpbGwgYmUgdXNlZCBmb3IgY29kZSByZXRyaWV2YWwuCgoMCgUF
AAIIARIDNwIWCgwKBQUAAggCEgM3GRoKgAEKAgQAEgQ8AE8BGnQgTWVzc2FnZSBkZXNjcmli
aW5nIHRoZSBjb25maWd1cmF0aW9uIGZvciBnZW5lcmF0aW5nIGVtYmVkZGluZ3MgZm9yIGEg
dmVjdG9yCiBmaWVsZCB1c2luZyBWZXJ0ZXggQUkgZW1iZWRkaW5ncyBBUEkuCgoKCgMEAAES
AzwIHQrCAQoEBAACABIDQAI/GrQBIFJlcXVpcmVkLiBSZXF1aXJlZDogSUQgb2YgdGhlIGVt
YmVkZGluZyBtb2RlbCB0byB1c2UuIFNlZQogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3Zl
cnRleC1haS9nZW5lcmF0aXZlLWFpL2RvY3MvbGVhcm4vbW9kZWxzI2VtYmVkZGluZ3MtbW9k
ZWxzCiBmb3IgdGhlIGxpc3Qgb2Ygc3VwcG9ydGVkIG1vZGVscy4KCgwKBQQAAgAFEgNAAggK
DAoFBAACAAESA0AJEQoMCgUEAAIAAxIDQBQVCgwKBQQAAgAIEgNAFj4KDwoIBAACAAicCAAS
A0AXPQrzAQoEBAACARIDRwJEGuUBIE9wdGlvbmFsLiBUZXh0IHRlbXBsYXRlIGZvciB0aGUg
aW5wdXQgdG8gdGhlIG1vZGVsLiBUaGUgdGVtcGxhdGUgbXVzdAogY29udGFpbiBvbmUgb3Ig
bW9yZSByZWZlcmVuY2VzIHRvIGZpZWxkcyBpbiB0aGUgRGF0YU9iamVjdCwgZS5nLjogIk1v
dmllCiBUaXRsZToge3RpdGxlfSAtLS0tIE1vdmllIFBsb3Q6IHtwbG90fSIuCgogUmVxdWly
ZWQgd2hlbiB1c2luZyB0aGUgdGV4dC1vbmx5IHBhdGguCgoMCgUEAAIBBRIDRwIICgwKBQQA
AgEBEgNHCRYKDAoFBAACAQMSA0cZGgoMCgUEAAIBCBIDRxtDCg8KCAQAAgEInAgAEgNHHEIK
hAMKBAQAAgISA04CSxr2AiBPcHRpb25hbC4gT3B0aW9uYWw6IFRhc2sgdHlwZSBmb3IgdGhl
IGVtYmVkZGluZ3MuIFJlcXVpcmVkIGZvciB0ZXh0LW9ubHkKIGVtYmVkZGluZyBtb2RlbHMs
IHNlZQogaHR0cHM6Ly9kb2NzLmNsb3VkLmdvb2dsZS5jb20vZ2VtaW5pLWVudGVycHJpc2Ut
YWdlbnQtcGxhdGZvcm0vbW9kZWxzL2VtYmVkZGluZ3MvdGFzay10eXBlcwogTm90IG5lZWRl
ZCBmb3IgbXVsdGkgbW9kYWwgZW1iZWRkaW5nIG1vZGVscywgc2VlCiBodHRwczovL2RvY3Mu
Y2xvdWQuZ29vZ2xlLmNvbS9nZW1pbmktZW50ZXJwcmlzZS1hZ2VudC1wbGF0Zm9ybS9tb2Rl
bHMvZW1iZWRkaW5ncy9nZXQtbXVsdGltb2RhbC1lbWJlZGRpbmdzI3NwZWNpZnktdGFzay1p
bnN0cnVjdGlvbnMKCgwKBQQAAgIGEgNOAhMKDAoFBAACAgESA04UHQoMCgUEAAICAxIDTiAh
CgwKBQQAAgIIEgNOIkoKDwoIBAACAgicCAASA04jSWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Vectorsearch::V1::EmbeddingConfig::VertexEmbeddingConfig ===
    # Fields for VertexEmbeddingConfig
    # Field: model_id Type: 9 ()
    # Field: text_template Type: 9 ()
    # Field: task_type Type: 14 (.google.cloud.vectorsearch.v1.EmbeddingTaskType)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Vectorsearch::V1::EmbeddingConfig - Compiled Protocol Buffers messages for google/cloud/vectorsearch/v1/embedding_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Vectorsearch::V1::EmbeddingConfig;

    my $msg = Google::Cloud::Vectorsearch::V1::EmbeddingConfig::VertexEmbeddingConfig->new({
        model_id => $model_id,
        text_template => $text_template,
        task_type => $task_type,
    });

    # Read or update a field
    my $val = $msg->model_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Vectorsearch::V1::EmbeddingConfig::VertexEmbeddingConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/vectorsearch/v1/embedding_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Vectorsearch::V1::EmbeddingConfig::VertexEmbeddingConfig

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

Type: C<Enum> (L<Google::Cloud::Vectorsearch::V1::EmbeddingTaskType>)

Optional. Optional: Task type for the embeddings. Required for text-only
embedding models, see
https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/embeddings/task-types
Not needed for multi modal embedding models, see
https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/embeddings/get-multimodal-embeddings#specify-task-instructions

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Vectorsearch::V1::EmbeddingConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
