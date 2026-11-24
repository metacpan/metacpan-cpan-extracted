package Google::Bigtable::V2::RequestStats;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Duration };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvYmlndGFibGUvdjIvcmVxdWVzdF9zdGF0cy5wcm90bxISZ29vZ2xlLmJpZ3Rh
YmxlLnYyGh5nb29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8iyAEKElJlYWRJdGVyYXRp
b25TdGF0cxImCg9yb3dzX3NlZW5fY291bnQYASABKANSDXJvd3NTZWVuQ291bnQSLgoTcm93
c19yZXR1cm5lZF9jb3VudBgCIAEoA1IRcm93c1JldHVybmVkQ291bnQSKAoQY2VsbHNfc2Vl
bl9jb3VudBgDIAEoA1IOY2VsbHNTZWVuQ291bnQSMAoUY2VsbHNfcmV0dXJuZWRfY291bnQY
BCABKANSEmNlbGxzUmV0dXJuZWRDb3VudCJoChNSZXF1ZXN0TGF0ZW5jeVN0YXRzElEKF2Zy
b250ZW5kX3NlcnZlcl9sYXRlbmN5GAEgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9u
UhVmcm9udGVuZFNlcnZlckxhdGVuY3kiygEKEUZ1bGxSZWFkU3RhdHNWaWV3ElgKFHJlYWRf
aXRlcmF0aW9uX3N0YXRzGAEgASgLMiYuZ29vZ2xlLmJpZ3RhYmxlLnYyLlJlYWRJdGVyYXRp
b25TdGF0c1IScmVhZEl0ZXJhdGlvblN0YXRzElsKFXJlcXVlc3RfbGF0ZW5jeV9zdGF0cxgC
IAEoCzInLmdvb2dsZS5iaWd0YWJsZS52Mi5SZXF1ZXN0TGF0ZW5jeVN0YXRzUhNyZXF1ZXN0
TGF0ZW5jeVN0YXRzInYKDFJlcXVlc3RTdGF0cxJYChRmdWxsX3JlYWRfc3RhdHNfdmlldxgB
IAEoCzIlLmdvb2dsZS5iaWd0YWJsZS52Mi5GdWxsUmVhZFN0YXRzVmlld0gAUhFmdWxsUmVh
ZFN0YXRzVmlld0IMCgpzdGF0c192aWV3QrsBChZjb20uZ29vZ2xlLmJpZ3RhYmxlLnYyQhFS
ZXF1ZXN0U3RhdHNQcm90b1ABWjhjbG91ZC5nb29nbGUuY29tL2dvL2JpZ3RhYmxlL2FwaXYy
L2JpZ3RhYmxlcGI7YmlndGFibGVwYqoCGEdvb2dsZS5DbG91ZC5CaWd0YWJsZS5WMsoCGEdv
b2dsZVxDbG91ZFxCaWd0YWJsZVxWMuoCG0dvb2dsZTo6Q2xvdWQ6OkJpZ3RhYmxlOjpWMkr5
IwoGEgQOAG8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAb
CgkKAgMAEgMSACgKCAoBCBIDFAA1CgkKAgglEgMUADUKCAoBCBIDFQBPCgkKAggLEgMVAE8K
CAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAyCgkKAggIEgMXADIKCAoBCBIDGAAvCgkK
AggBEgMYAC8KCAoBCBIDGQA1CgkKAggpEgMZADUKCAoBCBIDGgA0CgkKAggtEgMaADQKgwcK
AgQAEgQtADsBGr8BIFJlYWRJdGVyYXRpb25TdGF0cyBjYXB0dXJlcyBpbmZvcm1hdGlvbiBh
Ym91dCB0aGUgaXRlcmF0aW9uIG9mIHJvd3Mgb3IgY2VsbHMKIG92ZXIgdGhlIGNvdXJzZSBv
ZiBhIHJlYWQsIGUuZy4gaG93IG1hbnkgcmVzdWx0cyB3ZXJlIHNjYW5uZWQgaW4gYSByZWFk
CiBvcGVyYXRpb24gdmVyc3VzIHRoZSByZXN1bHRzIHJldHVybmVkLgoytAUKIE1lc3NhZ2Vz
IHJlbGF0ZWQgdG8gUmVxdWVzdFN0YXRzLCBwYXJ0IG9mIHRoZSBRdWVyeSBTdGF0cyBmZWF0
dXJlLCB0aGF0IGNhbgogaGVscCB1bmRlcnN0YW5kIHRoZSBwZXJmb3JtYW5jZSBvZiByZXF1
ZXN0cy4KCiBUaGUgbGF5b3V0IG9mIHJlcXVlc3RzIGJlbG93IGlzIGFzIGZvbGxvd3M6CiAg
ICogUmVxdWVzdFN0YXRzIHNlcnZlcyBhcyB0aGUgdG9wLWxldmVsIGNvbnRhaW5lciBmb3Ig
c3RhdGlzdGljcyBhbmQKICAgICBtZWFzdXJlcyByZWxhdGVkIHRvIEJpZ3RhYmxlIHJlcXVl
c3RzLiBUaGlzIGNvbW1vbiBvYmplY3QgaXMgcmV0dXJuZWQgYXMKICAgICBwYXJ0IG9mIG1l
dGhvZHMgaW4gdGhlIERhdGEgQVBJLgogICAqIFJlcXVlc3RTdGF0cyBjb250YWlucyBtdWx0
aXBsZSAqdmlld3MqIG9mIHJlbGF0ZWQgZGF0YSwgY2hvc2VuIGJ5IGFuCiAgICAgb3B0aW9u
IGluIHRoZSBzb3VyY2UgRGF0YSBBUEkgbWV0aG9kLiBUaGUgdmlldyB0aGF0IGlzIHJldHVy
bmVkIGlzCiAgICAgZGVzaWduZWQgdG8gaGF2ZSBhbGwgc3VibWVzc2FnZXMgKGFuZCB0aGVp
ciBzdWJtZXNzYWdlcywgYW5kIHNvIG9uKQogICAgIGZpbGxlZC1pbiwgdG8gcHJvdmlkZSBh
IGNvbXByZWhlbnNpdmUgc2VsZWN0aW9uIG9mIHN0YXRpc3RpY3MgYW5kCiAgICAgbWVhc3Vy
ZXMgcmVsYXRlZCB0byB0aGUgcmVxdWVzdGVkIHZpZXcuCgoKCgMEAAESAy0IGgp8CgQEAAIA
EgMwAhwabyBUaGUgcm93cyBzZWVuIChzY2FubmVkKSBhcyBwYXJ0IG9mIHRoZSByZXF1ZXN0
LiBUaGlzIGluY2x1ZGVzIHRoZSBjb3VudCBvZgogcm93cyByZXR1cm5lZCwgYXMgY2FwdHVy
ZWQgYmVsb3cuCgoMCgUEAAIABRIDMAIHCgwKBQQAAgABEgMwCBcKDAoFBAACAAMSAzAaGwo4
CgQEAAIBEgMzAiAaKyBUaGUgcm93cyByZXR1cm5lZCBhcyBwYXJ0IG9mIHRoZSByZXF1ZXN0
LgoKDAoFBAACAQUSAzMCBwoMCgUEAAIBARIDMwgbCgwKBQQAAgEDEgMzHh8KfgoEBAACAhID
NwIdGnEgVGhlIGNlbGxzIHNlZW4gKHNjYW5uZWQpIGFzIHBhcnQgb2YgdGhlIHJlcXVlc3Qu
IFRoaXMgaW5jbHVkZXMgdGhlIGNvdW50IG9mCiBjZWxscyByZXR1cm5lZCwgYXMgY2FwdHVy
ZWQgYmVsb3cuCgoMCgUEAAICBRIDNwIHCgwKBQQAAgIBEgM3CBgKDAoFBAACAgMSAzcbHAo5
CgQEAAIDEgM6AiEaLCBUaGUgY2VsbHMgcmV0dXJuZWQgYXMgcGFydCBvZiB0aGUgcmVxdWVz
dC4KCgwKBQQAAgMFEgM6AgcKDAoFBAACAwESAzoIHAoMCgUEAAIDAxIDOh8gCtcBCgIEARIE
QABTARrKASBSZXF1ZXN0TGF0ZW5jeVN0YXRzIHByb3ZpZGVzIGEgbWVhc3VyZW1lbnQgb2Yg
dGhlIGxhdGVuY3kgb2YgdGhlIHJlcXVlc3QgYXMKIGl0IGludGVyYWN0cyB3aXRoIGRpZmZl
cmVudCBzeXN0ZW1zIG92ZXIgaXRzIGxpZmV0aW1lLCBlLmcuIGhvdyBsb25nIHRoZQogcmVx
dWVzdCB0b29rIHRvIGV4ZWN1dGUgd2l0aGluIGEgZnJvbnRlbmQgc2VydmVyLgoKCgoDBAEB
EgNACBsK2gcKBAQBAgASA1ICNxrMByBUaGUgbGF0ZW5jeSBtZWFzdXJlZCBieSB0aGUgZnJv
bnRlbmQgc2VydmVyIGhhbmRsaW5nIHRoaXMgcmVxdWVzdCwgZnJvbQogd2hlbiB0aGUgcmVx
dWVzdCB3YXMgcmVjZWl2ZWQsIHRvIHdoZW4gdGhpcyB2YWx1ZSBpcyBzZW50IGJhY2sgaW4g
dGhlCiByZXNwb25zZS4gRm9yIG1vcmUgY29udGV4dCBvbiB0aGUgY29tcG9uZW50IHRoYXQg
aXMgbWVhc3VyaW5nIHRoaXMgbGF0ZW5jeSwKIHNlZTogaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2JpZ3RhYmxlL2RvY3Mvb3ZlcnZpZXcKCiBOb3RlOiBUaGlzIHZhbHVlIG1heSBiZSBz
bGlnaHRseSBzaG9ydGVyIHRoYW4gdGhlIHZhbHVlIHJlcG9ydGVkIGludG8KIGFnZ3JlZ2F0
ZSBsYXRlbmN5IG1ldHJpY3MgaW4gTW9uaXRvcmluZyBmb3IgdGhpcyByZXF1ZXN0CiAoaHR0
cHM6Ly9jbG91ZC5nb29nbGUuY29tL2JpZ3RhYmxlL2RvY3MvbW9uaXRvcmluZy1pbnN0YW5j
ZSkgYXMgdGhpcyB2YWx1ZQogbmVlZHMgdG8gYmUgc2VudCBpbiB0aGUgcmVzcG9uc2UgYmVm
b3JlIHRoZSBsYXRlbmN5IG1lYXN1cmVtZW50IGluY2x1ZGluZwogdGhhdCB0cmFuc21pc3Np
b24gaXMgZmluYWxpemVkLgoKIE5vdGU6IFRoaXMgdmFsdWUgaW5jbHVkZXMgdGhlIGVuZC10
by1lbmQgbGF0ZW5jeSBvZiBjb250YWN0aW5nIG5vZGVzIGluCiB0aGUgdGFyZ2V0ZWQgY2x1
c3RlciwgZS5nLiBtZWFzdXJpbmcgZnJvbSB3aGVuIHRoZSBmaXJzdCBieXRlIGFycml2ZXMg
YXQKIHRoZSBmcm9udGVuZCBzZXJ2ZXIsIHRvIHdoZW4gdGhpcyB2YWx1ZSBpcyBzZW50IGJh
Y2sgYXMgdGhlIGxhc3QgdmFsdWUgaW4KIHRoZSByZXNwb25zZSwgaW5jbHVkaW5nIGFueSBs
YXRlbmN5IGluY3VycmVkIGJ5IGNvbnRhY3Rpbmcgbm9kZXMsIHdhaXRpbmcKIGZvciByZXN1
bHRzIGZyb20gbm9kZXMsIGFuZCBmaW5hbGx5IHNlbmRpbmcgcmVzdWx0cyBmcm9tIG5vZGVz
IGJhY2sgdG8gdGhlCiBjYWxsZXIuCgoMCgUEAQIABhIDUgIaCgwKBQQBAgABEgNSGzIKDAoF
BAECAAMSA1I1NgpMCgIEAhIEVgBgARpAIEZ1bGxSZWFkU3RhdHNWaWV3IGNhcHR1cmVzIGFs
bCBrbm93biBpbmZvcm1hdGlvbiBhYm91dCBhIHJlYWQuCgoKCgMEAgESA1YIGQr0AQoEBAIC
ABIDWwIuGuYBIEl0ZXJhdGlvbiBzdGF0cyBkZXNjcmliZSBob3cgZWZmaWNpZW50IHRoZSBy
ZWFkIGlzLCBlLmcuIGNvbXBhcmluZwogcm93cyBzZWVuIHZzLiByb3dzIHJldHVybmVkIG9y
IGNlbGxzIHNlZW4gdnMgY2VsbHMgcmV0dXJuZWQgY2FuIHByb3ZpZGUgYW4KIGluZGljYXRp
b24gb2YgcmVhZCBlZmZpY2llbmN5ICh0aGUgaGlnaGVyIHRoZSByYXRpbyBvZiBzZWVuIHRv
IHJldHVuZWQgdGhlCiBiZXR0ZXIpLgoKDAoFBAICAAYSA1sCFAoMCgUEAgIAARIDWxUpCgwK
BQQCAgADEgNbLC0KagoEBAICARIDXwIwGl0gUmVxdWVzdCBsYXRlbmN5IHN0YXRzIGRlc2Ny
aWJlIHRoZSB0aW1lIHRha2VuIHRvIGNvbXBsZXRlIGEgcmVxdWVzdCwgZnJvbQogdGhlIHNl
cnZlciBzaWRlLgoKDAoFBAICAQYSA18CFQoMCgUEAgIBARIDXxYrCgwKBQQCAgEDEgNfLi8K
7wEKAgQDEgRlAG8BGuIBIFJlcXVlc3RTdGF0cyBpcyB0aGUgY29udGFpbmVyIGZvciBhZGRp
dGlvbmFsIGluZm9ybWF0aW9uIHBlcnRhaW5pbmcgdG8gYQogc2luZ2xlIHJlcXVlc3QsIGhl
bHBmdWwgZm9yIGV2YWx1YXRpbmcgdGhlIHBlcmZvcm1hbmNlIG9mIHRoZSBzZW50IHJlcXVl
c3QuCiBDdXJyZW50bHksIHRoZSBmb2xsb3dpbmcgbWV0aG9kIGlzIHN1cHBvcnRlZDogZ29v
Z2xlLmJpZ3RhYmxlLnYyLlJlYWRSb3dzCgoKCgMEAwESA2UIFAqoAQoEBAMIABIEagJuAxqZ
ASBJbmZvcm1hdGlvbiBwZXJ0YWluaW5nIHRvIGVhY2ggcmVxdWVzdCB0eXBlIHJlY2VpdmVk
LiBUaGUgdHlwZSBpcyBjaG9zZW4KIGJhc2VkIG9uIHRoZSByZXF1ZXN0ZWQgdmlldy4KCiBT
ZWUgdGhlIG1lc3NhZ2VzIGFib3ZlIGZvciBhZGRpdGlvbmFsIGNvbnRleHQuCgoMCgUEAwgA
ARIDaggSCnwKBAQDAgASA20ELxpvIEF2YWlsYWJsZSB3aXRoIHRoZSBSZWFkUm93c1JlcXVl
c3QuUmVxdWVzdFN0YXRzVmlldy5SRVFVRVNUX1NUQVRTX0ZVTEwKIHZpZXcsIHNlZSBwYWNr
YWdlIGdvb2dsZS5iaWd0YWJsZS52Mi4KCgwKBQQDAgAGEgNtBBUKDAoFBAMCAAESA20WKgoM
CgUEAwIAAxIDbS0uYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Bigtable::V2::RequestStats::ReadIterationStats ===
    # Fields for ReadIterationStats
    # Field: rows_seen_count Type: 3 ()
    # Field: rows_returned_count Type: 3 ()
    # Field: cells_seen_count Type: 3 ()
    # Field: cells_returned_count Type: 3 ()

