package Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics;

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
Cj9nb29nbGUvY2xvdWQvYmlncXVlcnkvbWlncmF0aW9uL3YyYWxwaGEvbWlncmF0aW9uX21l
dHJpY3MucHJvdG8SJ2dvb2dsZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjJhbHBoYRod
Z29vZ2xlL2FwaS9kaXN0cmlidXRpb24ucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aF2dvb2dsZS9hcGkvbWV0cmljLnByb3RvGh9nb29nbGUvcHJvdG9idWYvdGlt
ZXN0YW1wLnByb3RvIpECCgpUaW1lU2VyaWVzEhsKBm1ldHJpYxgBIAEoCUID4EECUgZtZXRy
aWMSSgoKdmFsdWVfdHlwZRgCIAEoDjImLmdvb2dsZS5hcGkuTWV0cmljRGVzY3JpcHRvci5W
YWx1ZVR5cGVCA+BBAlIJdmFsdWVUeXBlEk0KC21ldHJpY19raW5kGAMgASgOMicuZ29vZ2xl
LmFwaS5NZXRyaWNEZXNjcmlwdG9yLk1ldHJpY0tpbmRCA+BBAVIKbWV0cmljS2luZBJLCgZw
b2ludHMYBCADKAsyLi5nb29nbGUuY2xvdWQuYmlncXVlcnkubWlncmF0aW9uLnYyYWxwaGEu
UG9pbnRCA+BBAlIGcG9pbnRzIqUBCgVQb2ludBJRCghpbnRlcnZhbBgBIAEoCzI1Lmdvb2ds
ZS5jbG91ZC5iaWdxdWVyeS5taWdyYXRpb24udjJhbHBoYS5UaW1lSW50ZXJ2YWxSCGludGVy
dmFsEkkKBXZhbHVlGAIgASgLMjMuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5Lm1pZ3JhdGlvbi52
MmFscGhhLlR5cGVkVmFsdWVSBXZhbHVlIooBCgxUaW1lSW50ZXJ2YWwSPgoKc3RhcnRfdGlt
ZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBAVIJc3RhcnRUaW1lEjoK
CGVuZF90aW1lGAIgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EECUgdlbmRU
aW1lIu4BCgpUeXBlZFZhbHVlEh8KCmJvb2xfdmFsdWUYASABKAhIAFIJYm9vbFZhbHVlEiEK
C2ludDY0X3ZhbHVlGAIgASgDSABSCmludDY0VmFsdWUSIwoMZG91YmxlX3ZhbHVlGAMgASgB
SABSC2RvdWJsZVZhbHVlEiMKDHN0cmluZ192YWx1ZRgEIAEoCUgAUgtzdHJpbmdWYWx1ZRJJ
ChJkaXN0cmlidXRpb25fdmFsdWUYBSABKAsyGC5nb29nbGUuYXBpLkRpc3RyaWJ1dGlvbkgA
UhFkaXN0cmlidXRpb25WYWx1ZUIHCgV2YWx1ZULlAQorY29tLmdvb2dsZS5jbG91ZC5iaWdx
dWVyeS5taWdyYXRpb24udjJhbHBoYUIVTWlncmF0aW9uTWV0cmljc1Byb3RvUAFaSWNsb3Vk
Lmdvb2dsZS5jb20vZ28vYmlncXVlcnkvbWlncmF0aW9uL2FwaXYyYWxwaGEvbWlncmF0aW9u
cGI7bWlncmF0aW9ucGKqAidHb29nbGUuQ2xvdWQuQmlnUXVlcnkuTWlncmF0aW9uLlYyQWxw
aGHKAidHb29nbGVcQ2xvdWRcQmlnUXVlcnlcTWlncmF0aW9uXFYyYWxwaGFK+yAKBhIEDgBu
AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1
bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsK
IHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0
aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoK
ICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxl
c3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcs
IHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRl
ZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElP
TlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExp
Y2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMg
YW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMAoJCgIDABID
EgAnCgkKAgMBEgMTACkKCQoCAwISAxQAIQoJCgIDAxIDFQApCggKAQgSAxcARAoJCgIIJRID
FwBECggKAQgSAxgAYAoJCgIICxIDGABgCggKAQgSAxkAIgoJCgIIChIDGQAiCggKAQgSAxoA
NgoJCgIICBIDGgA2CggKAQgSAxsARAoJCgIIARIDGwBECggKAQgSAxwARQoJCgIIKRIDHABF
Ci8KAgQAEgQfADkBGiMgVGhlIG1ldHJpY3Mgb2JqZWN0IGZvciBhIFN1YlRhc2suCgoKCgME
AAESAx8IEgp6CgQEAAIAEgMjAj0abSBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIG1ldHJp
Yy4KCiBJZiB0aGUgbWV0cmljIGlzIG5vdCBrbm93biBieSB0aGUgc2VydmljZSB5ZXQsIGl0
IHdpbGwgYmUgYXV0by1jcmVhdGVkLgoKDAoFBAACAAUSAyMCCAoMCgUEAAIAARIDIwkPCgwK
BQQAAgADEgMjEhMKDAoFBAACAAgSAyMUPAoPCggEAAIACJwIABIDIxU7CjsKBAQAAgESAyYC
YBouIFJlcXVpcmVkLiBUaGUgdmFsdWUgdHlwZSBvZiB0aGUgdGltZSBzZXJpZXMuCgoMCgUE
AAIBBhIDJgInCgwKBQQAAgEBEgMmKDIKDAoFBAACAQMSAyY1NgoMCgUEAAIBCBIDJjdfCg8K
CAQAAgEInAgAEgMmOF4KxQIKBAQAAgISAy4CYhq3AiBPcHRpb25hbC4gVGhlIG1ldHJpYyBr
aW5kIG9mIHRoZSB0aW1lIHNlcmllcy4KCiBJZiBwcmVzZW50LCBpdCBtdXN0IGJlIHRoZSBz
YW1lIGFzIHRoZSBtZXRyaWMga2luZCBvZiB0aGUgYXNzb2NpYXRlZAogbWV0cmljLiBJZiB0
aGUgYXNzb2NpYXRlZCBtZXRyaWMncyBkZXNjcmlwdG9yIG11c3QgYmUgYXV0by1jcmVhdGVk
LCB0aGVuCiB0aGlzIGZpZWxkIHNwZWNpZmllcyB0aGUgbWV0cmljIGtpbmQgb2YgdGhlIG5l
dyBkZXNjcmlwdG9yIGFuZCBtdXN0IGJlCiBlaXRoZXIgYEdBVUdFYCAodGhlIGRlZmF1bHQp
IG9yIGBDVU1VTEFUSVZFYC4KCgwKBQQAAgIGEgMuAigKDAoFBAACAgESAy4pNAoMCgUEAAIC
AxIDLjc4CgwKBQQAAgIIEgMuOWEKDwoIBAACAgicCAASAy46YArkAwoEBAACAxIDOAJFGtYD
IFJlcXVpcmVkLiBUaGUgZGF0YSBwb2ludHMgb2YgdGhpcyB0aW1lIHNlcmllcy4gV2hlbiBs
aXN0aW5nIHRpbWUgc2VyaWVzLCBwb2ludHMgYXJlCiByZXR1cm5lZCBpbiByZXZlcnNlIHRp
bWUgb3JkZXIuCgogV2hlbiBjcmVhdGluZyBhIHRpbWUgc2VyaWVzLCB0aGlzIGZpZWxkIG11
c3QgY29udGFpbiBleGFjdGx5IG9uZSBwb2ludCBhbmQKIHRoZSBwb2ludCdzIHR5cGUgbXVz
dCBiZSB0aGUgc2FtZSBhcyB0aGUgdmFsdWUgdHlwZSBvZiB0aGUgYXNzb2NpYXRlZAogbWV0
cmljLiBJZiB0aGUgYXNzb2NpYXRlZCBtZXRyaWMncyBkZXNjcmlwdG9yIG11c3QgYmUgYXV0
by1jcmVhdGVkLCB0aGVuCiB0aGUgdmFsdWUgdHlwZSBvZiB0aGUgZGVzY3JpcHRvciBpcyBk
ZXRlcm1pbmVkIGJ5IHRoZSBwb2ludCdzIHR5cGUsIHdoaWNoCiBtdXN0IGJlIGBCT09MYCwg
YElOVDY0YCwgYERPVUJMRWAsIG9yIGBESVNUUklCVVRJT05gLgoKDAoFBAACAwQSAzgCCgoM
CgUEAAIDBhIDOAsQCgwKBQQAAgMBEgM4ERcKDAoFBAACAwMSAzgaGwoMCgUEAAIDCBIDOBxE
Cg8KCAQAAgMInAgAEgM4HUMKMwoCBAESBDwASgEaJyBBIHNpbmdsZSBkYXRhIHBvaW50IGlu
IGEgdGltZSBzZXJpZXMuCgoKCgMEAQESAzwIDQrqBAoEBAECABIDRgIcGtwEIFRoZSB0aW1l
IGludGVydmFsIHRvIHdoaWNoIHRoZSBkYXRhIHBvaW50IGFwcGxpZXMuICBGb3IgYEdBVUdF
YCBtZXRyaWNzLAogdGhlIHN0YXJ0IHRpbWUgZG9lcyBub3QgbmVlZCB0byBiZSBzdXBwbGll
ZCwgYnV0IGlmIGl0IGlzIHN1cHBsaWVkLCBpdCBtdXN0CiBlcXVhbCB0aGUgZW5kIHRpbWUu
ICBGb3IgYERFTFRBYCBtZXRyaWNzLCB0aGUgc3RhcnQgYW5kIGVuZCB0aW1lIHNob3VsZAog
c3BlY2lmeSBhIG5vbi16ZXJvIGludGVydmFsLCB3aXRoIHN1YnNlcXVlbnQgcG9pbnRzIHNw
ZWNpZnlpbmcgY29udGlndW91cwogYW5kIG5vbi1vdmVybGFwcGluZyBpbnRlcnZhbHMuICBG
b3IgYENVTVVMQVRJVkVgIG1ldHJpY3MsIHRoZSBzdGFydCBhbmQgZW5kCiB0aW1lIHNob3Vs
ZCBzcGVjaWZ5IGEgbm9uLXplcm8gaW50ZXJ2YWwsIHdpdGggc3Vic2VxdWVudCBwb2ludHMg
c3BlY2lmeWluZwogdGhlIHNhbWUgc3RhcnQgdGltZSBhbmQgaW5jcmVhc2luZyBlbmQgdGlt
ZXMsIHVudGlsIGFuIGV2ZW50IHJlc2V0cyB0aGUKIGN1bXVsYXRpdmUgdmFsdWUgdG8gemVy
byBhbmQgc2V0cyBhIG5ldyBzdGFydCB0aW1lIGZvciB0aGUgZm9sbG93aW5nCiBwb2ludHMu
CgoMCgUEAQIABhIDRgIOCgwKBQQBAgABEgNGDxcKDAoFBAECAAMSA0YaGworCgQEAQIBEgNJ
AhcaHiBUaGUgdmFsdWUgb2YgdGhlIGRhdGEgcG9pbnQuCgoMCgUEAQIBBhIDSQIMCgwKBQQB
AgEBEgNJDRIKDAoFBAECAQMSA0kVFgq7AQoCBAISBE8AVwEargEgQSB0aW1lIGludGVydmFs
IGV4dGVuZGluZyBqdXN0IGFmdGVyIGEgc3RhcnQgdGltZSB0aHJvdWdoIGFuIGVuZCB0aW1l
LgogSWYgdGhlIHN0YXJ0IHRpbWUgaXMgdGhlIHNhbWUgYXMgdGhlIGVuZCB0aW1lLCB0aGVu
IHRoZSBpbnRlcnZhbAogcmVwcmVzZW50cyBhIHNpbmdsZSBwb2ludCBpbiB0aW1lLgoKCgoD
BAIBEgNPCBQKqgEKBAQCAgASA1MCVBqcASBPcHRpb25hbC4gVGhlIGJlZ2lubmluZyBvZiB0
aGUgdGltZSBpbnRlcnZhbC4gIFRoZSBkZWZhdWx0IHZhbHVlCiBmb3IgdGhlIHN0YXJ0IHRp
bWUgaXMgdGhlIGVuZCB0aW1lLiBUaGUgc3RhcnQgdGltZSBtdXN0IG5vdCBiZQogbGF0ZXIg
dGhhbiB0aGUgZW5kIHRpbWUuCgoMCgUEAgIABhIDUwIbCgwKBQQCAgABEgNTHCYKDAoFBAIC
AAMSA1MpKgoMCgUEAgIACBIDUytTCg8KCAQCAgAInAgAEgNTLFIKNgoEBAICARIDVgJSGikg
UmVxdWlyZWQuIFRoZSBlbmQgb2YgdGhlIHRpbWUgaW50ZXJ2YWwuCgoMCgUEAgIBBhIDVgIb
CgwKBQQCAgEBEgNWHCQKDAoFBAICAQMSA1YnKAoMCgUEAgIBCBIDVilRCg8KCAQCAgEInAgA
EgNWKlAKLAoCBAMSBFoAbgEaICBBIHNpbmdsZSBzdHJvbmdseS10eXBlZCB2YWx1ZS4KCgoK
AwQDARIDWggSCiYKBAQDCAASBFwCbQMaGCBUaGUgdHlwZWQgdmFsdWUgZmllbGQuCgoMCgUE
AwgAARIDXAgNCjIKBAQDAgASA14EGBolIEEgQm9vbGVhbiB2YWx1ZTogYHRydWVgIG9yIGBm
YWxzZWAuCgoMCgUEAwIABRIDXgQICgwKBQQDAgABEgNeCRMKDAoFBAMCAAMSA14WFwpJCgQE
AwIBEgNhBBoaPCBBIDY0LWJpdCBpbnRlZ2VyLiBJdHMgcmFuZ2UgaXMgYXBwcm94aW1hdGVs
eSArLy05LjJ4MTBeMTguCgoMCgUEAwIBBRIDYQQJCgwKBQQDAgEBEgNhChUKDAoFBAMCAQMS
A2EYGQqfAQoEBAMCAhIDZgQcGpEBIEEgNjQtYml0IGRvdWJsZS1wcmVjaXNpb24gZmxvYXRp
bmctcG9pbnQgbnVtYmVyLiBJdHMgbWFnbml0dWRlCiBpcyBhcHByb3hpbWF0ZWx5ICsvLTEw
XigrLy0zMDApIGFuZCBpdCBoYXMgMTYgc2lnbmlmaWNhbnQgZGlnaXRzIG9mCiBwcmVjaXNp
b24uCgoMCgUEAwICBRIDZgQKCgwKBQQDAgIBEgNmCxcKDAoFBAMCAgMSA2YaGwouCgQEAwID
EgNpBBwaISBBIHZhcmlhYmxlLWxlbmd0aCBzdHJpbmcgdmFsdWUuCgoMCgUEAwIDBRIDaQQK
CgwKBQQDAgMBEgNpCxcKDAoFBAMCAwMSA2kaGwokCgQEAwIEEgNsBDMaFyBBIGRpc3RyaWJ1
dGlvbiB2YWx1ZS4KCgwKBQQDAgQGEgNsBBsKDAoFBAMCBAESA2wcLgoMCgUEAwIEAxIDbDEy
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeSeries ===
    # Fields for TimeSeries
    # Field: metric Type: 9 ()
    # Field: value_type Type: 14 (.google.api.MetricDescriptor.ValueType)
    # Field: metric_kind Type: 14 (.google.api.MetricDescriptor.MetricKind)
    # Field: points Type: 11 (.google.cloud.bigquery.migration.v2alpha.Point)

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::Point ===
    # Fields for Point
    # Field: interval Type: 11 (.google.cloud.bigquery.migration.v2alpha.TimeInterval)
    # Field: value Type: 11 (.google.cloud.bigquery.migration.v2alpha.TypedValue)

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeInterval ===
    # Fields for TimeInterval
    # Field: start_time Type: 11 (.google.protobuf.Timestamp)
    # Field: end_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TypedValue ===
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

Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics - Compiled Protocol Buffers messages for google/cloud/bigquery/migration/v2alpha/migration_metrics.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics;

    my $msg = Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeSeries->new({
        metric => $metric,
        value_type => $value_type,
        metric_kind => $metric_kind,
        points => $points,
    });

    # Read or update a field
    my $val = $msg->metric();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeSeries->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/migration/v2alpha/migration_metrics.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeSeries

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

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::Point>)

