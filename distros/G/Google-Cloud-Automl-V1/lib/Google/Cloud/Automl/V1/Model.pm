package Google::Cloud::Automl::V1::Model;

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
CiJnb29nbGUvY2xvdWQvYXV0b21sL3YxL21vZGVsLnByb3RvEhZnb29nbGUuY2xvdWQuYXV0
b21sLnYxGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiJnb29nbGUvY2xvdWQvYXV0b21s
L3YxL2ltYWdlLnByb3RvGiFnb29nbGUvY2xvdWQvYXV0b21sL3YxL3RleHQucHJvdG8aKGdv
b2dsZS9jbG91ZC9hdXRvbWwvdjEvdHJhbnNsYXRpb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8ijgsKBU1vZGVsEnAKGnRyYW5zbGF0aW9uX21vZGVsX21ldGFk
YXRhGA8gASgLMjAuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5UcmFuc2xhdGlvbk1vZGVsTWV0
YWRhdGFIAFIYdHJhbnNsYXRpb25Nb2RlbE1ldGFkYXRhEokBCiNpbWFnZV9jbGFzc2lmaWNh
dGlvbl9tb2RlbF9tZXRhZGF0YRgNIAEoCzI4Lmdvb2dsZS5jbG91ZC5hdXRvbWwudjEuSW1h
Z2VDbGFzc2lmaWNhdGlvbk1vZGVsTWV0YWRhdGFIAFIgaW1hZ2VDbGFzc2lmaWNhdGlvbk1v
ZGVsTWV0YWRhdGEShgEKInRleHRfY2xhc3NpZmljYXRpb25fbW9kZWxfbWV0YWRhdGEYDiAB
KAsyNy5nb29nbGUuY2xvdWQuYXV0b21sLnYxLlRleHRDbGFzc2lmaWNhdGlvbk1vZGVsTWV0
YWRhdGFIAFIfdGV4dENsYXNzaWZpY2F0aW9uTW9kZWxNZXRhZGF0YRKNAQolaW1hZ2Vfb2Jq
ZWN0X2RldGVjdGlvbl9tb2RlbF9tZXRhZGF0YRgUIAEoCzI5Lmdvb2dsZS5jbG91ZC5hdXRv
bWwudjEuSW1hZ2VPYmplY3REZXRlY3Rpb25Nb2RlbE1ldGFkYXRhSABSIWltYWdlT2JqZWN0
RGV0ZWN0aW9uTW9kZWxNZXRhZGF0YRJ6Ch50ZXh0X2V4dHJhY3Rpb25fbW9kZWxfbWV0YWRh
dGEYEyABKAsyMy5nb29nbGUuY2xvdWQuYXV0b21sLnYxLlRleHRFeHRyYWN0aW9uTW9kZWxN
ZXRhZGF0YUgAUht0ZXh0RXh0cmFjdGlvbk1vZGVsTWV0YWRhdGESdwoddGV4dF9zZW50aW1l
bnRfbW9kZWxfbWV0YWRhdGEYFiABKAsyMi5nb29nbGUuY2xvdWQuYXV0b21sLnYxLlRleHRT
ZW50aW1lbnRNb2RlbE1ldGFkYXRhSABSGnRleHRTZW50aW1lbnRNb2RlbE1ldGFkYXRhEhIK
BG5hbWUYASABKAlSBG5hbWUSIQoMZGlzcGxheV9uYW1lGAIgASgJUgtkaXNwbGF5TmFtZRId
CgpkYXRhc2V0X2lkGAMgASgJUglkYXRhc2V0SWQSOwoLY3JlYXRlX3RpbWUYByABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpjcmVhdGVUaW1lEjsKC3VwZGF0ZV90aW1lGAsg
ASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKdXBkYXRlVGltZRJYChBkZXBsb3lt
ZW50X3N0YXRlGAggASgOMi0uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5Nb2RlbC5EZXBsb3lt
ZW50U3RhdGVSD2RlcGxveW1lbnRTdGF0ZRISCgRldGFnGAogASgJUgRldGFnEkEKBmxhYmVs
cxgiIAMoCzIpLmdvb2dsZS5jbG91ZC5hdXRvbWwudjEuTW9kZWwuTGFiZWxzRW50cnlSBmxh
YmVscxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIF
dmFsdWU6AjgBIlEKD0RlcGxveW1lbnRTdGF0ZRIgChxERVBMT1lNRU5UX1NUQVRFX1VOU1BF
Q0lGSUVEEAASDAoIREVQTE9ZRUQQARIOCgpVTkRFUExPWUVEEAI6WOpBVQobYXV0b21sLmdv
b2dsZWFwaXMuY29tL01vZGVsEjZwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2Nh
dGlvbn0vbW9kZWxzL3ttb2RlbH1CEAoObW9kZWxfbWV0YWRhdGFCoAEKGmNvbS5nb29nbGUu
Y2xvdWQuYXV0b21sLnYxUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vYXV0b21sL2FwaXYxL2F1
dG9tbHBiO2F1dG9tbHBiqgIWR29vZ2xlLkNsb3VkLkF1dG9NTC5WMcoCFkdvb2dsZVxDbG91
ZFxBdXRvTWxcVjHqAhlHb29nbGU6OkNsb3VkOjpBdXRvTUw6OlYxSuEcCgYSBA4AbgEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAIwoJ
CgIDARIDEwAsCgkKAgMCEgMUACsKCQoCAwMSAxUAMgoJCgIDBBIDFgApCggKAQgSAxgAMwoJ
CgIIJRIDGAAzCggKAQgSAxkASQoJCgIICxIDGQBJCggKAQgSAxoAIgoJCgIIChIDGgAiCggK
AQgSAxsAMwoJCgIIARIDGwAzCggKAQgSAxwAMwoJCgIIKRIDHAAzCggKAQgSAx0AMgoJCgII
LRIDHQAyCkYKAgQAEgQgAG4BGjogQVBJIHByb3RvIHJlcHJlc2VudGluZyBhIHRyYWluZWQg
bWFjaGluZSBsZWFybmluZyBtb2RlbC4KCgoKAwQAARIDIAgNCgsKAwQABxIEIQIkBAoNCgUE
AAedCBIEIQIkBAouCgQEAAQAEgQnAjADGiAgRGVwbG95bWVudCBzdGF0ZSBvZiB0aGUgbW9k
ZWwuCgoMCgUEAAQAARIDJwcWCk4KBgQABAACABIDKQQlGj8gU2hvdWxkIG5vdCBiZSB1c2Vk
LCBhbiB1bi1zZXQgZW51bSBoYXMgdGhpcyB2YWx1ZSBieSBkZWZhdWx0LgoKDgoHBAAEAAIA
ARIDKQQgCg4KBwQABAACAAISAykjJAojCgYEAAQAAgESAywEERoUIE1vZGVsIGlzIGRlcGxv
eWVkLgoKDgoHBAAEAAIBARIDLAQMCg4KBwQABAACAQISAywPEAonCgYEAAQAAgISAy8EExoY
IE1vZGVsIGlzIG5vdCBkZXBsb3llZC4KCg4KBwQABAACAgESAy8EDgoOCgcEAAQAAgICEgMv
ERIKmgEKBAQACAASBDUCRwMaiwEgUmVxdWlyZWQuCiBUaGUgbW9kZWwgbWV0YWRhdGEgdGhh
dCBpcyBzcGVjaWZpYyB0byB0aGUgcHJvYmxlbSB0eXBlLgogTXVzdCBtYXRjaCB0aGUgbWV0
YWRhdGEgdHlwZSBvZiB0aGUgZGF0YXNldCB1c2VkIHRvIHRyYWluIHRoZSBtb2RlbC4KCgwK
BQQACAABEgM1CBYKLwoEBAACABIDNwQ9GiIgTWV0YWRhdGEgZm9yIHRyYW5zbGF0aW9uIG1v
ZGVscy4KCgwKBQQAAgAGEgM3BBwKDAoFBAACAAESAzcdNwoMCgUEAAIAAxIDNzo8CjgKBAQA
AgESAzoEThorIE1ldGFkYXRhIGZvciBpbWFnZSBjbGFzc2lmaWNhdGlvbiBtb2RlbHMuCgoM
CgUEAAIBBhIDOgQkCgwKBQQAAgEBEgM6JUgKDAoFBAACAQMSAzpLTQo3CgQEAAICEgM9BEwa
KiBNZXRhZGF0YSBmb3IgdGV4dCBjbGFzc2lmaWNhdGlvbiBtb2RlbHMuCgoMCgUEAAICBhID
PQQjCgwKBQQAAgIBEgM9JEYKDAoFBAACAgMSAz1JSwo6CgQEAAIDEgNABFEaLSBNZXRhZGF0
YSBmb3IgaW1hZ2Ugb2JqZWN0IGRldGVjdGlvbiBtb2RlbHMuCgoMCgUEAAIDBhIDQAQlCgwK
BQQAAgMBEgNAJksKDAoFBAACAwMSA0BOUAozCgQEAAIEEgNDBEQaJiBNZXRhZGF0YSBmb3Ig
dGV4dCBleHRyYWN0aW9uIG1vZGVscy4KCgwKBQQAAgQGEgNDBB8KDAoFBAACBAESA0MgPgoM
CgUEAAIEAxIDQ0FDCjIKBAQAAgUSA0YEQholIE1ldGFkYXRhIGZvciB0ZXh0IHNlbnRpbWVu
dCBtb2RlbHMuCgoMCgUEAAIFBhIDRgQeCgwKBQQAAgUBEgNGHzwKDAoFBAACBQMSA0Y/QQqC
AQoEBAACBhIDSwISGnUgT3V0cHV0IG9ubHkuIFJlc291cmNlIG5hbWUgb2YgdGhlIG1vZGVs
LgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2plY3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb25f
aWR9L21vZGVscy97bW9kZWxfaWR9YAoKDAoFBAACBgUSA0sCCAoMCgUEAAIGARIDSwkNCgwK
BQQAAgYDEgNLEBEK8gEKBAQAAgcSA1ECGhrkASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhl
IG1vZGVsIHRvIHNob3cgaW4gdGhlIGludGVyZmFjZS4gVGhlIG5hbWUgY2FuIGJlCiB1cCB0
byAzMiBjaGFyYWN0ZXJzIGxvbmcgYW5kIGNhbiBjb25zaXN0IG9ubHkgb2YgQVNDSUkgTGF0
aW4gbGV0dGVycyBBLVoKIGFuZCBhLXosIHVuZGVyc2NvcmVzCiAoXyksIGFuZCBBU0NJSSBk
aWdpdHMgMC05LiBJdCBtdXN0IHN0YXJ0IHdpdGggYSBsZXR0ZXIuCgoMCgUEAAIHBRIDUQII
CgwKBQQAAgcBEgNRCRUKDAoFBAACBwMSA1EYGQqWAQoEBAACCBIDVQIYGogBIFJlcXVpcmVk
LiBUaGUgcmVzb3VyY2UgSUQgb2YgdGhlIGRhdGFzZXQgdXNlZCB0byBjcmVhdGUgdGhlIG1v
ZGVsLiBUaGUgZGF0YXNldCBtdXN0CiBjb21lIGZyb20gdGhlIHNhbWUgYW5jZXN0b3IgcHJv
amVjdCBhbmQgbG9jYXRpb24uCgoMCgUEAAIIBRIDVQIICgwKBQQAAggBEgNVCRMKDAoFBAAC
CAMSA1UWFwpnCgQEAAIJEgNYAiwaWiBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhl
IG1vZGVsIHRyYWluaW5nIGZpbmlzaGVkICBhbmQgY2FuIGJlIHVzZWQgZm9yIHByZWRpY3Rp
b24uCgoMCgUEAAIJBhIDWAIbCgwKBQQAAgkBEgNYHCcKDAoFBAACCQMSA1gqKwpHCgQEAAIK
EgNbAi0aOiBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhpcyBtb2RlbCB3YXMgbGFz
dCB1cGRhdGVkLgoKDAoFBAACCgYSA1sCGwoMCgUEAAIKARIDWxwnCgwKBQQAAgoDEgNbKiwK
fgoEBAACCxIDXwInGnEgT3V0cHV0IG9ubHkuIERlcGxveW1lbnQgc3RhdGUgb2YgdGhlIG1v
ZGVsLiBBIG1vZGVsIGNhbiBvbmx5IHNlcnZlCiBwcmVkaWN0aW9uIHJlcXVlc3RzIGFmdGVy
IGl0IGdldHMgZGVwbG95ZWQuCgoMCgUEAAILBhIDXwIRCgwKBQQAAgsBEgNfEiIKDAoFBAAC
CwMSA18lJgp3CgQEAAIMEgNjAhMaaiBVc2VkIHRvIHBlcmZvcm0gYSBjb25zaXN0ZW50IHJl
YWQtbW9kaWZ5LXdyaXRlIHVwZGF0ZXMuIElmIG5vdCBzZXQsIGEgYmxpbmQKICJvdmVyd3Jp
dGUiIHVwZGF0ZSBoYXBwZW5zLgoKDAoFBAACDAUSA2MCCAoMCgUEAAIMARIDYwkNCgwKBQQA
AgwDEgNjEBIKrgMKBAQAAg0SA20CIhqgAyBPcHRpb25hbC4gVGhlIGxhYmVscyB3aXRoIHVz
ZXItZGVmaW5lZCBtZXRhZGF0YSB0byBvcmdhbml6ZSB5b3VyIG1vZGVsLgoKIExhYmVsIGtl
eXMgYW5kIHZhbHVlcyBjYW4gYmUgbm8gbG9uZ2VyIHRoYW4gNjQgY2hhcmFjdGVycwogKFVu
aWNvZGUgY29kZXBvaW50cyksIGNhbiBvbmx5IGNvbnRhaW4gbG93ZXJjYXNlIGxldHRlcnMs
IG51bWVyaWMKIGNoYXJhY3RlcnMsIHVuZGVyc2NvcmVzIGFuZCBkYXNoZXMuIEludGVybmF0
aW9uYWwgY2hhcmFjdGVycyBhcmUgYWxsb3dlZC4KIExhYmVsIHZhbHVlcyBhcmUgb3B0aW9u
YWwuIExhYmVsIGtleXMgbXVzdCBzdGFydCB3aXRoIGEgbGV0dGVyLgoKIFNlZSBodHRwczov
L2dvby5nbC94bVFueGYgZm9yIG1vcmUgaW5mb3JtYXRpb24gb24gYW5kIGV4YW1wbGVzIG9m
IGxhYmVscy4KCgwKBQQAAg0GEgNtAhUKDAoFBAACDQESA20WHAoMCgUEAAINAxIDbR8hYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::Model::Model ===
    # Fields for Model
    # Field: translation_model_metadata Type: 11 (.google.cloud.automl.v1.TranslationModelMetadata)
    # Field: image_classification_model_metadata Type: 11 (.google.cloud.automl.v1.ImageClassificationModelMetadata)
    # Field: text_classification_model_metadata Type: 11 (.google.cloud.automl.v1.TextClassificationModelMetadata)
    # Field: image_object_detection_model_metadata Type: 11 (.google.cloud.automl.v1.ImageObjectDetectionModelMetadata)
    # Field: text_extraction_model_metadata Type: 11 (.google.cloud.automl.v1.TextExtractionModelMetadata)
    # Field: text_sentiment_model_metadata Type: 11 (.google.cloud.automl.v1.TextSentimentModelMetadata)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: deployment_state Type: 14 (.google.cloud.automl.v1.Model.DeploymentState)
    # Field: etag Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.automl.v1.Model.LabelsEntry)

