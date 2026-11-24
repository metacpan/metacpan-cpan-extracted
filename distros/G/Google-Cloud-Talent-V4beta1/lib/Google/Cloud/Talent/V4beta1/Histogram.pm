package Google::Cloud::Talent::V4beta1::Histogram;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvdGFsZW50L3Y0YmV0YTEvaGlzdG9ncmFtLnByb3RvEhtnb29nbGUu
Y2xvdWQudGFsZW50LnY0YmV0YTEiOQoOSGlzdG9ncmFtUXVlcnkSJwoPaGlzdG9ncmFtX3F1
ZXJ5GAEgASgJUg5oaXN0b2dyYW1RdWVyeSLdAQoUSGlzdG9ncmFtUXVlcnlSZXN1bHQSJwoP
aGlzdG9ncmFtX3F1ZXJ5GAEgASgJUg5oaXN0b2dyYW1RdWVyeRJeCgloaXN0b2dyYW0YAiAD
KAsyQC5nb29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuSGlzdG9ncmFtUXVlcnlSZXN1bHQu
SGlzdG9ncmFtRW50cnlSCWhpc3RvZ3JhbRo8Cg5IaXN0b2dyYW1FbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoA1IFdmFsdWU6AjgBQnIKH2NvbS5nb29nbGUuY2xvdWQu
dGFsZW50LnY0YmV0YTFCDkhpc3RvZ3JhbVByb3RvUAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28v
dGFsZW50L2FwaXY0YmV0YTEvdGFsZW50cGI7dGFsZW50cGKiAgNDVFNKmw8KBhIEDgA3AQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoICgEIEgMSAE4K
CQoCCAsSAxIATgoICgEIEgMTACIKCQoCCAoSAxMAIgoICgEIEgMUAC8KCQoCCAgSAxQALwoI
CgEIEgMVADgKCQoCCAESAxUAOAoICgEIEgMWACEKCQoCCCQSAxYAIQokCgIEABIEGQAjARoY
IFRoZSBoaXN0b2dyYW0gcmVxdWVzdC4KCgoKAwQAARIDGQgWCoEDCgQEAAIAEgMiAh0a8wIg
QW4gZXhwcmVzc2lvbiBzcGVjaWZpZXMgYSBoaXN0b2dyYW0gcmVxdWVzdCBhZ2FpbnN0IG1h
dGNoaW5nIHJlc291cmNlcwogKGZvciBleGFtcGxlLCBqb2JzLCBwcm9maWxlcykgZm9yIHNl
YXJjaGVzLgoKIFNlZQogW1NlYXJjaEpvYnNSZXF1ZXN0Lmhpc3RvZ3JhbV9xdWVyaWVzXVtn
b29nbGUuY2xvdWQudGFsZW50LnY0YmV0YTEuU2VhcmNoSm9ic1JlcXVlc3QuaGlzdG9ncmFt
X3F1ZXJpZXNdCiBhbmQKIFtTZWFyY2hQcm9maWxlc1JlcXVlc3QuaGlzdG9ncmFtX3F1ZXJp
ZXNdW2dvb2dsZS5jbG91ZC50YWxlbnQudjRiZXRhMS5TZWFyY2hQcm9maWxlc1JlcXVlc3Qu
aGlzdG9ncmFtX3F1ZXJpZXNdCiBmb3IgZGV0YWlscyBhYm91dCBzeW50YXguCgoMCgUEAAIA
BRIDIgIICgwKBQQAAgABEgMiCRgKDAoFBAACAAMSAyIbHAqBAQoCBAESBCgANwEadSBIaXN0
b2dyYW0gcmVzdWx0IHRoYXQgbWF0Y2hlcwogW0hpc3RvZ3JhbVF1ZXJ5XVtnb29nbGUuY2xv
dWQudGFsZW50LnY0YmV0YTEuSGlzdG9ncmFtUXVlcnldIHNwZWNpZmllZCBpbgogc2VhcmNo
ZXMuCgoKCgMEAQESAygIHAouCgQEAQIAEgMqAh0aISBSZXF1ZXN0ZWQgaGlzdG9ncmFtIGV4
cHJlc3Npb24uCgoMCgUEAQIABRIDKgIICgwKBQQBAgABEgMqCRgKDAoFBAECAAMSAyobHArq
AwoEBAECARIDNgIjGtwDIEEgbWFwIGZyb20gdGhlIHZhbHVlcyBvZiB0aGUgZmFjZXQgYXNz
b2NpYXRlZCB3aXRoIGRpc3RpbmN0IHZhbHVlcyB0byB0aGUKIG51bWJlciBvZiBtYXRjaGlu
ZyBlbnRyaWVzIHdpdGggY29ycmVzcG9uZGluZyB2YWx1ZS4KCiBUaGUga2V5IGZvcm1hdCBp
czoKCiAqIChmb3Igc3RyaW5nIGhpc3RvZ3JhbSkgc3RyaW5nIHZhbHVlcyBzdG9yZWQgaW4g
dGhlIGZpZWxkLgogKiAoZm9yIG5hbWVkIG51bWVyaWMgYnVja2V0KSBuYW1lIHNwZWNpZmll
ZCBpbiBgYnVja2V0KClgIGZ1bmN0aW9uLCBsaWtlCiAgIGZvciBgYnVja2V0KDAsIE1BWCwg
Im5vbi1uZWdhdGl2ZSIpYCwgdGhlIGtleSB3aWxsIGJlIGBub24tbmVnYXRpdmVgLgogKiAo
Zm9yIGFub255bW91cyBudW1lcmljIGJ1Y2tldCkgcmFuZ2UgZm9ybWF0dGVkIGFzIGA8bG93
Pi08aGlnaD5gLCBmb3IKICAgZXhhbXBsZSwgYDAtMTAwMGAsIGBNSU4tMGAsIGFuZCBgMC1N
QVhgLgoKDAoFBAECAQYSAzYCFAoMCgUEAQIBARIDNhUeCgwKBQQBAgEDEgM2ISJiBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4beta1::Histogram::HistogramQuery ===
    # Fields for HistogramQuery
    # Field: histogram_query Type: 9 ()

