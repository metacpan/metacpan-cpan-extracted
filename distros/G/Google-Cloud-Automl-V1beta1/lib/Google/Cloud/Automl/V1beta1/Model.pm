package Google::Cloud::Automl::V1beta1::Model;

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
Cidnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvbW9kZWwucHJvdG8SG2dvb2dsZS5jbG91
ZC5hdXRvbWwudjFiZXRhMRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxonZ29vZ2xlL2Ns
b3VkL2F1dG9tbC92MWJldGExL2ltYWdlLnByb3RvGihnb29nbGUvY2xvdWQvYXV0b21sL3Yx
YmV0YTEvdGFibGVzLnByb3RvGiZnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdGV4dC5w
cm90bxotZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL3RyYW5zbGF0aW9uLnByb3RvGidn
b29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdmlkZW8ucHJvdG8aH2dvb2dsZS9wcm90b2J1
Zi90aW1lc3RhbXAucHJvdG8iqg0KBU1vZGVsEnUKGnRyYW5zbGF0aW9uX21vZGVsX21ldGFk
YXRhGA8gASgLMjUuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRyYW5zbGF0aW9uTW9k
ZWxNZXRhZGF0YUgAUhh0cmFuc2xhdGlvbk1vZGVsTWV0YWRhdGESjgEKI2ltYWdlX2NsYXNz
aWZpY2F0aW9uX21vZGVsX21ldGFkYXRhGA0gASgLMj0uZ29vZ2xlLmNsb3VkLmF1dG9tbC52
MWJldGExLkltYWdlQ2xhc3NpZmljYXRpb25Nb2RlbE1ldGFkYXRhSABSIGltYWdlQ2xhc3Np
ZmljYXRpb25Nb2RlbE1ldGFkYXRhEosBCiJ0ZXh0X2NsYXNzaWZpY2F0aW9uX21vZGVsX21l
dGFkYXRhGA4gASgLMjwuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRleHRDbGFzc2lm
aWNhdGlvbk1vZGVsTWV0YWRhdGFIAFIfdGV4dENsYXNzaWZpY2F0aW9uTW9kZWxNZXRhZGF0
YRKSAQolaW1hZ2Vfb2JqZWN0X2RldGVjdGlvbl9tb2RlbF9tZXRhZGF0YRgUIAEoCzI+Lmdv
b2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5JbWFnZU9iamVjdERldGVjdGlvbk1vZGVsTWV0
YWRhdGFIAFIhaW1hZ2VPYmplY3REZXRlY3Rpb25Nb2RlbE1ldGFkYXRhEo4BCiN2aWRlb19j
bGFzc2lmaWNhdGlvbl9tb2RlbF9tZXRhZGF0YRgXIAEoCzI9Lmdvb2dsZS5jbG91ZC5hdXRv
bWwudjFiZXRhMS5WaWRlb0NsYXNzaWZpY2F0aW9uTW9kZWxNZXRhZGF0YUgAUiB2aWRlb0Ns
YXNzaWZpY2F0aW9uTW9kZWxNZXRhZGF0YRKPAQokdmlkZW9fb2JqZWN0X3RyYWNraW5nX21v
ZGVsX21ldGFkYXRhGBUgASgLMj0uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlZpZGVv
T2JqZWN0VHJhY2tpbmdNb2RlbE1ldGFkYXRhSABSIHZpZGVvT2JqZWN0VHJhY2tpbmdNb2Rl
bE1ldGFkYXRhEn8KHnRleHRfZXh0cmFjdGlvbl9tb2RlbF9tZXRhZGF0YRgTIAEoCzI4Lmdv
b2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5UZXh0RXh0cmFjdGlvbk1vZGVsTWV0YWRhdGFI
AFIbdGV4dEV4dHJhY3Rpb25Nb2RlbE1ldGFkYXRhEmYKFXRhYmxlc19tb2RlbF9tZXRhZGF0
YRgYIAEoCzIwLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5UYWJsZXNNb2RlbE1ldGFk
YXRhSABSE3RhYmxlc01vZGVsTWV0YWRhdGESfAoddGV4dF9zZW50aW1lbnRfbW9kZWxfbWV0
YWRhdGEYFiABKAsyNy5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVGV4dFNlbnRpbWVu
dE1vZGVsTWV0YWRhdGFIAFIadGV4dFNlbnRpbWVudE1vZGVsTWV0YWRhdGESEgoEbmFtZRgB
IAEoCVIEbmFtZRIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEh0KCmRhdGFz
ZXRfaWQYAyABKAlSCWRhdGFzZXRJZBI7CgtjcmVhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSOwoLdXBkYXRlX3RpbWUYCyABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wUgp1cGRhdGVUaW1lEl0KEGRlcGxveW1lbnRfc3Rh
dGUYCCABKA4yMi5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuTW9kZWwuRGVwbG95bWVu
dFN0YXRlUg9kZXBsb3ltZW50U3RhdGUiUQoPRGVwbG95bWVudFN0YXRlEiAKHERFUExPWU1F
TlRfU1RBVEVfVU5TUEVDSUZJRUQQABIMCghERVBMT1lFRBABEg4KClVOREVQTE9ZRUQQAjpY
6kFVChthdXRvbWwuZ29vZ2xlYXBpcy5jb20vTW9kZWwSNnByb2plY3RzL3twcm9qZWN0fS9s
b2NhdGlvbnMve2xvY2F0aW9ufS9tb2RlbHMve21vZGVsfUIQCg5tb2RlbF9tZXRhZGF0YUKb
AQofY29tLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMVABWjdjbG91ZC5nb29nbGUuY29t
L2dvL2F1dG9tbC9hcGl2MWJldGExL2F1dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3Vk
XEF1dG9NbFxWMWJldGEx6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMWJldGExSoMaCgYS
BA4AagEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoC
AwASAxIAIwoJCgIDARIDEwAxCgkKAgMCEgMUADIKCQoCAwMSAxUAMAoJCgIDBBIDFgA3CgkK
AgMFEgMXADEKCQoCAwYSAxgAKQoICgEIEgMaAE4KCQoCCAsSAxoATgoICgEIEgMbACIKCQoC
CAoSAxsAIgoICgEIEgMcADgKCQoCCAESAxwAOAoICgEIEgMdADgKCQoCCCkSAx0AOAoICgEI
EgMeADcKCQoCCC0SAx4ANwpGCgIEABIEIQBqARo6IEFQSSBwcm90byByZXByZXNlbnRpbmcg
YSB0cmFpbmVkIG1hY2hpbmUgbGVhcm5pbmcgbW9kZWwuCgoKCgMEAAESAyEIDQoLCgMEAAcS
BCICJQQKDQoFBAAHnQgSBCICJQQKLgoEBAAEABIEKAIxAxogIERlcGxveW1lbnQgc3RhdGUg
b2YgdGhlIG1vZGVsLgoKDAoFBAAEAAESAygHFgpOCgYEAAQAAgASAyoEJRo/IFNob3VsZCBu
b3QgYmUgdXNlZCwgYW4gdW4tc2V0IGVudW0gaGFzIHRoaXMgdmFsdWUgYnkgZGVmYXVsdC4K
Cg4KBwQABAACAAESAyoEIAoOCgcEAAQAAgACEgMqIyQKIwoGBAAEAAIBEgMtBBEaFCBNb2Rl
bCBpcyBkZXBsb3llZC4KCg4KBwQABAACAQESAy0EDAoOCgcEAAQAAgECEgMtDxAKJwoGBAAE
AAICEgMwBBMaGCBNb2RlbCBpcyBub3QgZGVwbG95ZWQuCgoOCgcEAAQAAgIBEgMwBA4KDgoH
BAAEAAICAhIDMBESCpoBCgQEAAgAEgQ2AlEDGosBIFJlcXVpcmVkLgogVGhlIG1vZGVsIG1l
dGFkYXRhIHRoYXQgaXMgc3BlY2lmaWMgdG8gdGhlIHByb2JsZW0gdHlwZS4KIE11c3QgbWF0
Y2ggdGhlIG1ldGFkYXRhIHR5cGUgb2YgdGhlIGRhdGFzZXQgdXNlZCB0byB0cmFpbiB0aGUg
bW9kZWwuCgoMCgUEAAgAARIDNggWCi8KBAQAAgASAzgEPRoiIE1ldGFkYXRhIGZvciB0cmFu
c2xhdGlvbiBtb2RlbHMuCgoMCgUEAAIABhIDOAQcCgwKBQQAAgABEgM4HTcKDAoFBAACAAMS
Azg6PAo4CgQEAAIBEgM7BE4aKyBNZXRhZGF0YSBmb3IgaW1hZ2UgY2xhc3NpZmljYXRpb24g
bW9kZWxzLgoKDAoFBAACAQYSAzsEJAoMCgUEAAIBARIDOyVICgwKBQQAAgEDEgM7S00KNwoE
BAACAhIDPgRMGiogTWV0YWRhdGEgZm9yIHRleHQgY2xhc3NpZmljYXRpb24gbW9kZWxzLgoK
DAoFBAACAgYSAz4EIwoMCgUEAAICARIDPiRGCgwKBQQAAgIDEgM+SUsKOgoEBAACAxIDQQRR
Gi0gTWV0YWRhdGEgZm9yIGltYWdlIG9iamVjdCBkZXRlY3Rpb24gbW9kZWxzLgoKDAoFBAAC
AwYSA0EEJQoMCgUEAAIDARIDQSZLCgwKBQQAAgMDEgNBTlAKOAoEBAACBBIDRAROGisgTWV0
YWRhdGEgZm9yIHZpZGVvIGNsYXNzaWZpY2F0aW9uIG1vZGVscy4KCgwKBQQAAgQGEgNEBCQK
DAoFBAACBAESA0QlSAoMCgUEAAIEAxIDREtNCjkKBAQAAgUSA0cETxosIE1ldGFkYXRhIGZv
ciB2aWRlbyBvYmplY3QgdHJhY2tpbmcgbW9kZWxzLgoKDAoFBAACBQYSA0cEJAoMCgUEAAIF
ARIDRyVJCgwKBQQAAgUDEgNHTE4KMwoEBAACBhIDSgREGiYgTWV0YWRhdGEgZm9yIHRleHQg
ZXh0cmFjdGlvbiBtb2RlbHMuCgoMCgUEAAIGBhIDSgQfCgwKBQQAAgYBEgNKID4KDAoFBAAC
BgMSA0pBQwoqCgQEAAIHEgNNBDMaHSBNZXRhZGF0YSBmb3IgVGFibGVzIG1vZGVscy4KCgwK
BQQAAgcGEgNNBBcKDAoFBAACBwESA00YLQoMCgUEAAIHAxIDTTAyCjIKBAQAAggSA1AEQhol
IE1ldGFkYXRhIGZvciB0ZXh0IHNlbnRpbWVudCBtb2RlbHMuCgoMCgUEAAIIBhIDUAQeCgwK
BQQAAggBEgNQHzwKDAoFBAACCAMSA1A/QQqCAQoEBAACCRIDVQISGnUgT3V0cHV0IG9ubHku
IFJlc291cmNlIG5hbWUgb2YgdGhlIG1vZGVsLgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2pl
Y3RfaWR9L2xvY2F0aW9ucy97bG9jYXRpb25faWR9L21vZGVscy97bW9kZWxfaWR9YAoKDAoF
BAACCQUSA1UCCAoMCgUEAAIJARIDVQkNCgwKBQQAAgkDEgNVEBEK8gEKBAQAAgoSA1sCGhrk
ASBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIG1vZGVsIHRvIHNob3cgaW4gdGhlIGludGVy
ZmFjZS4gVGhlIG5hbWUgY2FuIGJlCiB1cCB0byAzMiBjaGFyYWN0ZXJzIGxvbmcgYW5kIGNh
biBjb25zaXN0IG9ubHkgb2YgQVNDSUkgTGF0aW4gbGV0dGVycyBBLVoKIGFuZCBhLXosIHVu
ZGVyc2NvcmVzCiAoXyksIGFuZCBBU0NJSSBkaWdpdHMgMC05LiBJdCBtdXN0IHN0YXJ0IHdp
dGggYSBsZXR0ZXIuCgoMCgUEAAIKBRIDWwIICgwKBQQAAgoBEgNbCRUKDAoFBAACCgMSA1sY
GQqWAQoEBAACCxIDXwIYGogBIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgSUQgb2YgdGhlIGRh
dGFzZXQgdXNlZCB0byBjcmVhdGUgdGhlIG1vZGVsLiBUaGUgZGF0YXNldCBtdXN0CiBjb21l
IGZyb20gdGhlIHNhbWUgYW5jZXN0b3IgcHJvamVjdCBhbmQgbG9jYXRpb24uCgoMCgUEAAIL
BRIDXwIICgwKBQQAAgsBEgNfCRMKDAoFBAACCwMSA18WFwpnCgQEAAIMEgNiAiwaWiBPdXRw
dXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhlIG1vZGVsIHRyYWluaW5nIGZpbmlzaGVkICBh
bmQgY2FuIGJlIHVzZWQgZm9yIHByZWRpY3Rpb24uCgoMCgUEAAIMBhIDYgIbCgwKBQQAAgwB
EgNiHCcKDAoFBAACDAMSA2IqKwpHCgQEAAINEgNlAi0aOiBPdXRwdXQgb25seS4gVGltZXN0
YW1wIHdoZW4gdGhpcyBtb2RlbCB3YXMgbGFzdCB1cGRhdGVkLgoKDAoFBAACDQYSA2UCGwoM
CgUEAAINARIDZRwnCgwKBQQAAg0DEgNlKiwKfgoEBAACDhIDaQInGnEgT3V0cHV0IG9ubHku
IERlcGxveW1lbnQgc3RhdGUgb2YgdGhlIG1vZGVsLiBBIG1vZGVsIGNhbiBvbmx5IHNlcnZl
CiBwcmVkaWN0aW9uIHJlcXVlc3RzIGFmdGVyIGl0IGdldHMgZGVwbG95ZWQuCgoMCgUEAAIO
BhIDaQIRCgwKBQQAAg4BEgNpEiIKDAoFBAACDgMSA2klJmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Model::Model ===
    # Fields for Model
    # Field: translation_model_metadata Type: 11 (.google.cloud.automl.v1beta1.TranslationModelMetadata)
    # Field: image_classification_model_metadata Type: 11 (.google.cloud.automl.v1beta1.ImageClassificationModelMetadata)
    # Field: text_classification_model_metadata Type: 11 (.google.cloud.automl.v1beta1.TextClassificationModelMetadata)
    # Field: image_object_detection_model_metadata Type: 11 (.google.cloud.automl.v1beta1.ImageObjectDetectionModelMetadata)
    # Field: video_classification_model_metadata Type: 11 (.google.cloud.automl.v1beta1.VideoClassificationModelMetadata)
    # Field: video_object_tracking_model_metadata Type: 11 (.google.cloud.automl.v1beta1.VideoObjectTrackingModelMetadata)
    # Field: text_extraction_model_metadata Type: 11 (.google.cloud.automl.v1beta1.TextExtractionModelMetadata)
    # Field: tables_model_metadata Type: 11 (.google.cloud.automl.v1beta1.TablesModelMetadata)
    # Field: text_sentiment_model_metadata Type: 11 (.google.cloud.automl.v1beta1.TextSentimentModelMetadata)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: dataset_id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: deployment_state Type: 14 (.google.cloud.automl.v1beta1.Model.DeploymentState)

