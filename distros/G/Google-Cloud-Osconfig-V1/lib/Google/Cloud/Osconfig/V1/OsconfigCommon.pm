package Google::Cloud::Osconfig::V1::OsconfigCommon;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvb3Njb25maWcvdjEvb3Njb25maWdfY29tbW9uLnByb3RvEhhnb29n
bGUuY2xvdWQub3Njb25maWcudjEiTAoORml4ZWRPclBlcmNlbnQSFgoFZml4ZWQYASABKAVI
AFIFZml4ZWQSGgoHcGVyY2VudBgCIAEoBUgAUgdwZXJjZW50QgYKBG1vZGVCtAEKHGNvbS5n
b29nbGUuY2xvdWQub3Njb25maWcudjFCBkNvbW1vblo4Y2xvdWQuZ29vZ2xlLmNvbS9nby9v
c2NvbmZpZy9hcGl2MS9vc2NvbmZpZ3BiO29zY29uZmlncGKqAhhHb29nbGUuQ2xvdWQuT3ND
b25maWcuVjHKAhhHb29nbGVcQ2xvdWRcT3NDb25maWdcVjHqAhtHb29nbGU6OkNsb3VkOjpP
c0NvbmZpZzo6VjFK+AgKBhIEDgAlAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAIQoICgEIEgMSADUKCQoCCCUSAxIANQoICgEIEgMTAE8KCQoCCAsSAxMA
TwoICgEIEgMUACcKCQoCCAgSAxQAJwoICgEIEgMVADUKCQoCCAESAxUANQoICgEIEgMWADUK
CQoCCCkSAxYANQoICgEIEgMXADQKCQoCCC0SAxcANAp2CgIEABIEGwAlARpqIE1lc3NhZ2Ug
ZW5jYXBzdWxhdGluZyBhIHZhbHVlIHRoYXQgY2FuIGJlIGVpdGhlciBhYnNvbHV0ZSAoImZp
eGVkIikgb3IKIHJlbGF0aXZlICgicGVyY2VudCIpIHRvIGEgdmFsdWUuCgoKCgMEAAESAxsI
FgoiCgQEAAgAEgQdAiQDGhQgVHlwZSBvZiB0aGUgdmFsdWUuCgoMCgUEAAgAARIDHQgMCicK
BAQAAgASAx8EFBoaIFNwZWNpZmllcyBhIGZpeGVkIHZhbHVlLgoKDAoFBAACAAUSAx8ECQoM
CgUEAAIAARIDHwoPCgwKBQQAAgADEgMfEhMKdAoEBAACARIDIwQWGmcgU3BlY2lmaWVzIHRo
ZSByZWxhdGl2ZSB2YWx1ZSBkZWZpbmVkIGFzIGEgcGVyY2VudGFnZSwgd2hpY2ggd2lsbCBi
ZQogbXVsdGlwbGllZCBieSBhIHJlZmVyZW5jZSB2YWx1ZS4KCgwKBQQAAgEFEgMjBAkKDAoF
BAACAQESAyMKEQoMCgUEAAIBAxIDIxQVYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::V1::OsconfigCommon::FixedOrPercent ===
    # Fields for FixedOrPercent
    # Field: fixed Type: 5 ()
    # Field: percent Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1::OsconfigCommon - Compiled Protocol Buffers messages for google/cloud/osconfig/v1/osconfig_common.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::V1::OsconfigCommon;

    my $msg = Google::Cloud::Osconfig::V1::OsconfigCommon::FixedOrPercent->new({
        fixed => $fixed,
        percent => $percent,
    });

    # Read or update a field
    my $val = $msg->fixed();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::V1::OsconfigCommon::FixedOrPercent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1/osconfig_common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::V1::OsconfigCommon::FixedOrPercent

Message encapsulating a value that can be either absolute ("fixed") or
relative ("percent") to a value.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->fixed() >> / C<< $msg->fixed($value) >>

Type: C<Int32>

Specifies a fixed value.

=item * C<< $msg->percent() >> / C<< $msg->percent($value) >>

Type: C<Int32>

Specifies the relative value defined as a percentage, which will be
multiplied by a reference value.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1::OsconfigCommon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