# === Message: Google::Bigtable::V2::RequestStats::RequestLatencyStats ===
    # Fields for RequestLatencyStats
    # Field: frontend_server_latency Type: 11 (.google.protobuf.Duration)

# === Message: Google::Bigtable::V2::RequestStats::FullReadStatsView ===
    # Fields for FullReadStatsView
    # Field: read_iteration_stats Type: 11 (.google.bigtable.v2.ReadIterationStats)
    # Field: request_latency_stats Type: 11 (.google.bigtable.v2.RequestLatencyStats)

# === Message: Google::Bigtable::V2::RequestStats::RequestStats ===
    # Fields for RequestStats
    # Field: full_read_stats_view Type: 11 (.google.bigtable.v2.FullReadStatsView)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Bigtable::V2::RequestStats - Compiled Protocol Buffers messages for google/bigtable/v2/request_stats.proto

=head1 SYNOPSIS

    use Google::Bigtable::V2::RequestStats;

    my $msg = Google::Bigtable::V2::RequestStats::ReadIterationStats->new({
        rows_seen_count => $rows_seen_count,
        rows_returned_count => $rows_returned_count,
        cells_seen_count => $cells_seen_count,
        cells_returned_count => $cells_returned_count,
    });

    # Read or update a field
    my $val = $msg->rows_seen_count();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Bigtable::V2::RequestStats::ReadIterationStats->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/bigtable/v2/request_stats.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Bigtable::V2::RequestStats::ReadIterationStats