# Enum: Model::DeploymentState
our $Model_DEPLOYMENT_STATE_UNSPECIFIED = 0;
our $Model_DEPLOYED = 1;
our $Model_UNDEPLOYED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Model - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/model.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Model;

    my $msg = Google::Cloud::Automl::V1beta1::Model::Model->new({
        translation_model_metadata => $translation_model_metadata,
        image_classification_model_metadata => $image_classification_model_metadata,
        text_classification_model_metadata => $text_classification_model_metadata,
        image_object_detection_model_metadata => $image_object_detection_model_metadata,
    });

    # Read or update a field
    my $val = $msg->translation_model_metadata();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Model::Model->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/model.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Model::Model

API proto representing a trained machine learning model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->translation_model_metadata() >> / C<< $msg->translation_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Translation::TranslationModelMetadata>)

Metadata for translation models.

=item * C<< $msg->image_classification_model_metadata() >> / C<< $msg->image_classification_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Image::ImageClassificationModelMetadata>)

Metadata for image classification models.

=item * C<< $msg->text_classification_model_metadata() >> / C<< $msg->text_classification_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Text::TextClassificationModelMetadata>)

Metadata for text classification models.

=item * C<< $msg->image_object_detection_model_metadata() >> / C<< $msg->image_object_detection_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Image::ImageObjectDetectionModelMetadata>)

