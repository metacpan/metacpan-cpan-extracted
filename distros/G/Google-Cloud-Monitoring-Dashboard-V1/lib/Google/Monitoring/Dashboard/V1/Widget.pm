package Google::Monitoring::Dashboard::V1::Widget;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Monitoring::Dashboard::V1::Alertchart };
    eval { require Google::Monitoring::Dashboard::V1::CollapsibleGroup };
    eval { require Google::Monitoring::Dashboard::V1::ErrorReportingPanel };
    eval { require Google::Monitoring::Dashboard::V1::IncidentList };
    eval { require Google::Monitoring::Dashboard::V1::LogsPanel };
    eval { require Google::Monitoring::Dashboard::V1::Piechart };
    eval { require Google::Monitoring::Dashboard::V1::Scorecard };
    eval { require Google::Monitoring::Dashboard::V1::SectionHeader };
    eval { require Google::Monitoring::Dashboard::V1::SingleViewGroup };
    eval { require Google::Monitoring::Dashboard::V1::Table };
    eval { require Google::Monitoring::Dashboard::V1::Text };
    eval { require Google::Monitoring::Dashboard::V1::Xychart };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvd2lkZ2V0LnByb3RvEh5nb29nbGUu
bW9uaXRvcmluZy5kYXNoYm9hcmQudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aL2dvb2dsZS9tb25pdG9yaW5nL2Rhc2hib2FyZC92MS9hbGVydGNoYXJ0LnByb3RvGjZn
b29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvY29sbGFwc2libGVfZ3JvdXAucHJvdG8a
Omdvb2dsZS9tb25pdG9yaW5nL2Rhc2hib2FyZC92MS9lcnJvcl9yZXBvcnRpbmdfcGFuZWwu
cHJvdG8aMmdvb2dsZS9tb25pdG9yaW5nL2Rhc2hib2FyZC92MS9pbmNpZGVudF9saXN0LnBy
b3RvGi9nb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvbG9nc19wYW5lbC5wcm90bxot
Z29vZ2xlL21vbml0b3JpbmcvZGFzaGJvYXJkL3YxL3BpZWNoYXJ0LnByb3RvGi5nb29nbGUv
bW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvc2NvcmVjYXJkLnByb3RvGjNnb29nbGUvbW9uaXRv
cmluZy9kYXNoYm9hcmQvdjEvc2VjdGlvbl9oZWFkZXIucHJvdG8aNmdvb2dsZS9tb25pdG9y
aW5nL2Rhc2hib2FyZC92MS9zaW5nbGVfdmlld19ncm91cC5wcm90bxoqZ29vZ2xlL21vbml0
b3JpbmcvZGFzaGJvYXJkL3YxL3RhYmxlLnByb3RvGilnb29nbGUvbW9uaXRvcmluZy9kYXNo
Ym9hcmQvdjEvdGV4dC5wcm90bxosZ29vZ2xlL21vbml0b3JpbmcvZGFzaGJvYXJkL3YxL3h5
Y2hhcnQucHJvdG8aG2dvb2dsZS9wcm90b2J1Zi9lbXB0eS5wcm90byLbCAoGV2lkZ2V0EhkK
BXRpdGxlGAEgASgJQgPgQQFSBXRpdGxlEkQKCHh5X2NoYXJ0GAIgASgLMicuZ29vZ2xlLm1v
bml0b3JpbmcuZGFzaGJvYXJkLnYxLlh5Q2hhcnRIAFIHeHlDaGFydBJJCglzY29yZWNhcmQY
AyABKAsyKS5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEuU2NvcmVjYXJkSABSCXNj
b3JlY2FyZBI6CgR0ZXh0GAQgASgLMiQuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYx
LlRleHRIAFIEdGV4dBIuCgVibGFuaxgFIAEoCzIWLmdvb2dsZS5wcm90b2J1Zi5FbXB0eUgA
UgVibGFuaxJNCgthbGVydF9jaGFydBgHIAEoCzIqLmdvb2dsZS5tb25pdG9yaW5nLmRhc2hi
b2FyZC52MS5BbGVydENoYXJ0SABSCmFsZXJ0Q2hhcnQSXQoRdGltZV9zZXJpZXNfdGFibGUY
CCABKAsyLy5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEuVGltZVNlcmllc1RhYmxl
SABSD3RpbWVTZXJpZXNUYWJsZRJfChFjb2xsYXBzaWJsZV9ncm91cBgJIAEoCzIwLmdvb2ds
ZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5Db2xsYXBzaWJsZUdyb3VwSABSEGNvbGxhcHNp
YmxlR3JvdXASSgoKbG9nc19wYW5lbBgKIAEoCzIpLmdvb2dsZS5tb25pdG9yaW5nLmRhc2hi
b2FyZC52MS5Mb2dzUGFuZWxIAFIJbG9nc1BhbmVsElMKDWluY2lkZW50X2xpc3QYDCABKAsy
LC5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEuSW5jaWRlbnRMaXN0SABSDGluY2lk
ZW50TGlzdBJHCglwaWVfY2hhcnQYDiABKAsyKC5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9h
cmQudjEuUGllQ2hhcnRIAFIIcGllQ2hhcnQSaQoVZXJyb3JfcmVwb3J0aW5nX3BhbmVsGBMg
ASgLMjMuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLkVycm9yUmVwb3J0aW5nUGFu
ZWxIAFITZXJyb3JSZXBvcnRpbmdQYW5lbBJWCg5zZWN0aW9uX2hlYWRlchgVIAEoCzItLmdv
b2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5TZWN0aW9uSGVhZGVySABSDXNlY3Rpb25I
ZWFkZXISXQoRc2luZ2xlX3ZpZXdfZ3JvdXAYFiABKAsyLy5nb29nbGUubW9uaXRvcmluZy5k
YXNoYm9hcmQudjEuU2luZ2xlVmlld0dyb3VwSABSD3NpbmdsZVZpZXdHcm91cBITCgJpZBgR
IAEoCUID4EEBUgJpZEIJCgdjb250ZW50QvQBCiJjb20uZ29vZ2xlLm1vbml0b3JpbmcuZGFz
aGJvYXJkLnYxQgtXaWRnZXRQcm90b1ABWkZjbG91ZC5nb29nbGUuY29tL2dvL21vbml0b3Jp
bmcvZGFzaGJvYXJkL2FwaXYxL2Rhc2hib2FyZHBiO2Rhc2hib2FyZHBiqgIkR29vZ2xlLkNs
b3VkLk1vbml0b3JpbmcuRGFzaGJvYXJkLlYxygIkR29vZ2xlXENsb3VkXE1vbml0b3Jpbmdc
RGFzaGJvYXJkXFYx6gIoR29vZ2xlOjpDbG91ZDo6TW9uaXRvcmluZzo6RGFzaGJvYXJkOjpW
MUrRFgoGEgQOAF4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
IExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAi
TGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxp
YW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBM
aWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNF
LTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8g
aW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlz
IGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMg
T1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4K
IFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBw
ZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhID
EAAnCgkKAgMAEgMSACkKCQoCAwESAxMAOQoJCgIDAhIDFABACgkKAgMDEgMVAEQKCQoCAwQS
AxYAPAoJCgIDBRIDFwA5CgkKAgMGEgMYADcKCQoCAwcSAxkAOAoJCgIDCBIDGgA9CgkKAgMJ
EgMbAEAKCQoCAwoSAxwANAoJCgIDCxIDHQAzCgkKAgMMEgMeADYKCQoCAw0SAx8AJQoICgEI
EgMhAEEKCQoCCCUSAyEAQQoICgEIEgMiAF0KCQoCCAsSAyIAXQoICgEIEgMjACIKCQoCCAoS
AyMAIgoICgEIEgMkACwKCQoCCAgSAyQALAoICgEIEgMlADsKCQoCCAESAyUAOwoICgEIEgMm
AEIKCQoCCCkSAyYAQgoICgEIEgMnAEEKCQoCCC0SAycAQQp/CgIEABIEKwBeARpzIFdpZGdl
dCBjb250YWlucyBhIHNpbmdsZSBkYXNoYm9hcmQgY29tcG9uZW50IGFuZCBjb25maWd1cmF0
aW9uIG9mIGhvdyB0bwogcHJlc2VudCB0aGUgY29tcG9uZW50IGluIHRoZSBkYXNoYm9hcmQu
CgoKCgMEAAESAysIDgoxCgQEAAIAEgMtAjwaJCBPcHRpb25hbC4gVGhlIHRpdGxlIG9mIHRo
ZSB3aWRnZXQuCgoMCgUEAAIABRIDLQIICgwKBQQAAgABEgMtCQ4KDAoFBAACAAMSAy0REgoM
CgUEAAIACBIDLRM7Cg8KCAQAAgAInAgAEgMtFDoKSgoEBAAIABIEMAJZAxo8IENvbnRlbnQg
ZGVmaW5lcyB0aGUgY29tcG9uZW50IHVzZWQgdG8gcG9wdWxhdGUgdGhlIHdpZGdldC4KCgwK
BQQACAABEgMwCA8KKwoEBAACARIDMgQZGh4gQSBjaGFydCBvZiB0aW1lIHNlcmllcyBkYXRh
LgoKDAoFBAACAQYSAzIECwoMCgUEAAIBARIDMgwUCgwKBQQAAgEDEgMyFxgKOAoEBAACAhID
NQQcGisgQSBzY29yZWNhcmQgc3VtbWFyaXppbmcgdGltZSBzZXJpZXMgZGF0YS4KCgwKBQQA
AgIGEgM1BA0KDAoFBAACAgESAzUOFwoMCgUEAAICAxIDNRobCkMKBAQAAgMSAzgEEho2IEEg
cmF3IHN0cmluZyBvciBtYXJrZG93biBkaXNwbGF5aW5nIHRleHR1YWwgY29udGVudC4KCgwK
BQQAAgMGEgM4BAgKDAoFBAACAwESAzgJDQoMCgUEAAIDAxIDOBARCh0KBAQAAgQSAzsEJBoQ
IEEgYmxhbmsgc3BhY2UuCgoMCgUEAAIEBhIDOwQZCgwKBQQAAgQBEgM7Gh8KDAoFBAACBAMS
AzsiIwosCgQEAAIFEgM+BB8aHyBBIGNoYXJ0IG9mIGFsZXJ0IHBvbGljeSBkYXRhLgoKDAoF
BAACBQYSAz4EDgoMCgUEAAIFARIDPg8aCgwKBQQAAgUDEgM+HR4KSwoEBAACBhIDQQQqGj4g
QSB3aWRnZXQgdGhhdCBkaXNwbGF5cyB0aW1lIHNlcmllcyBkYXRhIGluIGEgdGFidWxhciBm
b3JtYXQuCgoMCgUEAAIGBhIDQQQTCgwKBQQAAgYBEgNBFCUKDAoFBAACBgMSA0EoKQqbAQoE
BAACBxIDRQQrGo0BIEEgd2lkZ2V0IHRoYXQgZ3JvdXBzIHRoZSBvdGhlciB3aWRnZXRzLiBB
bGwgd2lkZ2V0cyB0aGF0IGFyZSB3aXRoaW4KIHRoZSBhcmVhIHNwYW5uZWQgYnkgdGhlIGdy
b3VwaW5nIHdpZGdldCBhcmUgY29uc2lkZXJlZCBtZW1iZXIgd2lkZ2V0cy4KCgwKBQQAAgcG
EgNFBBQKDAoFBAACBwESA0UVJgoMCgUEAAIHAxIDRSkqCjQKBAQAAggSA0gEHhonIEEgd2lk
Z2V0IHRoYXQgc2hvd3MgYSBzdHJlYW0gb2YgbG9ncy4KCgwKBQQAAggGEgNIBA0KDAoFBAAC
CAESA0gOGAoMCgUEAAIIAxIDSBsdCjIKBAQAAgkSA0sEJBolIEEgd2lkZ2V0IHRoYXQgc2hv
d3MgbGlzdCBvZiBhbGVydHMuCgoMCgUEAAIJBhIDSwQQCgwKBQQAAgkBEgNLER4KDAoFBAAC
CQMSA0shIwpFCgQEAAIKEgNOBBwaOCBBIHdpZGdldCB0aGF0IGRpc3BsYXlzIHRpbWVzZXJp
ZXMgZGF0YSBhcyBhIHBpZSBjaGFydC4KCgwKBQQAAgoGEgNOBAwKDAoFBAACCgESA04NFgoM
CgUEAAIKAxIDThkbCj0KBAQAAgsSA1EEMxowIEEgd2lkZ2V0IHRoYXQgZGlzcGxheXMgYSBs
aXN0IG9mIGVycm9yIGdyb3Vwcy4KCgwKBQQAAgsGEgNRBBcKDAoFBAACCwESA1EYLQoMCgUE
AAILAxIDUTAyCl4KBAQAAgwSA1UEJhpRIEEgd2lkZ2V0IHRoYXQgZGVmaW5lcyBhIHNlY3Rp
b24gaGVhZGVyIGZvciBlYXNpZXIgbmF2aWdhdGlvbiBvZiB0aGUKIGRhc2hib2FyZC4KCgwK
BQQAAgwGEgNVBBEKDAoFBAACDAESA1USIAoMCgUEAAIMAxIDVSMlCk8KBAQAAg0SA1gEKxpC
IEEgd2lkZ2V0IHRoYXQgZ3JvdXBzIHRoZSBvdGhlciB3aWRnZXRzIGJ5IHVzaW5nIGEgZHJv
cGRvd24gbWVudS4KCgwKBQQAAg0GEgNYBBMKDAoFBAACDQESA1gUJQoMCgUEAAINAxIDWCgq
Cn4KBAQAAg4SA10COhpxIE9wdGlvbmFsLiBUaGUgd2lkZ2V0IGlkLiBJZHMgbWF5IGJlIG1h
ZGUgdXAgb2YgYWxwaGFudW1lcmljcywgZGFzaGVzIGFuZAogdW5kZXJzY29yZXMuIFdpZGdl
dCBpZHMgYXJlIG9wdGlvbmFsLgoKDAoFBAACDgUSA10CCAoMCgUEAAIOARIDXQkLCgwKBQQA
Ag4DEgNdDhAKDAoFBAACDggSA10ROQoPCggEAAIOCJwIABIDXRI4YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::Widget::Widget ===
    # Fields for Widget
    # Field: title Type: 9 ()
    # Field: xy_chart Type: 11 (.google.monitoring.dashboard.v1.XyChart)
    # Field: scorecard Type: 11 (.google.monitoring.dashboard.v1.Scorecard)
    # Field: text Type: 11 (.google.monitoring.dashboard.v1.Text)
    # Field: blank Type: 11 (.google.protobuf.Empty)
    # Field: alert_chart Type: 11 (.google.monitoring.dashboard.v1.AlertChart)
    # Field: time_series_table Type: 11 (.google.monitoring.dashboard.v1.TimeSeriesTable)
    # Field: collapsible_group Type: 11 (.google.monitoring.dashboard.v1.CollapsibleGroup)
    # Field: logs_panel Type: 11 (.google.monitoring.dashboard.v1.LogsPanel)
    # Field: incident_list Type: 11 (.google.monitoring.dashboard.v1.IncidentList)
    # Field: pie_chart Type: 11 (.google.monitoring.dashboard.v1.PieChart)
    # Field: error_reporting_panel Type: 11 (.google.monitoring.dashboard.v1.ErrorReportingPanel)
    # Field: section_header Type: 11 (.google.monitoring.dashboard.v1.SectionHeader)
    # Field: single_view_group Type: 11 (.google.monitoring.dashboard.v1.SingleViewGroup)
    # Field: id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::Widget - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/widget.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::Widget;

    my $msg = Google::Monitoring::Dashboard::V1::Widget::Widget->new({
        title => $title,
        xy_chart => $xy_chart,
        scorecard => $scorecard,
        text => $text,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::Widget::Widget->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/widget.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::Widget::Widget

Widget contains a single dashboard component and configuration of how to
present the component in the dashboard.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Optional. The title of the widget.

=item * C<< $msg->xy_chart() >> / C<< $msg->xy_chart($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Xychart::XyChart>)

A chart of time series data.

=item * C<< $msg->scorecard() >> / C<< $msg->scorecard($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Scorecard::Scorecard>)

A scorecard summarizing time series data.

=item * C<< $msg->text() >> / C<< $msg->text($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Text::Text>)

A raw string or markdown displaying textual content.

=item * C<< $msg->blank() >> / C<< $msg->blank($value) >>

Type: C<Message> (L<Google::Protobuf::Empty::Empty>)

A blank space.

=item * C<< $msg->alert_chart() >> / C<< $msg->alert_chart($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Alertchart::AlertChart>)

A chart of alert policy data.

=item * C<< $msg->time_series_table() >> / C<< $msg->time_series_table($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Table::TimeSeriesTable>)

A widget that displays time series data in a tabular format.

=item * C<< $msg->collapsible_group() >> / C<< $msg->collapsible_group($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::CollapsibleGroup::CollapsibleGroup>)

A widget that groups the other widgets. All widgets that are within
the area spanned by the grouping widget are considered member widgets.

=item * C<< $msg->logs_panel() >> / C<< $msg->logs_panel($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::LogsPanel::LogsPanel>)

A widget that shows a stream of logs.

=item * C<< $msg->incident_list() >> / C<< $msg->incident_list($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::IncidentList::IncidentList>)

A widget that shows list of alerts.

=item * C<< $msg->pie_chart() >> / C<< $msg->pie_chart($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Piechart::PieChart>)

A widget that displays timeseries data as a pie chart.

=item * C<< $msg->error_reporting_panel() >> / C<< $msg->error_reporting_panel($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::ErrorReportingPanel::ErrorReportingPanel>)

A widget that displays a list of error groups.

=item * C<< $msg->section_header() >> / C<< $msg->section_header($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::SectionHeader::SectionHeader>)

A widget that defines a section header for easier navigation of the
dashboard.

=item * C<< $msg->single_view_group() >> / C<< $msg->single_view_group($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::SingleViewGroup::SingleViewGroup>)

A widget that groups the other widgets by using a dropdown menu.

=item * C<< $msg->id() >> / C<< $msg->id($value) >>

Type: C<String>

Optional. The widget id. Ids may be made up of alphanumerics, dashes and
underscores. Widget ids are optional.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::Widget::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
