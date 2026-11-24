package Google::Cloud::Automl::V1beta1::TextExtraction;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1beta1::TextSegment };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvYXV0b21sL3YxYmV0YTEvdGV4dF9leHRyYWN0aW9uLnByb3RvEhtn
b29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEaLmdvb2dsZS9jbG91ZC9hdXRvbWwvdjFiZXRh
MS90ZXh0X3NlZ21lbnQucHJvdG8ijQEKGFRleHRFeHRyYWN0aW9uQW5ub3RhdGlvbhJNCgx0
ZXh0X3NlZ21lbnQYAyABKAsyKC5nb29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTEuVGV4dFNl
Z21lbnRIAFILdGV4dFNlZ21lbnQSFAoFc2NvcmUYASABKAJSBXNjb3JlQgwKCmFubm90YXRp
b24i6wIKH1RleHRFeHRyYWN0aW9uRXZhbHVhdGlvbk1ldHJpY3MSFQoGYXVfcHJjGAEgASgC
UgVhdVByYxKRAQoaY29uZmlkZW5jZV9tZXRyaWNzX2VudHJpZXMYAiADKAsyUy5nb29nbGUu
Y2xvdWQuYXV0b21sLnYxYmV0YTEuVGV4dEV4dHJhY3Rpb25FdmFsdWF0aW9uTWV0cmljcy5D
b25maWRlbmNlTWV0cmljc0VudHJ5Uhhjb25maWRlbmNlTWV0cmljc0VudHJpZXManAEKFkNv
bmZpZGVuY2VNZXRyaWNzRW50cnkSMQoUY29uZmlkZW5jZV90aHJlc2hvbGQYASABKAJSE2Nv
bmZpZGVuY2VUaHJlc2hvbGQSFgoGcmVjYWxsGAMgASgCUgZyZWNhbGwSHAoJcHJlY2lzaW9u
GAQgASgCUglwcmVjaXNpb24SGQoIZjFfc2NvcmUYBSABKAJSB2YxU2NvcmVCmwEKH2NvbS5n
b29nbGUuY2xvdWQuYXV0b21sLnYxYmV0YTFQAVo3Y2xvdWQuZ29vZ2xlLmNvbS9nby9hdXRv
bWwvYXBpdjFiZXRhMS9hdXRvbWxwYjthdXRvbWxwYsoCG0dvb2dsZVxDbG91ZFxBdXRvTWxc
VjFiZXRhMeoCHkdvb2dsZTo6Q2xvdWQ6OkF1dG9NTDo6VjFiZXRhMUqUEgoGEgQOAEIBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAkCgkKAgMAEgMSADgK
CAoBCBIDFABOCgkKAggLEgMUAE4KCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgA4CgkK
AggBEgMWADgKCAoBCBIDFwA4CgkKAggpEgMXADgKCAoBCBIDGAA3CgkKAggtEgMYADcKNwoC
BAASBBsAJwEaKyBBbm5vdGF0aW9uIGZvciBpZGVudGlmeWluZyBzcGFucyBvZiB0ZXh0LgoK
CgoDBAABEgMbCCAKZwoEBAAIABIEHgIiAxpZIFJlcXVpcmVkLiBUZXh0IGV4dHJhY3Rpb24g
YW5ub3RhdGlvbnMgY2FuIGVpdGhlciBiZSBhIHRleHQgc2VnbWVudCBvciBhCiB0ZXh0IHJl
bGF0aW9uLgoKDAoFBAAIAAESAx4IEgp8CgQEAAIAEgMhBCEabyBBbiBlbnRpdHkgYW5ub3Rh
dGlvbiB3aWxsIHNldCB0aGlzLCB3aGljaCBpcyB0aGUgcGFydCBvZiB0aGUgb3JpZ2luYWwK
IHRleHQgdG8gd2hpY2ggdGhlIGFubm90YXRpb24gcGVydGFpbnMuCgoMCgUEAAIABhIDIQQP
CgwKBQQAAgABEgMhEBwKDAoFBAACAAMSAyEfIAqSAQoEBAACARIDJgISGoQBIE91dHB1dCBv
bmx5LiBBIGNvbmZpZGVuY2UgZXN0aW1hdGUgYmV0d2VlbiAwLjAgYW5kIDEuMC4gQSBoaWdo
ZXIgdmFsdWUKIG1lYW5zIGdyZWF0ZXIgY29uZmlkZW5jZSBpbiBjb3JyZWN0bmVzcyBvZiB0
aGUgYW5ub3RhdGlvbi4KCgwKBQQAAgEFEgMmAgcKDAoFBAACAQESAyYIDQoMCgUEAAIBAxID
JhARCkQKAgQBEgQqAEIBGjggTW9kZWwgZXZhbHVhdGlvbiBtZXRyaWNzIGZvciB0ZXh0IGV4
dHJhY3Rpb24gcHJvYmxlbXMuCgoKCgMEAQESAyoIJwo6CgQEAQMAEgQsAjoDGiwgTWV0cmlj
cyBmb3IgYSBzaW5nbGUgY29uZmlkZW5jZSB0aHJlc2hvbGQuCgoMCgUEAQMAARIDLAogCsUB
CgYEAQMAAgASAzAEIxq1ASBPdXRwdXQgb25seS4gVGhlIGNvbmZpZGVuY2UgdGhyZXNob2xk
IHZhbHVlIHVzZWQgdG8gY29tcHV0ZSB0aGUgbWV0cmljcy4KIE9ubHkgYW5ub3RhdGlvbnMg
d2l0aCBzY29yZSBvZiBhdCBsZWFzdCB0aGlzIHRocmVzaG9sZCBhcmUgY29uc2lkZXJlZCB0
bwogYmUgb25lcyB0aGUgbW9kZWwgd291bGQgcmV0dXJuLgoKDgoHBAEDAAIABRIDMAQJCg4K
BwQBAwACAAESAzAKHgoOCgcEAQMAAgADEgMwISIKSgoGBAEDAAIBEgMzBBUaOyBPdXRwdXQg
b25seS4gUmVjYWxsIHVuZGVyIHRoZSBnaXZlbiBjb25maWRlbmNlIHRocmVzaG9sZC4KCg4K
BwQBAwACAQUSAzMECQoOCgcEAQMAAgEBEgMzChAKDgoHBAEDAAIBAxIDMxMUCk0KBgQBAwAC
AhIDNgQYGj4gT3V0cHV0IG9ubHkuIFByZWNpc2lvbiB1bmRlciB0aGUgZ2l2ZW4gY29uZmlk
ZW5jZSB0aHJlc2hvbGQuCgoOCgcEAQMAAgIFEgM2BAkKDgoHBAEDAAICARIDNgoTCg4KBwQB
AwACAgMSAzYWFwpICgYEAQMAAgMSAzkEFxo5IE91dHB1dCBvbmx5LiBUaGUgaGFybW9uaWMg
bWVhbiBvZiByZWNhbGwgYW5kIHByZWNpc2lvbi4KCg4KBwQBAwACAwUSAzkECQoOCgcEAQMA
AgMBEgM5ChIKDgoHBAEDAAIDAxIDORUWCkkKBAQBAgASAz0CExo8IE91dHB1dCBvbmx5LiBU
aGUgQXJlYSB1bmRlciBwcmVjaXNpb24gcmVjYWxsIGN1cnZlIG1ldHJpYy4KCgwKBQQBAgAF
EgM9AgcKDAoFBAECAAESAz0IDgoMCgUEAQIAAxIDPRESCnQKBAQBAgESA0ECQRpnIE91dHB1
dCBvbmx5LiBNZXRyaWNzIHRoYXQgaGF2ZSBjb25maWRlbmNlIHRocmVzaG9sZHMuCiBQcmVj
aXNpb24tcmVjYWxsIGN1cnZlIGNhbiBiZSBkZXJpdmVkIGZyb20gaXQuCgoMCgUEAQIBBBID
QQIKCgwKBQQBAgEGEgNBCyEKDAoFBAECAQESA0EiPAoMCgUEAQIBAxIDQT9AYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1beta1::TextExtraction::TextExtractionAnnotation ===
    # Fields for TextExtractionAnnotation
    # Field: text_segment Type: 11 (.google.cloud.automl.v1beta1.TextSegment)
    # Field: score Type: 2 ()

