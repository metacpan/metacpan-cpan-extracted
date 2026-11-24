package Google::Cloud::Automl::V1::Translation;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Automl::V1::DataItems };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvYXV0b21sL3YxL3RyYW5zbGF0aW9uLnByb3RvEhZnb29nbGUuY2xv
dWQuYXV0b21sLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGidnb29nbGUv
Y2xvdWQvYXV0b21sL3YxL2RhdGFfaXRlbXMucHJvdG8iigEKGlRyYW5zbGF0aW9uRGF0YXNl
dE1ldGFkYXRhEjUKFHNvdXJjZV9sYW5ndWFnZV9jb2RlGAEgASgJQgPgQQJSEnNvdXJjZUxh
bmd1YWdlQ29kZRI1ChR0YXJnZXRfbGFuZ3VhZ2VfY29kZRgCIAEoCUID4EECUhJ0YXJnZXRM
YW5ndWFnZUNvZGUiZQocVHJhbnNsYXRpb25FdmFsdWF0aW9uTWV0cmljcxIdCgpibGV1X3Nj
b3JlGAEgASgBUglibGV1U2NvcmUSJgoPYmFzZV9ibGV1X3Njb3JlGAIgASgBUg1iYXNlQmxl
dVNjb3JlIp0BChhUcmFuc2xhdGlvbk1vZGVsTWV0YWRhdGESHQoKYmFzZV9tb2RlbBgBIAEo
CVIJYmFzZU1vZGVsEjAKFHNvdXJjZV9sYW5ndWFnZV9jb2RlGAIgASgJUhJzb3VyY2VMYW5n
dWFnZUNvZGUSMAoUdGFyZ2V0X2xhbmd1YWdlX2NvZGUYAyABKAlSEnRhcmdldExhbmd1YWdl
Q29kZSJrChVUcmFuc2xhdGlvbkFubm90YXRpb24SUgoSdHJhbnNsYXRlZF9jb250ZW50GAEg
ASgLMiMuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5UZXh0U25pcHBldFIRdHJhbnNsYXRlZENv
bnRlbnRCsgEKGmNvbS5nb29nbGUuY2xvdWQuYXV0b21sLnYxQhBUcmFuc2xhdGlvblByb3Rv
UAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vYXV0b21sL2FwaXYxL2F1dG9tbHBiO2F1dG9tbHBi
qgIWR29vZ2xlLkNsb3VkLkF1dG9NTC5WMcoCFkdvb2dsZVxDbG91ZFxBdXRvTWxcVjHqAhlH
b29nbGU6OkNsb3VkOjpBdXRvTUw6OlYxSrMRCgYSBA4ARAEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAKQoJCgIDARIDEwAxCggKAQgS
AxUAMwoJCgIIJRIDFQAzCggKAQgSAxYASQoJCgIICxIDFgBJCggKAQgSAxcAIgoJCgIIChID
FwAiCggKAQgSAxgAMQoJCgIICBIDGAAxCggKAQgSAxkAMwoJCgIIARIDGQAzCggKAQgSAxoA
MwoJCgIIKRIDGgAzCggKAQgSAxsAMgoJCgIILRIDGwAyCj8KAgQAEgQeACQBGjMgRGF0YXNl
dCBtZXRhZGF0YSB0aGF0IGlzIHNwZWNpZmljIHRvIHRyYW5zbGF0aW9uLgoKCgoDBAABEgMe
CCIKSQoEBAACABIDIAJLGjwgUmVxdWlyZWQuIFRoZSBCQ1AtNDcgbGFuZ3VhZ2UgY29kZSBv
ZiB0aGUgc291cmNlIGxhbmd1YWdlLgoKDAoFBAACAAUSAyACCAoMCgUEAAIAARIDIAkdCgwK
BQQAAgADEgMgICEKDAoFBAACAAgSAyAiSgoPCggEAAIACJwIABIDICNJCkkKBAQAAgESAyMC
Sxo8IFJlcXVpcmVkLiBUaGUgQkNQLTQ3IGxhbmd1YWdlIGNvZGUgb2YgdGhlIHRhcmdldCBs
YW5ndWFnZS4KCgwKBQQAAgEFEgMjAggKDAoFBAACAQESAyMJHQoMCgUEAAIBAxIDIyAhCgwK
BQQAAgEIEgMjIkoKDwoIBAACAQicCAASAyMjSQoxCgIEARIEJwAtARolIEV2YWx1YXRpb24g
bWV0cmljcyBmb3IgdGhlIGRhdGFzZXQuCgoKCgMEAQESAycIJAonCgQEAQIAEgMpAhgaGiBP
dXRwdXQgb25seS4gQkxFVSBzY29yZS4KCgwKBQQBAgAFEgMpAggKDAoFBAECAAESAykJEwoM
CgUEAQIAAxIDKRYXCjYKBAQBAgESAywCHRopIE91dHB1dCBvbmx5LiBCTEVVIHNjb3JlIGZv
ciBiYXNlIG1vZGVsLgoKDAoFBAECAQUSAywCCAoMCgUEAQIBARIDLAkYCgwKBQQBAgEDEgMs
GxwKPQoCBAISBDAAPgEaMSBNb2RlbCBtZXRhZGF0YSB0aGF0IGlzIHNwZWNpZmljIHRvIHRy
YW5zbGF0aW9uLgoKCgoDBAIBEgMwCCAK8QEKBAQCAgASAzUCGBrjASBUaGUgcmVzb3VyY2Ug
bmFtZSBvZiB0aGUgbW9kZWwgdG8gdXNlIGFzIGEgYmFzZWxpbmUgdG8gdHJhaW4gdGhlIGN1
c3RvbQogbW9kZWwuIElmIHVuc2V0LCB3ZSB1c2UgdGhlIGRlZmF1bHQgYmFzZSBtb2RlbCBw
cm92aWRlZCBieSBHb29nbGUKIFRyYW5zbGF0ZS4gRm9ybWF0OgogYHByb2plY3RzL3twcm9q
ZWN0X2lkfS9sb2NhdGlvbnMve2xvY2F0aW9uX2lkfS9tb2RlbHMve21vZGVsX2lkfWAKCgwK
BQQCAgAFEgM1AggKDAoFBAICAAESAzUJEwoMCgUEAgIAAxIDNRYXCoEBCgQEAgIBEgM5AiIa
dCBPdXRwdXQgb25seS4gSW5mZXJyZWQgZnJvbSB0aGUgZGF0YXNldC4KIFRoZSBzb3VyY2Ug
bGFuZ3VhZ2UgKFRoZSBCQ1AtNDcgbGFuZ3VhZ2UgY29kZSkgdGhhdCBpcyB1c2VkIGZvciB0
cmFpbmluZy4KCgwKBQQCAgEFEgM5AggKDAoFBAICAQESAzkJHQoMCgUEAgIBAxIDOSAhCmYK
BAQCAgISAz0CIhpZIE91dHB1dCBvbmx5LiBUaGUgdGFyZ2V0IGxhbmd1YWdlIChUaGUgQkNQ
LTQ3IGxhbmd1YWdlIGNvZGUpIHRoYXQgaXMgdXNlZAogZm9yIHRyYWluaW5nLgoKDAoFBAIC
AgUSAz0CCAoMCgUEAgICARIDPQkdCgwKBQQCAgIDEgM9ICEKOQoCBAMSBEEARAEaLSBBbm5v
dGF0aW9uIGRldGFpbHMgc3BlY2lmaWMgdG8gdHJhbnNsYXRpb24uCgoKCgMEAwESA0EIHQo0
CgQEAwIAEgNDAiUaJyBPdXRwdXQgb25seSAuIFRoZSB0cmFuc2xhdGVkIGNvbnRlbnQuCgoM
CgUEAwIABhIDQwINCgwKBQQDAgABEgNDDiAKDAoFBAMCAAMSA0MjJGIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::Translation::TranslationDatasetMetadata ===
    # Fields for TranslationDatasetMetadata
    # Field: source_language_code Type: 9 ()
    # Field: target_language_code Type: 9 ()

