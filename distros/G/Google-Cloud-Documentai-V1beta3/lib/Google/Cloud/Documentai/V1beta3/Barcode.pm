package Google::Cloud::Documentai::V1beta3::Barcode;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MWJldGEzL2JhcmNvZGUucHJvdG8SH2dvb2ds
ZS5jbG91ZC5kb2N1bWVudGFpLnYxYmV0YTMiYQoHQmFyY29kZRIWCgZmb3JtYXQYASABKAlS
BmZvcm1hdBIhCgx2YWx1ZV9mb3JtYXQYAiABKAlSC3ZhbHVlRm9ybWF0EhsKCXJhd192YWx1
ZRgDIAEoCVIIcmF3VmFsdWVC4wEKI2NvbS5nb29nbGUuY2xvdWQuZG9jdW1lbnRhaS52MWJl
dGEzQgxCYXJjb2RlUHJvdG9QAVpDY2xvdWQuZ29vZ2xlLmNvbS9nby9kb2N1bWVudGFpL2Fw
aXYxYmV0YTMvZG9jdW1lbnRhaXBiO2RvY3VtZW50YWlwYqoCH0dvb2dsZS5DbG91ZC5Eb2N1
bWVudEFJLlYxQmV0YTPKAh9Hb29nbGVcQ2xvdWRcRG9jdW1lbnRBSVxWMWJldGEz6gIiR29v
Z2xlOjpDbG91ZDo6RG9jdW1lbnRBSTo6VjFiZXRhM0rEDwoGEgQOAEQBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCggKAQgSAxIAPAoJCgIIJRIDEgA8
CggKAQgSAxMAWgoJCgIICxIDEwBaCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUALQoJ
CgIICBIDFQAtCggKAQgSAxYAPAoJCgIIARIDFgA8CggKAQgSAxcAPAoJCgIIKRIDFwA8CggK
AQgSAxgAOwoJCgIILRIDGAA7CjwKAgQAEgQbAEQBGjAgRW5jb2RlcyB0aGUgZGV0YWlsZWQg
aW5mb3JtYXRpb24gb2YgYSBiYXJjb2RlLgoKCgoDBAABEgMbCA8KzgMKBAQAAgASAy0CFBrA
AyBGb3JtYXQgb2YgYSBiYXJjb2RlLgogVGhlIHN1cHBvcnRlZCBmb3JtYXRzIGFyZToKCiAt
IGBDT0RFXzEyOGA6IENvZGUgMTI4IHR5cGUuCiAtIGBDT0RFXzM5YDogQ29kZSAzOSB0eXBl
LgogLSBgQ09ERV85M2A6IENvZGUgOTMgdHlwZS4KIC0gYENPREFCQVJgOiBDb2RhYmFyIHR5
cGUuCiAtIGBEQVRBX01BVFJJWGA6IDJEIERhdGEgTWF0cml4IHR5cGUuCiAtIGBJVEZgOiBJ
VEYgdHlwZS4KIC0gYEVBTl8xM2A6IEVBTi0xMyB0eXBlLgogLSBgRUFOXzhgOiBFQU4tOCB0
eXBlLgogLSBgUVJfQ09ERWA6IDJEIFFSIGNvZGUgdHlwZS4KIC0gYFVQQ19BYDogVVBDLUEg
dHlwZS4KIC0gYFVQQ19FYDogVVBDLUUgdHlwZS4KIC0gYFBERjQxN2A6IFBERjQxNyB0eXBl
LgogLSBgQVpURUNgOiAyRCBBenRlYyBjb2RlIHR5cGUuCiAtIGBEQVRBQkFSYDogR1MxIERh
dGFCYXIgY29kZSB0eXBlLgoKDAoFBAACAAUSAy0CCAoMCgUEAAIAARIDLQkPCgwKBQQAAgAD
EgMtEhMKzwMKBAQAAgESAz8CGhrBAyBWYWx1ZSBmb3JtYXQgZGVzY3JpYmVzIHRoZSBmb3Jt
YXQgb2YgdGhlIHZhbHVlIHRoYXQgYSBiYXJjb2RlCiBlbmNvZGVzLgogVGhlIHN1cHBvcnRl
ZCBmb3JtYXRzIGFyZToKCiAtIGBDT05UQUNUX0lORk9gOiBDb250YWN0IGluZm9ybWF0aW9u
LgogLSBgRU1BSUxgOiBFbWFpbCBhZGRyZXNzLgogLSBgSVNCTmA6IElTQk4gaWRlbnRpZmll
ci4KIC0gYFBIT05FYDogUGhvbmUgbnVtYmVyLgogLSBgUFJPRFVDVGA6IFByb2R1Y3QuCiAt
IGBTTVNgOiBTTVMgbWVzc2FnZS4KIC0gYFRFWFRgOiBUZXh0IHN0cmluZy4KIC0gYFVSTGA6
IFVSTCBhZGRyZXNzLgogLSBgV0lGSWA6IFdpZmkgaW5mb3JtYXRpb24uCiAtIGBHRU9gOiBH
ZW8tbG9jYWxpemF0aW9uLgogLSBgQ0FMRU5EQVJfRVZFTlRgOiBDYWxlbmRhciBldmVudC4K
IC0gYERSSVZFUl9MSUNFTlNFYDogRHJpdmVyJ3MgbGljZW5zZS4KCgwKBQQAAgEFEgM/AggK
DAoFBAACAQESAz8JFQoMCgUEAAIBAxIDPxgZCnMKBAQAAgISA0MCFxpmIFJhdyB2YWx1ZSBl
bmNvZGVkIGluIHRoZSBiYXJjb2RlLgogRm9yIGV4YW1wbGU6IGAnTUVCS006VElUTEU6R29v
Z2xlO1VSTDpodHRwczovL3d3dy5nb29nbGUuY29tOzsnYC4KCgwKBQQAAgIFEgNDAggKDAoF
BAACAgESA0MJEgoMCgUEAAICAxIDQxUWYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1beta3::Barcode::Barcode ===
    # Fields for Barcode
    # Field: format Type: 9 ()
    # Field: value_format Type: 9 ()
    # Field: raw_value Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1beta3::Barcode - Compiled Protocol Buffers messages for google/cloud/documentai/v1beta3/barcode.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1beta3::Barcode;

    my $msg = Google::Cloud::Documentai::V1beta3::Barcode::Barcode->new({
        format => $format,
        value_format => $value_format,
        raw_value => $raw_value,
    });

    # Read or update a field
    my $val = $msg->format();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1beta3::Barcode::Barcode->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1beta3/barcode.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1beta3::Barcode::Barcode

