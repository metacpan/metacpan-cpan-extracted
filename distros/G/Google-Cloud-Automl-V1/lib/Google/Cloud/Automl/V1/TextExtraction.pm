package Google::Cloud::Automl::V1::TextExtraction;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1::TextSegment };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvY2xvdWQvYXV0b21sL3YxL3RleHRfZXh0cmFjdGlvbi5wcm90bxIWZ29vZ2xl
LmNsb3VkLmF1dG9tbC52MRopZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MS90ZXh0X3NlZ21lbnQu
cHJvdG8iiAEKGFRleHRFeHRyYWN0aW9uQW5ub3RhdGlvbhJICgx0ZXh0X3NlZ21lbnQYAyAB
KAsyIy5nb29nbGUuY2xvdWQuYXV0b21sLnYxLlRleHRTZWdtZW50SABSC3RleHRTZWdtZW50
EhQKBXNjb3JlGAEgASgCUgVzY29yZUIMCgphbm5vdGF0aW9uIuYCCh9UZXh0RXh0cmFjdGlv
bkV2YWx1YXRpb25NZXRyaWNzEhUKBmF1X3ByYxgBIAEoAlIFYXVQcmMSjAEKGmNvbmZpZGVu
Y2VfbWV0cmljc19lbnRyaWVzGAIgAygLMk4uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MS5UZXh0
RXh0cmFjdGlvbkV2YWx1YXRpb25NZXRyaWNzLkNvbmZpZGVuY2VNZXRyaWNzRW50cnlSGGNv
bmZpZGVuY2VNZXRyaWNzRW50cmllcxqcAQoWQ29uZmlkZW5jZU1ldHJpY3NFbnRyeRIxChRj
b25maWRlbmNlX3RocmVzaG9sZBgBIAEoAlITY29uZmlkZW5jZVRocmVzaG9sZBIWCgZyZWNh
bGwYAyABKAJSBnJlY2FsbBIcCglwcmVjaXNpb24YBCABKAJSCXByZWNpc2lvbhIZCghmMV9z
Y29yZRgFIAEoAlIHZjFTY29yZUKgAQoaY29tLmdvb2dsZS5jbG91ZC5hdXRvbWwudjFQAVoy
Y2xvdWQuZ29vZ2xlLmNvbS9nby9hdXRvbWwvYXBpdjEvYXV0b21scGI7YXV0b21scGKqAhZH
b29nbGUuQ2xvdWQuQXV0b01MLlYxygIWR29vZ2xlXENsb3VkXEF1dG9NbFxWMeoCGUdvb2ds
ZTo6Q2xvdWQ6OkF1dG9NTDo6VjFKqRIKBhIEDgBDAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
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
aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgAzCggKAQgSAxQAMwoJCgIIJRIDFAAz
CggKAQgSAxUASQoJCgIICxIDFQBJCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAMwoJ
CgIIARIDFwAzCggKAQgSAxgAMwoJCgIIKRIDGAAzCggKAQgSAxkAMgoJCgIILRIDGQAyCjcK
AgQAEgQcACgBGisgQW5ub3RhdGlvbiBmb3IgaWRlbnRpZnlpbmcgc3BhbnMgb2YgdGV4dC4K
CgoKAwQAARIDHAggCmcKBAQACAASBB8CIwMaWSBSZXF1aXJlZC4gVGV4dCBleHRyYWN0aW9u
IGFubm90YXRpb25zIGNhbiBlaXRoZXIgYmUgYSB0ZXh0IHNlZ21lbnQgb3IgYQogdGV4dCBy
ZWxhdGlvbi4KCgwKBQQACAABEgMfCBIKfAoEBAACABIDIgQhGm8gQW4gZW50aXR5IGFubm90
YXRpb24gd2lsbCBzZXQgdGhpcywgd2hpY2ggaXMgdGhlIHBhcnQgb2YgdGhlIG9yaWdpbmFs
CiB0ZXh0IHRvIHdoaWNoIHRoZSBhbm5vdGF0aW9uIHBlcnRhaW5zLgoKDAoFBAACAAYSAyIE
DwoMCgUEAAIAARIDIhAcCgwKBQQAAgADEgMiHyAKkgEKBAQAAgESAycCEhqEASBPdXRwdXQg
b25seS4gQSBjb25maWRlbmNlIGVzdGltYXRlIGJldHdlZW4gMC4wIGFuZCAxLjAuIEEgaGln
aGVyIHZhbHVlCiBtZWFucyBncmVhdGVyIGNvbmZpZGVuY2UgaW4gY29ycmVjdG5lc3Mgb2Yg
dGhlIGFubm90YXRpb24uCgoMCgUEAAIBBRIDJwIHCgwKBQQAAgEBEgMnCA0KDAoFBAACAQMS
AycQEQpECgIEARIEKwBDARo4IE1vZGVsIGV2YWx1YXRpb24gbWV0cmljcyBmb3IgdGV4dCBl
eHRyYWN0aW9uIHByb2JsZW1zLgoKCgoDBAEBEgMrCCcKOgoEBAEDABIELQI7AxosIE1ldHJp
Y3MgZm9yIGEgc2luZ2xlIGNvbmZpZGVuY2UgdGhyZXNob2xkLgoKDAoFBAEDAAESAy0KIArF
AQoGBAEDAAIAEgMxBCMatQEgT3V0cHV0IG9ubHkuIFRoZSBjb25maWRlbmNlIHRocmVzaG9s
ZCB2YWx1ZSB1c2VkIHRvIGNvbXB1dGUgdGhlIG1ldHJpY3MuCiBPbmx5IGFubm90YXRpb25z
IHdpdGggc2NvcmUgb2YgYXQgbGVhc3QgdGhpcyB0aHJlc2hvbGQgYXJlIGNvbnNpZGVyZWQg
dG8KIGJlIG9uZXMgdGhlIG1vZGVsIHdvdWxkIHJldHVybi4KCg4KBwQBAwACAAUSAzEECQoO
CgcEAQMAAgABEgMxCh4KDgoHBAEDAAIAAxIDMSEiCkoKBgQBAwACARIDNAQVGjsgT3V0cHV0
IG9ubHkuIFJlY2FsbCB1bmRlciB0aGUgZ2l2ZW4gY29uZmlkZW5jZSB0aHJlc2hvbGQuCgoO
CgcEAQMAAgEFEgM0BAkKDgoHBAEDAAIBARIDNAoQCg4KBwQBAwACAQMSAzQTFApNCgYEAQMA
AgISAzcEGBo+IE91dHB1dCBvbmx5LiBQcmVjaXNpb24gdW5kZXIgdGhlIGdpdmVuIGNvbmZp
ZGVuY2UgdGhyZXNob2xkLgoKDgoHBAEDAAICBRIDNwQJCg4KBwQBAwACAgESAzcKEwoOCgcE
AQMAAgIDEgM3FhcKSAoGBAEDAAIDEgM6BBcaOSBPdXRwdXQgb25seS4gVGhlIGhhcm1vbmlj
IG1lYW4gb2YgcmVjYWxsIGFuZCBwcmVjaXNpb24uCgoOCgcEAQMAAgMFEgM6BAkKDgoHBAED
AAIDARIDOgoSCg4KBwQBAwACAwMSAzoVFgpJCgQEAQIAEgM+AhMaPCBPdXRwdXQgb25seS4g
VGhlIEFyZWEgdW5kZXIgcHJlY2lzaW9uIHJlY2FsbCBjdXJ2ZSBtZXRyaWMuCgoMCgUEAQIA
BRIDPgIHCgwKBQQBAgABEgM+CA4KDAoFBAECAAMSAz4REgp0CgQEAQIBEgNCAkEaZyBPdXRw
dXQgb25seS4gTWV0cmljcyB0aGF0IGhhdmUgY29uZmlkZW5jZSB0aHJlc2hvbGRzLgogUHJl
Y2lzaW9uLXJlY2FsbCBjdXJ2ZSBjYW4gYmUgZGVyaXZlZCBmcm9tIGl0LgoKDAoFBAECAQQS
A0ICCgoMCgUEAQIBBhIDQgshCgwKBQQBAgEBEgNCIjwKDAoFBAECAQMSA0I/QGIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::TextExtraction::TextExtractionAnnotation ===
    # Fields for TextExtractionAnnotation
    # Field: text_segment Type: 11 (.google.cloud.automl.v1.TextSegment)
    # Field: score Type: 2 ()

