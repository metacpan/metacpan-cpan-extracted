package Google::Cloud::Automl::V1::Dataset;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Automl::V1::Image };
    eval { require Google::Cloud::Automl::V1::Text };
    eval { require Google::Cloud::Automl::V1::Translation };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiRnb29nbGUvY2xvdWQvYXV0b21sL3YxL2RhdGFzZXQucHJvdG8SFmdvb2dsZS5jbG91ZC5h
dXRvbWwudjEaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aImdvb2dsZS9jbG91ZC9hdXRv
bWwvdjEvaW1hZ2UucHJvdG8aIWdvb2dsZS9jbG91ZC9hdXRvbWwvdjEvdGV4dC5wcm90bxoo
Z29vZ2xlL2Nsb3VkL2F1dG9tbC92MS90cmFuc2xhdGlvbi5wcm90bxofZ29vZ2xlL3Byb3Rv
YnVmL3RpbWVzdGFtcC5wcm90byL9CQoHRGF0YXNldBJ2Chx0cmFuc2xhdGlvbl9kYXRhc2V0
X21ldGFkYXRhGBcgASgLMjIuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5UcmFuc2xhdGlvbkRh
dGFzZXRNZXRhZGF0YUgAUhp0cmFuc2xhdGlvbkRhdGFzZXRNZXRhZGF0YRKPAQolaW1hZ2Vf
Y2xhc3NpZmljYXRpb25fZGF0YXNldF9tZXRhZGF0YRgYIAEoCzI6Lmdvb2dsZS5jbG91ZC5h
dXRvbWwudjEuSW1hZ2VDbGFzc2lmaWNhdGlvbkRhdGFzZXRNZXRhZGF0YUgAUiJpbWFnZUNs
YXNzaWZpY2F0aW9uRGF0YXNldE1ldGFkYXRhEowBCiR0ZXh0X2NsYXNzaWZpY2F0aW9uX2Rh
dGFzZXRfbWV0YWRhdGEYGSABKAsyOS5nb29nbGUuY2xvdWQuYXV0b21sLnYxLlRleHRDbGFz
c2lmaWNhdGlvbkRhdGFzZXRNZXRhZGF0YUgAUiF0ZXh0Q2xhc3NpZmljYXRpb25EYXRhc2V0
TWV0YWRhdGESkwEKJ2ltYWdlX29iamVjdF9kZXRlY3Rpb25fZGF0YXNldF9tZXRhZGF0YRga
IAEoCzI7Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjEuSW1hZ2VPYmplY3REZXRlY3Rpb25EYXRh
c2V0TWV0YWRhdGFIAFIjaW1hZ2VPYmplY3REZXRlY3Rpb25EYXRhc2V0TWV0YWRhdGESgAEK
IHRleHRfZXh0cmFjdGlvbl9kYXRhc2V0X21ldGFkYXRhGBwgASgLMjUuZ29vZ2xlLmNsb3Vk
LmF1dG9tbC52MS5UZXh0RXh0cmFjdGlvbkRhdGFzZXRNZXRhZGF0YUgAUh10ZXh0RXh0cmFj
dGlvbkRhdGFzZXRNZXRhZGF0YRJ9Ch90ZXh0X3NlbnRpbWVudF9kYXRhc2V0X21ldGFkYXRh
GB4gASgLMjQuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5UZXh0U2VudGltZW50RGF0YXNldE1l
dGFkYXRhSABSHHRleHRTZW50aW1lbnREYXRhc2V0TWV0YWRhdGESEgoEbmFtZRgBIAEoCVIE
bmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEiAKC2Rlc2NyaXB0aW9u
GAMgASgJUgtkZXNjcmlwdGlvbhIjCg1leGFtcGxlX2NvdW50GBUgASgFUgxleGFtcGxlQ291
bnQSOwoLY3JlYXRlX3RpbWUYDiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpj
cmVhdGVUaW1lEhIKBGV0YWcYESABKAlSBGV0YWcSQwoGbGFiZWxzGCcgAygLMisuZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MS5EYXRhc2V0LkxhYmVsc0VudHJ5UgZsYWJlbHMaOQoLTGFiZWxz
RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ATpe6kFb
Ch1hdXRvbWwuZ29vZ2xlYXBpcy5jb20vRGF0YXNldBI6cHJvamVjdHMve3Byb2plY3R9L2xv
Y2F0aW9ucy97bG9jYXRpb259L2RhdGFzZXRzL3tkYXRhc2V0fUISChBkYXRhc2V0X21ldGFk
YXRhQqABChpjb20uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MVABWjJjbG91ZC5nb29nbGUuY29t
L2dvL2F1dG9tbC9hcGl2MS9hdXRvbWxwYjthdXRvbWxwYqoCFkdvb2dsZS5DbG91ZC5BdXRv
TUwuVjHKAhZHb29nbGVcQ2xvdWRcQXV0b01sXFYx6gIZR29vZ2xlOjpDbG91ZDo6QXV0b01M
OjpWMUrjGAoGEgQOAF4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAfCgkKAgMAEgMSACMKCQoCAwESAxMALAoJCgIDAhIDFAArCgkKAgMDEgMVADIKCQoC
AwQSAxYAKQoICgEIEgMYADMKCQoCCCUSAxgAMwoICgEIEgMZAEkKCQoCCAsSAxkASQoICgEI
EgMaACIKCQoCCAoSAxoAIgoICgEIEgMbADMKCQoCCAESAxsAMwoICgEIEgMcADMKCQoCCCkS
AxwAMwoICgEIEgMdADIKCQoCCC0SAx0AMgqQAQoCBAASBCEAXgEagwEgQSB3b3Jrc3BhY2Ug
Zm9yIHNvbHZpbmcgYSBzaW5nbGUsIHBhcnRpY3VsYXIgbWFjaGluZSBsZWFybmluZyAoTUwp
IHByb2JsZW0uCiBBIHdvcmtzcGFjZSBjb250YWlucyBleGFtcGxlcyB0aGF0IG1heSBiZSBh
bm5vdGF0ZWQuCgoKCgMEAAESAyEIDwoLCgMEAAcSBCICJQQKDQoFBAAHnQgSBCICJQQKVQoE
BAAIABIEKQI7AxpHIFJlcXVpcmVkLgogVGhlIGRhdGFzZXQgbWV0YWRhdGEgdGhhdCBpcyBz
cGVjaWZpYyB0byB0aGUgcHJvYmxlbSB0eXBlLgoKDAoFBAAIAAESAykIGAo7CgQEAAIAEgMr
BEEaLiBNZXRhZGF0YSBmb3IgYSBkYXRhc2V0IHVzZWQgZm9yIHRyYW5zbGF0aW9uLgoKDAoF
BAACAAYSAysEHgoMCgUEAAIAARIDKx87CgwKBQQAAgADEgMrPkAKRAoEBAACARIDLgRSGjcg
TWV0YWRhdGEgZm9yIGEgZGF0YXNldCB1c2VkIGZvciBpbWFnZSBjbGFzc2lmaWNhdGlvbi4K
CgwKBQQAAgEGEgMuBCYKDAoFBAACAQESAy4nTAoMCgUEAAIBAxIDLk9RCkMKBAQAAgISAzEE
UBo2IE1ldGFkYXRhIGZvciBhIGRhdGFzZXQgdXNlZCBmb3IgdGV4dCBjbGFzc2lmaWNhdGlv
bi4KCgwKBQQAAgIGEgMxBCUKDAoFBAACAgESAzEmSgoMCgUEAAICAxIDMU1PCkYKBAQAAgMS
AzQEVRo5IE1ldGFkYXRhIGZvciBhIGRhdGFzZXQgdXNlZCBmb3IgaW1hZ2Ugb2JqZWN0IGRl
dGVjdGlvbi4KCgwKBQQAAgMGEgM0BCcKDAoFBAACAwESAzQoTwoMCgUEAAIDAxIDNFJUCj8K
BAQAAgQSAzcESBoyIE1ldGFkYXRhIGZvciBhIGRhdGFzZXQgdXNlZCBmb3IgdGV4dCBleHRy
YWN0aW9uLgoKDAoFBAACBAYSAzcEIQoMCgUEAAIEARIDNyJCCgwKBQQAAgQDEgM3RUcKPgoE
BAACBRIDOgRGGjEgTWV0YWRhdGEgZm9yIGEgZGF0YXNldCB1c2VkIGZvciB0ZXh0IHNlbnRp
bWVudC4KCgwKBQQAAgUGEgM6BCAKDAoFBAACBQESAzohQAoMCgUEAAIFAxIDOkNFCooBCgQE
AAIGEgM/AhIafSBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5hbWUgb2YgdGhlIGRhdGFz
ZXQuCiBGb3JtOiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb25f
aWR9L2RhdGFzZXRzL3tkYXRhc2V0X2lkfWAKCgwKBQQAAgYFEgM/AggKDAoFBAACBgESAz8J
DQoMCgUEAAIGAxIDPxARCtcBCgQEAAIHEgNFAhoayQEgUmVxdWlyZWQuIFRoZSBuYW1lIG9m
IHRoZSBkYXRhc2V0IHRvIHNob3cgaW4gdGhlIGludGVyZmFjZS4gVGhlIG5hbWUgY2FuIGJl
CiB1cCB0byAzMiBjaGFyYWN0ZXJzIGxvbmcgYW5kIGNhbiBjb25zaXN0IG9ubHkgb2YgQVND
SUkgTGF0aW4gbGV0dGVycyBBLVoKIGFuZCBhLXosIHVuZGVyc2NvcmVzCiAoXyksIGFuZCBB
U0NJSSBkaWdpdHMgMC05LgoKDAoFBAACBwUSA0UCCAoMCgUEAAIHARIDRQkVCgwKBQQAAgcD
EgNFGBkKbQoEBAACCBIDSQIZGmAgVXNlci1wcm92aWRlZCBkZXNjcmlwdGlvbiBvZiB0aGUg
ZGF0YXNldC4gVGhlIGRlc2NyaXB0aW9uIGNhbiBiZSB1cCB0bwogMjUwMDAgY2hhcmFjdGVy
cyBsb25nLgoKDAoFBAACCAUSA0kCCAoMCgUEAAIIARIDSQkUCgwKBQQAAggDEgNJFxgKQgoE
BAACCRIDTAIbGjUgT3V0cHV0IG9ubHkuIFRoZSBudW1iZXIgb2YgZXhhbXBsZXMgaW4gdGhl
IGRhdGFzZXQuCgoMCgUEAAIJBRIDTAIHCgwKBQQAAgkBEgNMCBUKDAoFBAACCQMSA0wYGgpE
CgQEAAIKEgNPAi0aNyBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhpcyBkYXRhc2V0
IHdhcyBjcmVhdGVkLgoKDAoFBAACCgYSA08CGwoMCgUEAAIKARIDTxwnCgwKBQQAAgoDEgNP
KiwKdQoEBAACCxIDUwITGmggVXNlZCB0byBwZXJmb3JtIGNvbnNpc3RlbnQgcmVhZC1tb2Rp
Znktd3JpdGUgdXBkYXRlcy4gSWYgbm90IHNldCwgYSBibGluZAogIm92ZXJ3cml0ZSIgdXBk
YXRlIGhhcHBlbnMuCgoMCgUEAAILBRIDUwIICgwKBQQAAgsBEgNTCQ0KDAoFBAACCwMSA1MQ
EgqwAwoEBAACDBIDXQIiGqIDIE9wdGlvbmFsLiBUaGUgbGFiZWxzIHdpdGggdXNlci1kZWZp
bmVkIG1ldGFkYXRhIHRvIG9yZ2FuaXplIHlvdXIgZGF0YXNldC4KCiBMYWJlbCBrZXlzIGFu
ZCB2YWx1ZXMgY2FuIGJlIG5vIGxvbmdlciB0aGFuIDY0IGNoYXJhY3RlcnMKIChVbmljb2Rl
IGNvZGVwb2ludHMpLCBjYW4gb25seSBjb250YWluIGxvd2VyY2FzZSBsZXR0ZXJzLCBudW1l
cmljCiBjaGFyYWN0ZXJzLCB1bmRlcnNjb3JlcyBhbmQgZGFzaGVzLiBJbnRlcm5hdGlvbmFs
IGNoYXJhY3RlcnMgYXJlIGFsbG93ZWQuCiBMYWJlbCB2YWx1ZXMgYXJlIG9wdGlvbmFsLiBM
YWJlbCBrZXlzIG11c3Qgc3RhcnQgd2l0aCBhIGxldHRlci4KCiBTZWUgaHR0cHM6Ly9nb28u
Z2wveG1RbnhmIGZvciBtb3JlIGluZm9ybWF0aW9uIG9uIGFuZCBleGFtcGxlcyBvZiBsYWJl
bHMuCgoMCgUEAAIMBhIDXQIVCgwKBQQAAgwBEgNdFhwKDAoFBAACDAMSA10fIWIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::Dataset::Dataset ===
    # Fields for Dataset
    # Field: translation_dataset_metadata Type: 11 (.google.cloud.automl.v1.TranslationDatasetMetadata)
    # Field: image_classification_dataset_metadata Type: 11 (.google.cloud.automl.v1.ImageClassificationDatasetMetadata)
    # Field: text_classification_dataset_metadata Type: 11 (.google.cloud.automl.v1.TextClassificationDatasetMetadata)
    # Field: image_object_detection_dataset_metadata Type: 11 (.google.cloud.automl.v1.ImageObjectDetectionDatasetMetadata)
    # Field: text_extraction_dataset_metadata Type: 11 (.google.cloud.automl.v1.TextExtractionDatasetMetadata)
    # Field: text_sentiment_dataset_metadata Type: 11 (.google.cloud.automl.v1.TextSentimentDatasetMetadata)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: example_count Type: 5 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.automl.v1.Dataset.LabelsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::Dataset - Compiled Protocol Buffers messages for google/cloud/automl/v1/dataset.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::Dataset;

    my $msg = Google::Cloud::Automl::V1::Dataset::Dataset->new({
        translation_dataset_metadata => $translation_dataset_metadata,
        image_classification_dataset_metadata => $image_classification_dataset_metadata,
        text_classification_dataset_metadata => $text_classification_dataset_metadata,
        image_object_detection_dataset_metadata => $image_object_detection_dataset_metadata,
    });

    # Read or update a field
    my $val = $msg->translation_dataset_metadata();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::Dataset::Dataset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/dataset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::Dataset::Dataset

