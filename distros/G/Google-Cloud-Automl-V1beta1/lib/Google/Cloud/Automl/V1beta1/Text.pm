package Google::Cloud::Automl::V1beta1::Text;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1beta1::Classification };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdGV4dC5wcm90bxIbZ29vZ2xlLmNsb3Vk
LmF1dG9tbC52MWJldGExGjBnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvY2xhc3NpZmlj
YXRpb24ucHJvdG8ihQEKIVRleHRDbGFzc2lmaWNhdGlvbkRhdGFzZXRNZXRhZGF0YRJgChNj
bGFzc2lmaWNhdGlvbl90eXBlGAEgASgOMi8uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGEx
LkNsYXNzaWZpY2F0aW9uVHlwZVISY2xhc3NpZmljYXRpb25UeXBlIoMBCh9UZXh0Q2xhc3Np
ZmljYXRpb25Nb2RlbE1ldGFkYXRhEmAKE2NsYXNzaWZpY2F0aW9uX3R5cGUYAyABKA4yLy5n
b29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuQ2xhc3NpZmljYXRpb25UeXBlUhJjbGFzc2lm
aWNhdGlvblR5cGUiHwodVGV4dEV4dHJhY3Rpb25EYXRhc2V0TWV0YWRhdGEiPAobVGV4dEV4
dHJhY3Rpb25Nb2RlbE1ldGFkYXRhEh0KCm1vZGVsX2hpbnQYAyABKAlSCW1vZGVsSGludCJD
ChxUZXh0U2VudGltZW50RGF0YXNldE1ldGFkYXRhEiMKDXNlbnRpbWVudF9tYXgYASABKAVS
DHNlbnRpbWVudE1heCIcChpUZXh0U2VudGltZW50TW9kZWxNZXRhZGF0YUKmAQofY29tLmdv
b2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMUIJVGV4dFByb3RvUAFaN2Nsb3VkLmdvb2dsZS5j
b20vZ28vYXV0b21sL2FwaXYxYmV0YTEvYXV0b21scGI7YXV0b21scGLKAhtHb29nbGVcQ2xv
dWRcQXV0b01sXFYxYmV0YTHqAh5Hb29nbGU6OkNsb3VkOjpBdXRvTUw6OlYxYmV0YTFKyRAK
BhIEDgBFAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJ
CgIDABIDEgA6CggKAQgSAxQATgoJCgIICxIDFABOCggKAQgSAxUAIgoJCgIIChIDFQAiCggK
AQgSAxYAKgoJCgIICBIDFgAqCggKAQgSAxcAOAoJCgIIARIDFwA4CggKAQgSAxgAOAoJCgII
KRIDGAA4CggKAQgSAxkANwoJCgIILRIDGQA3CjIKAgQAEgQcAB8BGiYgRGF0YXNldCBtZXRh
ZGF0YSBmb3IgY2xhc3NpZmljYXRpb24uCgoKCgMEAAESAxwIKQo8CgQEAAIAEgMeAi0aLyBS
ZXF1aXJlZC4gVHlwZSBvZiB0aGUgY2xhc3NpZmljYXRpb24gcHJvYmxlbS4KCgwKBQQAAgAG
EgMeAhQKDAoFBAACAAESAx4VKAoMCgUEAAIAAxIDHissCkUKAgQBEgQiACUBGjkgTW9kZWwg
bWV0YWRhdGEgdGhhdCBpcyBzcGVjaWZpYyB0byB0ZXh0IGNsYXNzaWZpY2F0aW9uLgoKCgoD
BAEBEgMiCCcKWAoEBAECABIDJAItGksgT3V0cHV0IG9ubHkuIENsYXNzaWZpY2F0aW9uIHR5
cGUgb2YgdGhlIGRhdGFzZXQgdXNlZCB0byB0cmFpbiB0aGlzIG1vZGVsLgoKDAoFBAECAAYS
AyQCFAoMCgUEAQIAARIDJBUoCgwKBQQBAgADEgMkKywKQgoCBAISBCgAKgEaNiBEYXRhc2V0
IG1ldGFkYXRhIHRoYXQgaXMgc3BlY2lmaWMgdG8gdGV4dCBleHRyYWN0aW9uCgoKCgMEAgES
AygIJQpBCgIEAxIELQA1ARo1IE1vZGVsIG1ldGFkYXRhIHRoYXQgaXMgc3BlY2lmaWMgdG8g
dGV4dCBleHRyYWN0aW9uLgoKCgoDBAMBEgMtCCMK6AEKBAQDAgASAzQCGBraASBJbmRpY2F0
ZXMgdGhlIHNjb3BlIG9mIG1vZGVsIHVzZSBjYXNlLgoKICogYGRlZmF1bHRgOiBVc2UgdG8g
dHJhaW4gYSBnZW5lcmFsIHRleHQgZXh0cmFjdGlvbiBtb2RlbC4gRGVmYXVsdCB2YWx1ZS4K
CiAqIGBoZWFsdGhfY2FyZWA6IFVzZSB0byB0cmFpbiBhIHRleHQgZXh0cmFjdGlvbiBtb2Rl
bCB0aGF0IGlzIHR1bmVkIGZvcgogICBoZWFsdGhjYXJlIGFwcGxpY2F0aW9ucy4KCgwKBQQD
AgAFEgM0AggKDAoFBAMCAAESAzQJEwoMCgUEAwIAAxIDNBYXCjIKAgQEEgQ4AEABGiYgRGF0
YXNldCBtZXRhZGF0YSBmb3IgdGV4dCBzZW50aW1lbnQuCgoKCgMEBAESAzgIJAqBAwoEBAQC
ABIDPwIaGvMCIFJlcXVpcmVkLiBBIHNlbnRpbWVudCBpcyBleHByZXNzZWQgYXMgYW4gaW50
ZWdlciBvcmRpbmFsLCB3aGVyZSBoaWdoZXIgdmFsdWUKIG1lYW5zIGEgbW9yZSBwb3NpdGl2
ZSBzZW50aW1lbnQuIFRoZSByYW5nZSBvZiBzZW50aW1lbnRzIHRoYXQgd2lsbCBiZSB1c2Vk
CiBpcyBiZXR3ZWVuIDAgYW5kIHNlbnRpbWVudF9tYXggKGluY2x1c2l2ZSBvbiBib3RoIGVu
ZHMpLCBhbmQgYWxsIHRoZSB2YWx1ZXMKIGluIHRoZSByYW5nZSBtdXN0IGJlIHJlcHJlc2Vu
dGVkIGluIHRoZSBkYXRhc2V0IGJlZm9yZSBhIG1vZGVsIGNhbiBiZQogY3JlYXRlZC4KIHNl
bnRpbWVudF9tYXggdmFsdWUgbXVzdCBiZSBiZXR3ZWVuIDEgYW5kIDEwIChpbmNsdXNpdmUp
LgoKDAoFBAQCAAUSAz8CBwoMCgUEBAIAARIDPwgVCgwKBQQEAgADEgM/GBkKQAoCBAUSBEMA
RQEaNCBNb2RlbCBtZXRhZGF0YSB0aGF0IGlzIHNwZWNpZmljIHRvIHRleHQgc2VudGltZW50
LgoKCgoDBAUBEgNDCCJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Text::TextClassificationDatasetMetadata ===
    # Fields for TextClassificationDatasetMetadata
    # Field: classification_type Type: 14 (.google.cloud.automl.v1beta1.ClassificationType)