# === Message: Google::Cloud::Automl::V1::TextExtraction::TextExtractionEvaluationMetrics ===
    # Fields for TextExtractionEvaluationMetrics
    # Field: au_prc Type: 2 ()
    # Field: confidence_metrics_entries Type: 11 (.google.cloud.automl.v1.TextExtractionEvaluationMetrics.ConfidenceMetricsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::TextExtraction - Compiled Protocol Buffers messages for google/cloud/automl/v1/text_extraction.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::TextExtraction;

    my $msg = Google::Cloud::Automl::V1::TextExtraction::TextExtractionAnnotation->new({
        text_segment => $text_segment,
        score => $score,
    });

    # Read or update a field
    my $val = $msg->text_segment();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::TextExtraction::TextExtractionAnnotation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/text_extraction.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::TextExtraction::TextExtractionAnnotation

Annotation for identifying spans of text.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->text_segment() >> / C<< $msg->text_segment($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::TextSegment::TextSegment>)

An entity annotation will set this, which is the part of the original
text to which the annotation pertains.

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Float>

Output only. A confidence estimate between 0.0 and 1.0. A higher value
means greater confidence in correctness of the annotation.

=back

=head2 Google::Cloud::Automl::V1::TextExtraction::TextExtractionEvaluationMetrics

Model evaluation metrics for text extraction problems.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->au_prc() >> / C<< $msg->au_prc($value) >>

Type: C<Float>

Output only. The Area under precision recall curve metric.

=item * C<< $msg->confidence_metrics_entries() >> / C<< $msg->confidence_metrics_entries($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::TextExtraction::TextExtractionEvaluationMetrics::ConfidenceMetricsEntry>)

Output only. Metrics that have confidence thresholds.
Precision-recall curve can be derived from it.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::TextExtraction::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