Required. The data points of this time series. When listing time series, points are
returned in reverse time order.

When creating a time series, this field must contain exactly one point and
the point's type must be the same as the value type of the associated
metric. If the associated metric's descriptor must be auto-created, then
the value type of the descriptor is determined by the point's type, which
must be `BOOL`, `INT64`, `DOUBLE`, or `DISTRIBUTION`.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::Point

A single data point in a time series.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->interval() >> / C<< $msg->interval($value) >>

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeInterval>)

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

Type: C<Message> (L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TypedValue>)

The value of the data point.

=back

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TimeInterval

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

=head2 Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::TypedValue

A single strongly-typed value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->bool_value() >> / C<< $msg->bool_value($value) >>

Type: C<Bool>

A Boolean value: `true` or `false`.

=item * C<< $msg->int64_value() >> / C<< $msg->int64_value($value) >>

Type: C<Int64>

A 64-bit integer. Its range is approximately +/-9.2x10^18.

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

A 64-bit double-precision floating-point number. Its magnitude
is approximately +/-10^(+/-300) and it has 16 significant digits of
precision.

=item * C<< $msg->string_value() >> / C<< $msg->string_value($value) >>

Type: C<String>

A variable-length string value.

=item * C<< $msg->distribution_value() >> / C<< $msg->distribution_value($value) >>

Type: C<Message> (L<Google::Api::Distribution::Distribution>)

A distribution value.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::Migration::V2alpha::MigrationMetrics::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
