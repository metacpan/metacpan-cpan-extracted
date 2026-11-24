package Google::Cloud::Automl::V1::AnnotationPayload;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1::Classification };
    eval { require Google::Cloud::Automl::V1::Detection };
    eval { require Google::Cloud::Automl::V1::TextExtraction };
    eval { require Google::Cloud::Automl::V1::TextSentiment };
    eval { require Google::Cloud::Automl::V1::Translation };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvYXV0b21sL3YxL2Fubm90YXRpb25fcGF5bG9hZC5wcm90bxIWZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MRorZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MS9jbGFzc2lmaWNh
dGlvbi5wcm90bxomZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MS9kZXRlY3Rpb24ucHJvdG8aLGdv
b2dsZS9jbG91ZC9hdXRvbWwvdjEvdGV4dF9leHRyYWN0aW9uLnByb3RvGitnb29nbGUvY2xv
dWQvYXV0b21sL3YxL3RleHRfc2VudGltZW50LnByb3RvGihnb29nbGUvY2xvdWQvYXV0b21s
L3YxL3RyYW5zbGF0aW9uLnByb3RvIsQEChFBbm5vdGF0aW9uUGF5bG9hZBJRCgt0cmFuc2xh
dGlvbhgCIAEoCzItLmdvb2dsZS5jbG91ZC5hdXRvbWwudjEuVHJhbnNsYXRpb25Bbm5vdGF0
aW9uSABSC3RyYW5zbGF0aW9uEloKDmNsYXNzaWZpY2F0aW9uGAMgASgLMjAuZ29vZ2xlLmNs
b3VkLmF1dG9tbC52MS5DbGFzc2lmaWNhdGlvbkFubm90YXRpb25IAFIOY2xhc3NpZmljYXRp
b24SbgoWaW1hZ2Vfb2JqZWN0X2RldGVjdGlvbhgEIAEoCzI2Lmdvb2dsZS5jbG91ZC5hdXRv
bWwudjEuSW1hZ2VPYmplY3REZXRlY3Rpb25Bbm5vdGF0aW9uSABSFGltYWdlT2JqZWN0RGV0
ZWN0aW9uElsKD3RleHRfZXh0cmFjdGlvbhgGIAEoCzIwLmdvb2dsZS5jbG91ZC5hdXRvbWwu
djEuVGV4dEV4dHJhY3Rpb25Bbm5vdGF0aW9uSABSDnRleHRFeHRyYWN0aW9uElgKDnRleHRf
c2VudGltZW50GAcgASgLMi8uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5UZXh0U2VudGltZW50
QW5ub3RhdGlvbkgAUg10ZXh0U2VudGltZW50EiwKEmFubm90YXRpb25fc3BlY19pZBgBIAEo
CVIQYW5ub3RhdGlvblNwZWNJZBIhCgxkaXNwbGF5X25hbWUYBSABKAlSC2Rpc3BsYXlOYW1l
QggKBmRldGFpbEKgAQoaY29tLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFQAVoyY2xvdWQuZ29v
Z2xlLmNvbS9nby9hdXRvbWwvYXBpdjEvYXV0b21scGI7YXV0b21scGKqAhZHb29nbGUuQ2xv
dWQuQXV0b01MLlYxygIWR29vZ2xlXENsb3VkXEF1dG9NbFxWMeoCGUdvb2dsZTo6Q2xvdWQ6
OkF1dG9NTDo6VjFK+RAKBhIEDgBAAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAHwoJCgIDABIDEgA1CgkKAgMBEgMTADAKCQoCAwISAxQANgoJCgIDAxID
FQA1CgkKAgMEEgMWADIKCAoBCBIDGAAzCgkKAgglEgMYADMKCAoBCBIDGQBJCgkKAggLEgMZ
AEkKCAoBCBIDGgAiCgkKAggKEgMaACIKCAoBCBIDGwAzCgkKAggBEgMbADMKCAoBCBIDHAAz
CgkKAggpEgMcADMKCAoBCBIDHQAyCgkKAggtEgMdADIKSQoCBAASBCAAQAEaPSBDb250YWlu
cyBhbm5vdGF0aW9uIGluZm9ybWF0aW9uIHRoYXQgaXMgcmVsZXZhbnQgdG8gQXV0b01MLgoK
CgoDBAABEgMgCBkKaQoEBAAIABIEIwIyAxpbIE91dHB1dCBvbmx5IC4gQWRkaXRpb25hbCBp
bmZvcm1hdGlvbiBhYm91dCB0aGUgYW5ub3RhdGlvbgogc3BlY2lmaWMgdG8gdGhlIEF1dG9N
TCBkb21haW4uCgoMCgUEAAgAARIDIwgOCjIKBAQAAgASAyUEKholIEFubm90YXRpb24gZGV0
YWlscyBmb3IgdHJhbnNsYXRpb24uCgoMCgUEAAIABhIDJQQZCgwKBQQAAgABEgMlGiUKDAoF
BAACAAMSAyUoKQpGCgQEAAIBEgMoBDAaOSBBbm5vdGF0aW9uIGRldGFpbHMgZm9yIGNvbnRl
bnQgb3IgaW1hZ2UgY2xhc3NpZmljYXRpb24uCgoMCgUEAAIBBhIDKAQcCgwKBQQAAgEBEgMo
HSsKDAoFBAACAQMSAyguLwo9CgQEAAICEgMrBD4aMCBBbm5vdGF0aW9uIGRldGFpbHMgZm9y
IGltYWdlIG9iamVjdCBkZXRlY3Rpb24uCgoMCgUEAAICBhIDKwQiCgwKBQQAAgIBEgMrIzkK
DAoFBAACAgMSAys8PQo2CgQEAAIDEgMuBDEaKSBBbm5vdGF0aW9uIGRldGFpbHMgZm9yIHRl
eHQgZXh0cmFjdGlvbi4KCgwKBQQAAgMGEgMuBBwKDAoFBAACAwESAy4dLAoMCgUEAAIDAxID
Li8wCjUKBAQAAgQSAzEELxooIEFubm90YXRpb24gZGV0YWlscyBmb3IgdGV4dCBzZW50aW1l
bnQuCgoMCgUEAAIEBhIDMQQbCgwKBQQAAgQBEgMxHCoKDAoFBAACBAMSAzEtLgrbAQoEBAAC
BRIDNwIgGs0BIE91dHB1dCBvbmx5IC4gVGhlIHJlc291cmNlIElEIG9mIHRoZSBhbm5vdGF0
aW9uIHNwZWMgdGhhdAogdGhpcyBhbm5vdGF0aW9uIHBlcnRhaW5zIHRvLiBUaGUgYW5ub3Rh
dGlvbiBzcGVjIGNvbWVzIGZyb20gZWl0aGVyIGFuCiBhbmNlc3RvciBkYXRhc2V0LCBvciB0
aGUgZGF0YXNldCB0aGF0IHdhcyB1c2VkIHRvIHRyYWluIHRoZSBtb2RlbCBpbiB1c2UuCgoM
CgUEAAIFBRIDNwIICgwKBQQAAgUBEgM3CRsKDAoFBAACBQMSAzceHwryAgoEBAACBhIDPwIa
GuQCIE91dHB1dCBvbmx5LiBUaGUgdmFsdWUgb2YKIFtkaXNwbGF5X25hbWVdW2dvb2dsZS5j
bG91ZC5hdXRvbWwudjEuQW5ub3RhdGlvblNwZWMuZGlzcGxheV9uYW1lXQogd2hlbiB0aGUg
bW9kZWwgd2FzIHRyYWluZWQuIEJlY2F1c2UgdGhpcyBmaWVsZCByZXR1cm5zIGEgdmFsdWUg
YXQgbW9kZWwKIHRyYWluaW5nIHRpbWUsIGZvciBkaWZmZXJlbnQgbW9kZWxzIHRyYWluZWQg
dXNpbmcgdGhlIHNhbWUgZGF0YXNldCwgdGhlCiByZXR1cm5lZCB2YWx1ZSBjb3VsZCBiZSBk
aWZmZXJlbnQgYXMgbW9kZWwgb3duZXIgY291bGQgdXBkYXRlIHRoZQogYGRpc3BsYXlfbmFt
ZWAgYmV0d2VlbiBhbnkgdHdvIG1vZGVsIHRyYWluaW5nLgoKDAoFBAACBgUSAz8CCAoMCgUE
AAIGARIDPwkVCgwKBQQAAgYDEgM/GBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::AnnotationPayload::AnnotationPayload ===
    # Fields for AnnotationPayload
    # Field: translation Type: 11 (.google.cloud.automl.v1.TranslationAnnotation)
    # Field: classification Type: 11 (.google.cloud.automl.v1.ClassificationAnnotation)
    # Field: image_object_detection Type: 11 (.google.cloud.automl.v1.ImageObjectDetectionAnnotation)
    # Field: text_extraction Type: 11 (.google.cloud.automl.v1.TextExtractionAnnotation)
    # Field: text_sentiment Type: 11 (.google.cloud.automl.v1.TextSentimentAnnotation)
    # Field: annotation_spec_id Type: 9 ()
    # Field: display_name Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::AnnotationPayload - Compiled Protocol Buffers messages for google/cloud/automl/v1/annotation_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::AnnotationPayload;

    my $msg = Google::Cloud::Automl::V1::AnnotationPayload::AnnotationPayload->new({
        translation => $translation,
        classification => $classification,
        image_object_detection => $image_object_detection,
        text_extraction => $text_extraction,
    });

    # Read or update a field
    my $val = $msg->translation();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::AnnotationPayload::AnnotationPayload->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/annotation_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::AnnotationPayload::AnnotationPayload

