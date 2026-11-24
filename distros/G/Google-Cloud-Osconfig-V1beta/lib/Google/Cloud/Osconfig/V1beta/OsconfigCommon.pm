package Google::Cloud::Osconfig::V1beta::OsconfigCommon;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvb3Njb25maWcvdjFiZXRhL29zY29uZmlnX2NvbW1vbi5wcm90bxIc
Z29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YSJMCg5GaXhlZE9yUGVyY2VudBIWCgVmaXhl
ZBgBIAEoBUgAUgVmaXhlZBIaCgdwZXJjZW50GAIgASgFSABSB3BlcmNlbnRCBgoEbW9kZUJo
CiBjb20uZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYmV0YUIGQ29tbW9uWjxjbG91ZC5nb29n
bGUuY29tL2dvL29zY29uZmlnL2FwaXYxYmV0YS9vc2NvbmZpZ3BiO29zY29uZmlncGJKuQgK
BhIEDgAjAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNl
bnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vu
c2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ug
d2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5z
ZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAK
CiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdy
aXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0
cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENP
TkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUg
dGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlz
c2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJQoI
CgEIEgMTAFMKCQoCCAsSAxMAUwoICgEIEgMUACcKCQoCCAgSAxQAJwoICgEIEgMVADkKCQoC
CAESAxUAOQp2CgIEABIEGQAjARpqIE1lc3NhZ2UgZW5jYXBzdWxhdGluZyBhIHZhbHVlIHRo
YXQgY2FuIGJlIGVpdGhlciBhYnNvbHV0ZSAoImZpeGVkIikgb3IKIHJlbGF0aXZlICgicGVy
Y2VudCIpIHRvIGEgdmFsdWUuCgoKCgMEAAESAxkIFgoiCgQEAAgAEgQbAiIDGhQgVHlwZSBv
ZiB0aGUgdmFsdWUuCgoMCgUEAAgAARIDGwgMCicKBAQAAgASAx0EFBoaIFNwZWNpZmllcyBh
IGZpeGVkIHZhbHVlLgoKDAoFBAACAAUSAx0ECQoMCgUEAAIAARIDHQoPCgwKBQQAAgADEgMd
EhMKdAoEBAACARIDIQQWGmcgU3BlY2lmaWVzIHRoZSByZWxhdGl2ZSB2YWx1ZSBkZWZpbmVk
IGFzIGEgcGVyY2VudGFnZSwgd2hpY2ggd2lsbCBiZQogbXVsdGlwbGllZCBieSBhIHJlZmVy
ZW5jZSB2YWx1ZS4KCgwKBQQAAgEFEgMhBAkKDAoFBAACAQESAyEKEQoMCgUEAAIBAxIDIRQV
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::V1beta::OsconfigCommon::FixedOrPercent ===
    # Fields for FixedOrPercent
    # Field: fixed Type: 5 ()
    # Field: percent Type: 5 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1beta::OsconfigCommon - Compiled Protocol Buffers messages for google/cloud/osconfig/v1beta/osconfig_common.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::V1beta::OsconfigCommon;

    my $msg = Google::Cloud::Osconfig::V1beta::OsconfigCommon::FixedOrPercent->new({
        fixed => $fixed,
        percent => $percent,
    });

    # Read or update a field
    my $val = $msg->fixed();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::V1beta::OsconfigCommon::FixedOrPercent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1beta/osconfig_common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::V1beta::OsconfigCommon::FixedOrPercent

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1beta::OsconfigCommon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
