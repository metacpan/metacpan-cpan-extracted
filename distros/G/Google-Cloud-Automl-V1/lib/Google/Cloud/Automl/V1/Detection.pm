package Google::Cloud::Automl::V1::Detection;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Automl::V1::Geometry };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvYXV0b21sL3YxL2RldGVjdGlvbi5wcm90bxIWZ29vZ2xlLmNsb3Vk
LmF1dG9tbC52MRolZ29vZ2xlL2Nsb3VkL2F1dG9tbC92MS9nZW9tZXRyeS5wcm90byJ/Ch5J
bWFnZU9iamVjdERldGVjdGlvbkFubm90YXRpb24SRwoMYm91bmRpbmdfYm94GAEgASgLMiQu
Z29vZ2xlLmNsb3VkLmF1dG9tbC52MS5Cb3VuZGluZ1BvbHlSC2JvdW5kaW5nQm94EhQKBXNj
b3JlGAIgASgCUgVzY29yZSKaAwoXQm91bmRpbmdCb3hNZXRyaWNzRW50cnkSIwoNaW91X3Ro
cmVzaG9sZBgBIAEoAlIMaW91VGhyZXNob2xkEjQKFm1lYW5fYXZlcmFnZV9wcmVjaXNpb24Y
AiABKAJSFG1lYW5BdmVyYWdlUHJlY2lzaW9uEoQBChpjb25maWRlbmNlX21ldHJpY3NfZW50
cmllcxgDIAMoCzJGLmdvb2dsZS5jbG91ZC5hdXRvbWwudjEuQm91bmRpbmdCb3hNZXRyaWNz
RW50cnkuQ29uZmlkZW5jZU1ldHJpY3NFbnRyeVIYY29uZmlkZW5jZU1ldHJpY3NFbnRyaWVz
GpwBChZDb25maWRlbmNlTWV0cmljc0VudHJ5EjEKFGNvbmZpZGVuY2VfdGhyZXNob2xkGAEg
ASgCUhNjb25maWRlbmNlVGhyZXNob2xkEhYKBnJlY2FsbBgCIAEoAlIGcmVjYWxsEhwKCXBy
ZWNpc2lvbhgDIAEoAlIJcHJlY2lzaW9uEhkKCGYxX3Njb3JlGAQgASgCUgdmMVNjb3JlIqgC
CiVJbWFnZU9iamVjdERldGVjdGlvbkV2YWx1YXRpb25NZXRyaWNzEj8KHGV2YWx1YXRlZF9i
b3VuZGluZ19ib3hfY291bnQYASABKAVSGWV2YWx1YXRlZEJvdW5kaW5nQm94Q291bnQScAoc
Ym91bmRpbmdfYm94X21ldHJpY3NfZW50cmllcxgCIAMoCzIvLmdvb2dsZS5jbG91ZC5hdXRv
bWwudjEuQm91bmRpbmdCb3hNZXRyaWNzRW50cnlSGWJvdW5kaW5nQm94TWV0cmljc0VudHJp
ZXMSTAojYm91bmRpbmdfYm94X21lYW5fYXZlcmFnZV9wcmVjaXNpb24YAyABKAJSH2JvdW5k
aW5nQm94TWVhbkF2ZXJhZ2VQcmVjaXNpb25CoAEKGmNvbS5nb29nbGUuY2xvdWQuYXV0b21s
LnYxUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vYXV0b21sL2FwaXYxL2F1dG9tbHBiO2F1dG9t
bHBiqgIWR29vZ2xlLkNsb3VkLkF1dG9NTC5WMcoCFkdvb2dsZVxDbG91ZFxBdXRvTWxcVjHq
AhlHb29nbGU6OkNsb3VkOjpBdXRvTUw6OlYxSocZCgYSBA4AVAEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIALwoICgEIEgMUADMKCQoC
CCUSAxQAMwoICgEIEgMVAEkKCQoCCAsSAxUASQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEI
EgMXADMKCQoCCAESAxcAMwoICgEIEgMYADMKCQoCCCkSAxgAMwoICgEIEgMZADIKCQoCCC0S
AxkAMgo8CgIEABIEHAAjARowIEFubm90YXRpb24gZGV0YWlscyBmb3IgaW1hZ2Ugb2JqZWN0
IGRldGVjdGlvbi4KCgoKAwQAARIDHAgmCksKBAQAAgASAx4CIBo+IE91dHB1dCBvbmx5LiBU
aGUgcmVjdGFuZ2xlIHJlcHJlc2VudGluZyB0aGUgb2JqZWN0IGxvY2F0aW9uLgoKDAoFBAAC
AAYSAx4CDgoMCgUEAAIAARIDHg8bCgwKBQQAAgADEgMeHh8KoQEKBAQAAgESAyICEhqTASBP
dXRwdXQgb25seS4gVGhlIGNvbmZpZGVuY2UgdGhhdCB0aGlzIGFubm90YXRpb24gaXMgcG9z
aXRpdmUgZm9yIHRoZSBwYXJlbnQgZXhhbXBsZSwKIHZhbHVlIGluIFswLCAxXSwgaGlnaGVy
IG1lYW5zIGhpZ2hlciBwb3NpdGl2aXR5IGNvbmZpZGVuY2UuCgoMCgUEAAIBBRIDIgIHCgwK
BQQAAgEBEgMiCA0KDAoFBAACAQMSAyIQEQqSAQoCBAESBCcAQgEahQEgQm91bmRpbmcgYm94
IG1hdGNoaW5nIG1vZGVsIG1ldHJpY3MgZm9yIGEgc2luZ2xlIGludGVyc2VjdGlvbi1vdmVy
LXVuaW9uCiB0aHJlc2hvbGQgYW5kIG11bHRpcGxlIGxhYmVsIG1hdGNoIGNvbmZpZGVuY2Ug
dGhyZXNob2xkcy4KCgoKAwQBARIDJwgfCjoKBAQBAwASBCkCNQMaLCBNZXRyaWNzIGZvciBh
IHNpbmdsZSBjb25maWRlbmNlIHRocmVzaG9sZC4KCgwKBQQBAwABEgMpCiAKWQoGBAEDAAIA
EgMrBCMaSiBPdXRwdXQgb25seS4gVGhlIGNvbmZpZGVuY2UgdGhyZXNob2xkIHZhbHVlIHVz
ZWQgdG8gY29tcHV0ZSB0aGUgbWV0cmljcy4KCg4KBwQBAwACAAUSAysECQoOCgcEAQMAAgAB
EgMrCh4KDgoHBAEDAAIAAxIDKyEiCkoKBgQBAwACARIDLgQVGjsgT3V0cHV0IG9ubHkuIFJl
Y2FsbCB1bmRlciB0aGUgZ2l2ZW4gY29uZmlkZW5jZSB0aHJlc2hvbGQuCgoOCgcEAQMAAgEF
EgMuBAkKDgoHBAEDAAIBARIDLgoQCg4KBwQBAwACAQMSAy4TFApNCgYEAQMAAgISAzEEGBo+
IE91dHB1dCBvbmx5LiBQcmVjaXNpb24gdW5kZXIgdGhlIGdpdmVuIGNvbmZpZGVuY2UgdGhy
ZXNob2xkLgoKDgoHBAEDAAICBRIDMQQJCg4KBwQBAwACAgESAzEKEwoOCgcEAQMAAgIDEgMx
FhcKSAoGBAEDAAIDEgM0BBcaOSBPdXRwdXQgb25seS4gVGhlIGhhcm1vbmljIG1lYW4gb2Yg
cmVjYWxsIGFuZCBwcmVjaXNpb24uCgoOCgcEAQMAAgMFEgM0BAkKDgoHBAEDAAIDARIDNAoS
Cg4KBwQBAwACAwMSAzQVFgpsCgQEAQIAEgM5AhoaXyBPdXRwdXQgb25seS4gVGhlIGludGVy
c2VjdGlvbi1vdmVyLXVuaW9uIHRocmVzaG9sZCB2YWx1ZSB1c2VkIHRvIGNvbXB1dGUKIHRo
aXMgbWV0cmljcyBlbnRyeS4KCgwKBQQBAgAFEgM5AgcKDAoFBAECAAESAzkIFQoMCgUEAQIA
AxIDORgZClMKBAQBAgESAzwCIxpGIE91dHB1dCBvbmx5LiBUaGUgbWVhbiBhdmVyYWdlIHBy
ZWNpc2lvbiwgbW9zdCBvZnRlbiBjbG9zZSB0byBhdV9wcmMuCgoMCgUEAQIBBRIDPAIHCgwK
BQQBAgEBEgM8CB4KDAoFBAECAQMSAzwhIgqqAQoEBAECAhIDQQJBGpwBIE91dHB1dCBvbmx5
LiBNZXRyaWNzIGZvciBlYWNoIGxhYmVsLW1hdGNoIGNvbmZpZGVuY2VfdGhyZXNob2xkIGZy
b20KIDAuMDUsMC4xMCwuLi4sMC45NSwwLjk2LDAuOTcsMC45OCwwLjk5LiBQcmVjaXNpb24t
cmVjYWxsIGN1cnZlIGlzCiBkZXJpdmVkIGZyb20gdGhlbS4KCgwKBQQBAgIEEgNBAgoKDAoF
BAECAgYSA0ELIQoMCgUEAQICARIDQSI8CgwKBQQBAgIDEgNBP0AKhAEKAgQCEgRGAFQBGngg
TW9kZWwgZXZhbHVhdGlvbiBtZXRyaWNzIGZvciBpbWFnZSBvYmplY3QgZGV0ZWN0aW9uIHBy
b2JsZW1zLgogRXZhbHVhdGVzIHByZWRpY3Rpb24gcXVhbGl0eSBvZiBsYWJlbGVkIGJvdW5k
aW5nIGJveGVzLgoKCgoDBAIBEgNGCC0KkwEKBAQCAgASA0kCKRqFASBPdXRwdXQgb25seS4g
VGhlIHRvdGFsIG51bWJlciBvZiBib3VuZGluZyBib3hlcyAoaS5lLiBzdW1tZWQgb3ZlciBh
bGwKIGltYWdlcykgdGhlIGdyb3VuZCB0cnV0aCB1c2VkIHRvIGNyZWF0ZSB0aGlzIGV2YWx1
YXRpb24gaGFkLgoKDAoFBAICAAUSA0kCBwoMCgUEAgIAARIDSQgkCgwKBQQCAgADEgNJJygK
4wEKBAQCAgESA08CRBrVASBPdXRwdXQgb25seS4gVGhlIGJvdW5kaW5nIGJveGVzIG1hdGNo
IG1ldHJpY3MgZm9yIGVhY2gKIEludGVyc2VjdGlvbi1vdmVyLXVuaW9uIHRocmVzaG9sZCAw
LjA1LDAuMTAsLi4uLDAuOTUsMC45NiwwLjk3LDAuOTgsMC45OQogYW5kIGVhY2ggbGFiZWwg
Y29uZmlkZW5jZSB0aHJlc2hvbGQgMC4wNSwwLjEwLC4uLiwwLjk1LDAuOTYsMC45NywwLjk4
LDAuOTkKIHBhaXIuCgoMCgUEAgIBBBIDTwIKCgwKBQQCAgEGEgNPCyIKDAoFBAICAQESA08j
PwoMCgUEAgIBAxIDT0JDCpkBCgQEAgICEgNTAjAaiwEgT3V0cHV0IG9ubHkuIFRoZSBzaW5n
bGUgbWV0cmljIGZvciBib3VuZGluZyBib3hlcyBldmFsdWF0aW9uOgogdGhlIG1lYW5fYXZl
cmFnZV9wcmVjaXNpb24gYXZlcmFnZWQgb3ZlciBhbGwgYm91bmRpbmdfYm94X21ldHJpY3Nf
ZW50cmllcy4KCgwKBQQCAgIFEgNTAgcKDAoFBAICAgESA1MIKwoMCgUEAgICAxIDUy4vYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::Detection::ImageObjectDetectionAnnotation ===
    # Fields for ImageObjectDetectionAnnotation
    # Field: bounding_box Type: 11 (.google.cloud.automl.v1.BoundingPoly)
    # Field: score Type: 2 ()

