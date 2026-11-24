package Google::Cloud::Automl::V1beta1::AnnotationPayload;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1beta1::Classification };
    eval { require Google::Cloud::Automl::V1beta1::Detection };
    eval { require Google::Cloud::Automl::V1beta1::Tables };
    eval { require Google::Cloud::Automl::V1beta1::TextExtraction };
    eval { require Google::Cloud::Automl::V1beta1::TextSentiment };
    eval { require Google::Cloud::Automl::V1beta1::Translation };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvYW5ub3RhdGlvbl9wYXlsb2FkLnByb3Rv
Ehtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEaMGdvb2dsZS9jbG91ZC9hdXRvbWwvdjFi
ZXRhMS9jbGFzc2lmaWNhdGlvbi5wcm90bxorZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGEx
L2RldGVjdGlvbi5wcm90bxooZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL3RhYmxlcy5w
cm90bxoxZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL3RleHRfZXh0cmFjdGlvbi5wcm90
bxowZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL3RleHRfc2VudGltZW50LnByb3RvGi1n
b29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdHJhbnNsYXRpb24ucHJvdG8iiQcKEUFubm90
YXRpb25QYXlsb2FkElYKC3RyYW5zbGF0aW9uGAIgASgLMjIuZ29vZ2xlLmNsb3VkLmF1dG9t
bC52MWJldGExLlRyYW5zbGF0aW9uQW5ub3RhdGlvbkgAUgt0cmFuc2xhdGlvbhJfCg5jbGFz
c2lmaWNhdGlvbhgDIAEoCzI1Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5DbGFzc2lm
aWNhdGlvbkFubm90YXRpb25IAFIOY2xhc3NpZmljYXRpb24ScwoWaW1hZ2Vfb2JqZWN0X2Rl
dGVjdGlvbhgEIAEoCzI7Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5JbWFnZU9iamVj
dERldGVjdGlvbkFubm90YXRpb25IAFIUaW1hZ2VPYmplY3REZXRlY3Rpb24SbwoUdmlkZW9f
Y2xhc3NpZmljYXRpb24YCSABKAsyOi5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVmlk
ZW9DbGFzc2lmaWNhdGlvbkFubm90YXRpb25IAFITdmlkZW9DbGFzc2lmaWNhdGlvbhJwChV2
aWRlb19vYmplY3RfdHJhY2tpbmcYCCABKAsyOi5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0
YTEuVmlkZW9PYmplY3RUcmFja2luZ0Fubm90YXRpb25IAFITdmlkZW9PYmplY3RUcmFja2lu
ZxJgCg90ZXh0X2V4dHJhY3Rpb24YBiABKAsyNS5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0
YTEuVGV4dEV4dHJhY3Rpb25Bbm5vdGF0aW9uSABSDnRleHRFeHRyYWN0aW9uEl0KDnRleHRf
c2VudGltZW50GAcgASgLMjQuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRleHRTZW50
aW1lbnRBbm5vdGF0aW9uSABSDXRleHRTZW50aW1lbnQSRwoGdGFibGVzGAogASgLMi0uZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRhYmxlc0Fubm90YXRpb25IAFIGdGFibGVzEiwK
EmFubm90YXRpb25fc3BlY19pZBgBIAEoCVIQYW5ub3RhdGlvblNwZWNJZBIhCgxkaXNwbGF5
X25hbWUYBSABKAlSC2Rpc3BsYXlOYW1lQggKBmRldGFpbEKbAQofY29tLmdvb2dsZS5jbG91
ZC5hdXRvbWwudjFiZXRhMVABWjdjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MWJl
dGExL2F1dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3VkXEF1dG9NbFxWMWJldGEx6gIe
R29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMWJldGExSswTCgYSBA4ASgEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAOgoJCgIDARIDEwA1
CgkKAgMCEgMUADIKCQoCAwMSAxUAOwoJCgIDBBIDFgA6CgkKAgMFEgMXADcKCAoBCBIDGQBO
CgkKAggLEgMZAE4KCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwA4CgkKAggBEgMbADgK
CAoBCBIDHAA4CgkKAggpEgMcADgKCAoBCBIDHQA3CgkKAggtEgMdADcKSQoCBAASBCAASgEa
PSBDb250YWlucyBhbm5vdGF0aW9uIGluZm9ybWF0aW9uIHRoYXQgaXMgcmVsZXZhbnQgdG8g
QXV0b01MLgoKCgoDBAABEgMgCBkKaQoEBAAIABIEIwI8AxpbIE91dHB1dCBvbmx5IC4gQWRk
aXRpb25hbCBpbmZvcm1hdGlvbiBhYm91dCB0aGUgYW5ub3RhdGlvbgogc3BlY2lmaWMgdG8g
dGhlIEF1dG9NTCBkb21haW4uCgoMCgUEAAgAARIDIwgOCjIKBAQAAgASAyUEKholIEFubm90
YXRpb24gZGV0YWlscyBmb3IgdHJhbnNsYXRpb24uCgoMCgUEAAIABhIDJQQZCgwKBQQAAgAB
EgMlGiUKDAoFBAACAAMSAyUoKQpGCgQEAAIBEgMoBDAaOSBBbm5vdGF0aW9uIGRldGFpbHMg
Zm9yIGNvbnRlbnQgb3IgaW1hZ2UgY2xhc3NpZmljYXRpb24uCgoMCgUEAAIBBhIDKAQcCgwK
BQQAAgEBEgMoHSsKDAoFBAACAQMSAyguLwo9CgQEAAICEgMrBD4aMCBBbm5vdGF0aW9uIGRl
dGFpbHMgZm9yIGltYWdlIG9iamVjdCBkZXRlY3Rpb24uCgoMCgUEAAICBhIDKwQiCgwKBQQA
AgIBEgMrIzkKDAoFBAACAgMSAys8PQprCgQEAAIDEgMvBDsaXiBBbm5vdGF0aW9uIGRldGFp
bHMgZm9yIHZpZGVvIGNsYXNzaWZpY2F0aW9uLgogUmV0dXJuZWQgZm9yIFZpZGVvIENsYXNz
aWZpY2F0aW9uIHByZWRpY3Rpb25zLgoKDAoFBAACAwYSAy8EIQoMCgUEAAIDARIDLyI2CgwK
BQQAAgMDEgMvOToKPAoEBAACBBIDMgQ8Gi8gQW5ub3RhdGlvbiBkZXRhaWxzIGZvciB2aWRl
byBvYmplY3QgdHJhY2tpbmcuCgoMCgUEAAIEBhIDMgQhCgwKBQQAAgQBEgMyIjcKDAoFBAAC
BAMSAzI6Owo2CgQEAAIFEgM1BDEaKSBBbm5vdGF0aW9uIGRldGFpbHMgZm9yIHRleHQgZXh0
cmFjdGlvbi4KCgwKBQQAAgUGEgM1BBwKDAoFBAACBQESAzUdLAoMCgUEAAIFAxIDNS8wCjUK
BAQAAgYSAzgELxooIEFubm90YXRpb24gZGV0YWlscyBmb3IgdGV4dCBzZW50aW1lbnQuCgoM
CgUEAAIGBhIDOAQbCgwKBQQAAgYBEgM4HCoKDAoFBAACBgMSAzgtLgotCgQEAAIHEgM7BCEa
ICBBbm5vdGF0aW9uIGRldGFpbHMgZm9yIFRhYmxlcy4KCgwKBQQAAgcGEgM7BBQKDAoFBAAC
BwESAzsVGwoMCgUEAAIHAxIDOx4gCtsBCgQEAAIIEgNBAiAazQEgT3V0cHV0IG9ubHkgLiBU
aGUgcmVzb3VyY2UgSUQgb2YgdGhlIGFubm90YXRpb24gc3BlYyB0aGF0CiB0aGlzIGFubm90
YXRpb24gcGVydGFpbnMgdG8uIFRoZSBhbm5vdGF0aW9uIHNwZWMgY29tZXMgZnJvbSBlaXRo
ZXIgYW4KIGFuY2VzdG9yIGRhdGFzZXQsIG9yIHRoZSBkYXRhc2V0IHRoYXQgd2FzIHVzZWQg
dG8gdHJhaW4gdGhlIG1vZGVsIGluIHVzZS4KCgwKBQQAAggFEgNBAggKDAoFBAACCAESA0EJ
GwoMCgUEAAIIAxIDQR4fCvcCCgQEAAIJEgNJAhoa6QIgT3V0cHV0IG9ubHkuIFRoZSB2YWx1
ZSBvZgogW2Rpc3BsYXlfbmFtZV1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkFubm90
YXRpb25TcGVjLmRpc3BsYXlfbmFtZV0KIHdoZW4gdGhlIG1vZGVsIHdhcyB0cmFpbmVkLiBC
ZWNhdXNlIHRoaXMgZmllbGQgcmV0dXJucyBhIHZhbHVlIGF0IG1vZGVsCiB0cmFpbmluZyB0
aW1lLCBmb3IgZGlmZmVyZW50IG1vZGVscyB0cmFpbmVkIHVzaW5nIHRoZSBzYW1lIGRhdGFz
ZXQsIHRoZQogcmV0dXJuZWQgdmFsdWUgY291bGQgYmUgZGlmZmVyZW50IGFzIG1vZGVsIG93
bmVyIGNvdWxkIHVwZGF0ZSB0aGUKIGBkaXNwbGF5X25hbWVgIGJldHdlZW4gYW55IHR3byBt
b2RlbCB0cmFpbmluZy4KCgwKBQQAAgkFEgNJAggKDAoFBAACCQESA0kJFQoMCgUEAAIJAxID
SRgZYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::AnnotationPayload::AnnotationPayload ===
    # Fields for AnnotationPayload
    # Field: translation Type: 11 (.google.cloud.automl.v1beta1.TranslationAnnotation)
    # Field: classification Type: 11 (.google.cloud.automl.v1beta1.ClassificationAnnotation)
    # Field: image_object_detection Type: 11 (.google.cloud.automl.v1beta1.ImageObjectDetectionAnnotation)
    # Field: video_classification Type: 11 (.google.cloud.automl.v1beta1.VideoClassificationAnnotation)
    # Field: video_object_tracking Type: 11 (.google.cloud.automl.v1beta1.VideoObjectTrackingAnnotation)
    # Field: text_extraction Type: 11 (.google.cloud.automl.v1beta1.TextExtractionAnnotation)
    # Field: text_sentiment Type: 11 (.google.cloud.automl.v1beta1.TextSentimentAnnotation)
    # Field: tables Type: 11 (.google.cloud.automl.v1beta1.TablesAnnotation)
    # Field: annotation_spec_id Type: 9 ()
    # Field: display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::AnnotationPayload - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/annotation_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::AnnotationPayload;

    my $msg = Google::Cloud::Automl::V1beta1::AnnotationPayload::AnnotationPayload->new({
        translation => $translation,
        classification => $classification,
        image_object_detection => $image_object_detection,
        video_classification => $video_classification,
    });

    # Read or update a field
    my $val = $msg->translation();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::AnnotationPayload::AnnotationPayload->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/annotation_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::AnnotationPayload::AnnotationPayload

