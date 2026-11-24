package Google::Cloud::Automl::V1::ModelEvaluation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Automl::V1::Classification };
    eval { require Google::Cloud::Automl::V1::Detection };
    eval { require Google::Cloud::Automl::V1::TextExtraction };
    eval { require Google::Cloud::Automl::V1::TextSentiment };
    eval { require Google::Cloud::Automl::V1::Translation };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvYXV0b21sL3YxL21vZGVsX2V2YWx1YXRpb24ucHJvdG8SFmdvb2ds
ZS5jbG91ZC5hdXRvbWwudjEaGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aK2dvb2dsZS9j
bG91ZC9hdXRvbWwvdjEvY2xhc3NpZmljYXRpb24ucHJvdG8aJmdvb2dsZS9jbG91ZC9hdXRv
bWwvdjEvZGV0ZWN0aW9uLnByb3RvGixnb29nbGUvY2xvdWQvYXV0b21sL3YxL3RleHRfZXh0
cmFjdGlvbi5wcm90bxorZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MS90ZXh0X3NlbnRpbWVudC5w
cm90bxooZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MS90cmFuc2xhdGlvbi5wcm90bxofZ29vZ2xl
L3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byKxCAoPTW9kZWxFdmFsdWF0aW9uEoUBCiFjbGFz
c2lmaWNhdGlvbl9ldmFsdWF0aW9uX21ldHJpY3MYCCABKAsyNy5nb29nbGUuY2xvdWQuYXV0
b21sLnYxLkNsYXNzaWZpY2F0aW9uRXZhbHVhdGlvbk1ldHJpY3NIAFIfY2xhc3NpZmljYXRp
b25FdmFsdWF0aW9uTWV0cmljcxJ8Ch50cmFuc2xhdGlvbl9ldmFsdWF0aW9uX21ldHJpY3MY
CSABKAsyNC5nb29nbGUuY2xvdWQuYXV0b21sLnYxLlRyYW5zbGF0aW9uRXZhbHVhdGlvbk1l
dHJpY3NIAFIcdHJhbnNsYXRpb25FdmFsdWF0aW9uTWV0cmljcxKZAQopaW1hZ2Vfb2JqZWN0
X2RldGVjdGlvbl9ldmFsdWF0aW9uX21ldHJpY3MYDCABKAsyPS5nb29nbGUuY2xvdWQuYXV0
b21sLnYxLkltYWdlT2JqZWN0RGV0ZWN0aW9uRXZhbHVhdGlvbk1ldHJpY3NIAFIlaW1hZ2VP
YmplY3REZXRlY3Rpb25FdmFsdWF0aW9uTWV0cmljcxKDAQohdGV4dF9zZW50aW1lbnRfZXZh
bHVhdGlvbl9tZXRyaWNzGAsgASgLMjYuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5UZXh0U2Vu
dGltZW50RXZhbHVhdGlvbk1ldHJpY3NIAFIedGV4dFNlbnRpbWVudEV2YWx1YXRpb25NZXRy
aWNzEoYBCiJ0ZXh0X2V4dHJhY3Rpb25fZXZhbHVhdGlvbl9tZXRyaWNzGA0gASgLMjcuZ29v
Z2xlLmNsb3VkLmF1dG9tbC52MS5UZXh0RXh0cmFjdGlvbkV2YWx1YXRpb25NZXRyaWNzSABS
H3RleHRFeHRyYWN0aW9uRXZhbHVhdGlvbk1ldHJpY3MSEgoEbmFtZRgBIAEoCVIEbmFtZRIs
ChJhbm5vdGF0aW9uX3NwZWNfaWQYAiABKAlSEGFubm90YXRpb25TcGVjSWQSIQoMZGlzcGxh
eV9uYW1lGA8gASgJUgtkaXNwbGF5TmFtZRI7CgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2ds
ZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSNgoXZXZhbHVhdGVkX2V4YW1wbGVf
Y291bnQYBiABKAVSFWV2YWx1YXRlZEV4YW1wbGVDb3VudDqHAepBgwEKJWF1dG9tbC5nb29n
bGVhcGlzLmNvbS9Nb2RlbEV2YWx1YXRpb24SWnByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlv
bnMve2xvY2F0aW9ufS9tb2RlbHMve21vZGVsfS9tb2RlbEV2YWx1YXRpb25zL3ttb2RlbF9l
dmFsdWF0aW9ufUIJCgdtZXRyaWNzQqABChpjb20uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MVAB
WjJjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MS9hdXRvbWxwYjthdXRvbWxwYqoC
Fkdvb2dsZS5DbG91ZC5BdXRvTUwuVjHKAhZHb29nbGVcQ2xvdWRcQXV0b01sXFYx6gIZR29v
Z2xlOjpDbG91ZDo6QXV0b01MOjpWMUrjHAoGEgQOAGQBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSACMKCQoCAwESAxMANQoJCgIDAhID
FAAwCgkKAgMDEgMVADYKCQoCAwQSAxYANQoJCgIDBRIDFwAyCgkKAgMGEgMYACkKCAoBCBID
GgAzCgkKAgglEgMaADMKCAoBCBIDGwBJCgkKAggLEgMbAEkKCAoBCBIDHAAiCgkKAggKEgMc
ACIKCAoBCBIDHQAzCgkKAggBEgMdADMKCAoBCBIDHgAzCgkKAggpEgMeADMKCAoBCBIDHwAy
CgkKAggtEgMfADIKLAoCBAASBCIAZAEaICBFdmFsdWF0aW9uIHJlc3VsdHMgb2YgYSBtb2Rl
bC4KCgoKAwQAARIDIggXCgsKAwQABxIEIwImBAoNCgUEAAedCBIEIwImBApGCgQEAAgAEgQp
AjsDGjggT3V0cHV0IG9ubHkuIFByb2JsZW0gdHlwZSBzcGVjaWZpYyBldmFsdWF0aW9uIG1l
dHJpY3MuCgoMCgUEAAgAARIDKQgPCrgBCgQEAAIAEgMuBEoaqgEgTW9kZWwgZXZhbHVhdGlv
biBtZXRyaWNzIGZvciBpbWFnZSwgdGV4dCwgdmlkZW8gYW5kIHRhYmxlcwogY2xhc3NpZmlj
YXRpb24uCiBUYWJsZXMgcHJvYmxlbSBpcyBjb25zaWRlcmVkIGEgY2xhc3NpZmljYXRpb24g
d2hlbiB0aGUgdGFyZ2V0IGNvbHVtbgogaXMgQ0FURUdPUlkgRGF0YVR5cGUuCgoMCgUEAAIA
BhIDLgQjCgwKBQQAAgABEgMuJEUKDAoFBAACAAMSAy5ISQo4CgQEAAIBEgMxBEQaKyBNb2Rl
bCBldmFsdWF0aW9uIG1ldHJpY3MgZm9yIHRyYW5zbGF0aW9uLgoKDAoFBAACAQYSAzEEIAoM
CgUEAAIBARIDMSE/CgwKBQQAAgEDEgMxQkMKQwoEBAACAhIDNARZGjYgTW9kZWwgZXZhbHVh
dGlvbiBtZXRyaWNzIGZvciBpbWFnZSBvYmplY3QgZGV0ZWN0aW9uLgoKDAoFBAACAgYSAzQE
KQoMCgUEAAICARIDNCpTCgwKBQQAAgIDEgM0VlgKPAoEBAACAxIDNwRKGi8gRXZhbHVhdGlv
biBtZXRyaWNzIGZvciB0ZXh0IHNlbnRpbWVudCBtb2RlbHMuCgoMCgUEAAIDBhIDNwQiCgwK
BQQAAgMBEgM3I0QKDAoFBAACAwMSAzdHSQo9CgQEAAIEEgM6BEwaMCBFdmFsdWF0aW9uIG1l
dHJpY3MgZm9yIHRleHQgZXh0cmFjdGlvbiBtb2RlbHMuCgoMCgUEAAIEBhIDOgQjCgwKBQQA
AgQBEgM6JEYKDAoFBAACBAMSAzpJSwq2AQoEBAACBRIDQAISGqgBIE91dHB1dCBvbmx5LiBS
ZXNvdXJjZSBuYW1lIG9mIHRoZSBtb2RlbCBldmFsdWF0aW9uLgogRm9ybWF0OgogYHByb2pl
Y3RzL3twcm9qZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9tb2RlbHMve21vZGVs
X2lkfS9tb2RlbEV2YWx1YXRpb25zL3ttb2RlbF9ldmFsdWF0aW9uX2lkfWAKCgwKBQQAAgUF
EgNAAggKDAoFBAACBQESA0AJDQoMCgUEAAIFAxIDQBARCrIDCgQEAAIGEgNKAiAapAMgT3V0
cHV0IG9ubHkuIFRoZSBJRCBvZiB0aGUgYW5ub3RhdGlvbiBzcGVjIHRoYXQgdGhlIG1vZGVs
IGV2YWx1YXRpb24gYXBwbGllcyB0by4gVGhlCiBUaGUgSUQgaXMgZW1wdHkgZm9yIHRoZSBv
dmVyYWxsIG1vZGVsIGV2YWx1YXRpb24uCiBGb3IgVGFibGVzIGFubm90YXRpb24gc3BlY3Mg
aW4gdGhlIGRhdGFzZXQgZG8gbm90IGV4aXN0IGFuZCB0aGlzIElEIGlzCiBhbHdheXMgbm90
IHNldCwgYnV0IGZvciBDTEFTU0lGSUNBVElPTgogW3ByZWRpY3Rpb25fdHlwZS1zXVtnb29n
bGUuY2xvdWQuYXV0b21sLnYxLlRhYmxlc01vZGVsTWV0YWRhdGEucHJlZGljdGlvbl90eXBl
XQogdGhlCiBbZGlzcGxheV9uYW1lXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxLk1vZGVsRXZh
bHVhdGlvbi5kaXNwbGF5X25hbWVdCiBmaWVsZCBpcyB1c2VkLgoKDAoFBAACBgUSA0oCCAoM
CgUEAAIGARIDSgkbCgwKBQQAAgYDEgNKHh8K+AQKBAQAAgcSA1YCGxrqBCBPdXRwdXQgb25s
eS4gVGhlIHZhbHVlIG9mCiBbZGlzcGxheV9uYW1lXVtnb29nbGUuY2xvdWQuYXV0b21sLnYx
LkFubm90YXRpb25TcGVjLmRpc3BsYXlfbmFtZV0KIGF0IHRoZSBtb21lbnQgd2hlbiB0aGUg
bW9kZWwgd2FzIHRyYWluZWQuIEJlY2F1c2UgdGhpcyBmaWVsZCByZXR1cm5zIGEKIHZhbHVl
IGF0IG1vZGVsIHRyYWluaW5nIHRpbWUsIGZvciBkaWZmZXJlbnQgbW9kZWxzIHRyYWluZWQg
ZnJvbSB0aGUgc2FtZQogZGF0YXNldCwgdGhlIHZhbHVlcyBtYXkgZGlmZmVyLCBzaW5jZSBk
aXNwbGF5IG5hbWVzIGNvdWxkIGhhZCBiZWVuIGNoYW5nZWQKIGJldHdlZW4gdGhlIHR3byBt
b2RlbCdzIHRyYWluaW5ncy4gRm9yIFRhYmxlcyBDTEFTU0lGSUNBVElPTgogW3ByZWRpY3Rp
b25fdHlwZS1zXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxLlRhYmxlc01vZGVsTWV0YWRhdGEu
cHJlZGljdGlvbl90eXBlXQogZGlzdGluY3QgdmFsdWVzIG9mIHRoZSB0YXJnZXQgY29sdW1u
IGF0IHRoZSBtb21lbnQgb2YgdGhlIG1vZGVsIGV2YWx1YXRpb24KIGFyZSBwb3B1bGF0ZWQg
aGVyZS4KIFRoZSBkaXNwbGF5X25hbWUgaXMgZW1wdHkgZm9yIHRoZSBvdmVyYWxsIG1vZGVs
IGV2YWx1YXRpb24uCgoMCgUEAAIHBRIDVgIICgwKBQQAAgcBEgNWCRUKDAoFBAACBwMSA1YY
GgpNCgQEAAIIEgNZAiwaQCBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhpcyBtb2Rl
bCBldmFsdWF0aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAACCAYSA1kCGwoMCgUEAAIIARIDWRwn
CgwKBQQAAggDEgNZKisKhQQKBAQAAgkSA2MCJBr3AyBPdXRwdXQgb25seS4gVGhlIG51bWJl
ciBvZiBleGFtcGxlcyB1c2VkIGZvciBtb2RlbCBldmFsdWF0aW9uLCBpLmUuIGZvcgogd2hp
Y2ggZ3JvdW5kIHRydXRoIGZyb20gdGltZSBvZiBtb2RlbCBjcmVhdGlvbiBpcyBjb21wYXJl
ZCBhZ2FpbnN0IHRoZQogcHJlZGljdGVkIGFubm90YXRpb25zIGNyZWF0ZWQgYnkgdGhlIG1v
ZGVsLgogRm9yIG92ZXJhbGwgTW9kZWxFdmFsdWF0aW9uIChpLmUuIHdpdGggYW5ub3RhdGlv
bl9zcGVjX2lkIG5vdCBzZXQpIHRoaXMgaXMKIHRoZSB0b3RhbCBudW1iZXIgb2YgYWxsIGV4
YW1wbGVzIHVzZWQgZm9yIGV2YWx1YXRpb24uCiBPdGhlcndpc2UsIHRoaXMgaXMgdGhlIGNv
dW50IG9mIGV4YW1wbGVzIHRoYXQgYWNjb3JkaW5nIHRvIHRoZSBncm91bmQKIHRydXRoIHdl
cmUgYW5ub3RhdGVkIGJ5IHRoZQogW2Fubm90YXRpb25fc3BlY19pZF1bZ29vZ2xlLmNsb3Vk
LmF1dG9tbC52MS5Nb2RlbEV2YWx1YXRpb24uYW5ub3RhdGlvbl9zcGVjX2lkXS4KCgwKBQQA
AgkFEgNjAgcKDAoFBAACCQESA2MIHwoMCgUEAAIJAxIDYyIjYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::ModelEvaluation::ModelEvaluation ===
    # Fields for ModelEvaluation
    # Field: classification_evaluation_metrics Type: 11 (.google.cloud.automl.v1.ClassificationEvaluationMetrics)
    # Field: translation_evaluation_metrics Type: 11 (.google.cloud.automl.v1.TranslationEvaluationMetrics)
    # Field: image_object_detection_evaluation_metrics Type: 11 (.google.cloud.automl.v1.ImageObjectDetectionEvaluationMetrics)
    # Field: text_sentiment_evaluation_metrics Type: 11 (.google.cloud.automl.v1.TextSentimentEvaluationMetrics)
    # Field: text_extraction_evaluation_metrics Type: 11 (.google.cloud.automl.v1.TextExtractionEvaluationMetrics)
    # Field: name Type: 9 ()
    # Field: annotation_spec_id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: evaluated_example_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::ModelEvaluation - Compiled Protocol Buffers messages for google/cloud/automl/v1/model_evaluation.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::ModelEvaluation;

    my $msg = Google::Cloud::Automl::V1::ModelEvaluation::ModelEvaluation->new({
        classification_evaluation_metrics => $classification_evaluation_metrics,
        translation_evaluation_metrics => $translation_evaluation_metrics,
        image_object_detection_evaluation_metrics => $image_object_detection_evaluation_metrics,
        text_sentiment_evaluation_metrics => $text_sentiment_evaluation_metrics,
    });

    # Read or update a field
    my $val = $msg->classification_evaluation_metrics();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::ModelEvaluation::ModelEvaluation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/model_evaluation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::ModelEvaluation::ModelEvaluation

