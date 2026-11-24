package Google::Cloud::Automl::V1beta1::Translation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Automl::V1beta1::DataItems };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdHJhbnNsYXRpb24ucHJvdG8SG2dvb2ds
ZS5jbG91ZC5hdXRvbWwudjFiZXRhMRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90
bxosZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGExL2RhdGFfaXRlbXMucHJvdG8iigEKGlRy
YW5zbGF0aW9uRGF0YXNldE1ldGFkYXRhEjUKFHNvdXJjZV9sYW5ndWFnZV9jb2RlGAEgASgJ
QgPgQQJSEnNvdXJjZUxhbmd1YWdlQ29kZRI1ChR0YXJnZXRfbGFuZ3VhZ2VfY29kZRgCIAEo
CUID4EECUhJ0YXJnZXRMYW5ndWFnZUNvZGUiZQocVHJhbnNsYXRpb25FdmFsdWF0aW9uTWV0
cmljcxIdCgpibGV1X3Njb3JlGAEgASgBUglibGV1U2NvcmUSJgoPYmFzZV9ibGV1X3Njb3Jl
GAIgASgBUg1iYXNlQmxldVNjb3JlIp0BChhUcmFuc2xhdGlvbk1vZGVsTWV0YWRhdGESHQoK
YmFzZV9tb2RlbBgBIAEoCVIJYmFzZU1vZGVsEjAKFHNvdXJjZV9sYW5ndWFnZV9jb2RlGAIg
ASgJUhJzb3VyY2VMYW5ndWFnZUNvZGUSMAoUdGFyZ2V0X2xhbmd1YWdlX2NvZGUYAyABKAlS
EnRhcmdldExhbmd1YWdlQ29kZSJwChVUcmFuc2xhdGlvbkFubm90YXRpb24SVwoSdHJhbnNs
YXRlZF9jb250ZW50GAEgASgLMiguZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLlRleHRT
bmlwcGV0UhF0cmFuc2xhdGVkQ29udGVudEKtAQofY29tLmdvb2dsZS5jbG91ZC5hdXRvbWwu
djFiZXRhMUIQVHJhbnNsYXRpb25Qcm90b1ABWjdjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9t
bC9hcGl2MWJldGExL2F1dG9tbHBiO2F1dG9tbHBiygIbR29vZ2xlXENsb3VkXEF1dG9NbFxW
MWJldGEx6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMWJldGExSpwRCgYSBA4AQwEKvAQK
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
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACQKCQoCAwASAxIAKQoJ
CgIDARIDEwA2CggKAQgSAxUATgoJCgIICxIDFQBOCggKAQgSAxYAIgoJCgIIChIDFgAiCggK
AQgSAxcAMQoJCgIICBIDFwAxCggKAQgSAxgAOAoJCgIIARIDGAA4CggKAQgSAxkAOAoJCgII
KRIDGQA4CggKAQgSAxoANwoJCgIILRIDGgA3Cj8KAgQAEgQdACMBGjMgRGF0YXNldCBtZXRh
ZGF0YSB0aGF0IGlzIHNwZWNpZmljIHRvIHRyYW5zbGF0aW9uLgoKCgoDBAABEgMdCCIKSQoE
BAACABIDHwJLGjwgUmVxdWlyZWQuIFRoZSBCQ1AtNDcgbGFuZ3VhZ2UgY29kZSBvZiB0aGUg
c291cmNlIGxhbmd1YWdlLgoKDAoFBAACAAUSAx8CCAoMCgUEAAIAARIDHwkdCgwKBQQAAgAD
EgMfICEKDAoFBAACAAgSAx8iSgoPCggEAAIACJwIABIDHyNJCkkKBAQAAgESAyICSxo8IFJl
cXVpcmVkLiBUaGUgQkNQLTQ3IGxhbmd1YWdlIGNvZGUgb2YgdGhlIHRhcmdldCBsYW5ndWFn
ZS4KCgwKBQQAAgEFEgMiAggKDAoFBAACAQESAyIJHQoMCgUEAAIBAxIDIiAhCgwKBQQAAgEI
EgMiIkoKDwoIBAACAQicCAASAyIjSQoxCgIEARIEJgAsARolIEV2YWx1YXRpb24gbWV0cmlj
cyBmb3IgdGhlIGRhdGFzZXQuCgoKCgMEAQESAyYIJAonCgQEAQIAEgMoAhgaGiBPdXRwdXQg
b25seS4gQkxFVSBzY29yZS4KCgwKBQQBAgAFEgMoAggKDAoFBAECAAESAygJEwoMCgUEAQIA
AxIDKBYXCjYKBAQBAgESAysCHRopIE91dHB1dCBvbmx5LiBCTEVVIHNjb3JlIGZvciBiYXNl
IG1vZGVsLgoKDAoFBAECAQUSAysCCAoMCgUEAQIBARIDKwkYCgwKBQQBAgEDEgMrGxwKPQoC
BAISBC8APQEaMSBNb2RlbCBtZXRhZGF0YSB0aGF0IGlzIHNwZWNpZmljIHRvIHRyYW5zbGF0
aW9uLgoKCgoDBAIBEgMvCCAK8QEKBAQCAgASAzQCGBrjASBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgbW9kZWwgdG8gdXNlIGFzIGEgYmFzZWxpbmUgdG8gdHJhaW4gdGhlIGN1c3RvbQog
bW9kZWwuIElmIHVuc2V0LCB3ZSB1c2UgdGhlIGRlZmF1bHQgYmFzZSBtb2RlbCBwcm92aWRl
ZCBieSBHb29nbGUKIFRyYW5zbGF0ZS4gRm9ybWF0OgogYHByb2plY3RzL3twcm9qZWN0X2lk
fS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9tb2RlbHMve21vZGVsX2lkfWAKCgwKBQQCAgAF
EgM0AggKDAoFBAICAAESAzQJEwoMCgUEAgIAAxIDNBYXCoABCgQEAgIBEgM4AiIacyBPdXRw
dXQgb25seS4gSW5mZXJyZWQgZnJvbSB0aGUgZGF0YXNldC4KIFRoZSBzb3VyY2UgbGFuZ3Vn
ZSAoVGhlIEJDUC00NyBsYW5ndWFnZSBjb2RlKSB0aGF0IGlzIHVzZWQgZm9yIHRyYWluaW5n
LgoKDAoFBAICAQUSAzgCCAoMCgUEAgIBARIDOAkdCgwKBQQCAgEDEgM4ICEKZQoEBAICAhID
PAIiGlggT3V0cHV0IG9ubHkuIFRoZSB0YXJnZXQgbGFuZ3VnZSAoVGhlIEJDUC00NyBsYW5n
dWFnZSBjb2RlKSB0aGF0IGlzIHVzZWQgZm9yCiB0cmFpbmluZy4KCgwKBQQCAgIFEgM8AggK
DAoFBAICAgESAzwJHQoMCgUEAgICAxIDPCAhCjkKAgQDEgRAAEMBGi0gQW5ub3RhdGlvbiBk
ZXRhaWxzIHNwZWNpZmljIHRvIHRyYW5zbGF0aW9uLgoKCgoDBAMBEgNACB0KNAoEBAMCABID
QgIlGicgT3V0cHV0IG9ubHkgLiBUaGUgdHJhbnNsYXRlZCBjb250ZW50LgoKDAoFBAMCAAYS
A0ICDQoMCgUEAwIAARIDQg4gCgwKBQQDAgADEgNCIyRiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::Translation::TranslationDatasetMetadata ===
    # Fields for TranslationDatasetMetadata
    # Field: source_language_code Type: 9 ()
    # Field: target_language_code Type: 9 ()

