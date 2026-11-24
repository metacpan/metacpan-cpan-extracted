package Google::Cloud::Automl::V1beta1::Dataset;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Automl::V1beta1::Image };
    eval { require Google::Cloud::Automl::V1beta1::Tables };
    eval { require Google::Cloud::Automl::V1beta1::Text };
    eval { require Google::Cloud::Automl::V1beta1::Translation };
    eval { require Google::Cloud::Automl::V1beta1::Video };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvZGF0YXNldC5wcm90bxIbZ29vZ2xlLmNs
b3VkLmF1dG9tbC52MWJldGExGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGidnb29nbGUv
Y2xvdWQvYXV0b21sL3YxYmV0YTEvaW1hZ2UucHJvdG8aKGdvb2dsZS9jbG91ZC9hdXRvbWwv
djFiZXRhMS90YWJsZXMucHJvdG8aJmdvb2dsZS9jbG91ZC9hdXRvbWwvdjFiZXRhMS90ZXh0
LnByb3RvGi1nb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdHJhbnNsYXRpb24ucHJvdG8a
J2dvb2dsZS9jbG91ZC9hdXRvbWwvdjFiZXRhMS92aWRlby5wcm90bxofZ29vZ2xlL3Byb3Rv
YnVmL3RpbWVzdGFtcC5wcm90byK5DAoHRGF0YXNldBJ7Chx0cmFuc2xhdGlvbl9kYXRhc2V0
X21ldGFkYXRhGBcgASgLMjcuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRyYW5zbGF0
aW9uRGF0YXNldE1ldGFkYXRhSABSGnRyYW5zbGF0aW9uRGF0YXNldE1ldGFkYXRhEpQBCiVp
bWFnZV9jbGFzc2lmaWNhdGlvbl9kYXRhc2V0X21ldGFkYXRhGBggASgLMj8uZ29vZ2xlLmNs
b3VkLmF1dG9tbC52MWJldGExLkltYWdlQ2xhc3NpZmljYXRpb25EYXRhc2V0TWV0YWRhdGFI
AFIiaW1hZ2VDbGFzc2lmaWNhdGlvbkRhdGFzZXRNZXRhZGF0YRKRAQokdGV4dF9jbGFzc2lm
aWNhdGlvbl9kYXRhc2V0X21ldGFkYXRhGBkgASgLMj4uZ29vZ2xlLmNsb3VkLmF1dG9tbC52
MWJldGExLlRleHRDbGFzc2lmaWNhdGlvbkRhdGFzZXRNZXRhZGF0YUgAUiF0ZXh0Q2xhc3Np
ZmljYXRpb25EYXRhc2V0TWV0YWRhdGESmAEKJ2ltYWdlX29iamVjdF9kZXRlY3Rpb25fZGF0
YXNldF9tZXRhZGF0YRgaIAEoCzJALmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5JbWFn
ZU9iamVjdERldGVjdGlvbkRhdGFzZXRNZXRhZGF0YUgAUiNpbWFnZU9iamVjdERldGVjdGlv
bkRhdGFzZXRNZXRhZGF0YRKUAQoldmlkZW9fY2xhc3NpZmljYXRpb25fZGF0YXNldF9tZXRh
ZGF0YRgfIAEoCzI/Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5WaWRlb0NsYXNzaWZp
Y2F0aW9uRGF0YXNldE1ldGFkYXRhSABSInZpZGVvQ2xhc3NpZmljYXRpb25EYXRhc2V0TWV0
YWRhdGESlQEKJnZpZGVvX29iamVjdF90cmFja2luZ19kYXRhc2V0X21ldGFkYXRhGB0gASgL
Mj8uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlZpZGVvT2JqZWN0VHJhY2tpbmdEYXRh
c2V0TWV0YWRhdGFIAFIidmlkZW9PYmplY3RUcmFja2luZ0RhdGFzZXRNZXRhZGF0YRKFAQog
dGV4dF9leHRyYWN0aW9uX2RhdGFzZXRfbWV0YWRhdGEYHCABKAsyOi5nb29nbGUuY2xvdWQu
YXV0b21sLnYxYmV0YTEuVGV4dEV4dHJhY3Rpb25EYXRhc2V0TWV0YWRhdGFIAFIddGV4dEV4
dHJhY3Rpb25EYXRhc2V0TWV0YWRhdGESggEKH3RleHRfc2VudGltZW50X2RhdGFzZXRfbWV0
YWRhdGEYHiABKAsyOS5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVGV4dFNlbnRpbWVu
dERhdGFzZXRNZXRhZGF0YUgAUhx0ZXh0U2VudGltZW50RGF0YXNldE1ldGFkYXRhEmwKF3Rh
Ymxlc19kYXRhc2V0X21ldGFkYXRhGCEgASgLMjIuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJl
dGExLlRhYmxlc0RhdGFzZXRNZXRhZGF0YUgAUhV0YWJsZXNEYXRhc2V0TWV0YWRhdGESEgoE
bmFtZRgBIAEoCVIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEiAK
C2Rlc2NyaXB0aW9uGAMgASgJUgtkZXNjcmlwdGlvbhIjCg1leGFtcGxlX2NvdW50GBUgASgF
UgxleGFtcGxlQ291bnQSOwoLY3JlYXRlX3RpbWUYDiABKAsyGi5nb29nbGUucHJvdG9idWYu
VGltZXN0YW1wUgpjcmVhdGVUaW1lEhIKBGV0YWcYESABKAlSBGV0YWc6XupBWwodYXV0b21s
Lmdvb2dsZWFwaXMuY29tL0RhdGFzZXQSOnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMv
e2xvY2F0aW9ufS9kYXRhc2V0cy97ZGF0YXNldH1CEgoQZGF0YXNldF9tZXRhZGF0YUKbAQof
Y29tLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMVABWjdjbG91ZC5nb29nbGUuY29tL2dv
L2F1dG9tbC9hcGl2MWJldGExL2F1dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3VkXEF1
dG9NbFxWMWJldGEx6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMWJldGExSsoXCgYSBA4A
XgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwAS
AxIAIwoJCgIDARIDEwAxCgkKAgMCEgMUADIKCQoCAwMSAxUAMAoJCgIDBBIDFgA3CgkKAgMF
EgMXADEKCQoCAwYSAxgAKQoICgEIEgMaAE4KCQoCCAsSAxoATgoICgEIEgMbACIKCQoCCAoS
AxsAIgoICgEIEgMcADgKCQoCCAESAxwAOAoICgEIEgMdADgKCQoCCCkSAx0AOAoICgEIEgMe
ADcKCQoCCC0SAx4ANwqQAQoCBAASBCIAXgEagwEgQSB3b3Jrc3BhY2UgZm9yIHNvbHZpbmcg
YSBzaW5nbGUsIHBhcnRpY3VsYXIgbWFjaGluZSBsZWFybmluZyAoTUwpIHByb2JsZW0uCiBB
IHdvcmtzcGFjZSBjb250YWlucyBleGFtcGxlcyB0aGF0IG1heSBiZSBhbm5vdGF0ZWQuCgoK
CgMEAAESAyIIDwoLCgMEAAcSBCMCJgQKDQoFBAAHnQgSBCMCJgQKVQoEBAAIABIEKgJFAxpH
IFJlcXVpcmVkLgogVGhlIGRhdGFzZXQgbWV0YWRhdGEgdGhhdCBpcyBzcGVjaWZpYyB0byB0
aGUgcHJvYmxlbSB0eXBlLgoKDAoFBAAIAAESAyoIGAo7CgQEAAIAEgMsBEEaLiBNZXRhZGF0
YSBmb3IgYSBkYXRhc2V0IHVzZWQgZm9yIHRyYW5zbGF0aW9uLgoKDAoFBAACAAYSAywEHgoM
CgUEAAIAARIDLB87CgwKBQQAAgADEgMsPkAKRAoEBAACARIDLwRSGjcgTWV0YWRhdGEgZm9y
IGEgZGF0YXNldCB1c2VkIGZvciBpbWFnZSBjbGFzc2lmaWNhdGlvbi4KCgwKBQQAAgEGEgMv
BCYKDAoFBAACAQESAy8nTAoMCgUEAAIBAxIDL09RCkMKBAQAAgISAzIEUBo2IE1ldGFkYXRh
IGZvciBhIGRhdGFzZXQgdXNlZCBmb3IgdGV4dCBjbGFzc2lmaWNhdGlvbi4KCgwKBQQAAgIG
EgMyBCUKDAoFBAACAgESAzImSgoMCgUEAAICAxIDMk1PCkYKBAQAAgMSAzUEVRo5IE1ldGFk
YXRhIGZvciBhIGRhdGFzZXQgdXNlZCBmb3IgaW1hZ2Ugb2JqZWN0IGRldGVjdGlvbi4KCgwK
BQQAAgMGEgM1BCcKDAoFBAACAwESAzUoTwoMCgUEAAIDAxIDNVJUCkQKBAQAAgQSAzgEUho3
IE1ldGFkYXRhIGZvciBhIGRhdGFzZXQgdXNlZCBmb3IgdmlkZW8gY2xhc3NpZmljYXRpb24u
CgoMCgUEAAIEBhIDOAQmCgwKBQQAAgQBEgM4J0wKDAoFBAACBAMSAzhPUQpFCgQEAAIFEgM7
BFMaOCBNZXRhZGF0YSBmb3IgYSBkYXRhc2V0IHVzZWQgZm9yIHZpZGVvIG9iamVjdCB0cmFj
a2luZy4KCgwKBQQAAgUGEgM7BCYKDAoFBAACBQESAzsnTQoMCgUEAAIFAxIDO1BSCj8KBAQA
AgYSAz4ESBoyIE1ldGFkYXRhIGZvciBhIGRhdGFzZXQgdXNlZCBmb3IgdGV4dCBleHRyYWN0
aW9uLgoKDAoFBAACBgYSAz4EIQoMCgUEAAIGARIDPiJCCgwKBQQAAgYDEgM+RUcKPgoEBAAC
BxIDQQRGGjEgTWV0YWRhdGEgZm9yIGEgZGF0YXNldCB1c2VkIGZvciB0ZXh0IHNlbnRpbWVu
dC4KCgwKBQQAAgcGEgNBBCAKDAoFBAACBwESA0EhQAoMCgUEAAIHAxIDQUNFCjYKBAQAAggS
A0QENxopIE1ldGFkYXRhIGZvciBhIGRhdGFzZXQgdXNlZCBmb3IgVGFibGVzLgoKDAoFBAAC
CAYSA0QEGQoMCgUEAAIIARIDRBoxCgwKBQQAAggDEgNENDYKigEKBAQAAgkSA0kCEhp9IE91
dHB1dCBvbmx5LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgZGF0YXNldC4KIEZvcm06IGBw
cm9qZWN0cy97cHJvamVjdF9pZH0vbG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vZGF0YXNldHMv
e2RhdGFzZXRfaWR9YAoKDAoFBAACCQUSA0kCCAoMCgUEAAIJARIDSQkNCgwKBQQAAgkDEgNJ
EBEK1wEKBAQAAgoSA08CGhrJASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGRhdGFzZXQg
dG8gc2hvdyBpbiB0aGUgaW50ZXJmYWNlLiBUaGUgbmFtZSBjYW4gYmUKIHVwIHRvIDMyIGNo
YXJhY3RlcnMgbG9uZyBhbmQgY2FuIGNvbnNpc3Qgb25seSBvZiBBU0NJSSBMYXRpbiBsZXR0
ZXJzIEEtWgogYW5kIGEteiwgdW5kZXJzY29yZXMKIChfKSwgYW5kIEFTQ0lJIGRpZ2l0cyAw
LTkuCgoMCgUEAAIKBRIDTwIICgwKBQQAAgoBEgNPCRUKDAoFBAACCgMSA08YGQptCgQEAAIL
EgNTAhkaYCBVc2VyLXByb3ZpZGVkIGRlc2NyaXB0aW9uIG9mIHRoZSBkYXRhc2V0LiBUaGUg
ZGVzY3JpcHRpb24gY2FuIGJlIHVwIHRvCiAyNTAwMCBjaGFyYWN0ZXJzIGxvbmcuCgoMCgUE
AAILBRIDUwIICgwKBQQAAgsBEgNTCRQKDAoFBAACCwMSA1MXGApCCgQEAAIMEgNWAhsaNSBP
dXRwdXQgb25seS4gVGhlIG51bWJlciBvZiBleGFtcGxlcyBpbiB0aGUgZGF0YXNldC4KCgwK
BQQAAgwFEgNWAgcKDAoFBAACDAESA1YIFQoMCgUEAAIMAxIDVhgaCkQKBAQAAg0SA1kCLRo3
IE91dHB1dCBvbmx5LiBUaW1lc3RhbXAgd2hlbiB0aGlzIGRhdGFzZXQgd2FzIGNyZWF0ZWQu
CgoMCgUEAAINBhIDWQIbCgwKBQQAAg0BEgNZHCcKDAoFBAACDQMSA1kqLAp1CgQEAAIOEgNd
AhMaaCBVc2VkIHRvIHBlcmZvcm0gY29uc2lzdGVudCByZWFkLW1vZGlmeS13cml0ZSB1cGRh
dGVzLiBJZiBub3Qgc2V0LCBhIGJsaW5kCiAib3ZlcndyaXRlIiB1cGRhdGUgaGFwcGVucy4K
CgwKBQQAAg4FEgNdAggKDAoFBAACDgESA10JDQoMCgUEAAIOAxIDXRASYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Dataset::Dataset ===
    # Fields for Dataset
    # Field: translation_dataset_metadata Type: 11 (.google.cloud.automl.v1beta1.TranslationDatasetMetadata)
    # Field: image_classification_dataset_metadata Type: 11 (.google.cloud.automl.v1beta1.ImageClassificationDatasetMetadata)
    # Field: text_classification_dataset_metadata Type: 11 (.google.cloud.automl.v1beta1.TextClassificationDatasetMetadata)
    # Field: image_object_detection_dataset_metadata Type: 11 (.google.cloud.automl.v1beta1.ImageObjectDetectionDatasetMetadata)
    # Field: video_classification_dataset_metadata Type: 11 (.google.cloud.automl.v1beta1.VideoClassificationDatasetMetadata)
    # Field: video_object_tracking_dataset_metadata Type: 11 (.google.cloud.automl.v1beta1.VideoObjectTrackingDatasetMetadata)
    # Field: text_extraction_dataset_metadata Type: 11 (.google.cloud.automl.v1beta1.TextExtractionDatasetMetadata)
    # Field: text_sentiment_dataset_metadata Type: 11 (.google.cloud.automl.v1beta1.TextSentimentDatasetMetadata)
    # Field: tables_dataset_metadata Type: 11 (.google.cloud.automl.v1beta1.TablesDatasetMetadata)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: example_count Type: 5 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Dataset - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/dataset.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Dataset;

    my $msg = Google::Cloud::Automl::V1beta1::Dataset::Dataset->new({
        translation_dataset_metadata => $translation_dataset_metadata,
        image_classification_dataset_metadata => $image_classification_dataset_metadata,
        text_classification_dataset_metadata => $text_classification_dataset_metadata,
        image_object_detection_dataset_metadata => $image_object_detection_dataset_metadata,
    });

    # Read or update a field
    my $val = $msg->translation_dataset_metadata();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Dataset::Dataset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/dataset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Dataset::Dataset

