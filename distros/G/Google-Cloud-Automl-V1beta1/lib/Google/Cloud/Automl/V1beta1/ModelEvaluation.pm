package Google::Cloud::Automl::V1beta1::ModelEvaluation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Automl::V1beta1::Classification };
    eval { require Google::Cloud::Automl::V1beta1::Detection };
    eval { require Google::Cloud::Automl::V1beta1::Regression };
    eval { require Google::Cloud::Automl::V1beta1::Tables };
    eval { require Google::Cloud::Automl::V1beta1::TextExtraction };
    eval { require Google::Cloud::Automl::V1beta1::TextSentiment };
    eval { require Google::Cloud::Automl::V1beta1::Translation };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvbW9kZWxfZXZhbHVhdGlvbi5wcm90bxIb
Z29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
GjBnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvY2xhc3NpZmljYXRpb24ucHJvdG8aK2dv
b2dsZS9jbG91ZC9hdXRvbWwvdjFiZXRhMS9kZXRlY3Rpb24ucHJvdG8aLGdvb2dsZS9jbG91
ZC9hdXRvbWwvdjFiZXRhMS9yZWdyZXNzaW9uLnByb3RvGihnb29nbGUvY2xvdWQvYXV0b21s
L3YxYmV0YTEvdGFibGVzLnByb3RvGjFnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdGV4
dF9leHRyYWN0aW9uLnByb3RvGjBnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdGV4dF9z
ZW50aW1lbnQucHJvdG8aLWdvb2dsZS9jbG91ZC9hdXRvbWwvdjFiZXRhMS90cmFuc2xhdGlv
bi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLpCgoPTW9kZWxFdmFs
dWF0aW9uEooBCiFjbGFzc2lmaWNhdGlvbl9ldmFsdWF0aW9uX21ldHJpY3MYCCABKAsyPC5n
b29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuQ2xhc3NpZmljYXRpb25FdmFsdWF0aW9uTWV0
cmljc0gAUh9jbGFzc2lmaWNhdGlvbkV2YWx1YXRpb25NZXRyaWNzEn4KHXJlZ3Jlc3Npb25f
ZXZhbHVhdGlvbl9tZXRyaWNzGBggASgLMjguZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGEx
LlJlZ3Jlc3Npb25FdmFsdWF0aW9uTWV0cmljc0gAUhtyZWdyZXNzaW9uRXZhbHVhdGlvbk1l
dHJpY3MSgQEKHnRyYW5zbGF0aW9uX2V2YWx1YXRpb25fbWV0cmljcxgJIAEoCzI5Lmdvb2ds
ZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5UcmFuc2xhdGlvbkV2YWx1YXRpb25NZXRyaWNzSABS
HHRyYW5zbGF0aW9uRXZhbHVhdGlvbk1ldHJpY3MSngEKKWltYWdlX29iamVjdF9kZXRlY3Rp
b25fZXZhbHVhdGlvbl9tZXRyaWNzGAwgASgLMkIuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJl
dGExLkltYWdlT2JqZWN0RGV0ZWN0aW9uRXZhbHVhdGlvbk1ldHJpY3NIAFIlaW1hZ2VPYmpl
Y3REZXRlY3Rpb25FdmFsdWF0aW9uTWV0cmljcxKbAQoodmlkZW9fb2JqZWN0X3RyYWNraW5n
X2V2YWx1YXRpb25fbWV0cmljcxgOIAEoCzJBLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRh
MS5WaWRlb09iamVjdFRyYWNraW5nRXZhbHVhdGlvbk1ldHJpY3NIAFIkdmlkZW9PYmplY3RU
cmFja2luZ0V2YWx1YXRpb25NZXRyaWNzEogBCiF0ZXh0X3NlbnRpbWVudF9ldmFsdWF0aW9u
X21ldHJpY3MYCyABKAsyOy5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVGV4dFNlbnRp
bWVudEV2YWx1YXRpb25NZXRyaWNzSABSHnRleHRTZW50aW1lbnRFdmFsdWF0aW9uTWV0cmlj
cxKLAQoidGV4dF9leHRyYWN0aW9uX2V2YWx1YXRpb25fbWV0cmljcxgNIAEoCzI8Lmdvb2ds
ZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5UZXh0RXh0cmFjdGlvbkV2YWx1YXRpb25NZXRyaWNz
SABSH3RleHRFeHRyYWN0aW9uRXZhbHVhdGlvbk1ldHJpY3MSEgoEbmFtZRgBIAEoCVIEbmFt
ZRIsChJhbm5vdGF0aW9uX3NwZWNfaWQYAiABKAlSEGFubm90YXRpb25TcGVjSWQSIQoMZGlz
cGxheV9uYW1lGA8gASgJUgtkaXNwbGF5TmFtZRI7CgtjcmVhdGVfdGltZRgFIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmNyZWF0ZVRpbWUSNgoXZXZhbHVhdGVkX2V4YW1w
bGVfY291bnQYBiABKAVSFWV2YWx1YXRlZEV4YW1wbGVDb3VudDqHAepBgwEKJWF1dG9tbC5n
b29nbGVhcGlzLmNvbS9Nb2RlbEV2YWx1YXRpb24SWnByb2plY3RzL3twcm9qZWN0fS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9tb2RlbHMve21vZGVsfS9tb2RlbEV2YWx1YXRpb25zL3ttb2Rl
bF9ldmFsdWF0aW9ufUIJCgdtZXRyaWNzQpsBCh9jb20uZ29vZ2xlLmNsb3VkLmF1dG9tbC52
MWJldGExUAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28vYXV0b21sL2FwaXYxYmV0YTEvYXV0b21s
cGI7YXV0b21scGLKAhtHb29nbGVcQ2xvdWRcQXV0b01sXFYxYmV0YTHqAh5Hb29nbGU6OkNs
b3VkOjpBdXRvTUw6OlYxYmV0YTFKtR8KBhIEDgByAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgAjCgkKAgMBEgMTADoKCQoCAwISAxQA
NQoJCgIDAxIDFQA2CgkKAgMEEgMWADIKCQoCAwUSAxcAOwoJCgIDBhIDGAA6CgkKAgMHEgMZ
ADcKCQoCAwgSAxoAKQoICgEIEgMcAE4KCQoCCAsSAxwATgoICgEIEgMdACIKCQoCCAoSAx0A
IgoICgEIEgMeADgKCQoCCAESAx4AOAoICgEIEgMfADgKCQoCCCkSAx8AOAoICgEIEgMgADcK
CQoCCC0SAyAANwosCgIEABIEIwByARogIEV2YWx1YXRpb24gcmVzdWx0cyBvZiBhIG1vZGVs
LgoKCgoDBAABEgMjCBcKCwoDBAAHEgQkAicECg0KBQQAB50IEgQkAicECkYKBAQACAASBCoC
RAMaOCBPdXRwdXQgb25seS4gUHJvYmxlbSB0eXBlIHNwZWNpZmljIGV2YWx1YXRpb24gbWV0
cmljcy4KCgwKBQQACAABEgMqCA8KuAEKBAQAAgASAy8EShqqASBNb2RlbCBldmFsdWF0aW9u
IG1ldHJpY3MgZm9yIGltYWdlLCB0ZXh0LCB2aWRlbyBhbmQgdGFibGVzCiBjbGFzc2lmaWNh
dGlvbi4KIFRhYmxlcyBwcm9ibGVtIGlzIGNvbnNpZGVyZWQgYSBjbGFzc2lmaWNhdGlvbiB3
aGVuIHRoZSB0YXJnZXQgY29sdW1uCiBpcyBDQVRFR09SWSBEYXRhVHlwZS4KCgwKBQQAAgAG
EgMvBCMKDAoFBAACAAESAy8kRQoMCgUEAAIAAxIDL0hJCpgBCgQEAAIBEgM0BEMaigEgTW9k
ZWwgZXZhbHVhdGlvbiBtZXRyaWNzIGZvciBUYWJsZXMgcmVncmVzc2lvbi4KIFRhYmxlcyBw
cm9ibGVtIGlzIGNvbnNpZGVyZWQgYSByZWdyZXNzaW9uIHdoZW4gdGhlIHRhcmdldCBjb2x1
bW4KIGhhcyBGTE9BVDY0IERhdGFUeXBlLgoKDAoFBAACAQYSAzQEHwoMCgUEAAIBARIDNCA9
CgwKBQQAAgEDEgM0QEIKOAoEBAACAhIDNwREGisgTW9kZWwgZXZhbHVhdGlvbiBtZXRyaWNz
IGZvciB0cmFuc2xhdGlvbi4KCgwKBQQAAgIGEgM3BCAKDAoFBAACAgESAzchPwoMCgUEAAIC
AxIDN0JDCkMKBAQAAgMSAzoEWRo2IE1vZGVsIGV2YWx1YXRpb24gbWV0cmljcyBmb3IgaW1h
Z2Ugb2JqZWN0IGRldGVjdGlvbi4KCgwKBQQAAgMGEgM6BCkKDAoFBAACAwESAzoqUwoMCgUE
AAIDAxIDOlZYCkIKBAQAAgQSAz0EVxo1IE1vZGVsIGV2YWx1YXRpb24gbWV0cmljcyBmb3Ig
dmlkZW8gb2JqZWN0IHRyYWNraW5nLgoKDAoFBAACBAYSAz0EKAoMCgUEAAIEARIDPSlRCgwK
BQQAAgQDEgM9VFYKPAoEBAACBRIDQARKGi8gRXZhbHVhdGlvbiBtZXRyaWNzIGZvciB0ZXh0
IHNlbnRpbWVudCBtb2RlbHMuCgoMCgUEAAIFBhIDQAQiCgwKBQQAAgUBEgNAI0QKDAoFBAAC
BQMSA0BHSQo9CgQEAAIGEgNDBEwaMCBFdmFsdWF0aW9uIG1ldHJpY3MgZm9yIHRleHQgZXh0
cmFjdGlvbiBtb2RlbHMuCgoMCgUEAAIGBhIDQwQjCgwKBQQAAgYBEgNDJEYKDAoFBAACBgMS
A0NJSwq3AQoEBAACBxIDSgISGqkBIE91dHB1dCBvbmx5LiBSZXNvdXJjZSBuYW1lIG9mIHRo
ZSBtb2RlbCBldmFsdWF0aW9uLgogRm9ybWF0OgoKIGBwcm9qZWN0cy97cHJvamVjdF9pZH0v
bG9jYXRpb25zL3tsb2NhdGlvbl9pZH0vbW9kZWxzL3ttb2RlbF9pZH0vbW9kZWxFdmFsdWF0
aW9ucy97bW9kZWxfZXZhbHVhdGlvbl9pZH1gCgoMCgUEAAIHBRIDSgIICgwKBQQAAgcBEgNK
CQ0KDAoFBAACBwMSA0oQEQq9AwoEBAACCBIDVQIgGq8DIE91dHB1dCBvbmx5LiBUaGUgSUQg
b2YgdGhlIGFubm90YXRpb24gc3BlYyB0aGF0IHRoZSBtb2RlbCBldmFsdWF0aW9uIGFwcGxp
ZXMgdG8uIFRoZQogVGhlIElEIGlzIGVtcHR5IGZvciB0aGUgb3ZlcmFsbCBtb2RlbCBldmFs
dWF0aW9uLgogRm9yIFRhYmxlcyBhbm5vdGF0aW9uIHNwZWNzIGluIHRoZSBkYXRhc2V0IGRv
IG5vdCBleGlzdCBhbmQgdGhpcyBJRCBpcwogYWx3YXlzIG5vdCBzZXQsIGJ1dCBmb3IgQ0xB
U1NJRklDQVRJT04KCiBbcHJlZGljdGlvbl90eXBlLXNdW2dvb2dsZS5jbG91ZC5hdXRvbWwu
djFiZXRhMS5UYWJsZXNNb2RlbE1ldGFkYXRhLnByZWRpY3Rpb25fdHlwZV0KIHRoZQogW2Rp
c3BsYXlfbmFtZV1bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLk1vZGVsRXZhbHVhdGlv
bi5kaXNwbGF5X25hbWVdCiBmaWVsZCBpcyB1c2VkLgoKDAoFBAACCAUSA1UCCAoMCgUEAAII
ARIDVQkbCgwKBQQAAggDEgNVHh8KhAUKBAQAAgkSA2MCGxr2BCBPdXRwdXQgb25seS4gVGhl
IHZhbHVlIG9mCiBbZGlzcGxheV9uYW1lXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEu
QW5ub3RhdGlvblNwZWMuZGlzcGxheV9uYW1lXSBhdAogdGhlIG1vbWVudCB3aGVuIHRoZSBt
b2RlbCB3YXMgdHJhaW5lZC4gQmVjYXVzZSB0aGlzIGZpZWxkIHJldHVybnMgYSB2YWx1ZQog
YXQgbW9kZWwgdHJhaW5pbmcgdGltZSwgZm9yIGRpZmZlcmVudCBtb2RlbHMgdHJhaW5lZCBm
cm9tIHRoZSBzYW1lIGRhdGFzZXQsCiB0aGUgdmFsdWVzIG1heSBkaWZmZXIsIHNpbmNlIGRp
c3BsYXkgbmFtZXMgY291bGQgaGFkIGJlZW4gY2hhbmdlZCBiZXR3ZWVuCiB0aGUgdHdvIG1v
ZGVsJ3MgdHJhaW5pbmdzLgogRm9yIFRhYmxlcyBDTEFTU0lGSUNBVElPTgoKIFtwcmVkaWN0
aW9uX3R5cGUtc11bZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRhYmxlc01vZGVsTWV0
YWRhdGEucHJlZGljdGlvbl90eXBlXQogZGlzdGluY3QgdmFsdWVzIG9mIHRoZSB0YXJnZXQg
Y29sdW1uIGF0IHRoZSBtb21lbnQgb2YgdGhlIG1vZGVsIGV2YWx1YXRpb24KIGFyZSBwb3B1
bGF0ZWQgaGVyZS4KIFRoZSBkaXNwbGF5X25hbWUgaXMgZW1wdHkgZm9yIHRoZSBvdmVyYWxs
IG1vZGVsIGV2YWx1YXRpb24uCgoMCgUEAAIJBRIDYwIICgwKBQQAAgkBEgNjCRUKDAoFBAAC
CQMSA2MYGgpNCgQEAAIKEgNmAiwaQCBPdXRwdXQgb25seS4gVGltZXN0YW1wIHdoZW4gdGhp
cyBtb2RlbCBldmFsdWF0aW9uIHdhcyBjcmVhdGVkLgoKDAoFBAACCgYSA2YCGwoMCgUEAAIK
ARIDZhwnCgwKBQQAAgoDEgNmKisKiwQKBAQAAgsSA3ECJBr9AyBPdXRwdXQgb25seS4gVGhl
IG51bWJlciBvZiBleGFtcGxlcyB1c2VkIGZvciBtb2RlbCBldmFsdWF0aW9uLCBpLmUuIGZv
cgogd2hpY2ggZ3JvdW5kIHRydXRoIGZyb20gdGltZSBvZiBtb2RlbCBjcmVhdGlvbiBpcyBj
b21wYXJlZCBhZ2FpbnN0IHRoZQogcHJlZGljdGVkIGFubm90YXRpb25zIGNyZWF0ZWQgYnkg
dGhlIG1vZGVsLgogRm9yIG92ZXJhbGwgTW9kZWxFdmFsdWF0aW9uIChpLmUuIHdpdGggYW5u
b3RhdGlvbl9zcGVjX2lkIG5vdCBzZXQpIHRoaXMgaXMKIHRoZSB0b3RhbCBudW1iZXIgb2Yg
YWxsIGV4YW1wbGVzIHVzZWQgZm9yIGV2YWx1YXRpb24uCiBPdGhlcndpc2UsIHRoaXMgaXMg
dGhlIGNvdW50IG9mIGV4YW1wbGVzIHRoYXQgYWNjb3JkaW5nIHRvIHRoZSBncm91bmQKIHRy
dXRoIHdlcmUgYW5ub3RhdGVkIGJ5IHRoZQoKIFthbm5vdGF0aW9uX3NwZWNfaWRdW2dvb2ds
ZS5jbG91ZC5hdXRvbWwudjFiZXRhMS5Nb2RlbEV2YWx1YXRpb24uYW5ub3RhdGlvbl9zcGVj
X2lkXS4KCgwKBQQAAgsFEgNxAgcKDAoFBAACCwESA3EIHwoMCgUEAAILAxIDcSIjYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::ModelEvaluation::ModelEvaluation ===
    # Fields for ModelEvaluation
    # Field: classification_evaluation_metrics Type: 11 (.google.cloud.automl.v1beta1.ClassificationEvaluationMetrics)
    # Field: regression_evaluation_metrics Type: 11 (.google.cloud.automl.v1beta1.RegressionEvaluationMetrics)
    # Field: translation_evaluation_metrics Type: 11 (.google.cloud.automl.v1beta1.TranslationEvaluationMetrics)
    # Field: image_object_detection_evaluation_metrics Type: 11 (.google.cloud.automl.v1beta1.ImageObjectDetectionEvaluationMetrics)
    # Field: video_object_tracking_evaluation_metrics Type: 11 (.google.cloud.automl.v1beta1.VideoObjectTrackingEvaluationMetrics)
    # Field: text_sentiment_evaluation_metrics Type: 11 (.google.cloud.automl.v1beta1.TextSentimentEvaluationMetrics)
    # Field: text_extraction_evaluation_metrics Type: 11 (.google.cloud.automl.v1beta1.TextExtractionEvaluationMetrics)
    # Field: name Type: 9 ()
    # Field: annotation_spec_id Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: evaluated_example_count Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::ModelEvaluation - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/model_evaluation.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::ModelEvaluation;

    my $msg = Google::Cloud::Automl::V1beta1::ModelEvaluation::ModelEvaluation->new({
        classification_evaluation_metrics => $classification_evaluation_metrics,
        regression_evaluation_metrics => $regression_evaluation_metrics,
        translation_evaluation_metrics => $translation_evaluation_metrics,
        image_object_detection_evaluation_metrics => $image_object_detection_evaluation_metrics,
    });

    # Read or update a field
    my $val = $msg->classification_evaluation_metrics();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::ModelEvaluation::ModelEvaluation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/model_evaluation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::ModelEvaluation::ModelEvaluation

