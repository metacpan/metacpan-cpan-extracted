package Google::Cloud::Retail::V2::Promotion;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvcmV0YWlsL3YyL3Byb21vdGlvbi5wcm90bxIWZ29vZ2xlLmNsb3Vk
LnJldGFpbC52MiIuCglQcm9tb3Rpb24SIQoMcHJvbW90aW9uX2lkGAEgASgJUgtwcm9tb3Rp
b25JZEK5AQoaY29tLmdvb2dsZS5jbG91ZC5yZXRhaWwudjJCDlByb21vdGlvblByb3RvUAFa
MmNsb3VkLmdvb2dsZS5jb20vZ28vcmV0YWlsL2FwaXYyL3JldGFpbHBiO3JldGFpbHBiogIG
UkVUQUlMqgIWR29vZ2xlLkNsb3VkLlJldGFpbC5WMsoCFkdvb2dsZVxDbG91ZFxSZXRhaWxc
VjLqAhlHb29nbGU6OkNsb3VkOjpSZXRhaWw6OlYySvAJCgYSBA4AJwEKvAQKAQwSAw4AEjKx
BCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNo
ZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1
c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZ
b3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3
dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5
IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlz
dHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElT
IiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5E
LCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUg
c3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlv
bnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCAoBCBIDEgAzCgkKAgglEgMSADMK
CAoBCBIDEwBJCgkKAggLEgMTAEkKCAoBCBIDFAAiCgkKAggKEgMUACIKCAoBCBIDFQAvCgkK
AggIEgMVAC8KCAoBCBIDFgAzCgkKAggBEgMWADMKCAoBCBIDFwAkCgkKAggkEgMXACQKCAoB
CBIDGAAzCgkKAggpEgMYADMKCAoBCBIDGQAyCgkKAggtEgMZADIKJAoCBAASBBwAJwEaGCBQ
cm9tb3Rpb24gaW5mb3JtYXRpb24uCgoKCgMEAAESAxwIEQqYAwoEBAACABIDJgIaGooDIElE
IG9mIHRoZSBwcm9tb3Rpb24uIEZvciBleGFtcGxlLCAiZnJlZSBnaWZ0Ii4KCiBUaGUgdmFs
dWUgbXVzdCBiZSBhIFVURi04IGVuY29kZWQgc3RyaW5nIHdpdGggYSBsZW5ndGggbGltaXQg
b2YgMTI4CiBjaGFyYWN0ZXJzLCBhbmQgbWF0Y2ggdGhlIHBhdHRlcm46IGBbYS16QS1aXVth
LXpBLVowLTlfXSpgLiBGb3IgZXhhbXBsZSwKIGlkMExpa2VUaGlzIG9yIElEXzFfTElLRV9U
SElTLiBPdGhlcndpc2UsIGFuIElOVkFMSURfQVJHVU1FTlQgZXJyb3IgaXMKIHJldHVybmVk
LgoKIENvcnJlc3BvbmRzIHRvIEdvb2dsZSBNZXJjaGFudCBDZW50ZXIgcHJvcGVydHkKIFtw
cm9tb3Rpb25faWRdKGh0dHBzOi8vc3VwcG9ydC5nb29nbGUuY29tL21lcmNoYW50cy9hbnN3
ZXIvNzA1MDE0OCkuCgoMCgUEAAIABRIDJgIICgwKBQQAAgABEgMmCRUKDAoFBAACAAMSAyYY
GWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Retail::V2::Promotion::Promotion ===
    # Fields for Promotion
    # Field: promotion_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Retail::V2::Promotion - Compiled Protocol Buffers messages for google/cloud/retail/v2/promotion.proto

=head1 SYNOPSIS

    use Google::Cloud::Retail::V2::Promotion;

    my $msg = Google::Cloud::Retail::V2::Promotion::Promotion->new({
        promotion_id => $promotion_id,
    });

    # Read or update a field
    my $val = $msg->promotion_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Retail::V2::Promotion::Promotion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/retail/v2/promotion.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Retail::V2::Promotion::Promotion

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Retail::V2::Promotion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