# === Message: Google::Cloud::Automl::V1beta1::Text::TextClassificationModelMetadata ===
    # Fields for TextClassificationModelMetadata
    # Field: classification_type Type: 14 (.google.cloud.automl.v1beta1.ClassificationType)

# === Message: Google::Cloud::Automl::V1beta1::Text::TextExtractionDatasetMetadata ===
    # Fields for TextExtractionDatasetMetadata

# === Message: Google::Cloud::Automl::V1beta1::Text::TextExtractionModelMetadata ===
    # Fields for TextExtractionModelMetadata
    # Field: model_hint Type: 9 ()

# === Message: Google::Cloud::Automl::V1beta1::Text::TextSentimentDatasetMetadata ===
    # Fields for TextSentimentDatasetMetadata
    # Field: sentiment_max Type: 5 ()

# === Message: Google::Cloud::Automl::V1beta1::Text::TextSentimentModelMetadata ===
    # Fields for TextSentimentModelMetadata

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Text - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/text.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Text;

    my $msg = Google::Cloud::Automl::V1beta1::Text::TextClassificationDatasetMetadata->new({
        classification_type => $classification_type,
    });

    # Read or update a field
    my $val = $msg->classification_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Text::TextClassificationDatasetMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/text.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Text::TextClassificationDatasetMetadata

Dataset metadata for classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classification_type() >> / C<< $msg->classification_type($value) >>

Type: C<Enum> (L<Google::Cloud::Automl::V1beta1::ClassificationType>)

Required. Type of the classification problem.

=back

=head2 Google::Cloud::Automl::V1beta1::Text::TextClassificationModelMetadata

Model metadata that is specific to text classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classification_type() >> / C<< $msg->classification_type($value) >>

Type: C<Enum> (L<Google::Cloud::Automl::V1beta1::ClassificationType>)

Output only. Classification type of the dataset used to train this model.

=back

=head2 Google::Cloud::Automl::V1beta1::Text::TextExtractionDatasetMetadata

Dataset metadata that is specific to text extraction

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1beta1::Text::TextExtractionModelMetadata

Model metadata that is specific to text extraction.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->model_hint() >> / C<< $msg->model_hint($value) >>

Type: C<String>

Indicates the scope of model use case.

* `default`: Use to train a general text extraction model. Default value.

* `health_care`: Use to train a text extraction model that is tuned for
  healthcare applications.

=back

=head2 Google::Cloud::Automl::V1beta1::Text::TextSentimentDatasetMetadata

Dataset metadata for text sentiment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sentiment_max() >> / C<< $msg->sentiment_max($value) >>

Type: C<Int32>

Required. A sentiment is expressed as an integer ordinal, where higher value
means a more positive sentiment. The range of sentiments that will be used
is between 0 and sentiment_max (inclusive on both ends), and all the values
in the range must be represented in the dataset before a model can be
created.
sentiment_max value must be between 1 and 10 (inclusive).

=back

=head2 Google::Cloud::Automl::V1beta1::Text::TextSentimentModelMetadata

Model metadata that is specific to text sentiment.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Text::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
