package Google::Monitoring::Dashboard::V1::Layouts;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Monitoring::Dashboard::V1::Widget };
    my $descriptor_b64 = <<'EOF';
Cixnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQvdjEvbGF5b3V0cy5wcm90bxIeZ29vZ2xl
Lm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxGitnb29nbGUvbW9uaXRvcmluZy9kYXNoYm9hcmQv
djEvd2lkZ2V0LnByb3RvImgKCkdyaWRMYXlvdXQSGAoHY29sdW1ucxgBIAEoA1IHY29sdW1u
cxJACgd3aWRnZXRzGAIgAygLMiYuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLldp
ZGdldFIHd2lkZ2V0cyKSAgoMTW9zYWljTGF5b3V0EhgKB2NvbHVtbnMYASABKAVSB2NvbHVt
bnMSRwoFdGlsZXMYAyADKAsyMS5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9hcmQudjEuTW9z
YWljTGF5b3V0LlRpbGVSBXRpbGVzGp4BCgRUaWxlEhMKBXhfcG9zGAEgASgFUgR4UG9zEhMK
BXlfcG9zGAIgASgFUgR5UG9zEhQKBXdpZHRoGAMgASgFUgV3aWR0aBIWCgZoZWlnaHQYBCAB
KAVSBmhlaWdodBI+CgZ3aWRnZXQYBSABKAsyJi5nb29nbGUubW9uaXRvcmluZy5kYXNoYm9h
cmQudjEuV2lkZ2V0UgZ3aWRnZXQirwEKCVJvd0xheW91dBJBCgRyb3dzGAEgAygLMi0uZ29v
Z2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYxLlJvd0xheW91dC5Sb3dSBHJvd3MaXwoDUm93
EhYKBndlaWdodBgBIAEoA1IGd2VpZ2h0EkAKB3dpZGdldHMYAiADKAsyJi5nb29nbGUubW9u
aXRvcmluZy5kYXNoYm9hcmQudjEuV2lkZ2V0Ugd3aWRnZXRzIsEBCgxDb2x1bW5MYXlvdXQS
TQoHY29sdW1ucxgBIAMoCzIzLmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52MS5Db2x1
bW5MYXlvdXQuQ29sdW1uUgdjb2x1bW5zGmIKBkNvbHVtbhIWCgZ3ZWlnaHQYASABKANSBndl
aWdodBJACgd3aWRnZXRzGAIgAygLMiYuZ29vZ2xlLm1vbml0b3JpbmcuZGFzaGJvYXJkLnYx
LldpZGdldFIHd2lkZ2V0c0L1AQoiY29tLmdvb2dsZS5tb25pdG9yaW5nLmRhc2hib2FyZC52
MUIMTGF5b3V0c1Byb3RvUAFaRmNsb3VkLmdvb2dsZS5jb20vZ28vbW9uaXRvcmluZy9kYXNo
Ym9hcmQvYXBpdjEvZGFzaGJvYXJkcGI7ZGFzaGJvYXJkcGKqAiRHb29nbGUuQ2xvdWQuTW9u
aXRvcmluZy5EYXNoYm9hcmQuVjHKAiRHb29nbGVcQ2xvdWRcTW9uaXRvcmluZ1xEYXNoYm9h
cmRcVjHqAihHb29nbGU6OkNsb3VkOjpNb25pdG9yaW5nOjpEYXNoYm9hcmQ6OlYxSv8hCgYS
BA4AbwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCQoC
AwASAxIANQoICgEIEgMUAEEKCQoCCCUSAxQAQQoICgEIEgMVAF0KCQoCCAsSAxUAXQoICgEI
EgMWACIKCQoCCAoSAxYAIgoICgEIEgMXAC0KCQoCCAgSAxcALQoICgEIEgMYADsKCQoCCAES
AxgAOwoICgEIEgMZAEIKCQoCCCkSAxkAQgoICgEIEgMaAEEKCQoCCC0SAxoAQQqaAQoCBAAS
BB4AJQEajQEgQSBiYXNpYyBsYXlvdXQgZGl2aWRlcyB0aGUgYXZhaWxhYmxlIHNwYWNlIGlu
dG8gdmVydGljYWwgY29sdW1ucyBvZiBlcXVhbAogd2lkdGggYW5kIGFycmFuZ2VzIGEgbGlz
dCBvZiB3aWRnZXRzIHVzaW5nIGEgcm93LWZpcnN0IHN0cmF0ZWd5LgoKCgoDBAABEgMeCBIK
mAEKBAQAAgASAyECFBqKASBUaGUgbnVtYmVyIG9mIGNvbHVtbnMgaW50byB3aGljaCB0aGUg
dmlldydzIHdpZHRoIGlzIGRpdmlkZWQuIElmIG9taXR0ZWQKIG9yIHNldCB0byB6ZXJvLCBh
IHN5c3RlbSBkZWZhdWx0IHdpbGwgYmUgdXNlZCB3aGlsZSByZW5kZXJpbmcuCgoMCgUEAAIA
BRIDIQIHCgwKBQQAAgABEgMhCA8KDAoFBAACAAMSAyESEwpXCgQEAAIBEgMkAh4aSiBUaGUg
aW5mb3JtYXRpb25hbCBlbGVtZW50cyB0aGF0IGFyZSBhcnJhbmdlZCBpbnRvIHRoZSBjb2x1
bW5zIHJvdy1maXJzdC4KCgwKBQQAAgEEEgMkAgoKDAoFBAACAQYSAyQLEQoMCgUEAAIBARID
JBIZCgwKBQQAAgEDEgMkHB0K5AEKAgQBEgQqAEkBGtcBIEEgbW9zYWljIGxheW91dCBkaXZp
ZGVzIHRoZSBhdmFpbGFibGUgc3BhY2UgaW50byBhIGdyaWQgb2YgYmxvY2tzLCBhbmQKIG92
ZXJsYXlzIHRoZSBncmlkIHdpdGggdGlsZXMuIFVubGlrZSBgR3JpZExheW91dGAsIHRpbGVz
IG1heSBzcGFuIG11bHRpcGxlCiBncmlkIGJsb2NrcyBhbmQgY2FuIGJlIHBsYWNlZCBhdCBh
cmJpdHJhcnkgbG9jYXRpb25zIGluIHRoZSBncmlkLgoKCgoDBAEBEgMqCBQKYgoEBAEDABIE
LQJBAxpUIEEgc2luZ2xlIHRpbGUgaW4gdGhlIG1vc2FpYy4gVGhlIHBsYWNlbWVudCBhbmQg
c2l6ZSBvZiB0aGUgdGlsZSBhcmUKIGNvbmZpZ3VyYWJsZS4KCgwKBQQBAwABEgMtCg4KywEK
BgQBAwACABIDMQQUGrsBIFRoZSB6ZXJvLWluZGV4ZWQgcG9zaXRpb24gb2YgdGhlIHRpbGUg
aW4gZ3JpZCBibG9ja3MgcmVsYXRpdmUgdG8gdGhlCiBsZWZ0IGVkZ2Ugb2YgdGhlIGdyaWQu
IFRpbGVzIG11c3QgYmUgY29udGFpbmVkIHdpdGhpbiB0aGUgc3BlY2lmaWVkCiBudW1iZXIg
b2YgY29sdW1ucy4gYHhfcG9zYCBjYW5ub3QgYmUgbmVnYXRpdmUuCgoOCgcEAQMAAgAFEgMx
BAkKDgoHBAEDAAIAARIDMQoPCg4KBwQBAwACAAMSAzESEwqIAQoGBAEDAAIBEgM1BBQaeSBU
aGUgemVyby1pbmRleGVkIHBvc2l0aW9uIG9mIHRoZSB0aWxlIGluIGdyaWQgYmxvY2tzIHJl
bGF0aXZlIHRvIHRoZQogdG9wIGVkZ2Ugb2YgdGhlIGdyaWQuIGB5X3Bvc2AgY2Fubm90IGJl
IG5lZ2F0aXZlLgoKDgoHBAEDAAIBBRIDNQQJCg4KBwQBAwACAQESAzUKDwoOCgcEAQMAAgED
EgM1EhMKZwoGBAEDAAICEgM5BBQaWCBUaGUgd2lkdGggb2YgdGhlIHRpbGUsIG1lYXN1cmVk
IGluIGdyaWQgYmxvY2tzLiBUaWxlcyBtdXN0IGhhdmUgYQogbWluaW11bSB3aWR0aCBvZiAx
LgoKDgoHBAEDAAICBRIDOQQJCg4KBwQBAwACAgESAzkKDwoOCgcEAQMAAgIDEgM5EhMKaQoG
BAEDAAIDEgM9BBUaWiBUaGUgaGVpZ2h0IG9mIHRoZSB0aWxlLCBtZWFzdXJlZCBpbiBncmlk
IGJsb2Nrcy4gVGlsZXMgbXVzdCBoYXZlIGEKIG1pbmltdW0gaGVpZ2h0IG9mIDEuCgoOCgcE
AQMAAgMFEgM9BAkKDgoHBAEDAAIDARIDPQoQCg4KBwQBAwACAwMSAz0TFApaCgYEAQMAAgQS
A0AEFhpLIFRoZSBpbmZvcm1hdGlvbmFsIHdpZGdldCBjb250YWluZWQgaW4gdGhlIHRpbGUu
IEZvciBleGFtcGxlIGFuIGBYeUNoYXJ0YC4KCg4KBwQBAwACBAYSA0AECgoOCgcEAQMAAgQB
EgNACxEKDgoHBAEDAAIEAxIDQBQVCnQKBAQBAgASA0UCFBpnIFRoZSBudW1iZXIgb2YgY29s
dW1ucyBpbiB0aGUgbW9zYWljIGdyaWQuIFRoZSBudW1iZXIgb2YgY29sdW1ucyBtdXN0IGJl
CiBiZXR3ZWVuIDEgYW5kIDEyLCBpbmNsdXNpdmUuCgoMCgUEAQIABRIDRQIHCgwKBQQBAgAB
EgNFCA8KDAoFBAECAAMSA0USEwokCgQEAQIBEgNIAhoaFyBUaGUgdGlsZXMgdG8gZGlzcGxh
eS4KCgwKBQQBAgEEEgNIAgoKDAoFBAECAQYSA0gLDwoMCgUEAQIBARIDSBAVCgwKBQQBAgED
EgNIGBkKhQEKAgQCEgRNAFwBGnkgQSBzaW1wbGlmaWVkIGxheW91dCB0aGF0IGRpdmlkZXMg
dGhlIGF2YWlsYWJsZSBzcGFjZSBpbnRvIHJvd3MKIGFuZCBhcnJhbmdlcyBhIHNldCBvZiB3
aWRnZXRzIGhvcml6b250YWxseSBpbiBlYWNoIHJvdy4KCgoKAwQCARIDTQgRCkQKBAQCAwAS
BE8CWAMaNiBEZWZpbmVzIHRoZSBsYXlvdXQgcHJvcGVydGllcyBhbmQgY29udGVudCBmb3Ig
YSByb3cuCgoMCgUEAgMAARIDTwoNCv8BCgYEAgMAAgASA1QEFRrvASBUaGUgcmVsYXRpdmUg
d2VpZ2h0IG9mIHRoaXMgcm93LiBUaGUgcm93IHdlaWdodCBpcyB1c2VkIHRvIGFkanVzdCB0
aGUKIGhlaWdodCBvZiByb3dzIG9uIHRoZSBzY3JlZW4gKHJlbGF0aXZlIHRvIHBlZXJzKS4g
R3JlYXRlciB0aGUgd2VpZ2h0LAogZ3JlYXRlciB0aGUgaGVpZ2h0IG9mIHRoZSByb3cgb24g
dGhlIHNjcmVlbi4gSWYgb21pdHRlZCwgYSB2YWx1ZQogb2YgMSBpcyB1c2VkIHdoaWxlIHJl
bmRlcmluZy4KCg4KBwQCAwACAAUSA1QECQoOCgcEAgMAAgABEgNUChAKDgoHBAIDAAIAAxID
VBMUCkcKBgQCAwACARIDVwQgGjggVGhlIGRpc3BsYXkgd2lkZ2V0cyBhcnJhbmdlZCBob3Jp
em9udGFsbHkgaW4gdGhpcyByb3cuCgoOCgcEAgMAAgEEEgNXBAwKDgoHBAIDAAIBBhIDVw0T
Cg4KBwQCAwACAQESA1cUGwoOCgcEAgMAAgEDEgNXHh8KLgoEBAICABIDWwIYGiEgVGhlIHJv
d3Mgb2YgY29udGVudCB0byBkaXNwbGF5LgoKDAoFBAICAAQSA1sCCgoMCgUEAgIABhIDWwsO
CgwKBQQCAgABEgNbDxMKDAoFBAICAAMSA1sWFwqTAQoCBAMSBGAAbwEahgEgQSBzaW1wbGlm
aWVkIGxheW91dCB0aGF0IGRpdmlkZXMgdGhlIGF2YWlsYWJsZSBzcGFjZSBpbnRvIHZlcnRp
Y2FsIGNvbHVtbnMKIGFuZCBhcnJhbmdlcyBhIHNldCBvZiB3aWRnZXRzIHZlcnRpY2FsbHkg
aW4gZWFjaCBjb2x1bW4uCgoKCgMEAwESA2AIFApHCgQEAwMAEgRiAmsDGjkgRGVmaW5lcyB0
aGUgbGF5b3V0IHByb3BlcnRpZXMgYW5kIGNvbnRlbnQgZm9yIGEgY29sdW1uLgoKDAoFBAMD
AAESA2IKEAqJAgoGBAMDAAIAEgNnBBUa+QEgVGhlIHJlbGF0aXZlIHdlaWdodCBvZiB0aGlz
IGNvbHVtbi4gVGhlIGNvbHVtbiB3ZWlnaHQgaXMgdXNlZCB0byBhZGp1c3QKIHRoZSB3aWR0
aCBvZiBjb2x1bW5zIG9uIHRoZSBzY3JlZW4gKHJlbGF0aXZlIHRvIHBlZXJzKS4KIEdyZWF0
ZXIgdGhlIHdlaWdodCwgZ3JlYXRlciB0aGUgd2lkdGggb2YgdGhlIGNvbHVtbiBvbiB0aGUg
c2NyZWVuLgogSWYgb21pdHRlZCwgYSB2YWx1ZSBvZiAxIGlzIHVzZWQgd2hpbGUgcmVuZGVy
aW5nLgoKDgoHBAMDAAIABRIDZwQJCg4KBwQDAwACAAESA2cKEAoOCgcEAwMAAgADEgNnExQK
SAoGBAMDAAIBEgNqBCAaOSBUaGUgZGlzcGxheSB3aWRnZXRzIGFycmFuZ2VkIHZlcnRpY2Fs
bHkgaW4gdGhpcyBjb2x1bW4uCgoOCgcEAwMAAgEEEgNqBAwKDgoHBAMDAAIBBhIDag0TCg4K
BwQDAwACAQESA2oUGwoOCgcEAwMAAgEDEgNqHh8KMQoEBAMCABIDbgIeGiQgVGhlIGNvbHVt
bnMgb2YgY29udGVudCB0byBkaXNwbGF5LgoKDAoFBAMCAAQSA24CCgoMCgUEAwIABhIDbgsR
CgwKBQQDAgABEgNuEhkKDAoFBAMCAAMSA24cHWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Monitoring::Dashboard::V1::Layouts::GridLayout ===
    # Fields for GridLayout
    # Field: columns Type: 3 ()
    # Field: widgets Type: 11 (.google.monitoring.dashboard.v1.Widget)

