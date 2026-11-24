package Google::Cloud::Documentai::V1::Barcode;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZG9jdW1lbnRhaS92MS9iYXJjb2RlLnByb3RvEhpnb29nbGUuY2xv
dWQuZG9jdW1lbnRhaS52MSJhCgdCYXJjb2RlEhYKBmZvcm1hdBgBIAEoCVIGZm9ybWF0EiEK
DHZhbHVlX2Zvcm1hdBgCIAEoCVILdmFsdWVGb3JtYXQSGwoJcmF3X3ZhbHVlGAMgASgJUghy
YXdWYWx1ZULKAQoeY29tLmdvb2dsZS5jbG91ZC5kb2N1bWVudGFpLnYxQgxCYXJjb2RlUHJv
dG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9kb2N1bWVudGFpL2FwaXYxL2RvY3VtZW50YWlw
Yjtkb2N1bWVudGFpcGKqAhpHb29nbGUuQ2xvdWQuRG9jdW1lbnRBSS5WMcoCGkdvb2dsZVxD
bG91ZFxEb2N1bWVudEFJXFYx6gIdR29vZ2xlOjpDbG91ZDo6RG9jdW1lbnRBSTo6VjFKxA8K
BhIEDgBEAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIwoI
CgEIEgMSADcKCQoCCCUSAxIANwoICgEIEgMTAFUKCQoCCAsSAxMAVQoICgEIEgMUACIKCQoC
CAoSAxQAIgoICgEIEgMVAC0KCQoCCAgSAxUALQoICgEIEgMWADcKCQoCCAESAxYANwoICgEI
EgMXADcKCQoCCCkSAxcANwoICgEIEgMYADYKCQoCCC0SAxgANgo8CgIEABIEGwBEARowIEVu
Y29kZXMgdGhlIGRldGFpbGVkIGluZm9ybWF0aW9uIG9mIGEgYmFyY29kZS4KCgoKAwQAARID
GwgPCs4DCgQEAAIAEgMtAhQawAMgRm9ybWF0IG9mIGEgYmFyY29kZS4KIFRoZSBzdXBwb3J0
ZWQgZm9ybWF0cyBhcmU6CgogLSBgQ09ERV8xMjhgOiBDb2RlIDEyOCB0eXBlLgogLSBgQ09E
RV8zOWA6IENvZGUgMzkgdHlwZS4KIC0gYENPREVfOTNgOiBDb2RlIDkzIHR5cGUuCiAtIGBD
T0RBQkFSYDogQ29kYWJhciB0eXBlLgogLSBgREFUQV9NQVRSSVhgOiAyRCBEYXRhIE1hdHJp
eCB0eXBlLgogLSBgSVRGYDogSVRGIHR5cGUuCiAtIGBFQU5fMTNgOiBFQU4tMTMgdHlwZS4K
IC0gYEVBTl84YDogRUFOLTggdHlwZS4KIC0gYFFSX0NPREVgOiAyRCBRUiBjb2RlIHR5cGUu
CiAtIGBVUENfQWA6IFVQQy1BIHR5cGUuCiAtIGBVUENfRWA6IFVQQy1FIHR5cGUuCiAtIGBQ
REY0MTdgOiBQREY0MTcgdHlwZS4KIC0gYEFaVEVDYDogMkQgQXp0ZWMgY29kZSB0eXBlLgog
LSBgREFUQUJBUmA6IEdTMSBEYXRhQmFyIGNvZGUgdHlwZS4KCgwKBQQAAgAFEgMtAggKDAoF
BAACAAESAy0JDwoMCgUEAAIAAxIDLRITCs8DCgQEAAIBEgM/AhoawQMgVmFsdWUgZm9ybWF0
IGRlc2NyaWJlcyB0aGUgZm9ybWF0IG9mIHRoZSB2YWx1ZSB0aGF0IGEgYmFyY29kZQogZW5j
b2Rlcy4KIFRoZSBzdXBwb3J0ZWQgZm9ybWF0cyBhcmU6CgogLSBgQ09OVEFDVF9JTkZPYDog
Q29udGFjdCBpbmZvcm1hdGlvbi4KIC0gYEVNQUlMYDogRW1haWwgYWRkcmVzcy4KIC0gYElT
Qk5gOiBJU0JOIGlkZW50aWZpZXIuCiAtIGBQSE9ORWA6IFBob25lIG51bWJlci4KIC0gYFBS
T0RVQ1RgOiBQcm9kdWN0LgogLSBgU01TYDogU01TIG1lc3NhZ2UuCiAtIGBURVhUYDogVGV4
dCBzdHJpbmcuCiAtIGBVUkxgOiBVUkwgYWRkcmVzcy4KIC0gYFdJRklgOiBXaWZpIGluZm9y
bWF0aW9uLgogLSBgR0VPYDogR2VvLWxvY2FsaXphdGlvbi4KIC0gYENBTEVOREFSX0VWRU5U
YDogQ2FsZW5kYXIgZXZlbnQuCiAtIGBEUklWRVJfTElDRU5TRWA6IERyaXZlcidzIGxpY2Vu
c2UuCgoMCgUEAAIBBRIDPwIICgwKBQQAAgEBEgM/CRUKDAoFBAACAQMSAz8YGQpzCgQEAAIC
EgNDAhcaZiBSYXcgdmFsdWUgZW5jb2RlZCBpbiB0aGUgYmFyY29kZS4KIEZvciBleGFtcGxl
OiBgJ01FQktNOlRJVExFOkdvb2dsZTtVUkw6aHR0cHM6Ly93d3cuZ29vZ2xlLmNvbTs7J2Au
CgoMCgUEAAICBRIDQwIICgwKBQQAAgIBEgNDCRIKDAoFBAACAgMSA0MVFmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Documentai::V1::Barcode::Barcode ===
    # Fields for Barcode
    # Field: format Type: 9 ()
    # Field: value_format Type: 9 ()
    # Field: raw_value Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Documentai::V1::Barcode - Compiled Protocol Buffers messages for google/cloud/documentai/v1/barcode.proto

=head1 SYNOPSIS

    use Google::Cloud::Documentai::V1::Barcode;

    my $msg = Google::Cloud::Documentai::V1::Barcode::Barcode->new({
        format => $format,
        value_format => $value_format,
        raw_value => $raw_value,
    });

    # Read or update a field
    my $val = $msg->format();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Documentai::V1::Barcode::Barcode->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/documentai/v1/barcode.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Documentai::V1::Barcode::Barcode

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Documentai::V1::Barcode::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
