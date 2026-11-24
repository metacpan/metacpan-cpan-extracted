package Google::Cloud::Automl::V1::TextSentiment;

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
Citnb29nbGUvY2xvdWQvYXV0b21sL3YxL3RleHRfc2VudGltZW50LnByb3RvEhZnb29nbGUu
Y2xvdWQuYXV0b21sLnYxGitnb29nbGUvY2xvdWQvYXV0b21sL3YxL2NsYXNzaWZpY2F0aW9u
LnByb3RvIjcKF1RleHRTZW50aW1lbnRBbm5vdGF0aW9uEhwKCXNlbnRpbWVudBgBIAEoBVIJ
c2VudGltZW50Io8DCh5UZXh0U2VudGltZW50RXZhbHVhdGlvbk1ldHJpY3MSHAoJcHJlY2lz
aW9uGAEgASgCUglwcmVjaXNpb24SFgoGcmVjYWxsGAIgASgCUgZyZWNhbGwSGQoIZjFfc2Nv
cmUYAyABKAJSB2YxU2NvcmUSLgoTbWVhbl9hYnNvbHV0ZV9lcnJvchgEIAEoAlIRbWVhbkFi
c29sdXRlRXJyb3ISLAoSbWVhbl9zcXVhcmVkX2Vycm9yGAUgASgCUhBtZWFuU3F1YXJlZEVy
cm9yEiEKDGxpbmVhcl9rYXBwYRgGIAEoAlILbGluZWFyS2FwcGESJwoPcXVhZHJhdGljX2th
cHBhGAcgASgCUg5xdWFkcmF0aWNLYXBwYRJyChBjb25mdXNpb25fbWF0cml4GAggASgLMkcu
Z29vZ2xlLmNsb3VkLmF1dG9tbC52MS5DbGFzc2lmaWNhdGlvbkV2YWx1YXRpb25NZXRyaWNz
LkNvbmZ1c2lvbk1hdHJpeFIPY29uZnVzaW9uTWF0cml4QrQBChpjb20uZ29vZ2xlLmNsb3Vk
LmF1dG9tbC52MUISVGV4dFNlbnRpbWVudFByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28v
YXV0b21sL2FwaXYxL2F1dG9tbHBiO2F1dG9tbHBiqgIWR29vZ2xlLkNsb3VkLkF1dG9NTC5W
McoCFkdvb2dsZVxDbG91ZFxBdXRvTWxcVjHqAhlHb29nbGU6OkNsb3VkOjpBdXRvTUw6OlYx
SrEXCgYSBA4ATAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgog
TGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJM
aWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlh
bmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExp
Y2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0Ut
Mi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBp
biB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMg
ZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBP
UiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgog
U2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBl
cm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQ
AB8KCQoCAwASAxIANQoICgEIEgMUADMKCQoCCCUSAxQAMwoICgEIEgMVAEkKCQoCCAsSAxUA
SQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADMKCQoCCAgSAxcAMwoICgEIEgMYADMK
CQoCCAESAxgAMwoICgEIEgMZADMKCQoCCCkSAxkAMwoICgEIEgMaADIKCQoCCC0SAxoAMgpF
CgIEABIEHQArARo5IENvbnRhaW5zIGFubm90YXRpb24gZGV0YWlscyBzcGVjaWZpYyB0byB0
ZXh0IHNlbnRpbWVudC4KCgoKAwQAARIDHQgfCqgGCgQEAAIAEgMqAhYamgYgT3V0cHV0IG9u
bHkuIFRoZSBzZW50aW1lbnQgd2l0aCB0aGUgc2VtYW50aWMsIGFzIGdpdmVuIHRvIHRoZQog
W0F1dG9NbC5JbXBvcnREYXRhXVtnb29nbGUuY2xvdWQuYXV0b21sLnYxLkF1dG9NbC5JbXBv
cnREYXRhXSB3aGVuIHBvcHVsYXRpbmcgdGhlIGRhdGFzZXQgZnJvbSB3aGljaCB0aGUgbW9k
ZWwgdXNlZAogZm9yIHRoZSBwcmVkaWN0aW9uIGhhZCBiZWVuIHRyYWluZWQuCiBUaGUgc2Vu
dGltZW50IHZhbHVlcyBhcmUgYmV0d2VlbiAwIGFuZAogRGF0YXNldC50ZXh0X3NlbnRpbWVu
dF9kYXRhc2V0X21ldGFkYXRhLnNlbnRpbWVudF9tYXggKGluY2x1c2l2ZSksCiB3aXRoIGhp
Z2hlciB2YWx1ZSBtZWFuaW5nIG1vcmUgcG9zaXRpdmUgc2VudGltZW50LiBUaGV5IGFyZSBj
b21wbGV0ZWx5CiByZWxhdGl2ZSwgaS5lLiAwIG1lYW5zIGxlYXN0IHBvc2l0aXZlIHNlbnRp
bWVudCBhbmQgc2VudGltZW50X21heCBtZWFucwogdGhlIG1vc3QgcG9zaXRpdmUgZnJvbSB0
aGUgc2VudGltZW50cyBwcmVzZW50IGluIHRoZSB0cmFpbiBkYXRhLiBUaGVyZWZvcmUKICBl
LmcuIGlmIHRyYWluIGRhdGEgaGFkIG9ubHkgbmVnYXRpdmUgc2VudGltZW50LCB0aGVuIHNl
bnRpbWVudF9tYXgsIHdvdWxkCiBiZSBzdGlsbCBuZWdhdGl2ZSAoYWx0aG91Z2ggbGVhc3Qg
bmVnYXRpdmUpLgogVGhlIHNlbnRpbWVudCBzaG91bGRuJ3QgYmUgY29uZnVzZWQgd2l0aCAi
c2NvcmUiIG9yICJtYWduaXR1ZGUiCiBmcm9tIHRoZSBwcmV2aW91cyBOYXR1cmFsIExhbmd1
YWdlIFNlbnRpbWVudCBBbmFseXNpcyBBUEkuCgoMCgUEAAIABRIDKgIHCgwKBQQAAgABEgMq
CBEKDAoFBAACAAMSAyoUFQpDCgIEARIELgBMARo3IE1vZGVsIGV2YWx1YXRpb24gbWV0cmlj
cyBmb3IgdGV4dCBzZW50aW1lbnQgcHJvYmxlbXMuCgoKCgMEAQESAy4IJgomCgQEAQIAEgMw
AhYaGSBPdXRwdXQgb25seS4gUHJlY2lzaW9uLgoKDAoFBAECAAUSAzACBwoMCgUEAQIAARID
MAgRCgwKBQQBAgADEgMwFBUKIwoEBAECARIDMwITGhYgT3V0cHV0IG9ubHkuIFJlY2FsbC4K
CgwKBQQBAgEFEgMzAgcKDAoFBAECAQESAzMIDgoMCgUEAQIBAxIDMxESCkYKBAQBAgISAzYC
FRo5IE91dHB1dCBvbmx5LiBUaGUgaGFybW9uaWMgbWVhbiBvZiByZWNhbGwgYW5kIHByZWNp
c2lvbi4KCgwKBQQBAgIFEgM2AgcKDAoFBAECAgESAzYIEAoMCgUEAQICAxIDNhMUCowBCgQE
AQIDEgM6AiAafyBPdXRwdXQgb25seS4gTWVhbiBhYnNvbHV0ZSBlcnJvci4gT25seSBzZXQg
Zm9yIHRoZSBvdmVyYWxsIG1vZGVsCiBldmFsdWF0aW9uLCBub3QgZm9yIGV2YWx1YXRpb24g
b2YgYSBzaW5nbGUgYW5ub3RhdGlvbiBzcGVjLgoKDAoFBAECAwUSAzoCBwoMCgUEAQIDARID
OggbCgwKBQQBAgMDEgM6Hh8KiwEKBAQBAgQSAz4CHxp+IE91dHB1dCBvbmx5LiBNZWFuIHNx
dWFyZWQgZXJyb3IuIE9ubHkgc2V0IGZvciB0aGUgb3ZlcmFsbCBtb2RlbAogZXZhbHVhdGlv
biwgbm90IGZvciBldmFsdWF0aW9uIG9mIGEgc2luZ2xlIGFubm90YXRpb24gc3BlYy4KCgwK
BQQBAgQFEgM+AgcKDAoFBAECBAESAz4IGgoMCgUEAQIEAxIDPh0eCo8BCgQEAQIFEgNCAhka
gQEgT3V0cHV0IG9ubHkuIExpbmVhciB3ZWlnaHRlZCBrYXBwYS4gT25seSBzZXQgZm9yIHRo
ZSBvdmVyYWxsIG1vZGVsCiBldmFsdWF0aW9uLCBub3QgZm9yIGV2YWx1YXRpb24gb2YgYSBz
aW5nbGUgYW5ub3RhdGlvbiBzcGVjLgoKDAoFBAECBQUSA0ICBwoMCgUEAQIFARIDQggUCgwK
BQQBAgUDEgNCFxgKkgEKBAQBAgYSA0YCHBqEASBPdXRwdXQgb25seS4gUXVhZHJhdGljIHdl
aWdodGVkIGthcHBhLiBPbmx5IHNldCBmb3IgdGhlIG92ZXJhbGwgbW9kZWwKIGV2YWx1YXRp
b24sIG5vdCBmb3IgZXZhbHVhdGlvbiBvZiBhIHNpbmdsZSBhbm5vdGF0aW9uIHNwZWMuCgoM
CgUEAQIGBRIDRgIHCgwKBQQBAgYBEgNGCBcKDAoFBAECBgMSA0YaGwqdAQoEBAECBxIDSwJH
Go8BIE91dHB1dCBvbmx5LiBDb25mdXNpb24gbWF0cml4IG9mIHRoZSBldmFsdWF0aW9uLgog
T25seSBzZXQgZm9yIHRoZSBvdmVyYWxsIG1vZGVsIGV2YWx1YXRpb24sIG5vdCBmb3IgZXZh
bHVhdGlvbiBvZiBhIHNpbmdsZQogYW5ub3RhdGlvbiBzcGVjLgoKDAoFBAECBwYSA0sCMQoM
CgUEAQIHARIDSzJCCgwKBQQBAgcDEgNLRUZiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::TextSentiment::TextSentimentAnnotation ===
    # Fields for TextSentimentAnnotation
    # Field: sentiment Type: 5 ()