A workspace for solving a single, particular machine learning (ML) problem.
A workspace contains examples that may be annotated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->translation_dataset_metadata() >> / C<< $msg->translation_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Translation::TranslationDatasetMetadata>)

Metadata for a dataset used for translation.

=item * C<< $msg->image_classification_dataset_metadata() >> / C<< $msg->image_classification_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Image::ImageClassificationDatasetMetadata>)

Metadata for a dataset used for image classification.

=item * C<< $msg->text_classification_dataset_metadata() >> / C<< $msg->text_classification_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Text::TextClassificationDatasetMetadata>)

Metadata for a dataset used for text classification.

=item * C<< $msg->image_object_detection_dataset_metadata() >> / C<< $msg->image_object_detection_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Image::ImageObjectDetectionDatasetMetadata>)

Metadata for a dataset used for image object detection.

=item * C<< $msg->text_extraction_dataset_metadata() >> / C<< $msg->text_extraction_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Text::TextExtractionDatasetMetadata>)

Metadata for a dataset used for text extraction.

=item * C<< $msg->text_sentiment_dataset_metadata() >> / C<< $msg->text_sentiment_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Text::TextSentimentDatasetMetadata>)

Metadata for a dataset used for text sentiment.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the dataset.
Form: `projects/{project_id}/locations/{location_id}/datasets/{dataset_id}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The name of the dataset to show in the interface. The name can be
up to 32 characters long and can consist only of ASCII Latin letters A-Z
and a-z, underscores
(_), and ASCII digits 0-9.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

User-provided description of the dataset. The description can be up to
25000 characters long.

=item * C<< $msg->example_count() >> / C<< $msg->example_count($value) >>

Type: C<Int32>

Output only. The number of examples in the dataset.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when this dataset was created.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Used to perform consistent read-modify-write updates. If not set, a blind
"overwrite" update happens.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Dataset::Dataset::LabelsEntry>)

Optional. The labels with user-defined metadata to organize your dataset.

Label keys and values can be no longer than 64 characters
(Unicode codepoints), can only contain lowercase letters, numeric
characters, underscores and dashes. International characters are allowed.
Label values are optional. Label keys must start with a letter.

See https://goo.gl/xmQnxf for more information on and examples of labels.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::Dataset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