# === Message: Google::Cloud::Automl::V1::Detection::BoundingBoxMetricsEntry ===
    # Fields for BoundingBoxMetricsEntry
    # Field: iou_threshold Type: 2 ()
    # Field: mean_average_precision Type: 2 ()
    # Field: confidence_metrics_entries Type: 11 (.google.cloud.automl.v1.BoundingBoxMetricsEntry.ConfidenceMetricsEntry)

# === Message: Google::Cloud::Automl::V1::Detection::ImageObjectDetectionEvaluationMetrics ===
    # Fields for ImageObjectDetectionEvaluationMetrics
    # Field: evaluated_bounding_box_count Type: 5 ()
    # Field: bounding_box_metrics_entries Type: 11 (.google.cloud.automl.v1.BoundingBoxMetricsEntry)
    # Field: bounding_box_mean_average_precision Type: 2 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::Detection - Compiled Protocol Buffers messages for google/cloud/automl/v1/detection.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::Detection;

    my $msg = Google::Cloud::Automl::V1::Detection::ImageObjectDetectionAnnotation->new({
        bounding_box => $bounding_box,
        score => $score,
    });

    # Read or update a field
    my $val = $msg->bounding_box();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::Detection::ImageObjectDetectionAnnotation->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/detection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::Detection::ImageObjectDetectionAnnotation