# === Message: Google::Cloud::Automl::V1::TextSentiment::TextSentimentEvaluationMetrics ===
    # Fields for TextSentimentEvaluationMetrics
    # Field: precision Type: 2 ()
    # Field: recall Type: 2 ()
    # Field: f1_score Type: 2 ()
    # Field: mean_absolute_error Type: 2 ()
    # Field: mean_squared_error Type: 2 ()
    # Field: linear_kappa Type: 2 ()
    # Field: quadratic_kappa Type: 2 ()
    # Field: confusion_matrix Type: 11 (.google.cloud.automl.v1.ClassificationEvaluationMetrics.ConfusionMatrix)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::TextSentiment - Compiled Protocol Buffers messages for google/cloud/automl/v1/text_sentiment.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::TextSentiment;

    my $msg = Google::Cloud::Automl::V1::TextSentiment::TextSentimentAnnotation->new({
        sentiment => $sentiment,
    });

    # Read or update a field
    my $val = $msg->sentiment();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::TextSentiment::TextSentimentAnnotation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/text_sentiment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::TextSentiment::TextSentimentAnnotation

Contains annotation details specific to text sentiment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sentiment() >> / C<< $msg->sentiment($value) >>

Type: C<Int32>

Output only. The sentiment with the semantic, as given to the
[AutoMl.ImportData][google.cloud.automl.v1.AutoMl.ImportData] when populating the dataset from which the model used
for the prediction had been trained.
The sentiment values are between 0 and
Dataset.text_sentiment_dataset_metadata.sentiment_max (inclusive),
with higher value meaning more positive sentiment. They are completely
relative, i.e. 0 means least positive sentiment and sentiment_max means
the most positive from the sentiments present in the train data. Therefore
 e.g. if train data had only negative sentiment, then sentiment_max, would
