package Google::Cloud::Retail::V2alpha::Promotion;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvcmV0YWlsL3YyYWxwaGEvcHJvbW90aW9uLnByb3RvEhtnb29nbGUu
Y2xvdWQucmV0YWlsLnYyYWxwaGEiLgoJUHJvbW90aW9uEiEKDHByb21vdGlvbl9pZBgBIAEo
CVILcHJvbW90aW9uSWRC0gEKH2NvbS5nb29nbGUuY2xvdWQucmV0YWlsLnYyYWxwaGFCDlBy
b21vdGlvblByb3RvUAFaN2Nsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYWxwaGEv
cmV0YWlscGI7cmV0YWlscGKiAgZSRVRBSUyqAhtHb29nbGUuQ2xvdWQuUmV0YWlsLlYyQWxw
aGHKAhtHb29nbGVcQ2xvdWRcUmV0YWlsXFYyYWxwaGHqAh5Hb29nbGU6OkNsb3VkOjpSZXRh
aWw6OlYyYWxwaGFK8AkKBhIEDgAnAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
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
ZS4KCggKAQISAxAAJAoICgEIEgMSADgKCQoCCCUSAxIAOAoICgEIEgMTAE4KCQoCCAsSAxMA
TgoICgEIEgMUACIKCQoCCAoSAxQAIgoICgEIEgMVAC8KCQoCCAgSAxUALwoICgEIEgMWADgK
CQoCCAESAxYAOAoICgEIEgMXACQKCQoCCCQSAxcAJAoICgEIEgMYADgKCQoCCCkSAxgAOAoI
CgEIEgMZADcKCQoCCC0SAxkANwokCgIEABIEHAAnARoYIFByb21vdGlvbiBpbmZvcm1hdGlv
bi4KCgoKAwQAARIDHAgRCpgDCgQEAAIAEgMmAhoaigMgSUQgb2YgdGhlIHByb21vdGlvbi4g
Rm9yIGV4YW1wbGUsICJmcmVlIGdpZnQiLgoKIFRoZSB2YWx1ZSBtdXN0IGJlIGEgVVRGLTgg
ZW5jb2RlZCBzdHJpbmcgd2l0aCBhIGxlbmd0aCBsaW1pdCBvZiAxMjgKIGNoYXJhY3RlcnMs
IGFuZCBtYXRjaCB0aGUgcGF0dGVybjogYFthLXpBLVpdW2EtekEtWjAtOV9dKmAuIEZvciBl
eGFtcGxlLAogaWQwTGlrZVRoaXMgb3IgSURfMV9MSUtFX1RISVMuIE90aGVyd2lzZSwgYW4g
SU5WQUxJRF9BUkdVTUVOVCBlcnJvciBpcwogcmV0dXJuZWQuCgogQ29ycmVzcG9uZHMgdG8g
R29vZ2xlIE1lcmNoYW50IENlbnRlciBwcm9wZXJ0eQogW3Byb21vdGlvbl9pZF0oaHR0cHM6
Ly9zdXBwb3J0Lmdvb2dsZS5jb20vbWVyY2hhbnRzL2Fuc3dlci83MDUwMTQ4KS4KCgwKBQQA
AgAFEgMmAggKDAoFBAACAAESAyYJFQoMCgUEAAIAAxIDJhgZYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2alpha::Promotion::Promotion ===
    # Fields for Promotion
    # Field: promotion_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2alpha::Promotion - Compiled Protocol Buffers messages for google/cloud/retail/v2alpha/promotion.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2alpha::Promotion;

    my $msg = Google::Cloud::Retail::V2alpha::Promotion::Promotion->new({
        promotion_id => $promotion_id,
    });

    # Read or update a field
    my $val = $msg->promotion_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2alpha::Promotion::Promotion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2alpha/promotion.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2alpha::Promotion::Promotion

Promotion information.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->promotion_id() >> / C<< $msg->promotion_id($value) >>

Type: C<String>

ID of the promotion. For example, "free gift".

The value must be a UTF-8 encoded string with a length limit of 128
characters, and match the pattern: `[a-zA-Z][a-zA-Z0-9_]*`. For example,
id0LikeThis or ID_1_LIKE_THIS. Otherwise, an INVALID_ARGUMENT error is
returned.

Corresponds to Google Merchant Center property
[promotion_id](https://support.google.com/merchants/answer/7050148).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2alpha::Promotion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