Metadata for image object detection models.

=item * C<< $msg->video_classification_model_metadata() >> / C<< $msg->video_classification_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Video::VideoClassificationModelMetadata>)

Metadata for video classification models.

=item * C<< $msg->video_object_tracking_model_metadata() >> / C<< $msg->video_object_tracking_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Video::VideoObjectTrackingModelMetadata>)

Metadata for video object tracking models.

=item * C<< $msg->text_extraction_model_metadata() >> / C<< $msg->text_extraction_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Text::TextExtractionModelMetadata>)

Metadata for text extraction models.

=item * C<< $msg->tables_model_metadata() >> / C<< $msg->tables_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Tables::TablesModelMetadata>)

Metadata for Tables models.

=item * C<< $msg->text_sentiment_model_metadata() >> / C<< $msg->text_sentiment_model_metadata($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Text::TextSentimentModelMetadata>)

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

Type: C<Enum> (L<Google::Cloud::Automl::V1beta1::Model::DeploymentState>)

Output only. Deployment state of the model. A model can only serve
prediction requests after it gets deployed.

=back

=head3 Enum: Model::DeploymentState

=over 4

=item * C<DEPLOYMENT_STATE_UNSPECIFIED> => C<0>

=item * C<DEPLOYED> => C<1>

=item * C<UNDEPLOYED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Model::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