Evaluation results of a model.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->classification_evaluation_metrics() >> / C<< $msg->classification_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Classification::ClassificationEvaluationMetrics>)

Model evaluation metrics for image, text, video and tables
classification.
Tables problem is considered a classification when the target column
is CATEGORY DataType.

=item * C<< $msg->regression_evaluation_metrics() >> / C<< $msg->regression_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Regression::RegressionEvaluationMetrics>)

Model evaluation metrics for Tables regression.
Tables problem is considered a regression when the target column
has FLOAT64 DataType.

=item * C<< $msg->translation_evaluation_metrics() >> / C<< $msg->translation_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Translation::TranslationEvaluationMetrics>)

Model evaluation metrics for translation.

=item * C<< $msg->image_object_detection_evaluation_metrics() >> / C<< $msg->image_object_detection_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Detection::ImageObjectDetectionEvaluationMetrics>)

Model evaluation metrics for image object detection.

=item * C<< $msg->video_object_tracking_evaluation_metrics() >> / C<< $msg->video_object_tracking_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Detection::VideoObjectTrackingEvaluationMetrics>)

Model evaluation metrics for video object tracking.

=item * C<< $msg->text_sentiment_evaluation_metrics() >> / C<< $msg->text_sentiment_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentEvaluationMetrics>)

Evaluation metrics for text sentiment models.

=item * C<< $msg->text_extraction_evaluation_metrics() >> / C<< $msg->text_extraction_evaluation_metrics($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::TextExtraction::TextExtractionEvaluationMetrics>)

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

[prediction_type-s][google.cloud.automl.v1beta1.TablesModelMetadata.prediction_type]
the
[display_name][google.cloud.automl.v1beta1.ModelEvaluation.display_name]
field is used.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The value of
[display_name][google.cloud.automl.v1beta1.AnnotationSpec.display_name] at
the moment when the model was trained. Because this field returns a value
at model training time, for different models trained from the same dataset,
the values may differ, since display names could had been changed between
the two model's trainings.
For Tables CLASSIFICATION

[prediction_type-s][google.cloud.automl.v1beta1.TablesModelMetadata.prediction_type]
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

[annotation_spec_id][google.cloud.automl.v1beta1.ModelEvaluation.annotation_spec_id].

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::ModelEvaluation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
