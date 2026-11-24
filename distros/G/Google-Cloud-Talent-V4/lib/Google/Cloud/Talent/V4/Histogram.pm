package Google::Cloud::Talent::V4::Histogram;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvdGFsZW50L3Y0L2hpc3RvZ3JhbS5wcm90bxIWZ29vZ2xlLmNsb3Vk
LnRhbGVudC52NCI5Cg5IaXN0b2dyYW1RdWVyeRInCg9oaXN0b2dyYW1fcXVlcnkYASABKAlS
Dmhpc3RvZ3JhbVF1ZXJ5ItgBChRIaXN0b2dyYW1RdWVyeVJlc3VsdBInCg9oaXN0b2dyYW1f
cXVlcnkYASABKAlSDmhpc3RvZ3JhbVF1ZXJ5ElkKCWhpc3RvZ3JhbRgCIAMoCzI7Lmdvb2ds
ZS5jbG91ZC50YWxlbnQudjQuSGlzdG9ncmFtUXVlcnlSZXN1bHQuSGlzdG9ncmFtRW50cnlS
CWhpc3RvZ3JhbRo8Cg5IaXN0b2dyYW1FbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1
ZRgCIAEoA1IFdmFsdWU6AjgBQmgKGmNvbS5nb29nbGUuY2xvdWQudGFsZW50LnY0Qg5IaXN0
b2dyYW1Qcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL3RhbGVudC9hcGl2NC90YWxlbnRw
Yjt0YWxlbnRwYqICA0NUU0r4DQoGEgQOADUBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAfCggKAQgSAxIASQoJCgIICxIDEgBJCggKAQgSAxMAIgoJCgII
ChIDEwAiCggKAQgSAxQALwoJCgIICBIDFAAvCggKAQgSAxUAMwoJCgIIARIDFQAzCggKAQgS
AxYAIQoJCgIIJBIDFgAhCiQKAgQAEgQZACEBGhggVGhlIGhpc3RvZ3JhbSByZXF1ZXN0LgoK
CgoDBAABEgMZCBYK5AEKBAQAAgASAyACHRrWASBBbiBleHByZXNzaW9uIHNwZWNpZmllcyBh
IGhpc3RvZ3JhbSByZXF1ZXN0IGFnYWluc3QgbWF0Y2hpbmcgam9icyBmb3IKIHNlYXJjaGVz
LgoKIFNlZQogW1NlYXJjaEpvYnNSZXF1ZXN0Lmhpc3RvZ3JhbV9xdWVyaWVzXVtnb29nbGUu
Y2xvdWQudGFsZW50LnY0LlNlYXJjaEpvYnNSZXF1ZXN0Lmhpc3RvZ3JhbV9xdWVyaWVzXQog
Zm9yIGRldGFpbHMgYWJvdXQgc3ludGF4LgoKDAoFBAACAAUSAyACCAoMCgUEAAIAARIDIAkY
CgwKBQQAAgADEgMgGxwKfAoCBAESBCYANQEacCBIaXN0b2dyYW0gcmVzdWx0IHRoYXQgbWF0
Y2hlcwogW0hpc3RvZ3JhbVF1ZXJ5XVtnb29nbGUuY2xvdWQudGFsZW50LnY0Lkhpc3RvZ3Jh
bVF1ZXJ5XSBzcGVjaWZpZWQgaW4KIHNlYXJjaGVzLgoKCgoDBAEBEgMmCBwKLgoEBAECABID
KAIdGiEgUmVxdWVzdGVkIGhpc3RvZ3JhbSBleHByZXNzaW9uLgoKDAoFBAECAAUSAygCCAoM
CgUEAQIAARIDKAkYCgwKBQQBAgADEgMoGxwK6gMKBAQBAgESAzQCIxrcAyBBIG1hcCBmcm9t
IHRoZSB2YWx1ZXMgb2YgdGhlIGZhY2V0IGFzc29jaWF0ZWQgd2l0aCBkaXN0aW5jdCB2YWx1
ZXMgdG8gdGhlCiBudW1iZXIgb2YgbWF0Y2hpbmcgZW50cmllcyB3aXRoIGNvcnJlc3BvbmRp
bmcgdmFsdWUuCgogVGhlIGtleSBmb3JtYXQgaXM6CgogKiAoZm9yIHN0cmluZyBoaXN0b2dy
YW0pIHN0cmluZyB2YWx1ZXMgc3RvcmVkIGluIHRoZSBmaWVsZC4KICogKGZvciBuYW1lZCBu
dW1lcmljIGJ1Y2tldCkgbmFtZSBzcGVjaWZpZWQgaW4gYGJ1Y2tldCgpYCBmdW5jdGlvbiwg
bGlrZQogICBmb3IgYGJ1Y2tldCgwLCBNQVgsICJub24tbmVnYXRpdmUiKWAsIHRoZSBrZXkg
d2lsbCBiZSBgbm9uLW5lZ2F0aXZlYC4KICogKGZvciBhbm9ueW1vdXMgbnVtZXJpYyBidWNr
ZXQpIHJhbmdlIGZvcm1hdHRlZCBhcyBgPGxvdz4tPGhpZ2g+YCwgZm9yCiAgIGV4YW1wbGUs
IGAwLTEwMDBgLCBgTUlOLTBgLCBhbmQgYDAtTUFYYC4KCgwKBQQBAgEGEgM0AhQKDAoFBAEC
AQESAzQVHgoMCgUEAQIBAxIDNCEiYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Talent::V4::Histogram::HistogramQuery ===
    # Fields for HistogramQuery
    # Field: histogram_query Type: 9 ()

# === Message: Google::Cloud::Talent::V4::Histogram::HistogramQueryResult ===
    # Fields for HistogramQueryResult
    # Field: histogram_query Type: 9 ()
    # Field: histogram Type: 11 (.google.cloud.talent.v4.HistogramQueryResult.HistogramEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Talent::V4::Histogram - Compiled Protocol Buffers messages for google/cloud/talent/v4/histogram.proto

=head1 SYNOPSIS

    use Google::Cloud::Talent::V4::Histogram;

    my $msg = Google::Cloud::Talent::V4::Histogram::HistogramQuery->new({
        histogram_query => $histogram_query,
    });

    # Read or update a field
    my $val = $msg->histogram_query();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Talent::V4::Histogram::HistogramQuery->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/talent/v4/histogram.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Talent::V4::Histogram::HistogramQuery

The histogram request.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->histogram_query() >> / C<< $msg->histogram_query($value) >>

Type: C<String>

An expression specifies a histogram request against matching jobs for
searches.

See
[SearchJobsRequest.histogram_queries][google.cloud.talent.v4.SearchJobsRequest.histogram_queries]
for details about syntax.

=back

=head2 Google::Cloud::Talent::V4::Histogram::HistogramQueryResult

Histogram result that matches
[HistogramQuery][google.cloud.talent.v4.HistogramQuery] specified in
searches.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->histogram_query() >> / C<< $msg->histogram_query($value) >>

Type: C<String>

Requested histogram expression.

=item * C<< $msg->histogram() >> / C<< $msg->histogram($value) >>

Type: C<Message> (L<Google::Cloud::Talent::V4::Histogram::HistogramQueryResult::HistogramEntry>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Talent::V4::Histogram::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