A workspace for solving a single, particular machine learning (ML) problem.
A workspace contains examples that may be annotated.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->translation_dataset_metadata() >> / C<< $msg->translation_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Translation::TranslationDatasetMetadata>)

Metadata for a dataset used for translation.

=item * C<< $msg->image_classification_dataset_metadata() >> / C<< $msg->image_classification_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Image::ImageClassificationDatasetMetadata>)

Metadata for a dataset used for image classification.

=item * C<< $msg->text_classification_dataset_metadata() >> / C<< $msg->text_classification_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Text::TextClassificationDatasetMetadata>)

Metadata for a dataset used for text classification.

=item * C<< $msg->image_object_detection_dataset_metadata() >> / C<< $msg->image_object_detection_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionDatasetMetadata>)

Metadata for a dataset used for image object detection.

=item * C<< $msg->video_classification_dataset_metadata() >> / C<< $msg->video_classification_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Video::VideoClassificationDatasetMetadata>)

Metadata for a dataset used for video classification.

=item * C<< $msg->video_object_tracking_dataset_metadata() >> / C<< $msg->video_object_tracking_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingDatasetMetadata>)

Metadata for a dataset used for video object tracking.

=item * C<< $msg->text_extraction_dataset_metadata() >> / C<< $msg->text_extraction_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Text::TextExtractionDatasetMetadata>)

Metadata for a dataset used for text extraction.

=item * C<< $msg->text_sentiment_dataset_metadata() >> / C<< $msg->text_sentiment_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Text::TextSentimentDatasetMetadata>)

Metadata for a dataset used for text sentiment.

=item * C<< $msg->tables_dataset_metadata() >> / C<< $msg->tables_dataset_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Tables::TablesDatasetMetadata>)

Metadata for a dataset used for Tables.

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

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Dataset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