Contains annotation information that is relevant to AutoML.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->translation() >> / C<< $msg->translation($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Translation::TranslationAnnotation>)

Annotation details for translation.

=item * C<< $msg->classification() >> / C<< $msg->classification($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Classification::ClassificationAnnotation>)

Annotation details for content or image classification.

=item * C<< $msg->image_object_detection() >> / C<< $msg->image_object_detection($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionAnnotation>)

Annotation details for image object detection.

=item * C<< $msg->video_classification() >> / C<< $msg->video_classification($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Classification::VideoClassificationAnnotation>)

Annotation details for video classification.
Returned for Video Classification predictions.

=item * C<< $msg->video_object_tracking() >> / C<< $msg->video_object_tracking($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingAnnotation>)

Annotation details for video object tracking.

=item * C<< $msg->text_extraction() >> / C<< $msg->text_extraction($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::TextExtraction::TextExtractionAnnotation>)

Annotation details for text extraction.

=item * C<< $msg->text_sentiment() >> / C<< $msg->text_sentiment($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentAnnotation>)

Annotation details for text sentiment.

=item * C<< $msg->tables() >> / C<< $msg->tables($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Tables::TablesAnnotation>)

Annotation details for Tables.

=item * C<< $msg->annotation_spec_id() >> / C<< $msg->annotation_spec_id($value) >>

Type: C<String>

Output only . The resource ID of the annotation spec that
this annotation pertains to. The annotation spec comes from either an
ancestor dataset, or the dataset that was used to train the model in use.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The value of
[display_name][google.cloud.automl.v1beta1.AnnotationSpec.display_name]
when the model was trained. Because this field returns a value at model
training time, for different models trained using the same dataset, the
returned value could be different as model owner could update the
`display_name` between any two model training.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::AnnotationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
