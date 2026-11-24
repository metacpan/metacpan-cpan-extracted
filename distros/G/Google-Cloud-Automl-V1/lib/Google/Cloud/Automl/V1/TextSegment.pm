package Google::Cloud::Automl::V1::TextSegment;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvYXV0b21sL3YxL3RleHRfc2VnbWVudC5wcm90bxIWZ29vZ2xlLmNs
b3VkLmF1dG9tbC52MSJpCgtUZXh0U2VnbWVudBIYCgdjb250ZW50GAMgASgJUgdjb250ZW50
EiEKDHN0YXJ0X29mZnNldBgBIAEoA1ILc3RhcnRPZmZzZXQSHQoKZW5kX29mZnNldBgCIAEo
A1IJZW5kT2Zmc2V0QrIBChpjb20uZ29vZ2xlLmNsb3VkLmF1dG9tbC52MUIQVGV4dFNlZ21l
bnRQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2F1dG9tbC9hcGl2MS9hdXRvbWxwYjth
dXRvbWxwYqoCFkdvb2dsZS5DbG91ZC5BdXRvTUwuVjHKAhZHb29nbGVcQ2xvdWRcQXV0b01s
XFYx6gIZR29vZ2xlOjpDbG91ZDo6QXV0b01MOjpWMUqLCwoGEgQOACcBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCggKAQgSAxIAMwoJCgIIJRIDEgAz
CggKAQgSAxMASQoJCgIICxIDEwBJCggKAQgSAxQAIgoJCgIIChIDFAAiCggKAQgSAxUAMQoJ
CgIICBIDFQAxCggKAQgSAxYAMwoJCgIIARIDFgAzCggKAQgSAxcAMwoJCgIIKRIDFwAzCggK
AQgSAxgAMgoJCgIILRIDGAAyCloKAgQAEgQbACcBGk4gQSBjb250aWd1b3VzIHBhcnQgb2Yg
YSB0ZXh0IChzdHJpbmcpLCBhc3N1bWluZyBpdCBoYXMgYW4gVVRGLTggTkZDIGVuY29kaW5n
LgoKCgoDBAABEgMbCBMKOwoEBAACABIDHQIVGi4gT3V0cHV0IG9ubHkuIFRoZSBjb250ZW50
IG9mIHRoZSBUZXh0U2VnbWVudC4KCgwKBQQAAgAFEgMdAggKDAoFBAACAAESAx0JEAoMCgUE
AAIAAxIDHRMUCpYBCgQEAAIBEgMhAhkaiAEgUmVxdWlyZWQuIFplcm8tYmFzZWQgY2hhcmFj
dGVyIGluZGV4IG9mIHRoZSBmaXJzdCBjaGFyYWN0ZXIgb2YgdGhlIHRleHQKIHNlZ21lbnQg
KGNvdW50aW5nIGNoYXJhY3RlcnMgZnJvbSB0aGUgYmVnaW5uaW5nIG9mIHRoZSB0ZXh0KS4K
CgwKBQQAAgEFEgMhAgcKDAoFBAACAQESAyEIFAoMCgUEAAIBAxIDIRcYCugBCgQEAAICEgMm
Ahca2gEgUmVxdWlyZWQuIFplcm8tYmFzZWQgY2hhcmFjdGVyIGluZGV4IG9mIHRoZSBmaXJz
dCBjaGFyYWN0ZXIgcGFzdCB0aGUgZW5kIG9mCiB0aGUgdGV4dCBzZWdtZW50IChjb3VudGlu
ZyBjaGFyYWN0ZXIgZnJvbSB0aGUgYmVnaW5uaW5nIG9mIHRoZSB0ZXh0KS4KIFRoZSBjaGFy
YWN0ZXIgYXQgdGhlIGVuZF9vZmZzZXQgaXMgTk9UIGluY2x1ZGVkIGluIHRoZSB0ZXh0IHNl
Z21lbnQuCgoMCgUEAAICBRIDJgIHCgwKBQQAAgIBEgMmCBIKDAoFBAACAgMSAyYVFmIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Automl::V1::TextSegment::TextSegment ===
    # Fields for TextSegment
    # Field: content Type: 9 ()
    # Field: start_offset Type: 3 ()
    # Field: end_offset Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Automl::V1::TextSegment - Compiled Protocol Buffers messages for google/cloud/automl/v1/text_segment.proto

=head1 SYNOPSIS

    use Google::Cloud::Automl::V1::TextSegment;

    my $msg = Google::Cloud::Automl::V1::TextSegment::TextSegment->new({
        content => $content,
        start_offset => $start_offset,
        end_offset => $end_offset,
    });

    # Read or update a field
    my $val = $msg->content();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Automl::V1::TextSegment::TextSegment->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/automl/v1/text_segment.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Automl::V1::TextSegment::TextSegment

A contiguous part of a text (string), assuming it has an UTF-8 NFC encoding.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->content() >> / C<< $msg->content($value) >>

Type: C<String>

Output only. The content of the TextSegment.

=item * C<< $msg->start_offset() >> / C<< $msg->start_offset($value) >>

Type: C<Int64>

Required. Zero-based character index of the first character of the text
segment (counting characters from the beginning of the text).

=item * C<< $msg->end_offset() >> / C<< $msg->end_offset($value) >>

Type: C<Int64>

Required. Zero-based character index of the first character past the end of
the text segment (counting character from the beginning of the text).
The character at the end_offset is NOT included in the text segment.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Automl::V1::TextSegment::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