# === Message: Google::Monitoring::Dashboard::V1::Layouts::MosaicLayout ===
    # Fields for MosaicLayout
    # Field: columns Type: 5 ()
    # Field: tiles Type: 11 (.google.monitoring.dashboard.v1.MosaicLayout.Tile)

# === Message: Google::Monitoring::Dashboard::V1::Layouts::RowLayout ===
    # Fields for RowLayout
    # Field: rows Type: 11 (.google.monitoring.dashboard.v1.RowLayout.Row)

# === Message: Google::Monitoring::Dashboard::V1::Layouts::ColumnLayout ===
    # Fields for ColumnLayout
    # Field: columns Type: 11 (.google.monitoring.dashboard.v1.ColumnLayout.Column)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Monitoring::Dashboard::V1::Layouts - Compiled Protocol Buffers messages for google/monitoring/dashboard/v1/layouts.proto

=head1 SYNOPSIS

    use Google::Monitoring::Dashboard::V1::Layouts;

    my $msg = Google::Monitoring::Dashboard::V1::Layouts::GridLayout->new({
        columns => $columns,
        widgets => $widgets,
    });

    # Read or update a field
    my $val = $msg->columns();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Monitoring::Dashboard::V1::Layouts::GridLayout->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/monitoring/dashboard/v1/layouts.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Monitoring::Dashboard::V1::Layouts::GridLayout

