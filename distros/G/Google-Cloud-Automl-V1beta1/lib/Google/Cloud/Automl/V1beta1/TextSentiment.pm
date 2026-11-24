package Google::Cloud::Automl::V1beta1::TextSentiment;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1beta1::Classification };
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdGV4dF9zZW50aW1lbnQucHJvdG8SG2dv
b2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMRowZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MWJldGEx
L2NsYXNzaWZpY2F0aW9uLnByb3RvIjcKF1RleHRTZW50aW1lbnRBbm5vdGF0aW9uEhwKCXNl
bnRpbWVudBgBIAEoBVIJc2VudGltZW50IsYDCh5UZXh0U2VudGltZW50RXZhbHVhdGlvbk1l
dHJpY3MSHAoJcHJlY2lzaW9uGAEgASgCUglwcmVjaXNpb24SFgoGcmVjYWxsGAIgASgCUgZy
ZWNhbGwSGQoIZjFfc2NvcmUYAyABKAJSB2YxU2NvcmUSLgoTbWVhbl9hYnNvbHV0ZV9lcnJv
chgEIAEoAlIRbWVhbkFic29sdXRlRXJyb3ISLAoSbWVhbl9zcXVhcmVkX2Vycm9yGAUgASgC
UhBtZWFuU3F1YXJlZEVycm9yEiEKDGxpbmVhcl9rYXBwYRgGIAEoAlILbGluZWFyS2FwcGES
JwoPcXVhZHJhdGljX2thcHBhGAcgASgCUg5xdWFkcmF0aWNLYXBwYRJ3ChBjb25mdXNpb25f
bWF0cml4GAggASgLMkwuZ29vZ2xlLmNsb3VkLmF1dG9tbC52MWJldGExLkNsYXNzaWZpY2F0
aW9uRXZhbHVhdGlvbk1ldHJpY3MuQ29uZnVzaW9uTWF0cml4Ug9jb25mdXNpb25NYXRyaXgS
MAoSYW5ub3RhdGlvbl9zcGVjX2lkGAkgAygJQgIYAVIQYW5ub3RhdGlvblNwZWNJZEKtAQof
Y29tLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFiZXRhMUISVGV4dFNlbnRpbWVudFByb3RvWjdj
bG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MWJldGExL2F1dG9tbHBiO2F1dG9tbHBi
ygIbR29vZ2xlXENsb3VkXEF1dG9NbFxWMWJldGEx6gIeR29vZ2xlOjpDbG91ZDo6QXV0b01M
OjpWMWJldGExSr4YCgYSBA4ATgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACQKCQoCAwASAxIAOgoICgEIEgMUAE4KCQoCCAsSAxQATgoICgEIEgMVADMK
CQoCCAgSAxUAMwoICgEIEgMWADgKCQoCCAESAxYAOAoICgEIEgMXADgKCQoCCCkSAxcAOAoI
CgEIEgMYADcKCQoCCC0SAxgANwpFCgIEABIEGwApARo5IENvbnRhaW5zIGFubm90YXRpb24g
ZGV0YWlscyBzcGVjaWZpYyB0byB0ZXh0IHNlbnRpbWVudC4KCgoKAwQAARIDGwgfCq0GCgQE
AAIAEgMoAhYanwYgT3V0cHV0IG9ubHkuIFRoZSBzZW50aW1lbnQgd2l0aCB0aGUgc2VtYW50
aWMsIGFzIGdpdmVuIHRvIHRoZQogW0F1dG9NbC5JbXBvcnREYXRhXVtnb29nbGUuY2xvdWQu
YXV0b21sLnYxYmV0YTEuQXV0b01sLkltcG9ydERhdGFdIHdoZW4gcG9wdWxhdGluZyB0aGUg
ZGF0YXNldCBmcm9tIHdoaWNoIHRoZSBtb2RlbCB1c2VkCiBmb3IgdGhlIHByZWRpY3Rpb24g
aGFkIGJlZW4gdHJhaW5lZC4KIFRoZSBzZW50aW1lbnQgdmFsdWVzIGFyZSBiZXR3ZWVuIDAg
YW5kCiBEYXRhc2V0LnRleHRfc2VudGltZW50X2RhdGFzZXRfbWV0YWRhdGEuc2VudGltZW50
X21heCAoaW5jbHVzaXZlKSwKIHdpdGggaGlnaGVyIHZhbHVlIG1lYW5pbmcgbW9yZSBwb3Np
dGl2ZSBzZW50aW1lbnQuIFRoZXkgYXJlIGNvbXBsZXRlbHkKIHJlbGF0aXZlLCBpLmUuIDAg
bWVhbnMgbGVhc3QgcG9zaXRpdmUgc2VudGltZW50IGFuZCBzZW50aW1lbnRfbWF4IG1lYW5z
CiB0aGUgbW9zdCBwb3NpdGl2ZSBmcm9tIHRoZSBzZW50aW1lbnRzIHByZXNlbnQgaW4gdGhl
IHRyYWluIGRhdGEuIFRoZXJlZm9yZQogIGUuZy4gaWYgdHJhaW4gZGF0YSBoYWQgb25seSBu
ZWdhdGl2ZSBzZW50aW1lbnQsIHRoZW4gc2VudGltZW50X21heCwgd291bGQKIGJlIHN0aWxs
IG5lZ2F0aXZlIChhbHRob3VnaCBsZWFzdCBuZWdhdGl2ZSkuCiBUaGUgc2VudGltZW50IHNo
b3VsZG4ndCBiZSBjb25mdXNlZCB3aXRoICJzY29yZSIgb3IgIm1hZ25pdHVkZSIKIGZyb20g
dGhlIHByZXZpb3VzIE5hdHVyYWwgTGFuZ3VhZ2UgU2VudGltZW50IEFuYWx5c2lzIEFQSS4K
CgwKBQQAAgAFEgMoAgcKDAoFBAACAAESAygIEQoMCgUEAAIAAxIDKBQVCkMKAgQBEgQsAE4B
GjcgTW9kZWwgZXZhbHVhdGlvbiBtZXRyaWNzIGZvciB0ZXh0IHNlbnRpbWVudCBwcm9ibGVt
cy4KCgoKAwQBARIDLAgmCiYKBAQBAgASAy4CFhoZIE91dHB1dCBvbmx5LiBQcmVjaXNpb24u
CgoMCgUEAQIABRIDLgIHCgwKBQQBAgABEgMuCBEKDAoFBAECAAMSAy4UFQojCgQEAQIBEgMx
AhMaFiBPdXRwdXQgb25seS4gUmVjYWxsLgoKDAoFBAECAQUSAzECBwoMCgUEAQIBARIDMQgO
CgwKBQQBAgEDEgMxERIKRgoEBAECAhIDNAIVGjkgT3V0cHV0IG9ubHkuIFRoZSBoYXJtb25p
YyBtZWFuIG9mIHJlY2FsbCBhbmQgcHJlY2lzaW9uLgoKDAoFBAECAgUSAzQCBwoMCgUEAQIC
ARIDNAgQCgwKBQQBAgIDEgM0ExQKjAEKBAQBAgMSAzgCIBp/IE91dHB1dCBvbmx5LiBNZWFu
IGFic29sdXRlIGVycm9yLiBPbmx5IHNldCBmb3IgdGhlIG92ZXJhbGwgbW9kZWwKIGV2YWx1
YXRpb24sIG5vdCBmb3IgZXZhbHVhdGlvbiBvZiBhIHNpbmdsZSBhbm5vdGF0aW9uIHNwZWMu
CgoMCgUEAQIDBRIDOAIHCgwKBQQBAgMBEgM4CBsKDAoFBAECAwMSAzgeHwqLAQoEBAECBBID
PAIfGn4gT3V0cHV0IG9ubHkuIE1lYW4gc3F1YXJlZCBlcnJvci4gT25seSBzZXQgZm9yIHRo
ZSBvdmVyYWxsIG1vZGVsCiBldmFsdWF0aW9uLCBub3QgZm9yIGV2YWx1YXRpb24gb2YgYSBz
aW5nbGUgYW5ub3RhdGlvbiBzcGVjLgoKDAoFBAECBAUSAzwCBwoMCgUEAQIEARIDPAgaCgwK
BQQBAgQDEgM8HR4KjwEKBAQBAgUSA0ACGRqBASBPdXRwdXQgb25seS4gTGluZWFyIHdlaWdo
dGVkIGthcHBhLiBPbmx5IHNldCBmb3IgdGhlIG92ZXJhbGwgbW9kZWwKIGV2YWx1YXRpb24s
IG5vdCBmb3IgZXZhbHVhdGlvbiBvZiBhIHNpbmdsZSBhbm5vdGF0aW9uIHNwZWMuCgoMCgUE
AQIFBRIDQAIHCgwKBQQBAgUBEgNACBQKDAoFBAECBQMSA0AXGAqSAQoEBAECBhIDRAIcGoQB
IE91dHB1dCBvbmx5LiBRdWFkcmF0aWMgd2VpZ2h0ZWQga2FwcGEuIE9ubHkgc2V0IGZvciB0
aGUgb3ZlcmFsbCBtb2RlbAogZXZhbHVhdGlvbiwgbm90IGZvciBldmFsdWF0aW9uIG9mIGEg
c2luZ2xlIGFubm90YXRpb24gc3BlYy4KCgwKBQQBAgYFEgNEAgcKDAoFBAECBgESA0QIFwoM
CgUEAQIGAxIDRBobCp0BCgQEAQIHEgNJAkcajwEgT3V0cHV0IG9ubHkuIENvbmZ1c2lvbiBt
YXRyaXggb2YgdGhlIGV2YWx1YXRpb24uCiBPbmx5IHNldCBmb3IgdGhlIG92ZXJhbGwgbW9k
ZWwgZXZhbHVhdGlvbiwgbm90IGZvciBldmFsdWF0aW9uIG9mIGEgc2luZ2xlCiBhbm5vdGF0
aW9uIHNwZWMuCgoMCgUEAQIHBhIDSQIxCgwKBQQBAgcBEgNJMkIKDAoFBAECBwMSA0lFRgpb
CgQEAQIIEgNNAj0aTiBPdXRwdXQgb25seS4gVGhlIGFubm90YXRpb24gc3BlYyBpZHMgdXNl
ZCBmb3IgdGhpcyBldmFsdWF0aW9uLgogRGVwcmVjYXRlZCAuCgoMCgUEAQIIBBIDTQIKCgwK
BQQBAggFEgNNCxEKDAoFBAECCAESA00SJAoMCgUEAQIIAxIDTScoCgwKBQQBAggIEgNNKTwK
DQoGBAECCAgDEgNNKjtiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentAnnotation ===
    # Fields for TextSentimentAnnotation
    # Field: sentiment Type: 5 ()

