package Google::Monitoring::Dashboard::V1::Piechart;

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
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvcGllY2hhcnQucHJvdG8SHmdvb2ds
ZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5w
cm90bxosZ29vZ2xlL21vbml0b3JpbmcvZGFzaGJvYXJkL3YxL21ldHJpY3MucHJvdG8aHmdv
b2dsZS9wcm90b2J1Zi9kdXJhdGlvbi5wcm90byKoBAoIUGllQ2hhcnQSWgoJZGF0YV9zZXRz
GAEgAygLMjguZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlBpZUNoYXJ0LlBpZUNo
YXJ0RGF0YVNldEID4EECUghkYXRhU2V0cxJZCgpjaGFydF90eXBlGAIgASgOMjUuZ29vZ2xl
Lm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlBpZUNoYXJ0LlBpZUNoYXJ0VHlwZUID4EECUglj
aGFydFR5cGUSJAoLc2hvd19sYWJlbHMYBCABKAhCA+BBAVIKc2hvd0xhYmVscxr6AQoPUGll
Q2hhcnREYXRhU2V0EmAKEXRpbWVfc2VyaWVzX3F1ZXJ5GAEgASgLMi8uZ29vZ2xlLm1vbml0
b3JpbmcuZGFzaGJvYXJkLnYxLlRpbWVTZXJpZXNRdWVyeUID4EECUg90aW1lU2VyaWVzUXVl
cnkSMwoTc2xpY2VfbmFtZV90ZW1wbGF0ZRgCIAEoCUID4EEBUhFzbGljZU5hbWVUZW1wbGF0
ZRJQChRtaW5fYWxpZ25tZW50X3BlcmlvZBgDIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJh
dGlvbkID4EEBUhJtaW5BbGlnbm1lbnRQZXJpb2QiQgoMUGllQ2hhcnRUeXBlEh4KGlBJRV9D
SEFSVF9UWVBFX1VOU1BFQ0lGSUVEEAASBwoDUElFEAESCQoFRE9OVVQQAkL2AQoiY29tLmdv
b2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MUINUGllQ2hhcnRQcm90b1ABWkZjbG91ZC5n
b29nbGUuY29tL2dvL21vbml0b3JpbmcvZGFzaGJvYXJkL2FwaXYxL2Rhc2hib2FyZHBiO2Rh
c2hib2FyZHBiqgIkR29vZ2xlLkNsb3VkLk1vbml0b3JpbmcuRGFzaGJvYXJkLlYxygIkR29v
Z2xlXENsb3VkXE1vbml0b3JpbmdcRGFzaGJvYXJkXFYx6gIoR29vZ2xlOjpDbG91ZDo6TW9u
aXRvcmluZzo6RGFzaGJvYXJkOjpWMUr7FQoGEgQOAE0BCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAnCgkKAgMAEgMSACkKCQoCAwESAxMANgoJCgIDAhID
FAAoCggKAQgSAxYAQQoJCgIIJRIDFgBBCggKAQgSAxcAXQoJCgIICxIDFwBdCggKAQgSAxgA
IgoJCgIIChIDGAAiCggKAQgSAxkALgoJCgIICBIDGQAuCggKAQgSAxoAOwoJCgIIARIDGgA7
CggKAQgSAxsAQgoJCgIIKRIDGwBCCggKAQgSAxwAQQoJCgIILRIDHABBCkkKAgQAEgQfAE0B
Gj0gQSB3aWRnZXQgdGhhdCBkaXNwbGF5cyB0aW1lc2VyaWVzIGRhdGEgYXMgYSBwaWUgb3Ig
YSBkb251dC4KCgoKAwQAARIDHwgQCjYKBAQAAwASBCECNgMaKCBHcm91cHMgYSB0aW1lIHNl
cmllcyBxdWVyeSBkZWZpbml0aW9uLgoKDAoFBAADAAESAyEKGQpvCgYEAAMAAgASBCQEJTEa
XyBSZXF1aXJlZC4gVGhlIHF1ZXJ5IGZvciB0aGUgUGllQ2hhcnQuIFNlZSwKIGBnb29nbGUu
bW9uaXRvcmluZy5kYXNoYm9hcmQudjEuVGltZVNlcmllc1F1ZXJ5YC4KCg4KBwQAAwACAAYS
AyQEEwoOCgcEAAMAAgABEgMkFCUKDgoHBAADAAIAAxIDJCgpCg4KBwQAAwACAAgSAyUIMAoR
CgoEAAMAAgAInAgAEgMlCS8K0QIKBgQAAwACARIDLQRMGsECIE9wdGlvbmFsLiBBIHRlbXBs
YXRlIGZvciB0aGUgbmFtZSBvZiB0aGUgc2xpY2UuIFRoaXMgbmFtZSB3aWxsIGJlCiBkaXNw
bGF5ZWQgaW4gdGhlIGxlZ2VuZCBhbmQgdGhlIHRvb2x0aXAgb2YgdGhlIHBpZSBjaGFydC4g
SXQgcmVwbGFjZXMgdGhlCiBhdXRvLWdlbmVyYXRlZCBuYW1lcyBmb3IgdGhlIHNsaWNlcy4g
Rm9yIGV4YW1wbGUsIGlmIHRoZSB0ZW1wbGF0ZSBpcyBzZXQKIHRvCiBgJHtyZXNvdXJjZS5s
YWJlbHMuem9uZX1gLCB0aGUgem9uZSdzIHZhbHVlIHdpbGwgYmUgdXNlZCBmb3IgdGhlIG5h
bWUKIGluc3RlYWQgb2YgdGhlIGRlZmF1bHQgbmFtZS4KCg4KBwQAAwACAQUSAy0ECgoOCgcE
AAMAAgEBEgMtCx4KDgoHBAADAAIBAxIDLSEiCg4KBwQAAwACAQgSAy0jSwoRCgoEAAMAAgEI
nAgAEgMtJEoK8QIKBgQAAwACAhIENAQ1MRrgAiBPcHRpb25hbC4gVGhlIGxvd2VyIGJvdW5k
IG9uIGRhdGEgcG9pbnQgZnJlcXVlbmN5IGZvciB0aGlzIGRhdGEgc2V0LAogaW1wbGVtZW50
ZWQgYnkgc3BlY2lmeWluZyB0aGUgbWluaW11bSBhbGlnbm1lbnQgcGVyaW9kIHRvIHVzZSBp
biBhIHRpbWUKIHNlcmllcyBxdWVyeS4gRm9yIGV4YW1wbGUsIGlmIHRoZSBkYXRhIGlzIHB1
Ymxpc2hlZCBvbmNlIGV2ZXJ5IDEwCiBtaW51dGVzLCB0aGUgYG1pbl9hbGlnbm1lbnRfcGVy
aW9kYCBzaG91bGQgYmUgYXQgbGVhc3QgMTAgbWludXRlcy4gSXQKIHdvdWxkIG5vdCBtYWtl
IHNlbnNlIHRvIGZldGNoIGFuZCBhbGlnbiBkYXRhIGF0IG9uZSBtaW51dGUgaW50ZXJ2YWxz
LgoKDgoHBAADAAICBhIDNAQcCg4KBwQAAwACAgESAzQdMQoOCgcEAAMAAgIDEgM0NDUKDgoH
BAADAAICCBIDNQgwChEKCgQAAwACAgicCAASAzUJLwooCgQEAAQAEgQ5AkIDGhogVHlwZXMg
Zm9yIHRoZSBwaWUgY2hhcnQuCgoMCgUEAAQAARIDOQcTCj8KBgQABAACABIDOwQjGjAgVGhl
IHplcm8gdmFsdWUuIE5vIHR5cGUgc3BlY2lmaWVkLiBEbyBub3QgdXNlLgoKDgoHBAAEAAIA
ARIDOwQeCg4KBwQABAACAAISAzshIgolCgYEAAQAAgESAz4EDBoWIEEgUGllIHR5cGUgUGll
Q2hhcnQuCgoOCgcEAAQAAgEBEgM+BAcKDgoHBAAEAAIBAhIDPgoLClYKBgQABAACAhIDQQQO
GkcgU2ltaWxhciB0byBQSUUsIGJ1dCB0aGUgRE9OVVQgdHlwZSBQaWVDaGFydCBoYXMgYSBo
b2xlIGluIHRoZSBtaWRkbGUuCgoOCgcEAAQAAgIBEgNBBAkKDgoHBAAEAAICAhIDQQwNCjsK
BAQAAgASBEUCRi8aLSBSZXF1aXJlZC4gVGhlIHF1ZXJpZXMgZm9yIHRoZSBjaGFydCdzIGRh
dGEuCgoMCgUEAAIABBIDRQIKCgwKBQQAAgAGEgNFCxoKDAoFBAACAAESA0UbJAoMCgUEAAIA
AxIDRScoCgwKBQQAAgAIEgNGBi4KDwoIBAACAAicCAASA0YHLQpLCgQEAAIBEgNJAkcaPiBS
ZXF1aXJlZC4gSW5kaWNhdGVzIHRoZSB2aXN1YWxpemF0aW9uIHR5cGUgZm9yIHRoZSBQaWVD
aGFydC4KCgwKBQQAAgEGEgNJAg4KDAoFBAACAQESA0kPGQoMCgUEAAIBAxIDSRwdCgwKBQQA
AgEIEgNJHkYKDwoIBAACAQicCAASA0kfRQpaCgQEAAICEgNMAkAaTSBPcHRpb25hbC4gSW5k
aWNhdGVzIHdoZXRoZXIgb3Igbm90IHRoZSBwaWUgY2hhcnQgc2hvdWxkIHNob3cgc2xpY2Vz
JyBsYWJlbHMKCgwKBQQAAgIFEgNMAgYKDAoFBAACAgESA0wHEgoMCgUEAAICAxIDTBUWCgwK
BQQAAgIIEgNMFz8KDwoIBAACAgicCAASA0wYPmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::Piechart::PieChart ===
    # Fields for PieChart
    # Field: data_sets Type: 11 (.google.monitoring.dashboard.v1.PieChart.PieChartDataSet)
    # Field: chart_type Type: 14 (.google.monitoring.dashboard.v1.PieChart.PieChartType)
    # Field: show_labels Type: 8 ()