# Enum: Model::DeploymentState
our $Model_DEPLOYMENT_STATE_UNSPECIFIED = 0;
our $Model_DEPLOYED = 1;
our $Model_UNDEPLOYED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::Model - Compiled Protocol Buffers messages for google/cloud/automl/v1/model.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::Model;

    my $msg = Google::Cloud::Automl::V1::Model::Model->new({
        translation_model_metadata => $translation_model_metadata,
        image_classification_model_metadata => $image_classification_model_metadata,
        text_classification_model_metadata => $text_classification_model_metadata,
        image_object_detection_model_metadata => $image_object_detection_model_metadata,
    });

    # Read or update a field
    my $val = $msg->translation_model_metadata();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::Model::Model->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::Model::Model

API proto representing a trained machine learning model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->translation_model_metadata() >> / C<< $msg->translation_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Translation::TranslationModelMetadata>)

Metadata for translation models.

=item * C<< $msg->image_classification_model_metadata() >> / C<< $msg->image_classification_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Image::ImageClassificationModelMetadata>)

Metadata for image classification models.

=item * C<< $msg->text_classification_model_metadata() >> / C<< $msg->text_classification_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Text::TextClassificationModelMetadata>)

Metadata for text classification models.

=item * C<< $msg->image_object_detection_model_metadata() >> / C<< $msg->image_object_detection_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Image::ImageObjectDetectionModelMetadata>)