be still negative (although least negative).
The sentiment shouldn't be confused with "score" or "magnitude"
from the previous Natural Language Sentiment Analysis API.

=back

=head2 Google::Cloud::Automl::V1::TextSentiment::TextSentimentEvaluationMetrics

Model evaluation metrics for text sentiment problems.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->precision() >> / C<< $msg->precision($value) >>

Type: C<Float>

Output only. Precision.

=item * C<< $msg->recall() >> / C<< $msg->recall($value) >>

Type: C<Float>

Output only. Recall.

=item * C<< $msg->f1_score() >> / C<< $msg->f1_score($value) >>

Type: C<Float>

Output only. The harmonic mean of recall and precision.

=item * C<< $msg->mean_absolute_error() >> / C<< $msg->mean_absolute_error($value) >>

Type: C<Float>

Output only. Mean absolute error. Only set for the overall model
evaluation, not for evaluation of a single annotation spec.

=item * C<< $msg->mean_squared_error() >> / C<< $msg->mean_squared_error($value) >>

Type: C<Float>

Output only. Mean squared error. Only set for the overall model
evaluation, not for evaluation of a single annotation spec.

=item * C<< $msg->linear_kappa() >> / C<< $msg->linear_kappa($value) >>

Type: C<Float>

Output only. Linear weighted kappa. Only set for the overall model
evaluation, not for evaluation of a single annotation spec.

=item * C<< $msg->quadratic_kappa() >> / C<< $msg->quadratic_kappa($value) >>

Type: C<Float>

Output only. Quadratic weighted kappa. Only set for the overall model
evaluation, not for evaluation of a single annotation spec.

=item * C<< $msg->confusion_matrix() >> / C<< $msg->confusion_matrix($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Classification::ClassificationEvaluationMetrics::ConfusionMatrix>)

Output only. Confusion matrix of the evaluation.
Only set for the overall model evaluation, not for evaluation of a single
annotation spec.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::TextSentiment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
