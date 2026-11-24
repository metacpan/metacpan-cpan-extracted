package Google::Cloud::Bigquery::Migration::V2::MigrationMetrics;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Distribution };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Metric };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyL21pZ3JhdGlvbl9tZXRyaWNz
LnByb3RvEiJnb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyGh1nb29nbGUvYXBp
L2Rpc3RyaWJ1dGlvbi5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoX
Z29vZ2xlL2FwaS9tZXRyaWMucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJv
dG8ijAIKClRpbWVTZXJpZXMSGwoGbWV0cmljGAEgASgJQgPgQQJSBm1ldHJpYxJKCgp2YWx1
ZV90eXBlGAIgASgOMiYuZ29vZ2xlLmFwaS5NZXRyaWNEZXNjcmlwdG9yLlZhbHVlVHlwZUID
4EECUgl2YWx1ZVR5cGUSTQoLbWV0cmljX2tpbmQYAyABKA4yJy5nb29nbGUuYXBpLk1ldHJp
Y0Rlc2NyaXB0b3IuTWV0cmljS2luZEID4EEBUgptZXRyaWNLaW5kEkYKBnBvaW50cxgEIAMo
CzIpLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuUG9pbnRCA+BBAlIGcG9p
bnRzIpsBCgVQb2ludBJMCghpbnRlcnZhbBgBIAEoCzIwLmdvb2dsZS5jbG91ZC5iaWdxdWVy
eS5taWdyYXRpb24udjIuVGltZUludGVydmFsUghpbnRlcnZhbBJECgV2YWx1ZRgCIAEoCzIu
Lmdvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjIuVHlwZWRWYWx1ZVIFdmFsdWUi
igEKDFRpbWVJbnRlcnZhbBI+CgpzdGFydF90aW1lGAEgASgLMhouZ29vZ2xlLnByb3RvYnVm
LlRpbWVzdGFtcEID4EEBUglzdGFydFRpbWUSOgoIZW5kX3RpbWUYAiABKAsyGi5nb29nbGUu
cHJvdG9idWYuVGltZXN0YW1wQgPgQQJSB2VuZFRpbWUi7gEKClR5cGVkVmFsdWUSHwoKYm9v
bF92YWx1ZRgBIAEoCEgAUglib29sVmFsdWUSIQoLaW50NjRfdmFsdWUYAiABKANIAFIKaW50
NjRWYWx1ZRIjCgxkb3VibGVfdmFsdWUYAyABKAFIAFILZG91YmxlVmFsdWUSIwoMc3RyaW5n
X3ZhbHVlGAQgASgJSABSC3N0cmluZ1ZhbHVlEkkKEmRpc3RyaWJ1dGlvbl92YWx1ZRgFIAEo
CzIYLmdvb2dsZS5hcGkuRGlzdHJpYnV0aW9uSABSEWRpc3RyaWJ1dGlvblZhbHVlQgcKBXZh
bHVlQtEBCiZjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52MkIVTWlncmF0
aW9uTWV0cmljc1Byb3RvUAFaRGNsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvbWlncmF0
aW9uL2FwaXYyL21pZ3JhdGlvbnBiO21pZ3JhdGlvbnBiqgIiR29vZ2xlLkNsb3VkLkJpZ1F1
ZXJ5Lk1pZ3JhdGlvbi5WMsoCIkdvb2dsZVxDbG91ZFxCaWdRdWVyeVxNaWdyYXRpb25cVjJK
gyEKBhIEDgByAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
KwoJCgIDABIDEgAnCgkKAgMBEgMTACkKCQoCAwISAxQAIQoJCgIDAxIDFQApCggKAQgSAxcA
PwoJCgIIJRIDFwA/CggKAQgSAxgAWwoJCgIICxIDGABbCggKAQgSAxkAIgoJCgIIChIDGQAi
CggKAQgSAxoANgoJCgIICBIDGgA2CggKAQgSAxsAPwoJCgIIARIDGwA/CggKAQgSAxwAQAoJ
CgIIKRIDHABACi8KAgQAEgQfADsBGiMgVGhlIG1ldHJpY3Mgb2JqZWN0IGZvciBhIFN1YlRh
c2suCgoKCgMEAAESAx8IEgp6CgQEAAIAEgMjAj0abSBSZXF1aXJlZC4gVGhlIG5hbWUgb2Yg
dGhlIG1ldHJpYy4KCiBJZiB0aGUgbWV0cmljIGlzIG5vdCBrbm93biBieSB0aGUgc2Vydmlj
ZSB5ZXQsIGl0IHdpbGwgYmUgYXV0by1jcmVhdGVkLgoKDAoFBAACAAUSAyMCCAoMCgUEAAIA
ARIDIwkPCgwKBQQAAgADEgMjEhMKDAoFBAACAAgSAyMUPAoPCggEAAIACJwIABIDIxU7CjwK
BAQAAgESBCYCJy8aLiBSZXF1aXJlZC4gVGhlIHZhbHVlIHR5cGUgb2YgdGhlIHRpbWUgc2Vy
aWVzLgoKDAoFBAACAQYSAyYCJwoMCgUEAAIBARIDJigyCgwKBQQAAgEDEgMmNTYKDAoFBAAC
AQgSAycGLgoPCggEAAIBCJwIABIDJwctCsYCCgQEAAICEgQvAjAvGrcCIE9wdGlvbmFsLiBU
aGUgbWV0cmljIGtpbmQgb2YgdGhlIHRpbWUgc2VyaWVzLgoKIElmIHByZXNlbnQsIGl0IG11
c3QgYmUgdGhlIHNhbWUgYXMgdGhlIG1ldHJpYyBraW5kIG9mIHRoZSBhc3NvY2lhdGVkCiBt
ZXRyaWMuIElmIHRoZSBhc3NvY2lhdGVkIG1ldHJpYydzIGRlc2NyaXB0b3IgbXVzdCBiZSBh
dXRvLWNyZWF0ZWQsIHRoZW4KIHRoaXMgZmllbGQgc3BlY2lmaWVzIHRoZSBtZXRyaWMga2lu
ZCBvZiB0aGUgbmV3IGRlc2NyaXB0b3IgYW5kIG11c3QgYmUKIGVpdGhlciBgR0FVR0VgICh0
aGUgZGVmYXVsdCkgb3IgYENVTVVMQVRJVkVgLgoKDAoFBAACAgYSAy8CKAoMCgUEAAICARID
Lyk0CgwKBQQAAgIDEgMvNzgKDAoFBAACAggSAzAGLgoPCggEAAICCJwIABIDMActCuQDCgQE
AAIDEgM6AkUa1gMgUmVxdWlyZWQuIFRoZSBkYXRhIHBvaW50cyBvZiB0aGlzIHRpbWUgc2Vy
aWVzLiBXaGVuIGxpc3RpbmcgdGltZSBzZXJpZXMsCiBwb2ludHMgYXJlIHJldHVybmVkIGlu
IHJldmVyc2UgdGltZSBvcmRlci4KCiBXaGVuIGNyZWF0aW5nIGEgdGltZSBzZXJpZXMsIHRo
aXMgZmllbGQgbXVzdCBjb250YWluIGV4YWN0bHkgb25lIHBvaW50IGFuZAogdGhlIHBvaW50
J3MgdHlwZSBtdXN0IGJlIHRoZSBzYW1lIGFzIHRoZSB2YWx1ZSB0eXBlIG9mIHRoZSBhc3Nv
Y2lhdGVkCiBtZXRyaWMuIElmIHRoZSBhc3NvY2lhdGVkIG1ldHJpYydzIGRlc2NyaXB0b3Ig
bXVzdCBiZSBhdXRvLWNyZWF0ZWQsIHRoZW4KIHRoZSB2YWx1ZSB0eXBlIG9mIHRoZSBkZXNj
cmlwdG9yIGlzIGRldGVybWluZWQgYnkgdGhlIHBvaW50J3MgdHlwZSwgd2hpY2gKIG11c3Qg
YmUgYEJPT0xgLCBgSU5UNjRgLCBgRE9VQkxFYCwgb3IgYERJU1RSSUJVVElPTmAuCgoMCgUE
AAIDBBIDOgIKCgwKBQQAAgMGEgM6CxAKDAoFBAACAwESAzoRFwoMCgUEAAIDAxIDOhobCgwK
BQQAAgMIEgM6HEQKDwoIBAACAwicCAASAzodQwozCgIEARIEPgBMARonIEEgc2luZ2xlIGRh
dGEgcG9pbnQgaW4gYSB0aW1lIHNlcmllcy4KCgoKAwQBARIDPggNCuoECgQEAQIAEgNIAhwa
3AQgVGhlIHRpbWUgaW50ZXJ2YWwgdG8gd2hpY2ggdGhlIGRhdGEgcG9pbnQgYXBwbGllcy4g
IEZvciBgR0FVR0VgIG1ldHJpY3MsCiB0aGUgc3RhcnQgdGltZSBkb2VzIG5vdCBuZWVkIHRv
IGJlIHN1cHBsaWVkLCBidXQgaWYgaXQgaXMgc3VwcGxpZWQsIGl0IG11c3QKIGVxdWFsIHRo
ZSBlbmQgdGltZS4gIEZvciBgREVMVEFgIG1ldHJpY3MsIHRoZSBzdGFydCBhbmQgZW5kIHRp
bWUgc2hvdWxkCiBzcGVjaWZ5IGEgbm9uLXplcm8gaW50ZXJ2YWwsIHdpdGggc3Vic2VxdWVu
dCBwb2ludHMgc3BlY2lmeWluZyBjb250aWd1b3VzCiBhbmQgbm9uLW92ZXJsYXBwaW5nIGlu
dGVydmFscy4gIEZvciBgQ1VNVUxBVElWRWAgbWV0cmljcywgdGhlIHN0YXJ0IGFuZCBlbmQK
IHRpbWUgc2hvdWxkIHNwZWNpZnkgYSBub24temVybyBpbnRlcnZhbCwgd2l0aCBzdWJzZXF1
ZW50IHBvaW50cyBzcGVjaWZ5aW5nCiB0aGUgc2FtZSBzdGFydCB0aW1lIGFuZCBpbmNyZWFz
aW5nIGVuZCB0aW1lcywgdW50aWwgYW4gZXZlbnQgcmVzZXRzIHRoZQogY3VtdWxhdGl2ZSB2
YWx1ZSB0byB6ZXJvIGFuZCBzZXRzIGEgbmV3IHN0YXJ0IHRpbWUgZm9yIHRoZSBmb2xsb3dp
bmcKIHBvaW50cy4KCgwKBQQBAgAGEgNIAg4KDAoFBAECAAESA0gPFwoMCgUEAQIAAxIDSBob
CisKBAQBAgESA0sCFxoeIFRoZSB2YWx1ZSBvZiB0aGUgZGF0YSBwb2ludC4KCgwKBQQBAgEG
EgNLAgwKDAoFBAECAQESA0sNEgoMCgUEAQIBAxIDSxUWCrsBCgIEAhIEUQBbARquASBBIHRp
bWUgaW50ZXJ2YWwgZXh0ZW5kaW5nIGp1c3QgYWZ0ZXIgYSBzdGFydCB0aW1lIHRocm91Z2gg
YW4gZW5kIHRpbWUuCiBJZiB0aGUgc3RhcnQgdGltZSBpcyB0aGUgc2FtZSBhcyB0aGUgZW5k
IHRpbWUsIHRoZW4gdGhlIGludGVydmFsCiByZXByZXNlbnRzIGEgc2luZ2xlIHBvaW50IGlu
IHRpbWUuCgoKCgMEAgESA1EIFAqrAQoEBAICABIEVQJWLxqcASBPcHRpb25hbC4gVGhlIGJl
Z2lubmluZyBvZiB0aGUgdGltZSBpbnRlcnZhbC4gIFRoZSBkZWZhdWx0IHZhbHVlCiBmb3Ig
dGhlIHN0YXJ0IHRpbWUgaXMgdGhlIGVuZCB0aW1lLiBUaGUgc3RhcnQgdGltZSBtdXN0IG5v
dCBiZQogbGF0ZXIgdGhhbiB0aGUgZW5kIHRpbWUuCgoMCgUEAgIABhIDVQIbCgwKBQQCAgAB
EgNVHCYKDAoFBAICAAMSA1UpKgoMCgUEAgIACBIDVgYuCg8KCAQCAgAInAgAEgNWBy0KNwoE
BAICARIEWQJaLxopIFJlcXVpcmVkLiBUaGUgZW5kIG9mIHRoZSB0aW1lIGludGVydmFsLgoK
DAoFBAICAQYSA1kCGwoMCgUEAgIBARIDWRwkCgwKBQQCAgEDEgNZJygKDAoFBAICAQgSA1oG
LgoPCggEAgIBCJwIABIDWgctCiwKAgQDEgReAHIBGiAgQSBzaW5nbGUgc3Ryb25nbHktdHlw
ZWQgdmFsdWUuCgoKCgMEAwESA14IEgomCgQEAwgAEgRgAnEDGhggVGhlIHR5cGVkIHZhbHVl
IGZpZWxkLgoKDAoFBAMIAAESA2AIDQoyCgQEAwIAEgNiBBgaJSBBIEJvb2xlYW4gdmFsdWU6
IGB0cnVlYCBvciBgZmFsc2VgLgoKDAoFBAMCAAUSA2IECAoMCgUEAwIAARIDYgkTCgwKBQQD
AgADEgNiFhcKSwoEBAMCARIDZQQaGj4gQSA2NC1iaXQgaW50ZWdlci4gSXRzIHJhbmdlIGlz
IGFwcHJveGltYXRlbHkgYCsvLTkuMngxMF4xOGAuCgoMCgUEAwIBBRIDZQQJCgwKBQQDAgEB
EgNlChUKDAoFBAMCAQMSA2UYGQqhAQoEBAMCAhIDagQcGpMBIEEgNjQtYml0IGRvdWJsZS1w
cmVjaXNpb24gZmxvYXRpbmctcG9pbnQgbnVtYmVyLiBJdHMgbWFnbml0dWRlCiBpcyBhcHBy
b3hpbWF0ZWx5IGArLy0xMF4oKy8tMzAwKWAgYW5kIGl0IGhhcyAxNiBzaWduaWZpY2FudCBk
aWdpdHMgb2YKIHByZWNpc2lvbi4KCgwKBQQDAgIFEgNqBAoKDAoFBAMCAgESA2oLFwoMCgUE
AwICAxIDahobCi4KBAQDAgMSA20EHBohIEEgdmFyaWFibGUtbGVuZ3RoIHN0cmluZyB2YWx1
ZS4KCgwKBQQDAgMFEgNtBAoKDAoFBAMCAwESA20LFwoMCgUEAwIDAxIDbRobCiQKBAQDAgQS
A3AEMxoXIEEgZGlzdHJpYnV0aW9uIHZhbHVlLgoKDAoFBAMCBAYSA3AEGwoMCgUEAwIEARID
cBwuCgwKBQQDAgQDEgNwMTJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::TimeSeries ===
    # Fields for TimeSeries
    # Field: metric Type: 9 ()
    # Field: value_type Type: 14 (.google.api.MetricDescriptor.ValueType)
    # Field: metric_kind Type: 14 (.google.api.MetricDescriptor.MetricKind)
    # Field: points Type: 11 (.google.cloud.bigquery.migration.v2.Point)

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::Point ===
    # Fields for Point
    # Field: interval Type: 11 (.google.cloud.bigquery.migration.v2.TimeInterval)
    # Field: value Type: 11 (.google.cloud.bigquery.migration.v2.TypedValue)

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::TimeInterval ===
    # Fields for TimeInterval
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::TypedValue ===
    # Fields for TypedValue
    # Field: bool_value Type: 8 ()
    # Field: int64_value Type: 3 ()
    # Field: double_value Type: 1 ()
    # Field: string_value Type: 9 ()
    # Field: distribution_value Type: 11 (.google.api.Distribution)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::Migration::V2::MigrationMetrics - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2/migration_metrics.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2::MigrationMetrics;

    my $msg = Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::TimeSeries->new({
        metric => $metric,
        value_type => $value_type,
        metric_kind => $metric_kind,
        points => $points,
    });

    # Read or update a field
    my $val = $msg->metric();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::TimeSeries->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2/migration_metrics.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::TimeSeries