Annotation details for image object detection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bounding_box() >> / C<< $msg->bounding_box($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Geometry::BoundingPoly>)

Output only. The rectangle representing the object location.

=item * C<< $msg->score() >> / C<< $msg->score($value) >>

Type: C<Float>

Output only. The confidence that this annotation is positive for the parent example,
value in [0, 1], higher means higher positivity confidence.

=back

=head2 Google::Cloud::Automl::V1::Detection::BoundingBoxMetricsEntry

Bounding box matching model metrics for a single intersection-over-union
threshold and multiple label match confidence thresholds.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->iou_threshold() >> / C<< $msg->iou_threshold($value) >>

Type: C<Float>

Output only. The intersection-over-union threshold value used to compute
this metrics entry.

=item * C<< $msg->mean_average_precision() >> / C<< $msg->mean_average_precision($value) >>

Type: C<Float>

Output only. The mean average precision, most often close to au_prc.

=item * C<< $msg->confidence_metrics_entries() >> / C<< $msg->confidence_metrics_entries($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Detection::BoundingBoxMetricsEntry::ConfidenceMetricsEntry>)

Output only. Metrics for each label-match confidence_threshold from
0.05,0.10,...,0.95,0.96,0.97,0.98,0.99. Precision-recall curve is
derived from them.

=back

=head2 Google::Cloud::Automl::V1::Detection::ImageObjectDetectionEvaluationMetrics

Model evaluation metrics for image object detection problems.
Evaluates prediction quality of labeled bounding boxes.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->evaluated_bounding_box_count() >> / C<< $msg->evaluated_bounding_box_count($value) >>

Type: C<Int32>

Output only. The total number of bounding boxes (i.e. summed over all
images) the ground truth used to create this evaluation had.

=item * C<< $msg->bounding_box_metrics_entries() >> / C<< $msg->bounding_box_metrics_entries($value) >>

Type: C<Message> (L<Google::Cloud::Automl::V1::Detection::BoundingBoxMetricsEntry>)

Output only. The bounding boxes match metrics for each
Intersection-over-union threshold 0.05,0.10,...,0.95,0.96,0.97,0.98,0.99
and each label confidence threshold 0.05,0.10,...,0.95,0.96,0.97,0.98,0.99
pair.

=item * C<< $msg->bounding_box_mean_average_precision() >> / C<< $msg->bounding_box_mean_average_precision($value) >>

Type: C<Float>

Output only. The single metric for bounding boxes evaluation:
the mean_average_precision averaged over all bounding_box_metrics_entries.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::Detection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
