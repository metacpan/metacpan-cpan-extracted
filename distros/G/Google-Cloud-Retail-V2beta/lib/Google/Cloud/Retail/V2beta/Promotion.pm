package Google::Cloud::Retail::V2beta::Promotion;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvcmV0YWlsL3YyYmV0YS9wcm9tb3Rpb24ucHJvdG8SGmdvb2dsZS5j
bG91ZC5yZXRhaWwudjJiZXRhIi4KCVByb21vdGlvbhIhCgxwcm9tb3Rpb25faWQYASABKAlS
C3Byb21vdGlvbklkQs0BCh5jb20uZ29vZ2xlLmNsb3VkLnJldGFpbC52MmJldGFCDlByb21v
dGlvblByb3RvUAFaNmNsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyYmV0YS9yZXRh
aWxwYjtyZXRhaWxwYqICBlJFVEFJTKoCGkdvb2dsZS5DbG91ZC5SZXRhaWwuVjJCZXRhygIa
R29vZ2xlXENsb3VkXFJldGFpbFxWMmJldGHqAh1Hb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYy
YmV0YUrwCQoGEgQOACcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
QwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRo
ZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29t
cGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRo
ZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNF
TlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQg
dG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNl
IGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJ
RVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGll
ZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmlu
ZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoB
AhIDEAAjCggKAQgSAxIANwoJCgIIJRIDEgA3CggKAQgSAxMATQoJCgIICxIDEwBNCggKAQgS
AxQAIgoJCgIIChIDFAAiCggKAQgSAxUALwoJCgIICBIDFQAvCggKAQgSAxYANwoJCgIIARID
FgA3CggKAQgSAxcAJAoJCgIIJBIDFwAkCggKAQgSAxgANwoJCgIIKRIDGAA3CggKAQgSAxkA
NgoJCgIILRIDGQA2CiQKAgQAEgQcACcBGhggUHJvbW90aW9uIGluZm9ybWF0aW9uLgoKCgoD
BAABEgMcCBEKmAMKBAQAAgASAyYCGhqKAyBJRCBvZiB0aGUgcHJvbW90aW9uLiBGb3IgZXhh
bXBsZSwgImZyZWUgZ2lmdCIuCgogVGhlIHZhbHVlIG11c3QgYmUgYSBVVEYtOCBlbmNvZGVk
IHN0cmluZyB3aXRoIGEgbGVuZ3RoIGxpbWl0IG9mIDEyOAogY2hhcmFjdGVycywgYW5kIG1h
dGNoIHRoZSBwYXR0ZXJuOiBgW2EtekEtWl1bYS16QS1aMC05X10qYC4gRm9yIGV4YW1wbGUs
CiBpZDBMaWtlVGhpcyBvciBJRF8xX0xJS0VfVEhJUy4gT3RoZXJ3aXNlLCBhbiBJTlZBTElE
X0FSR1VNRU5UIGVycm9yIGlzCiByZXR1cm5lZC4KCiBDb3JyZXNwb25kcyB0byBHb29nbGUg
TWVyY2hhbnQgQ2VudGVyIHByb3BlcnR5CiBbcHJvbW90aW9uX2lkXShodHRwczovL3N1cHBv
cnQuZ29vZ2xlLmNvbS9tZXJjaGFudHMvYW5zd2VyLzcwNTAxNDgpLgoKDAoFBAACAAUSAyYC
CAoMCgUEAAIAARIDJgkVCgwKBQQAAgADEgMmGBliBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2beta::Promotion::Promotion ===
    # Fields for Promotion
    # Field: promotion_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2beta::Promotion - Compiled Protocol Buffers messages for google/cloud/retail/v2beta/promotion.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2beta::Promotion;

    my $msg = Google::Cloud::Retail::V2beta::Promotion::Promotion->new({
        promotion_id => $promotion_id,
    });

    # Read or update a field
    my $val = $msg->promotion_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2beta::Promotion::Promotion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2beta/promotion.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2beta::Promotion::Promotion

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2beta::Promotion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