ReadIterationStats captures information about the iteration of rows or cells
over the course of a read, e.g. how many results were scanned in a read
operation versus the results returned.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rows_seen_count() >> / C<< $msg->rows_seen_count($value) >>

Type: C<Int64>

The rows seen (scanned) as part of the request. This includes the count of
rows returned, as captured below.

=item * C<< $msg->rows_returned_count() >> / C<< $msg->rows_returned_count($value) >>

Type: C<Int64>

The rows returned as part of the request.

=item * C<< $msg->cells_seen_count() >> / C<< $msg->cells_seen_count($value) >>

Type: C<Int64>

The cells seen (scanned) as part of the request. This includes the count of
cells returned, as captured below.

=item * C<< $msg->cells_returned_count() >> / C<< $msg->cells_returned_count($value) >>

Type: C<Int64>

The cells returned as part of the request.

=back

=head2 Google::Bigtable::V2::RequestStats::RequestLatencyStats

RequestLatencyStats provides a measurement of the latency of the request as
it interacts with different systems over its lifetime, e.g. how long the
request took to execute within a frontend server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->frontend_server_latency() >> / C<< $msg->frontend_server_latency($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

The latency measured by the frontend server handling this request, from
when the request was received, to when this value is sent back in the
response. For more context on the component that is measuring this latency,
see: https://cloud.google.com/bigtable/docs/overview

Note: This value may be slightly shorter than the value reported into
aggregate latency metrics in Monitoring for this request
(https://cloud.google.com/bigtable/docs/monitoring-instance) as this value
needs to be sent in the response before the latency measurement including
that transmission is finalized.

Note: This value includes the end-to-end latency of contacting nodes in
the targeted cluster, e.g. measuring from when the first byte arrives at
the frontend server, to when this value is sent back as the last value in
the response, including any latency incurred by contacting nodes, waiting
for results from nodes, and finally sending results from nodes back to the
caller.

=back

=head2 Google::Bigtable::V2::RequestStats::FullReadStatsView

FullReadStatsView captures all known information about a read.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->read_iteration_stats() >> / C<< $msg->read_iteration_stats($value) >>

Type: C<Message> (L<Google::Bigtable::V2::RequestStats::ReadIterationStats>)

Iteration stats describe how efficient the read is, e.g. comparing
rows seen vs. rows returned or cells seen vs cells returned can provide an
indication of read efficiency (the higher the ratio of seen to retuned the
better).

=item * C<< $msg->request_latency_stats() >> / C<< $msg->request_latency_stats($value) >>

Type: C<Message> (L<Google::Bigtable::V2::RequestStats::RequestLatencyStats>)

Request latency stats describe the time taken to complete a request, from
the server side.

=back

=head2 Google::Bigtable::V2::RequestStats::RequestStats

RequestStats is the container for additional information pertaining to a
single request, helpful for evaluating the performance of the sent request.
Currently, the following method is supported: google.bigtable.v2.ReadRows

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->full_read_stats_view() >> / C<< $msg->full_read_stats_view($value) >>

Type: C<Message> (L<Google::Bigtable::V2::RequestStats::FullReadStatsView>)

Available with the ReadRowsRequest.RequestStatsView.REQUEST_STATS_FULL
view, see package google.bigtable.v2.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Bigtable::V2::RequestStats::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