# === Message: Google::Cloud::Talent::V4beta1::Histogram::HistogramQueryResult ===
    # Fields for HistogramQueryResult
    # Field: histogram_query Type: 9 ()
    # Field: histogram Type: 11 (.google.cloud.talent.v4beta1.HistogramQueryResult.HistogramEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4beta1::Histogram - Compiled Protocol Buffers messages for google/cloud/talent/v4beta1/histogram.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4beta1::Histogram;

    my $msg = Google::Cloud::Talent::V4beta1::Histogram::HistogramQuery->new({
        histogram_query => $histogram_query,
    });

    # Read or update a field
    my $val = $msg->histogram_query();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4beta1::Histogram::HistogramQuery->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4beta1/histogram.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4beta1::Histogram::HistogramQuery

The histogram request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->histogram_query() >> / C<< $msg->histogram_query($value) >>

Type: C<String>

An expression specifies a histogram request against matching resources
(for example, jobs, profiles) for searches.

See
[SearchJobsRequest.histogram_queries][google.cloud.talent.v4beta1.SearchJobsRequest.histogram_queries]
and
[SearchProfilesRequest.histogram_queries][google.cloud.talent.v4beta1.SearchProfilesRequest.histogram_queries]
for details about syntax.

=back

=head2 Google::Cloud::Talent::V4beta1::Histogram::HistogramQueryResult

Histogram result that matches
[HistogramQuery][google.cloud.talent.v4beta1.HistogramQuery] specified in
searches.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->histogram_query() >> / C<< $msg->histogram_query($value) >>

Type: C<String>

Requested histogram expression.

=item * C<< $msg->histogram() >> / C<< $msg->histogram($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4beta1::Histogram::HistogramQueryResult::HistogramEntry>)

A map from the values of the facet associated with distinct values to the
number of matching entries with corresponding value.

The key format is:

* (for string histogram) string values stored in the field.
* (for named numeric bucket) name specified in `bucket()` function, like
  for `bucket(0, MAX, "non-negative")`, the key will be `non-negative`.
* (for anonymous numeric bucket) range formatted as `<low>-<high>`, for
  example, `0-1000`, `MIN-0`, and `0-MAX`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4beta1::Histogram::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