Evaluation results of a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classification_evaluation_metrics() >> / C<< $msg->classification_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics>)

Model evaluation metrics for image, text, video and tables
classification.
Tables problem is considered a classification when the target column
is CATEGORY DataType.

=item * C<< $msg->translation_evaluation_metrics() >> / C<< $msg->translation_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Translation::TranslationEvaluationMetrics>)

Model evaluation metrics for translation.

=item * C<< $msg->image_object_detection_evaluation_metrics() >> / C<< $msg->image_object_detection_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Detection::ImageObjectDetectionEvaluationMetrics>)

Model evaluation metrics for image object detection.

=item * C<< $msg->text_sentiment_evaluation_metrics() >> / C<< $msg->text_sentiment_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::TextSentiment::TextSentimentEvaluationMetrics>)

Evaluation metrics for text sentiment models.

=item * C<< $msg->text_extraction_evaluation_metrics() >> / C<< $msg->text_extraction_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::TextExtraction::TextExtractionEvaluationMetrics>)

Evaluation metrics for text extraction models.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name of the model evaluation.
Format:
`projects/{project_id}/locations/{location_id}/models/{model_id}/modelEvaluations/{model_evaluation_id}`

=item * C<< $msg->annotation_spec_id() >> / C<< $msg->annotation_spec_id($value) >>