A basic layout divides the available space into vertical columns of equal
width and arranges a list of widgets using a row-first strategy.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Int64>

The number of columns into which the view's width is divided. If omitted
or set to zero, a system default will be used while rendering.

=item * C<< $msg->widgets() >> / C<< $msg->widgets($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Widget::Widget>)

The informational elements that are arranged into the columns row-first.

=back

=head2 Google::Monitoring::Dashboard::V1::Layouts::MosaicLayout

A mosaic layout divides the available space into a grid of blocks, and
overlays the grid with tiles. Unlike `GridLayout`, tiles may span multiple
grid blocks and can be placed at arbitrary locations in the grid.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Int32>

The number of columns in the mosaic grid. The number of columns must be
between 1 and 12, inclusive.

=item * C<< $msg->tiles() >> / C<< $msg->tiles($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Layouts::MosaicLayout::Tile>)

The tiles to display.

=back

=head2 Google::Monitoring::Dashboard::V1::Layouts::RowLayout

A simplified layout that divides the available space into rows
and arranges a set of widgets horizontally in each row.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->rows() >> / C<< $msg->rows($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Layouts::RowLayout::Row>)

The rows of content to display.

=back

=head2 Google::Monitoring::Dashboard::V1::Layouts::ColumnLayout

A simplified layout that divides the available space into vertical columns
and arranges a set of widgets vertically in each column.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->columns() >> / C<< $msg->columns($value) >>

Type: C<Message> (L<Google::Monitoring::Dashboard::V1::Layouts::ColumnLayout::Column>)

The columns of content to display.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Monitoring::Dashboard::V1::Layouts::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