The metrics object for a SubTask.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->metric() >> / C<< $msg->metric($value) >>

Type: C<String>

Required. The name of the metric.

If the metric is not known by the service yet, it will be auto-created.

=item * C<< $msg->value_type() >> / C<< $msg->value_type($value) >>

Type: C<Enum> (L<Google::Api::MetricDescriptor::ValueType>)

Required. The value type of the time series.

=item * C<< $msg->metric_kind() >> / C<< $msg->metric_kind($value) >>

Type: C<Enum> (L<Google::Api::MetricDescriptor::MetricKind>)

Optional. The metric kind of the time series.

If present, it must be the same as the metric kind of the associated
metric. If the associated metric's descriptor must be auto-created, then
this field specifies the metric kind of the new descriptor and must be
either `GAUGE` (the default) or `CUMULATIVE`.

=item * C<< $msg->points() >> / C<< $msg->points($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::Point>)

Required. The data points of this time series. When listing time series,
points are returned in reverse time order.

When creating a time series, this field must contain exactly one point and
the point's type must be the same as the value type of the associated
metric. If the associated metric's descriptor must be auto-created, then
the value type of the descriptor is determined by the point's type, which
must be `BOOL`, `INT64`, `DOUBLE`, or `DISTRIBUTION`.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::Point