# === Message: Google::Cloud::Automl::V1beta1::TextExtraction::TextExtractionEvaluationMetrics ===
    # Fields for TextExtractionEvaluationMetrics
    # Field: au_prc Type: 2 ()
    # Field: confidence_metrics_entries Type: 11 (.google.cloud.automl.v1beta1.TextExtractionEvaluationMetrics.ConfidenceMetricsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1beta1::TextExtraction - Compiled Protocol Buffers messages for google/cloud/automl/v1beta1/text_extraction.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1beta1::TextExtraction;

    my $msg = Google::Cloud::Automl::V1beta1::TextExtraction::TextExtractionAnnotation->new({
        text_segment => $text_segment,
        score => $score,
    });

    # Read or update a field
    my $val = $msg->text_segment();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1beta1::TextExtraction::TextExtractionAnnotation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1beta1/text_extraction.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1beta1::TextExtraction::TextExtractionAnnotation

Annotation for identifying spans of text.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text_segment() >> / C<< $msg->text_segment($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::TextSegment::TextSegment>)

An entity annotation will set this, which is the part of the original
text to which the annotation pertains.

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Float>

Output only. A confidence estimate between 0.0 and 1.0. A higher value
means greater confidence in correctness of the annotation.

=back

=head2 Google::Cloud::Automl::V1beta1::TextExtraction::TextExtractionEvaluationMetrics

Model evaluation metrics for text extraction problems.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->au_prc() >> / C<< $msg->au_prc($value) >>

Type: C<Float>

Output only. The Area under precision recall curve metric.

=item * C<< $msg->confidence_metrics_entries() >> / C<< $msg->confidence_metrics_entries($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1beta1::TextExtraction::TextExtractionEvaluationMetrics::ConfidenceMetricsEntry>)

Output only. Metrics that have confidence thresholds.
Precision-recall curve can be derived from it.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1beta1::TextExtraction::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