Encodes the detailed information of a barcode.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->format() >> / C<< $msg->format($value) >>

Type: C<String>

Format of a barcode.
The supported formats are:

- `CODE_128`: Code 128 type.
- `CODE_39`: Code 39 type.
- `CODE_93`: Code 93 type.
- `CODABAR`: Codabar type.
- `DATA_MATRIX`: 2D Data Matrix type.
- `ITF`: ITF type.
- `EAN_13`: EAN-13 type.
- `EAN_8`: EAN-8 type.
- `QR_CODE`: 2D QR code type.
- `UPC_A`: UPC-A type.
- `UPC_E`: UPC-E type.
- `PDF417`: PDF417 type.
- `AZTEC`: 2D Aztec code type.
- `DATABAR`: GS1 DataBar code type.

=item * C<< $msg->value_format() >> / C<< $msg->value_format($value) >>

Type: C<String>

Value format describes the format of the value that a barcode
encodes.
The supported formats are:

- `CONTACT_INFO`: Contact information.
- `EMAIL`: Email address.
- `ISBN`: ISBN identifier.
- `PHONE`: Phone number.
- `PRODUCT`: Product.
- `SMS`: SMS message.
- `TEXT`: Text string.
- `URL`: URL address.
- `WIFI`: Wifi information.
- `GEO`: Geo-localization.
- `CALENDAR_EVENT`: Calendar event.
- `DRIVER_LICENSE`: Driver's license.

=item * C<< $msg->raw_value() >> / C<< $msg->raw_value($value) >>

Type: C<String>

Raw value encoded in the barcode.
For example: `'MEBKM:TITLE:Google;URL:https://www.google.com;;'`.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1beta3::Barcode::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