# === Message: Google::Cloud::Automl::V1beta1::Translation::TranslationEvaluationMetrics ===
    # Fields for TranslationEvaluationMetrics
    # Field: bleu_score Type: 1 ()
    # Field: base_bleu_score Type: 1 ()

# === Message: Google::Cloud::Automl::V1beta1::Translation::TranslationModelMetadata ===
    # Fields for TranslationModelMetadata
    # Field: base_model Type: 9 ()
    # Field: source_language_code Type: 9 ()
    # Field: target_language_code Type: 9 ()

# === Message: Google::Cloud::Automl::V1beta1::Translation::TranslationAnnotation ===
    # Fields for TranslationAnnotation
    # Field: translated_content Type: 11 (.google.cloud.automl.v1beta1.TextSnippet)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::Translation - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/translation.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::Translation;

    my $msg = Google::Cloud::Automl::V1beta1::Translation::TranslationDatasetMetadata->new({
        source_language_code => $source_language_code,
        target_language_code => $target_language_code,
    });

    # Read or update a field
    my $val = $msg->source_language_code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::Translation::TranslationDatasetMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/translation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::Translation::TranslationDatasetMetadata

Dataset metadata that is specific to translation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->source_language_code() >> / C<< $msg->source_language_code($value) >>

Type: C<String>

Required. The BCP-47 language code of the source language.

=item * C<< $msg->target_language_code() >> / C<< $msg->target_language_code($value) >>

Type: C<String>

Required. The BCP-47 language code of the target language.

=back

=head2 Google::Cloud::Automl::V1beta1::Translation::TranslationEvaluationMetrics

Evaluation metrics for the dataset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bleu_score() >> / C<< $msg->bleu_score($value) >>

Type: C<Double>

Output only. BLEU score.

=item * C<< $msg->base_bleu_score() >> / C<< $msg->base_bleu_score($value) >>

Type: C<Double>

Output only. BLEU score for base model.

=back

=head2 Google::Cloud::Automl::V1beta1::Translation::TranslationModelMetadata

Model metadata that is specific to translation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->base_model() >> / C<< $msg->base_model($value) >>

Type: C<String>

The resource name of the model to use as a baseline to train the custom
model. If unset, we use the default base model provided by Google
Translate. Format:
`projects/{project_id}/locations/{location_id}/models/{model_id}`

=item * C<< $msg->source_language_code() >> / C<< $msg->source_language_code($value) >>

Type: C<String>

Output only. Inferred from the dataset.
The source languge (The BCP-47 language code) that is used for training.

=item * C<< $msg->target_language_code() >> / C<< $msg->target_language_code($value) >>

Type: C<String>

Output only. The target languge (The BCP-47 language code) that is used for
training.

=back

=head2 Google::Cloud::Automl::V1beta1::Translation::TranslationAnnotation

Annotation details specific to translation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->translated_content() >> / C<< $msg->translated_content($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::DataItems::TextSnippet>)

Output only . The translated content.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::Translation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