# Enum: PieChart::PieChartType
our $PieChart_PIE_CHART_TYPE_UNSPECIFIED = 0;
our $PieChart_PIE = 1;
our $PieChart_DONUT = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::Piechart - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/piechart.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::Piechart;

    my $msg = Google::Monitoring::Dashboard::V1::Piechart::PieChart->new({
        data_sets => $data_sets,
        chart_type => $chart_type,
        show_labels => $show_labels,
    });

    # Read or update a field
    my $val = $msg->data_sets();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::Piechart::PieChart->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/piechart.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::Piechart::PieChart

A widget that displays timeseries data as a pie or a donut.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->data_sets() >> / C<< $msg->data_sets($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Piechart::PieChart::PieChartDataSet>)

Required. The queries for the chart's data.

=item * C<< $msg->chart_type() >> / C<< $msg->chart_type($value) >>

Type: C<Enum> (L<Google::Monitoring::Dashboard::V1::PieChart::PieChartType>)

Required. Indicates the visualization type for the PieChart.

=item * C<< $msg->show_labels() >> / C<< $msg->show_labels($value) >>

Type: C<Bool>

Optional. Indicates whether or not the pie chart should show slices' labels

=back

=head3 Enum: PieChart::PieChartType

=over 4

=item * C<PIE_CHART_TYPE_UNSPECIFIED> => C<0>

=item * C<PIE> => C<1>

=item * C<DONUT> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::Piechart::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