# === Message: Google::Cloud::Automl::V1::Translation::TranslationEvaluationMetrics ===
    # Fields for TranslationEvaluationMetrics
    # Field: bleu_score Type: 1 ()
    # Field: base_bleu_score Type: 1 ()

# === Message: Google::Cloud::Automl::V1::Translation::TranslationModelMetadata ===
    # Fields for TranslationModelMetadata
    # Field: base_model Type: 9 ()
    # Field: source_language_code Type: 9 ()
    # Field: target_language_code Type: 9 ()

# === Message: Google::Cloud::Automl::V1::Translation::TranslationAnnotation ===
    # Fields for TranslationAnnotation
    # Field: translated_content Type: 11 (.google.cloud.automl.v1.TextSnippet)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::Translation - Compiled Protocol Buffers messages for google/cloud/automl/v1/translation.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::Translation;

    my $msg = Google::Cloud::Automl::V1::Translation::TranslationDatasetMetadata->new({
        source_language_code => $source_language_code,
        target_language_code => $target_language_code,
    });

    # Read or update a field
    my $val = $msg->source_language_code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::Translation::TranslationDatasetMetadata->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/translation.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::Translation::TranslationDatasetMetadata

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

=head2 Google::Cloud::Automl::V1::Translation::TranslationEvaluationMetrics

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

=head2 Google::Cloud::Automl::V1::Translation::TranslationModelMetadata

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
The source language (The BCP-47 language code) that is used for training.

=item * C<< $msg->target_language_code() >> / C<< $msg->target_language_code($value) >>

Type: C<String>

Output only. The target language (The BCP-47 language code) that is used
for training.

=back

=head2 Google::Cloud::Automl::V1::Translation::TranslationAnnotation

Annotation details specific to translation.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->translated_content() >> / C<< $msg->translated_content($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::DataItems::TextSnippet>)

Output only . The translated content.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::Translation::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
