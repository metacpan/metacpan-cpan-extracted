package Google::Monitoring::Dashboard::V1::Scorecard;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Monitoring::Dashboard::V1::Metrics };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvc2NvcmVjYXJkLnByb3RvEh5nb29n
bGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aLGdvb2dsZS9tb25pdG9yaW5nL2Rhc2hib2FyZC92MS9tZXRyaWNzLnByb3RvGh5n
b29nbGUvcHJvdG9idWYvZHVyYXRpb24ucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5w
cm90byLIBQoJU2NvcmVjYXJkEmAKEXRpbWVfc2VyaWVzX3F1ZXJ5GAEgASgLMi8uZ29vZ2xl
Lm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlRpbWVTZXJpZXNRdWVyeUID4EECUg90aW1lU2Vy
aWVzUXVlcnkSVAoKZ2F1Z2VfdmlldxgEIAEoCzIzLmdvb2dsZS5tb25pdG9yaW5nLmRhc2hi
b2FyZC52MS5TY29yZWNhcmQuR2F1Z2VWaWV3SABSCWdhdWdlVmlldxJkChBzcGFya19jaGFy
dF92aWV3GAUgASgLMjguZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlNjb3JlY2Fy
ZC5TcGFya0NoYXJ0Vmlld0gAUg5zcGFya0NoYXJ0VmlldxI3CgpibGFua192aWV3GAcgASgL
MhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5SABSCWJsYW5rVmlldxJJCgp0aHJlc2hvbGRzGAYg
AygLMikuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlRocmVzaG9sZFIKdGhyZXNo
b2xkcxpNCglHYXVnZVZpZXcSHwoLbG93ZXJfYm91bmQYASABKAFSCmxvd2VyQm91bmQSHwoL
dXBwZXJfYm91bmQYAiABKAFSCnVwcGVyQm91bmQavAEKDlNwYXJrQ2hhcnRWaWV3El0KEHNw
YXJrX2NoYXJ0X3R5cGUYASABKA4yLi5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEu
U3BhcmtDaGFydFR5cGVCA+BBAlIOc3BhcmtDaGFydFR5cGUSSwoUbWluX2FsaWdubWVudF9w
ZXJpb2QYAiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SEm1pbkFsaWdubWVudFBl
cmlvZEILCglkYXRhX3ZpZXdC9wEKImNvbS5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQu
djFCDlNjb3JlY2FyZFByb3RvUAFaRmNsb3VkLmdvb2dsZS5jb20vZ28vbW9uaXRvcmluZy9k
YXNoYm9hcmQvYXBpdjEvZGFzaGJvYXJkcGI7ZGFzaGJvYXJkcGKqAiRHb29nbGUuQ2xvdWQu
TW9uaXRvcmluZy5EYXNoYm9hcmQuVjHKAiRHb29nbGVcQ2xvdWRcTW9uaXRvcmluZ1xEYXNo
Ym9hcmRcVjHqAihHb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpEYXNoYm9hcmQ6OlYxSpIh
CgYSBA4AegEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcK
CQoCAwASAxIAKQoJCgIDARIDEwA2CgkKAgMCEgMUACgKCQoCAwMSAxUAJQoICgEIEgMXAEEK
CQoCCCUSAxcAQQoICgEIEgMYAF0KCQoCCAsSAxgAXQoICgEIEgMZACIKCQoCCAoSAxkAIgoI
CgEIEgMaAC8KCQoCCAgSAxoALwoICgEIEgMbADsKCQoCCAESAxsAOwoICgEIEgMcAEIKCQoC
CCkSAxwAQgoICgEIEgMdAEEKCQoCCC0SAx0AQQpzCgIEABIEIQB6ARpnIEEgd2lkZ2V0IHNo
b3dpbmcgdGhlIGxhdGVzdCB2YWx1ZSBvZiBhIG1ldHJpYywgYW5kIGhvdyB0aGlzIHZhbHVl
IHJlbGF0ZXMgdG8KIG9uZSBvciBtb3JlIHRocmVzaG9sZHMuCgoKCgMEAAESAyEIEQrMAQoE
BAADABIEJQItAxq9ASBBIGdhdWdlIGNoYXJ0IHNob3dzIHdoZXJlIHRoZSBjdXJyZW50IHZh
bHVlIHNpdHMgd2l0aGluIGEgcHJlLWRlZmluZWQKIHJhbmdlLiBUaGUgdXBwZXIgYW5kIGxv
d2VyIGJvdW5kcyBzaG91bGQgZGVmaW5lIHRoZSBwb3NzaWJsZSByYW5nZSBvZgogdmFsdWVz
IGZvciB0aGUgc2NvcmVjYXJkJ3MgcXVlcnkgKGluY2x1c2l2ZSkuCgoMCgUEAAMAARIDJQoT
Cn4KBgQAAwACABIDKAQbGm8gVGhlIGxvd2VyIGJvdW5kIGZvciB0aGlzIGdhdWdlIGNoYXJ0
LiBUaGUgdmFsdWUgb2YgdGhlIGNoYXJ0IHNob3VsZAogYWx3YXlzIGJlIGdyZWF0ZXIgdGhh
biBvciBlcXVhbCB0byB0aGlzLgoKDgoHBAADAAIABRIDKAQKCg4KBwQAAwACAAESAygLFgoO
CgcEAAMAAgADEgMoGRoKewoGBAADAAIBEgMsBBsabCBUaGUgdXBwZXIgYm91bmQgZm9yIHRo
aXMgZ2F1Z2UgY2hhcnQuIFRoZSB2YWx1ZSBvZiB0aGUgY2hhcnQgc2hvdWxkCiBhbHdheXMg
YmUgbGVzcyB0aGFuIG9yIGVxdWFsIHRvIHRoaXMuCgoOCgcEAAMAAgEFEgMsBAoKDgoHBAAD
AAIBARIDLAsWCg4KBwQAAwACAQMSAywZGgr0AQoEBAADARIEMwI+AxrlASBBIHNwYXJrQ2hh
cnQgaXMgYSBzbWFsbCBjaGFydCBzdWl0YWJsZSBmb3IgaW5jbHVzaW9uIGluIGEgdGFibGUt
Y2VsbCBvcgogaW5saW5lIGluIHRleHQuIFRoaXMgbWVzc2FnZSBjb250YWlucyB0aGUgY29u
ZmlndXJhdGlvbiBmb3IgYSBzcGFya0NoYXJ0CiB0byBzaG93IHVwIG9uIGEgU2NvcmVjYXJk
LCBzaG93aW5nIHJlY2VudCB0cmVuZHMgb2YgdGhlIHNjb3JlY2FyZCdzCiB0aW1lc2VyaWVz
LgoKDAoFBAADAQESAzMKGApNCgYEAAMBAgASBDUENjEaPSBSZXF1aXJlZC4gVGhlIHR5cGUg
b2Ygc3BhcmtjaGFydCB0byBzaG93IGluIHRoaXMgY2hhcnRWaWV3LgoKDgoHBAADAQIABhID
NQQSCg4KBwQAAwECAAESAzUTIwoOCgcEAAMBAgADEgM1JicKDgoHBAADAQIACBIDNggwChEK
CgQAAwECAAicCAASAzYJLwrXAgoGBAADAQIBEgM9BDYaxwIgVGhlIGxvd2VyIGJvdW5kIG9u
IGRhdGEgcG9pbnQgZnJlcXVlbmN5IGluIHRoZSBjaGFydCBpbXBsZW1lbnRlZCBieQogc3Bl
Y2lmeWluZyB0aGUgbWluaW11bSBhbGlnbm1lbnQgcGVyaW9kIHRvIHVzZSBpbiBhIHRpbWUg
c2VyaWVzIHF1ZXJ5LgogRm9yIGV4YW1wbGUsIGlmIHRoZSBkYXRhIGlzIHB1Ymxpc2hlZCBv
bmNlIGV2ZXJ5IDEwIG1pbnV0ZXMgaXQgd291bGQgbm90CiBtYWtlIHNlbnNlIHRvIGZldGNo
IGFuZCBhbGlnbiBkYXRhIGF0IG9uZSBtaW51dGUgaW50ZXJ2YWxzLiBUaGlzIGZpZWxkIGlz
CiBvcHRpb25hbCBhbmQgZXhpc3RzIG9ubHkgYXMgYSBoaW50LgoKDgoHBAADAQIBBhIDPQQc
Cg4KBwQAAwECAQESAz0dMQoOCgcEAAMBAgEDEgM9NDUKYQoEBAACABIEQgJDLxpTIFJlcXVp
cmVkLiBGaWVsZHMgZm9yIHF1ZXJ5aW5nIHRpbWUgc2VyaWVzIGRhdGEgZnJvbSB0aGUKIFN0
YWNrZHJpdmVyIG1ldHJpY3MgQVBJLgoKDAoFBAACAAYSA0ICEQoMCgUEAAIAARIDQhIjCgwK
BQQAAgADEgNCJicKDAoFBAACAAgSA0MGLgoPCggEAAIACJwIABIDQwctCooBCgQEAAgAEgRH
AlEDGnwgRGVmaW5lcyB0aGUgb3B0aW9uYWwgYWRkaXRpb25hbCBjaGFydCBzaG93biBvbiB0
aGUgc2NvcmVjYXJkLiBJZgogbmVpdGhlciBpcyBpbmNsdWRlZCAtIHRoZW4gYSBkZWZhdWx0
IHNjb3JlY2FyZCBpcyBzaG93bi4KCgwKBQQACAABEgNHCBEKPgoEBAACARIDSQQdGjEgV2ls
bCBjYXVzZSB0aGUgc2NvcmVjYXJkIHRvIHNob3cgYSBnYXVnZSBjaGFydC4KCgwKBQQAAgEG
EgNJBA0KDAoFBAACAQESA0kOGAoMCgUEAAIBAxIDSRscCj4KBAQAAgISA0wEKBoxIFdpbGwg
Y2F1c2UgdGhlIHNjb3JlY2FyZCB0byBzaG93IGEgc3BhcmsgY2hhcnQuCgoMCgUEAAICBhID
TAQSCgwKBQQAAgIBEgNMEyMKDAoFBAACAgMSA0wmJwp9CgQEAAIDEgNQBCkacCBXaWxsIGNh
dXNlIHRoZSBgU2NvcmVjYXJkYCB0byBzaG93IG9ubHkgdGhlIHZhbHVlLCB3aXRoIG5vIGlu
ZGljYXRvciB0bwogaXRzIHZhbHVlIHJlbGF0aXZlIHRvIGl0cyB0aHJlc2hvbGRzLgoKDAoF
BAACAwYSA1AEGQoMCgUEAAIDARIDUBokCgwKBQQAAgMDEgNQJygKlwkKBAQAAgQSA3kCJBqJ
CSBUaGUgdGhyZXNob2xkcyB1c2VkIHRvIGRldGVybWluZSB0aGUgc3RhdGUgb2YgdGhlIHNj
b3JlY2FyZCBnaXZlbiB0aGUKIHRpbWUgc2VyaWVzJyBjdXJyZW50IHZhbHVlLiBGb3IgYW4g
YWN0dWFsIHZhbHVlIHgsIHRoZSBzY29yZWNhcmQgaXMgaW4gYQogZGFuZ2VyIHN0YXRlIGlm
IHggaXMgbGVzcyB0aGFuIG9yIGVxdWFsIHRvIGEgZGFuZ2VyIHRocmVzaG9sZCB0aGF0IHRy
aWdnZXJzCiBiZWxvdywgb3IgZ3JlYXRlciB0aGFuIG9yIGVxdWFsIHRvIGEgZGFuZ2VyIHRo
cmVzaG9sZCB0aGF0IHRyaWdnZXJzIGFib3ZlLgogU2ltaWxhcmx5LCBpZiB4IGlzIGFib3Zl
L2JlbG93IGEgd2FybmluZyB0aHJlc2hvbGQgdGhhdCB0cmlnZ2VycwogYWJvdmUvYmVsb3cs
IHRoZW4gdGhlIHNjb3JlY2FyZCBpcyBpbiBhIHdhcm5pbmcgc3RhdGUgLSB1bmxlc3MgeCBh
bHNvIHB1dHMKIGl0IGluIGEgZGFuZ2VyIHN0YXRlLiAoRGFuZ2VyIHRydW1wcyB3YXJuaW5n
LikKCiBBcyBhbiBleGFtcGxlLCBjb25zaWRlciBhIHNjb3JlY2FyZCB3aXRoIHRoZSBmb2xs
b3dpbmcgZm91ciB0aHJlc2hvbGRzOgoKIGBgYAogewogICB2YWx1ZTogOTAsCiAgIGNhdGVn
b3J5OiAnREFOR0VSJywKICAgdHJpZ2dlcjogJ0FCT1ZFJywKIH0sCiB7CiAgIHZhbHVlOiA3
MCwKICAgY2F0ZWdvcnk6ICdXQVJOSU5HJywKICAgdHJpZ2dlcjogJ0FCT1ZFJywKIH0sCiB7
CiAgIHZhbHVlOiAxMCwKICAgY2F0ZWdvcnk6ICdEQU5HRVInLAogICB0cmlnZ2VyOiAnQkVM
T1cnLAogfSwKIHsKICAgdmFsdWU6IDIwLAogICBjYXRlZ29yeTogJ1dBUk5JTkcnLAogICB0
cmlnZ2VyOiAnQkVMT1cnLAogfQogYGBgCgogVGhlbjogdmFsdWVzIGxlc3MgdGhhbiBvciBl
cXVhbCB0byAxMCB3b3VsZCBwdXQgdGhlIHNjb3JlY2FyZCBpbiBhIERBTkdFUgogc3RhdGUs
IHZhbHVlcyBncmVhdGVyIHRoYW4gMTAgYnV0IGxlc3MgdGhhbiBvciBlcXVhbCB0byAyMCBh
IFdBUk5JTkcgc3RhdGUsCiB2YWx1ZXMgc3RyaWN0bHkgYmV0d2VlbiAyMCBhbmQgNzAgYW4g
T0sgc3RhdGUsIHZhbHVlcyBncmVhdGVyIHRoYW4gb3IgZXF1YWwKIHRvIDcwIGJ1dCBsZXNz
IHRoYW4gOTAgYSBXQVJOSU5HIHN0YXRlLCBhbmQgdmFsdWVzIGdyZWF0ZXIgdGhhbiBvciBl
cXVhbCB0bwogOTAgYSBEQU5HRVIgc3RhdGUuCgoMCgUEAAIEBBIDeQIKCgwKBQQAAgQGEgN5
CxQKDAoFBAACBAESA3kVHwoMCgUEAAIEAxIDeSIjYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::Scorecard::Scorecard ===
    # Fields for Scorecard
    # Field: time_series_query Type: 11 (.google.monitoring.dashboard.v1.TimeSeriesQuery)
    # Field: gauge_view Type: 11 (.google.monitoring.dashboard.v1.Scorecard.GaugeView)
    # Field: spark_chart_view Type: 11 (.google.monitoring.dashboard.v1.Scorecard.SparkChartView)
    # Field: blank_view Type: 11 (.google.protobuf.Empty)
    # Field: thresholds Type: 11 (.google.monitoring.dashboard.v1.Threshold)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::Scorecard - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/scorecard.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::Scorecard;

    my $msg = Google::Monitoring::Dashboard::V1::Scorecard::Scorecard->new({
        time_series_query => $time_series_query,
        gauge_view => $gauge_view,
        spark_chart_view => $spark_chart_view,
        blank_view => $blank_view,
    });

    # Read or update a field
    my $val = $msg->time_series_query();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::Scorecard::Scorecard->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/scorecard.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::Scorecard::Scorecard

