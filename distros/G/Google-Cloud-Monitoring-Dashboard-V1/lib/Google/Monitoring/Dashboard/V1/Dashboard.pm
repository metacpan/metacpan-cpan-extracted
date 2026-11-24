package Google::Monitoring::Dashboard::V1::Dashboard;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Monitoring::Dashboard::V1::DashboardFilter };
    eval { require Google::Monitoring::Dashboard::V1::Layouts };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvZGFzaGJvYXJkLnByb3RvEh5nb29n
bGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aNWdvb2dsZS9tb25pdG9yaW5nL2Rh
c2hib2FyZC92MS9kYXNoYm9hcmRfZmlsdGVyLnByb3RvGixnb29nbGUvbW9uaXRvcmluZy9k
YXNoYm9hcmQvdjEvbGF5b3V0cy5wcm90byLsBQoJRGFzaGJvYXJkEhcKBG5hbWUYASABKAlC
A+BBCFIEbmFtZRImCgxkaXNwbGF5X25hbWUYAiABKAlCA+BBAlILZGlzcGxheU5hbWUSEgoE
ZXRhZxgEIAEoCVIEZXRhZxJNCgtncmlkX2xheW91dBgFIAEoCzIqLmdvb2dsZS5tb25pdG9y
aW5nLmRhc2hib2FyZC52MS5HcmlkTGF5b3V0SABSCmdyaWRMYXlvdXQSUwoNbW9zYWljX2xh
eW91dBgGIAEoCzIsLmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5Nb3NhaWNMYXlv
dXRIAFIMbW9zYWljTGF5b3V0EkoKCnJvd19sYXlvdXQYCCABKAsyKS5nb29nbGUubW9uaXRv
cmluZy5kYXNoYm9hcmQudjEuUm93TGF5b3V0SABSCXJvd0xheW91dBJTCg1jb2x1bW5fbGF5
b3V0GAkgASgLMiwuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLkNvbHVtbkxheW91
dEgAUgxjb2x1bW5MYXlvdXQSXAoRZGFzaGJvYXJkX2ZpbHRlcnMYCyADKAsyLy5nb29nbGUu
bW9uaXRvcmluZy5kYXNoYm9hcmQudjEuRGFzaGJvYXJkRmlsdGVyUhBkYXNoYm9hcmRGaWx0
ZXJzEk0KBmxhYmVscxgMIAMoCzI1Lmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5E
YXNoYm9hcmQuTGFiZWxzRW50cnlSBmxhYmVscxo5CgtMYWJlbHNFbnRyeRIQCgNrZXkYASAB
KAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBOlPqQVAKI21vbml0b3JpbmcuZ29v
Z2xlYXBpcy5jb20vRGFzaGJvYXJkEilwcm9qZWN0cy97cHJvamVjdH0vZGFzaGJvYXJkcy97
ZGFzaGJvYXJkfUIICgZsYXlvdXRC+AEKImNvbS5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9h
cmQudjFCD0Rhc2hib2FyZHNQcm90b1ABWkZjbG91ZC5nb29nbGUuY29tL2dvL21vbml0b3Jp
bmcvZGFzaGJvYXJkL2FwaXYxL2Rhc2hib2FyZHBiO2Rhc2hib2FyZHBiqgIkR29vZ2xlLkNs
b3VkLk1vbml0b3JpbmcuRGFzaGJvYXJkLlYxygIkR29vZ2xlXENsb3VkXE1vbml0b3Jpbmdc
RGFzaGJvYXJkXFYx6gIoR29vZ2xlOjpDbG91ZDo6TW9uaXRvcmluZzo6RGFzaGJvYXJkOjpW
MUqIFQoGEgQOAE4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoK
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
EAAnCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA/CgkKAgMDEgMVADYKCAoBCBID
FwBBCgkKAgglEgMXAEEKCAoBCBIDGABdCgkKAggLEgMYAF0KCAoBCBIDGQAiCgkKAggKEgMZ
ACIKCAoBCBIDGgAwCgkKAggIEgMaADAKCAoBCBIDGwA7CgkKAggBEgMbADsKCAoBCBIDHABC
CgkKAggpEgMcAEIKCAoBCBIDHQBBCgkKAggtEgMdAEEKhAEKAgQAEgQhAE4BGnggQSBHb29n
bGUgU3RhY2tkcml2ZXIgZGFzaGJvYXJkLiBEYXNoYm9hcmRzIGRlZmluZSB0aGUgY29udGVu
dCBhbmQgbGF5b3V0CiBvZiBwYWdlcyBpbiB0aGUgU3RhY2tkcml2ZXIgd2ViIGFwcGxpY2F0
aW9uLgoKCgoDBAABEgMhCBEKCwoDBAAHEgQiAiUECg0KBQQAB50IEgQiAiUECj4KBAQAAgAS
AygCPRoxIElkZW50aWZpZXIuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBkYXNoYm9hcmQu
CgoMCgUEAAIABRIDKAIICgwKBQQAAgABEgMoCQ0KDAoFBAACAAMSAygQEQoMCgUEAAIACBID
KBI8Cg8KCAQAAgAInAgAEgMoEzsKOgoEBAACARIDKwJDGi0gUmVxdWlyZWQuIFRoZSBtdXRh
YmxlLCBodW1hbi1yZWFkYWJsZSBuYW1lLgoKDAoFBAACAQUSAysCCAoMCgUEAAIBARIDKwkV
CgwKBQQAAgEDEgMrGBkKDAoFBAACAQgSAysaQgoPCggEAAIBCJwIABIDKxtBCr0DCgQEAAIC
EgM0AhIarwMgYGV0YWdgIGlzIHVzZWQgZm9yIG9wdGltaXN0aWMgY29uY3VycmVuY3kgY29u
dHJvbCBhcyBhIHdheSB0byBoZWxwCiBwcmV2ZW50IHNpbXVsdGFuZW91cyB1cGRhdGVzIG9m
IGEgcG9saWN5IGZyb20gb3ZlcndyaXRpbmcgZWFjaCBvdGhlci4KIEFuIGBldGFnYCBpcyBy
ZXR1cm5lZCBpbiB0aGUgcmVzcG9uc2UgdG8gYEdldERhc2hib2FyZGAsIGFuZAogdXNlcnMg
YXJlIGV4cGVjdGVkIHRvIHB1dCB0aGF0IGV0YWcgaW4gdGhlIHJlcXVlc3QgdG8gYFVwZGF0
ZURhc2hib2FyZGAgdG8KIGVuc3VyZSB0aGF0IHRoZWlyIGNoYW5nZSB3aWxsIGJlIGFwcGxp
ZWQgdG8gdGhlIHNhbWUgdmVyc2lvbiBvZiB0aGUKIERhc2hib2FyZCBjb25maWd1cmF0aW9u
LiBUaGUgZmllbGQgc2hvdWxkIG5vdCBiZSBwYXNzZWQgZHVyaW5nCiBkYXNoYm9hcmQgY3Jl
YXRpb24uCgoMCgUEAAICBRIDNAIICgwKBQQAAgIBEgM0CQ0KDAoFBAACAgMSAzQQEQpTCgQE
AAgAEgQ3AkcDGkUgQSBkYXNoYm9hcmQncyByb290IGNvbnRhaW5lciBlbGVtZW50IHRoYXQg
ZGVmaW5lcyB0aGUgbGF5b3V0IHN0eWxlLgoKDAoFBAAIAAESAzcIDgqEAQoEBAACAxIDOgQf
GncgQ29udGVudCBpcyBhcnJhbmdlZCB3aXRoIGEgYmFzaWMgbGF5b3V0IHRoYXQgcmUtZmxv
d3MgYSBzaW1wbGUgbGlzdCBvZgogaW5mb3JtYXRpb25hbCBlbGVtZW50cyBsaWtlIHdpZGdl
dHMgb3IgdGlsZXMuCgoMCgUEAAIDBhIDOgQOCgwKBQQAAgMBEgM6DxoKDAoFBAACAwMSAzod
Hgp3CgQEAAIEEgM+BCMaaiBUaGUgY29udGVudCBpcyBhcnJhbmdlZCBhcyBhIGdyaWQgb2Yg
dGlsZXMsIHdpdGggZWFjaCBjb250ZW50IHdpZGdldAogb2NjdXB5aW5nIG9uZSBvciBtb3Jl
IGdyaWQgYmxvY2tzLgoKDAoFBAACBAYSAz4EEAoMCgUEAAIEARIDPhEeCgwKBQQAAgQDEgM+
ISIKagoEBAACBRIDQgQdGl0gVGhlIGNvbnRlbnQgaXMgZGl2aWRlZCBpbnRvIGVxdWFsbHkg
c3BhY2VkIHJvd3MgYW5kIHRoZSB3aWRnZXRzIGFyZQogYXJyYW5nZWQgaG9yaXpvbnRhbGx5
LgoKDAoFBAACBQYSA0IEDQoMCgUEAAIFARIDQg4YCgwKBQQAAgUDEgNCGxwKawoEBAACBhID
RgQjGl4gVGhlIGNvbnRlbnQgaXMgZGl2aWRlZCBpbnRvIGVxdWFsbHkgc3BhY2VkIGNvbHVt
bnMgYW5kIHRoZSB3aWRnZXRzIGFyZQogYXJyYW5nZWQgdmVydGljYWxseS4KCgwKBQQAAgYG
EgNGBBAKDAoFBAACBgESA0YRHgoMCgUEAAIGAxIDRiEiClkKBAQAAgcSA0oCMhpMIEZpbHRl
cnMgdG8gcmVkdWNlIHRoZSBhbW91bnQgb2YgZGF0YSBjaGFydGVkIGJhc2VkIG9uIHRoZSBm
aWx0ZXIgY3JpdGVyaWEuCgoMCgUEAAIHBBIDSgIKCgwKBQQAAgcGEgNKCxoKDAoFBAACBwES
A0obLAoMCgUEAAIHAxIDSi8xCi4KBAQAAggSA00CIhohIExhYmVscyBhcHBsaWVkIHRvIHRo
ZSBkYXNoYm9hcmQKCgwKBQQAAggGEgNNAhUKDAoFBAACCAESA00WHAoMCgUEAAIIAxIDTR8h
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::Dashboard::Dashboard ===
    # Fields for Dashboard
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: etag Type: 9 ()
    # Field: grid_layout Type: 11 (.google.monitoring.dashboard.v1.GridLayout)
    # Field: mosaic_layout Type: 11 (.google.monitoring.dashboard.v1.MosaicLayout)
    # Field: row_layout Type: 11 (.google.monitoring.dashboard.v1.RowLayout)
    # Field: column_layout Type: 11 (.google.monitoring.dashboard.v1.ColumnLayout)
    # Field: dashboard_filters Type: 11 (.google.monitoring.dashboard.v1.DashboardFilter)
    # Field: labels Type: 11 (.google.monitoring.dashboard.v1.Dashboard.LabelsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::Dashboard - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/dashboard.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::Dashboard;

    my $msg = Google::Monitoring::Dashboard::V1::Dashboard::Dashboard->new({
        name => $name,
        display_name => $display_name,
        etag => $etag,
        grid_layout => $grid_layout,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::Dashboard::Dashboard->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/dashboard.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::Dashboard::Dashboard

A Google Stackdriver dashboard. Dashboards define the content and layout
of pages in the Stackdriver web application.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the dashboard.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Required. The mutable, human-readable name.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

`etag` is used for optimistic concurrency control as a way to help
prevent simultaneous updates of a policy from overwriting each other.
An `etag` is returned in the response to `GetDashboard`, and
users are expected to put that etag in the request to `UpdateDashboard` to
ensure that their change will be applied to the same version of the
Dashboard configuration. The field should not be passed during
dashboard creation.

=item * C<< $msg->grid_layout() >> / C<< $msg->grid_layout($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Layouts::GridLayout>)

Content is arranged with a basic layout that re-flows a simple list of
informational elements like widgets or tiles.

=item * C<< $msg->mosaic_layout() >> / C<< $msg->mosaic_layout($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Layouts::MosaicLayout>)

The content is arranged as a grid of tiles, with each content widget
occupying one or more grid blocks.

=item * C<< $msg->row_layout() >> / C<< $msg->row_layout($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Layouts::RowLayout>)

The content is divided into equally spaced rows and the widgets are
arranged horizontally.

=item * C<< $msg->column_layout() >> / C<< $msg->column_layout($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Layouts::ColumnLayout>)

The content is divided into equally spaced columns and the widgets are
arranged vertically.

=item * C<< $msg->dashboard_filters() >> / C<< $msg->dashboard_filters($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::DashboardFilter::DashboardFilter>)

Filters to reduce the amount of data charted based on the filter criteria.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Dashboard::Dashboard::LabelsEntry>)

Labels applied to the dashboard

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::Dashboard::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
