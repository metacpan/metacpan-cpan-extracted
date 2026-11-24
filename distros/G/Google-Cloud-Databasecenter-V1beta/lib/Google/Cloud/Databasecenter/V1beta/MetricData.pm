package Google::Cloud::Databasecenter::V1beta::MetricData;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjRnb29nbGUvY2xvdWQvZGF0YWJhc2VjZW50ZXIvdjFiZXRhL21ldHJpY19kYXRhLnByb3Rv
EiJnb29nbGUuY2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhGh9nb29nbGUvcHJvdG9idWYv
dGltZXN0YW1wLnByb3RvIqYJCgdNZXRyaWNzEmMKE3A5OV9jcHVfdXRpbGl6YXRpb24YASAB
KAsyLi5nb29nbGUuY2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhLk1ldHJpY0RhdGFIAFIR
cDk5Q3B1VXRpbGl6YXRpb26IAQESYwoTcDk1X2NwdV91dGlsaXphdGlvbhgCIAEoCzIuLmdv
b2dsZS5jbG91ZC5kYXRhYmFzZWNlbnRlci52MWJldGEuTWV0cmljRGF0YUgBUhFwOTVDcHVV
dGlsaXphdGlvbogBARJwChpjdXJyZW50X3N0b3JhZ2VfdXNlZF9ieXRlcxgDIAEoCzIuLmdv
b2dsZS5jbG91ZC5kYXRhYmFzZWNlbnRlci52MWJldGEuTWV0cmljRGF0YUgCUhdjdXJyZW50
U3RvcmFnZVVzZWRCeXRlc4gBARJtChhwZWFrX3N0b3JhZ2VfdXRpbGl6YXRpb24YBCABKAsy
Li5nb29nbGUuY2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhLk1ldHJpY0RhdGFIA1IWcGVh
a1N0b3JhZ2VVdGlsaXphdGlvbogBARJrChdwZWFrX21lbW9yeV91dGlsaXphdGlvbhgFIAEo
CzIuLmdvb2dsZS5jbG91ZC5kYXRhYmFzZWNlbnRlci52MWJldGEuTWV0cmljRGF0YUgEUhVw
ZWFrTWVtb3J5VXRpbGl6YXRpb26IAQESawoXcGVha19udW1iZXJfY29ubmVjdGlvbnMYBiAB
KAsyLi5nb29nbGUuY2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhLk1ldHJpY0RhdGFIBVIV
cGVha051bWJlckNvbm5lY3Rpb25ziAEBElIKCm5vZGVfY291bnQYByABKAsyLi5nb29nbGUu
Y2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhLk1ldHJpY0RhdGFIBlIJbm9kZUNvdW50iAEB
EmcKFXByb2Nlc3NpbmdfdW5pdF9jb3VudBgIIAEoCzIuLmdvb2dsZS5jbG91ZC5kYXRhYmFz
ZWNlbnRlci52MWJldGEuTWV0cmljRGF0YUgHUhNwcm9jZXNzaW5nVW5pdENvdW50iAEBEm4K
GWN1cnJlbnRfbWVtb3J5X3VzZWRfYnl0ZXMYCSABKAsyLi5nb29nbGUuY2xvdWQuZGF0YWJh
c2VjZW50ZXIudjFiZXRhLk1ldHJpY0RhdGFICFIWY3VycmVudE1lbW9yeVVzZWRCeXRlc4gB
AUIWChRfcDk5X2NwdV91dGlsaXphdGlvbkIWChRfcDk1X2NwdV91dGlsaXphdGlvbkIdChtf
Y3VycmVudF9zdG9yYWdlX3VzZWRfYnl0ZXNCGwoZX3BlYWtfc3RvcmFnZV91dGlsaXphdGlv
bkIaChhfcGVha19tZW1vcnlfdXRpbGl6YXRpb25CGgoYX3BlYWtfbnVtYmVyX2Nvbm5lY3Rp
b25zQg0KC19ub2RlX2NvdW50QhgKFl9wcm9jZXNzaW5nX3VuaXRfY291bnRCHAoaX2N1cnJl
bnRfbWVtb3J5X3VzZWRfYnl0ZXMimQEKCk1ldHJpY0RhdGESRAoFdmFsdWUYASABKAsyLi5n
b29nbGUuY2xvdWQuZGF0YWJhc2VjZW50ZXIudjFiZXRhLlR5cGVkVmFsdWVSBXZhbHVlEkUK
EG9ic2VydmF0aW9uX3RpbWUYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUg9v
YnNlcnZhdGlvblRpbWUiXQoKVHlwZWRWYWx1ZRIjCgxkb3VibGVfdmFsdWUYASABKAFIAFIL
ZG91YmxlVmFsdWUSIQoLaW50NjRfdmFsdWUYAiABKANIAFIKaW50NjRWYWx1ZUIHCgV2YWx1
ZUL9AQomY29tLmdvb2dsZS5jbG91ZC5kYXRhYmFzZWNlbnRlci52MWJldGFCD01ldHJpY0Rh
dGFQcm90b1ABWk5jbG91ZC5nb29nbGUuY29tL2dvL2RhdGFiYXNlY2VudGVyL2FwaXYxYmV0
YS9kYXRhYmFzZWNlbnRlcnBiO2RhdGFiYXNlY2VudGVycGKqAiJHb29nbGUuQ2xvdWQuRGF0
YWJhc2VDZW50ZXIuVjFCZXRhygIiR29vZ2xlXENsb3VkXERhdGFiYXNlQ2VudGVyXFYxYmV0
YeoCJUdvb2dsZTo6Q2xvdWQ6OkRhdGFiYXNlQ2VudGVyOjpWMWJldGFKuhcKBhIEDgBSAQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAKwoJCgIDABIDEgAp
CggKAQgSAxQAPwoJCgIIJRIDFAA/CggKAQgSAxUAZQoJCgIICxIDFQBlCggKAQgSAxYAIgoJ
CgIIChIDFgAiCggKAQgSAxcAMAoJCgIICBIDFwAwCggKAQgSAxgAPwoJCgIIARIDGAA/CggK
AQgSAxkAPwoJCgIIKRIDGQA/CggKAQgSAxoAPgoJCgIILRIDGgA+CkUKAgQAEgQdAD0BGjkg
TWV0cmljcyByZXByZXNlbnRzIHRoZSBtZXRyaWNzIGZvciBhIGRhdGFiYXNlIHJlc291cmNl
LgoKCgoDBAABEgMdCA8KlwEKBAQAAgASAyACLhqJASBQOTkgQ1BVIHV0aWxpemF0aW9uIG9i
c2VydmVkIGZvciB0aGUgcmVzb3VyY2UuIFRoZSB2YWx1ZSBpcyBhCiBmcmFjdGlvbiBiZXR3
ZWVuIDAuMCBhbmQgMS4wIChtYXkgbW9tZW50YXJpbHkgZXhjZWVkIDEuMCBpbiBzb21lIGNh
c2VzKS4KCgwKBQQAAgAEEgMgAgoKDAoFBAACAAYSAyALFQoMCgUEAAIAARIDIBYpCgwKBQQA
AgADEgMgLC0KlwEKBAQAAgESAyQCLhqJASBQOTUgQ1BVIHV0aWxpemF0aW9uIG9ic2VydmVk
IGZvciB0aGUgcmVzb3VyY2UuIFRoZSB2YWx1ZSBpcyBhCiBmcmFjdGlvbiBiZXR3ZWVuIDAu
MCBhbmQgMS4wIChtYXkgbW9tZW50YXJpbHkgZXhjZWVkIDEuMCBpbiBzb21lIGNhc2VzKS4K
CgwKBQQAAgEEEgMkAgoKDAoFBAACAQYSAyQLFQoMCgUEAAIBARIDJBYpCgwKBQQAAgEDEgMk
LC0KPQoEBAACAhIDJwI1GjAgQ3VycmVudCBzdG9yYWdlIHVzZWQgYnkgdGhlIHJlc291cmNl
IGluIGJ5dGVzLgoKDAoFBAACAgQSAycCCgoMCgUEAAICBhIDJwsVCgwKBQQAAgIBEgMnFjAK
DAoFBAACAgMSAyczNAqcAQoEBAACAxIDKwIzGo4BIFBlYWsgc3RvcmFnZSB1dGlsaXphdGlv
biBvYnNlcnZlZCBmb3IgdGhlIHJlc291cmNlLiBUaGUgdmFsdWUgaXMgYQogZnJhY3Rpb24g
YmV0d2VlbiAwLjAgYW5kIDEuMCAobWF5IG1vbWVudGFyaWx5IGV4Y2VlZCAxLjAgaW4gc29t
ZSBjYXNlcykuCgoMCgUEAAIDBBIDKwIKCgwKBQQAAgMGEgMrCxUKDAoFBAACAwESAysWLgoM
CgUEAAIDAxIDKzEyCpsBCgQEAAIEEgMvAjIajQEgUGVhayBtZW1vcnkgdXRpbGl6YXRpb24g
b2JzZXJ2ZWQgZm9yIHRoZSByZXNvdXJjZS4gVGhlIHZhbHVlIGlzIGEKIGZyYWN0aW9uIGJl
dHdlZW4gMC4wIGFuZCAxLjAgKG1heSBtb21lbnRhcmlseSBleGNlZWQgMS4wIGluIHNvbWUg
Y2FzZXMpLgoKDAoFBAACBAQSAy8CCgoMCgUEAAIEBhIDLwsVCgwKBQQAAgQBEgMvFi0KDAoF
BAACBAMSAy8wMQpmCgQEAAIFEgMzAjIaWSBQZWFrIG51bWJlciBvZiBjb25uZWN0aW9ucyBv
YnNlcnZlZCBmb3IgdGhlIHJlc291cmNlLiBUaGUgdmFsdWUgaXMgYQogcG9zaXRpdmUgaW50
ZWdlci4KCgwKBQQAAgUEEgMzAgoKDAoFBAACBQYSAzMLFQoMCgUEAAIFARIDMxYtCgwKBQQA
AgUDEgMzMDEKQwoEBAACBhIDNgIlGjYgTnVtYmVyIG9mIG5vZGVzIGluIGluc3RhbmNlIGZv
ciBzcGFubmVyIG9yIGJpZ3RhYmxlLgoKDAoFBAACBgQSAzYCCgoMCgUEAAIGBhIDNgsVCgwK
BQQAAgYBEgM2FiAKDAoFBAACBgMSAzYjJAo1CgQEAAIHEgM5AjAaKCBOdW1iZXIgb2YgcHJv
Y2Vzc2luZyB1bml0cyBpbiBzcGFubmVyLgoKDAoFBAACBwQSAzkCCgoMCgUEAAIHBhIDOQsV
CgwKBQQAAgcBEgM5FisKDAoFBAACBwMSAzkuLwo8CgQEAAIIEgM8AjQaLyBDdXJyZW50IG1l
bW9yeSB1c2VkIGJ5IHRoZSByZXNvdXJjZSBpbiBieXRlcy4KCgwKBQQAAggEEgM8AgoKDAoF
BAACCAYSAzwLFQoMCgUEAAIIARIDPBYvCgwKBQQAAggDEgM8MjMKTAoCBAESBEAARgEaQCBN
ZXRyaWNEYXRhIHJlcHJlc2VudHMgdGhlIG1ldHJpYyBkYXRhIGZvciBhIGRhdGFiYXNlIHJl
c291cmNlLgoKCgoDBAEBEgNACBIKNAoEBAECABIDQgIXGicgVGhlIHZhbHVlIGFzc29jaWF0
ZWQgd2l0aCB0aGUgbWV0cmljLgoKDAoFBAECAAYSA0ICDAoMCgUEAQIAARIDQg0SCgwKBQQB
AgADEgNCFRYKTQoEBAECARIDRQIxGkAgVGhlIHRpbWUgdGhlIG1ldHJpYyB3YXMgb2JzZXJ2
ZWQgaW4gdGhlIG1ldHJpYyBzb3VyY2Ugc2VydmljZS4KCgwKBQQBAgEGEgNFAhsKDAoFBAEC
AQESA0UcLAoMCgUEAQIBAxIDRS8wCk8KAgQCEgRJAFIBGkMgVHlwZWRWYWx1ZSByZXByZXNl
bnRzIHRoZSB2YWx1ZSBvZiB0aGUgbWV0cmljIGJhc2VkIG9uIGRhdGEgdHlwZS4KCgoKAwQC
ARIDSQgSClcKBAQCCAASBEsCUQMaSSBUaGUgZGF0YSB0eXBlIG9mIG1ldHJpYyB2YWx1ZSB3
b3VsZCBiZSBjaG9zZW4gYmFzZWQgb24gdGhlIG1ldHJpYyB0eXBlLgoKDAoFBAIIAAESA0sI
DQoxCgQEAgIAEgNNBBwaJCBUaGUgdmFsdWUgb2YgdGhlIG1ldHJpYyBhcyBkb3VibGUuCgoM
CgUEAgIABRIDTQQKCgwKBQQCAgABEgNNCxcKDAoFBAICAAMSA00aGwouCgQEAgIBEgNQBBoa
ISBUaGUgdmFsdWUgb2YgdGhlIG1ldHJpYyBhcyBpbnQuCgoMCgUEAgIBBRIDUAQJCgwKBQQC
AgEBEgNQChUKDAoFBAICAQMSA1AYGWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Databasecenter::V1beta::MetricData::Metrics ===
    # Fields for Metrics
    # Field: p99_cpu_utilization Type: 11 (.google.cloud.databasecenter.v1beta.MetricData)
    # Field: p95_cpu_utilization Type: 11 (.google.cloud.databasecenter.v1beta.MetricData)
    # Field: current_storage_used_bytes Type: 11 (.google.cloud.databasecenter.v1beta.MetricData)
    # Field: peak_storage_utilization Type: 11 (.google.cloud.databasecenter.v1beta.MetricData)
    # Field: peak_memory_utilization Type: 11 (.google.cloud.databasecenter.v1beta.MetricData)
    # Field: peak_number_connections Type: 11 (.google.cloud.databasecenter.v1beta.MetricData)
    # Field: node_count Type: 11 (.google.cloud.databasecenter.v1beta.MetricData)
    # Field: processing_unit_count Type: 11 (.google.cloud.databasecenter.v1beta.MetricData)
    # Field: current_memory_used_bytes Type: 11 (.google.cloud.databasecenter.v1beta.MetricData)