A widget showing the latest value of a metric, and how this value relates to
one or more thresholds.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->time_series_query() >> / C<< $msg->time_series_query($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Metrics::TimeSeriesQuery>)

Required. Fields for querying time series data from the
Stackdriver metrics API.

=item * C<< $msg->gauge_view() >> / C<< $msg->gauge_view($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Scorecard::Scorecard::GaugeView>)

Will cause the scorecard to show a gauge chart.

=item * C<< $msg->spark_chart_view() >> / C<< $msg->spark_chart_view($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Scorecard::Scorecard::SparkChartView>)

Will cause the scorecard to show a spark chart.

=item * C<< $msg->blank_view() >> / C<< $msg->blank_view($value) >>

Type: C<Message> (L<Google::Protobuf::Empty::Empty>)

Will cause the `Scorecard` to show only the value, with no indicator to
its value relative to its thresholds.

=item * C<< $msg->thresholds() >> / C<< $msg->thresholds($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Metrics::Threshold>)

The thresholds used to determine the state of the scorecard given the
time series' current value. For an actual value x, the scorecard is in a
danger state if x is less than or equal to a danger threshold that triggers
below, or greater than or equal to a danger threshold that triggers above.
Similarly, if x is above/below a warning threshold that triggers
above/below, then the scorecard is in a warning state - unless x also puts
it in a danger state. (Danger trumps warning.)

As an example, consider a scorecard with the following four thresholds:

```
{
  value: 90,
  category: 'DANGER',
  trigger: 'ABOVE',
},
{
  value: 70,
  category: 'WARNING',
  trigger: 'ABOVE',
},
{
  value: 10,
  category: 'DANGER',
  trigger: 'BELOW',
},
{
  value: 20,
  category: 'WARNING',
  trigger: 'BELOW',
}
```

Then: values less than or equal to 10 would put the scorecard in a DANGER
state, values greater than 10 but less than or equal to 20 a WARNING state,
values strictly between 20 and 70 an OK state, values greater than or equal
to 70 but less than 90 a WARNING state, and values greater than or equal to
90 a DANGER state.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::Scorecard::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