# === Message: Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentEvaluationMetrics ===
    # Fields for TextSentimentEvaluationMetrics
    # Field: precision Type: 2 ()
    # Field: recall Type: 2 ()
    # Field: f1_score Type: 2 ()
    # Field: mean_absolute_error Type: 2 ()
    # Field: mean_squared_error Type: 2 ()
    # Field: linear_kappa Type: 2 ()
    # Field: quadratic_kappa Type: 2 ()
    # Field: confusion_matrix Type: 11 (.google.cloud.automl.v1beta1.ClassificationEvaluationMetrics.ConfusionMatrix)
    # Field: annotation_spec_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::TextSentiment - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/text_sentiment.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::TextSentiment;

    my $msg = Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentAnnotation->new({
        sentiment => $sentiment,
    });

    # Read or update a field
    my $val = $msg->sentiment();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentAnnotation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/text_sentiment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentAnnotation

Contains annotation details specific to text sentiment.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sentiment() >> / C<< $msg->sentiment($value) >>

Type: C<Int32>

Output only. The sentiment with the semantic, as given to the
[AutoMl.ImportData][google.cloud.automl.v1beta1.AutoMl.ImportData] when populating the dataset from which the model used
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

=head2 Google::Cloud::Automl::V1beta1::TextSentiment::TextSentimentEvaluationMetrics

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

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::Classification::ClassificationEvaluationMetrics::ConfusionMatrix>)

Output only. Confusion matrix of the evaluation.
Only set for the overall model evaluation, not for evaluation of a single
annotation spec.

=item * C<< $msg->annotation_spec_id() >> / C<< $msg->annotation_spec_id($value) >>

Type: C<String>

Output only. The annotation spec ids used for this evaluation.
Deprecated .

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::TextSentiment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