A single data point in a time series.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->interval() >> / C<< $msg->interval($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::TimeInterval>)

The time interval to which the data point applies.  For `GAUGE` metrics,
the start time does not need to be supplied, but if it is supplied, it must
equal the end time.  For `DELTA` metrics, the start and end time should
specify a non-zero interval, with subsequent points specifying contiguous
and non-overlapping intervals.  For `CUMULATIVE` metrics, the start and end
time should specify a non-zero interval, with subsequent points specifying
the same start time and increasing end times, until an event resets the
cumulative value to zero and sets a new start time for the following
points.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::TypedValue>)

The value of the data point.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::TimeInterval

A time interval extending just after a start time through an end time.
If the start time is the same as the end time, then the interval
represents a single point in time.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->start_time() >> / C<< $msg->start_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Optional. The beginning of the time interval.  The default value
for the start time is the end time. The start time must not be
later than the end time.

=item * C<< $msg->end_time() >> / C<< $msg->end_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Required. The end of the time interval.

=back

=head2 Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::TypedValue

A single strongly-typed value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

A Boolean value: `true` or `false`.

=item * C<< $msg->int64_value() >> / C<< $msg->int64_value($value) >>

Type: C<Int64>

A 64-bit integer. Its range is approximately `+/-9.2x10^18`.

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

A 64-bit double-precision floating-point number. Its magnitude
is approximately `+/-10^(+/-300)` and it has 16 significant digits of
precision.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

A variable-length string value.

=item * C<< $msg->distribution_value() >> / C<< $msg->distribution_value($value) >>

Type: C<Message> (L<Google::Api::Distribution::Distribution>)

A distribution value.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2::MigrationMetrics::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
