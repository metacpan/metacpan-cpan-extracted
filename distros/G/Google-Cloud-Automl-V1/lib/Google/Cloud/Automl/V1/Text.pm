package Google::Cloud::Automl::V1::Text;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1::Classification };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvY2xvdWQvYXV0b21sL3YxL3RleHQucHJvdG8SFmdvb2dsZS5jbG91ZC5hdXRv
bWwudjEaK2dvb2dsZS9jbG91ZC9hdXRvbWwvdjEvY2xhc3NpZmljYXRpb24ucHJvdG8igAEK
IVRleHRDbGFzc2lmaWNhdGlvbkRhdGFzZXRNZXRhZGF0YRJbChNjbGFzc2lmaWNhdGlvbl90
eXBlGAEgASgOMiouZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5DbGFzc2lmaWNhdGlvblR5cGVS
EmNsYXNzaWZpY2F0aW9uVHlwZSJ+Ch9UZXh0Q2xhc3NpZmljYXRpb25Nb2RlbE1ldGFkYXRh
ElsKE2NsYXNzaWZpY2F0aW9uX3R5cGUYAyABKA4yKi5nb29nbGUuY2xvdWQuYXV0b21sLnYx
LkNsYXNzaWZpY2F0aW9uVHlwZVISY2xhc3NpZmljYXRpb25UeXBlIh8KHVRleHRFeHRyYWN0
aW9uRGF0YXNldE1ldGFkYXRhIh0KG1RleHRFeHRyYWN0aW9uTW9kZWxNZXRhZGF0YSJDChxU
ZXh0U2VudGltZW50RGF0YXNldE1ldGFkYXRhEiMKDXNlbnRpbWVudF9tYXgYASABKAVSDHNl
bnRpbWVudE1heCIcChpUZXh0U2VudGltZW50TW9kZWxNZXRhZGF0YUKrAQoaY29tLmdvb2ds
ZS5jbG91ZC5hdXRvbWwudjFCCVRleHRQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2F1
dG9tbC9hcGl2MS9hdXRvbWxwYjthdXRvbWxwYqoCFkdvb2dsZS5DbG91ZC5BdXRvTUwuVjHK
AhZHb29nbGVcQ2xvdWRcQXV0b01sXFYx6gIZR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMUrJ
DgoGEgQOAEABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAf
CgkKAgMAEgMSADUKCAoBCBIDFAAzCgkKAgglEgMUADMKCAoBCBIDFQBJCgkKAggLEgMVAEkK
CAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAqCgkKAggIEgMXACoKCAoBCBIDGAAzCgkK
AggBEgMYADMKCAoBCBIDGQAzCgkKAggpEgMZADMKCAoBCBIDGgAyCgkKAggtEgMaADIKMgoC
BAASBB0AIAEaJiBEYXRhc2V0IG1ldGFkYXRhIGZvciBjbGFzc2lmaWNhdGlvbi4KCgoKAwQA
ARIDHQgpCjwKBAQAAgASAx8CLRovIFJlcXVpcmVkLiBUeXBlIG9mIHRoZSBjbGFzc2lmaWNh
dGlvbiBwcm9ibGVtLgoKDAoFBAACAAYSAx8CFAoMCgUEAAIAARIDHxUoCgwKBQQAAgADEgMf
KywKRQoCBAESBCMAJgEaOSBNb2RlbCBtZXRhZGF0YSB0aGF0IGlzIHNwZWNpZmljIHRvIHRl
eHQgY2xhc3NpZmljYXRpb24uCgoKCgMEAQESAyMIJwpYCgQEAQIAEgMlAi0aSyBPdXRwdXQg
b25seS4gQ2xhc3NpZmljYXRpb24gdHlwZSBvZiB0aGUgZGF0YXNldCB1c2VkIHRvIHRyYWlu
IHRoaXMgbW9kZWwuCgoMCgUEAQIABhIDJQIUCgwKBQQBAgABEgMlFSgKDAoFBAECAAMSAyUr
LApCCgIEAhIEKQArARo2IERhdGFzZXQgbWV0YWRhdGEgdGhhdCBpcyBzcGVjaWZpYyB0byB0
ZXh0IGV4dHJhY3Rpb24KCgoKAwQCARIDKQglCkEKAgQDEgQuADABGjUgTW9kZWwgbWV0YWRh
dGEgdGhhdCBpcyBzcGVjaWZpYyB0byB0ZXh0IGV4dHJhY3Rpb24uCgoKCgMEAwESAy4IIwoy
CgIEBBIEMwA7ARomIERhdGFzZXQgbWV0YWRhdGEgZm9yIHRleHQgc2VudGltZW50LgoKCgoD
BAQBEgMzCCQKgQMKBAQEAgASAzoCGhrzAiBSZXF1aXJlZC4gQSBzZW50aW1lbnQgaXMgZXhw
cmVzc2VkIGFzIGFuIGludGVnZXIgb3JkaW5hbCwgd2hlcmUgaGlnaGVyIHZhbHVlCiBtZWFu
cyBhIG1vcmUgcG9zaXRpdmUgc2VudGltZW50LiBUaGUgcmFuZ2Ugb2Ygc2VudGltZW50cyB0
aGF0IHdpbGwgYmUgdXNlZAogaXMgYmV0d2VlbiAwIGFuZCBzZW50aW1lbnRfbWF4IChpbmNs
dXNpdmUgb24gYm90aCBlbmRzKSwgYW5kIGFsbCB0aGUgdmFsdWVzCiBpbiB0aGUgcmFuZ2Ug
bXVzdCBiZSByZXByZXNlbnRlZCBpbiB0aGUgZGF0YXNldCBiZWZvcmUgYSBtb2RlbCBjYW4g
YmUKIGNyZWF0ZWQuCiBzZW50aW1lbnRfbWF4IHZhbHVlIG11c3QgYmUgYmV0d2VlbiAxIGFu
ZCAxMCAoaW5jbHVzaXZlKS4KCgwKBQQEAgAFEgM6AgcKDAoFBAQCAAESAzoIFQoMCgUEBAIA
AxIDOhgZCkAKAgQFEgQ+AEABGjQgTW9kZWwgbWV0YWRhdGEgdGhhdCBpcyBzcGVjaWZpYyB0
byB0ZXh0IHNlbnRpbWVudC4KCgoKAwQFARIDPggiYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::Text::TextClassificationDatasetMetadata ===
    # Fields for TextClassificationDatasetMetadata
    # Field: classification_type Type: 14 (.google.cloud.automl.v1.ClassificationType)