# === Message: Google::Cloud::Databasecenter::V1beta::MetricData::MetricData ===
    # Fields for MetricData
    # Field: value Type: 11 (.google.cloud.databasecenter.v1beta.TypedValue)
    # Field: observation_time Type: 11 (.google.protobuf.Timestamp)

# === Message: Google::Cloud::Databasecenter::V1beta::MetricData::TypedValue ===
    # Fields for TypedValue
    # Field: double_value Type: 1 ()
    # Field: int64_value Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Databasecenter::V1beta::MetricData - Compiled Protocol Buffers messages for google/cloud/databasecenter/v1beta/metric_data.proto

=head1 SYNOPSIS

    use Google::Cloud::Databasecenter::V1beta::MetricData;

    my $msg = Google::Cloud::Databasecenter::V1beta::MetricData::Metrics->new({
        p99_cpu_utilization => $p99_cpu_utilization,
        p95_cpu_utilization => $p95_cpu_utilization,
        current_storage_used_bytes => $current_storage_used_bytes,
        peak_storage_utilization => $peak_storage_utilization,
    });

    # Read or update a field
    my $val = $msg->p99_cpu_utilization();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Databasecenter::V1beta::MetricData::Metrics->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/databasecenter/v1beta/metric_data.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Databasecenter::V1beta::MetricData::Metrics