Metadata for image object detection models.

=item * C<< $msg->text_extraction_model_metadata() >> / C<< $msg->text_extraction_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Text::TextExtractionModelMetadata>)

Metadata for text extraction models.

=item * C<< $msg->text_sentiment_model_metadata() >> / C<< $msg->text_sentiment_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Text::TextSentimentModelMetadata>)

Metadata for text sentiment models.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the model.
Format: `projects/{project_id}/locations/{location_id}/models/{model_id}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The name of the model to show in the interface. The name can be
up to 32 characters long and can consist only of ASCII Latin letters A-Z
and a-z, underscores
(_), and ASCII digits 0-9. It must start with a letter.

=item * C<< $msg->dataset_id() >> / C<< $msg->dataset_id($value) >>

Type: C<String>

Required. The resource ID of the dataset used to create the model. The dataset must
come from the same ancestor project and location.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the model training finished  and can be used for prediction.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when this model was last updated.

=item * C<< $msg->deployment_state() >> / C<< $msg->deployment_state($value) >>

Type: C<Enum> (L<Google::Cloud::Automl::V1::Model::DeploymentState>)

Output only. Deployment state of the model. A model can only serve
prediction requests after it gets deployed.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

Used to perform a consistent read-modify-write updates. If not set, a blind
"overwrite" update happens.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Model::Model::LabelsEntry>)

Optional. The labels with user-defined metadata to organize your model.

Label keys and values can be no longer than 64 characters
(Unicode codepoints), can only contain lowercase letters, numeric
characters, underscores and dashes. International characters are allowed.
Label values are optional. Label keys must start with a letter.

See https://goo.gl/xmQnxf for more information on and examples of labels.

=back

=head3 Enum: Model::DeploymentState

=over 4

=item * C<DEPLOYMENT_STATE_UNSPECIFIED> => C<0>

=item * C<DEPLOYED> => C<1>

=item * C<UNDEPLOYED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::Model::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