# === Message: Google::Cloud::Automl::V1::Text::TextClassificationModelMetadata ===
    # Fields for TextClassificationModelMetadata
    # Field: classification_type Type: 14 (.google.cloud.automl.v1.ClassificationType)

# === Message: Google::Cloud::Automl::V1::Text::TextExtractionDatasetMetadata ===
    # Fields for TextExtractionDatasetMetadata

# === Message: Google::Cloud::Automl::V1::Text::TextExtractionModelMetadata ===
    # Fields for TextExtractionModelMetadata

# === Message: Google::Cloud::Automl::V1::Text::TextSentimentDatasetMetadata ===
    # Fields for TextSentimentDatasetMetadata
    # Field: sentiment_max Type: 5 ()

# === Message: Google::Cloud::Automl::V1::Text::TextSentimentModelMetadata ===
    # Fields for TextSentimentModelMetadata

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::Text - Compiled Protocol Buffers messages for google/cloud/automl/v1/text.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::Text;

    my $msg = Google::Cloud::Automl::V1::Text::TextClassificationDatasetMetadata->new({
        classification_type => $classification_type,
    });

    # Read or update a field
    my $val = $msg->classification_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::Text::TextClassificationDatasetMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/text.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::Text::TextClassificationDatasetMetadata

Dataset metadata for classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classification_type() >> / C<< $msg->classification_type($value) >>

Type: C<Enum> (L<Google::Cloud::Automl::V1::ClassificationType>)

Required. Type of the classification problem.

=back

=head2 Google::Cloud::Automl::V1::Text::TextClassificationModelMetadata

Model metadata that is specific to text classification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classification_type() >> / C<< $msg->classification_type($value) >>

Type: C<Enum> (L<Google::Cloud::Automl::V1::ClassificationType>)

Output only. Classification type of the dataset used to train this model.

=back

=head2 Google::Cloud::Automl::V1::Text::TextExtractionDatasetMetadata

Dataset metadata that is specific to text extraction

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1::Text::TextExtractionModelMetadata

Model metadata that is specific to text extraction.

Inherits from L<Protobuf::Message>.

=head2 Google::Cloud::Automl::V1::Text::TextSentimentDatasetMetadata

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

=head2 Google::Cloud::Automl::V1::Text::TextSentimentModelMetadata

Model metadata that is specific to text sentiment.

Inherits from L<Protobuf::Message>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::Text::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