Metrics represents the metrics for a database resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->p99_cpu_utilization() >> / C<< $msg->p99_cpu_utilization($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::MetricData::MetricData>)

P99 CPU utilization observed for the resource. The value is a
fraction between 0.0 and 1.0 (may momentarily exceed 1.0 in some cases).

=item * C<< $msg->p95_cpu_utilization() >> / C<< $msg->p95_cpu_utilization($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::MetricData::MetricData>)

P95 CPU utilization observed for the resource. The value is a
fraction between 0.0 and 1.0 (may momentarily exceed 1.0 in some cases).

=item * C<< $msg->current_storage_used_bytes() >> / C<< $msg->current_storage_used_bytes($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::MetricData::MetricData>)

Current storage used by the resource in bytes.

=item * C<< $msg->peak_storage_utilization() >> / C<< $msg->peak_storage_utilization($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::MetricData::MetricData>)

Peak storage utilization observed for the resource. The value is a
fraction between 0.0 and 1.0 (may momentarily exceed 1.0 in some cases).

=item * C<< $msg->peak_memory_utilization() >> / C<< $msg->peak_memory_utilization($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::MetricData::MetricData>)

Peak memory utilization observed for the resource. The value is a
fraction between 0.0 and 1.0 (may momentarily exceed 1.0 in some cases).