Contains annotation information that is relevant to AutoML.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->translation() >> / C<< $msg->translation($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Translation::TranslationAnnotation>)

Annotation details for translation.

=item * C<< $msg->classification() >> / C<< $msg->classification($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Classification::ClassificationAnnotation>)

Annotation details for content or image classification.

=item * C<< $msg->image_object_detection() >> / C<< $msg->image_object_detection($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Detection::ImageObjectDetectionAnnotation>)

Annotation details for image object detection.

=item * C<< $msg->text_extraction() >> / C<< $msg->text_extraction($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::TextExtraction::TextExtractionAnnotation>)

Annotation details for text extraction.

=item * C<< $msg->text_sentiment() >> / C<< $msg->text_sentiment($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::TextSentiment::TextSentimentAnnotation>)

Annotation details for text sentiment.

=item * C<< $msg->annotation_spec_id() >> / C<< $msg->annotation_spec_id($value) >>

Type: C<String>

Output only . The resource ID of the annotation spec that
this annotation pertains to. The annotation spec comes from either an
ancestor dataset, or the dataset that was used to train the model in use.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The value of
[display_name][google.cloud.automl.v1.AnnotationSpec.display_name]
when the model was trained. Because this field returns a value at model
training time, for different models trained using the same dataset, the
returned value could be different as model owner could update the
`display_name` between any two model training.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::AnnotationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