Type: C<String>

Output only. The ID of the annotation spec that the model evaluation applies to. The
The ID is empty for the overall model evaluation.
For Tables annotation specs in the dataset do not exist and this ID is
always not set, but for CLASSIFICATION
[prediction_type-s][google.cloud.automl.v1.TablesModelMetadata.prediction_type]
the
[display_name][google.cloud.automl.v1.ModelEvaluation.display_name]
field is used.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The value of
[display_name][google.cloud.automl.v1.AnnotationSpec.display_name]
at the moment when the model was trained. Because this field returns a
value at model training time, for different models trained from the same
dataset, the values may differ, since display names could had been changed
between the two model's trainings. For Tables CLASSIFICATION
[prediction_type-s][google.cloud.automl.v1.TablesModelMetadata.prediction_type]
distinct values of the target column at the moment of the model evaluation
are populated here.
The display_name is empty for the overall model evaluation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when this model evaluation was created.

=item * C<< $msg->evaluated_example_count() >> / C<< $msg->evaluated_example_count($value) >>

Type: C<Int32>

Output only. The number of examples used for model evaluation, i.e. for
which ground truth from time of model creation is compared against the
predicted annotations created by the model.
For overall ModelEvaluation (i.e. with annotation_spec_id not set) this is
the total number of all examples used for evaluation.
Otherwise, this is the count of examples that according to the ground
truth were annotated by the
[annotation_spec_id][google.cloud.automl.v1.ModelEvaluation.annotation_spec_id].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::ModelEvaluation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