=item * C<< $msg->peak_number_connections() >> / C<< $msg->peak_number_connections($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::MetricData::MetricData>)

Peak number of connections observed for the resource. The value is a
positive integer.

=item * C<< $msg->node_count() >> / C<< $msg->node_count($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::MetricData::MetricData>)

Number of nodes in instance for spanner or bigtable.

=item * C<< $msg->processing_unit_count() >> / C<< $msg->processing_unit_count($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::MetricData::MetricData>)

Number of processing units in spanner.

=item * C<< $msg->current_memory_used_bytes() >> / C<< $msg->current_memory_used_bytes($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::MetricData::MetricData>)

Current memory used by the resource in bytes.

=back

=head2 Google::Cloud::Databasecenter::V1beta::MetricData::MetricData

MetricData represents the metric data for a database resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Cloud::Databasecenter::V1beta::MetricData::TypedValue>)

The value associated with the metric.

=item * C<< $msg->observation_time() >> / C<< $msg->observation_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time the metric was observed in the metric source service.

=back

=head2 Google::Cloud::Databasecenter::V1beta::MetricData::TypedValue

TypedValue represents the value of the metric based on data type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->double_value() >> / C<< $msg->double_value($value) >>

Type: C<Double>

The value of the metric as double.

=item * C<< $msg->int64_value() >> / C<< $msg->int64_value($value) >>

Type: C<Int64>

The value of the metric as int.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Databasecenter::V1beta::MetricData::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
