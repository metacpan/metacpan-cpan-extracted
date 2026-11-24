package Google::Cloud::Support::V2beta::Content;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvY29udGVudC5wcm90bxIbZ29vZ2xlLmNs
b3VkLnN1cHBvcnQudjJiZXRhIiwKC1RleHRDb250ZW50Eh0KCnBsYWluX3RleHQYASABKAlS
CXBsYWluVGV4dELJAQofY29tLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YUIMQ29udGVu
dFByb3RvUAFaOWNsb3VkLmdvb2dsZS5jb20vZ28vc3VwcG9ydC9hcGl2MmJldGEvc3VwcG9y
dHBiO3N1cHBvcnRwYqoCG0dvb2dsZS5DbG91ZC5TdXBwb3J0LlYyQmV0YcoCG0dvb2dsZVxD
bG91ZFxTdXBwb3J0XFYyYmV0YeoCHkdvb2dsZTo6Q2xvdWQ6OlN1cHBvcnQ6OlYyYmV0YUqj
BwoGEgQOAB4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExp
Y2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGlj
ZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5j
ZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNl
bnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIu
MAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4g
d3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRp
c3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1Ig
Q09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNl
ZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJt
aXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAk
CggKAQgSAxIAOAoJCgIIJRIDEgA4CggKAQgSAxMAUAoJCgIICxIDEwBQCggKAQgSAxQAIgoJ
CgIIChIDFAAiCggKAQgSAxUALQoJCgIICBIDFQAtCggKAQgSAxYAOAoJCgIIARIDFgA4CggK
AQgSAxcAOAoJCgIIKRIDFwA4CggKAQgSAxgANwoJCgIILRIDGAA3CjcKAgQAEgQbAB4BGisg
U3RvcmVzIHRleHQgYXR0YWNoZWQgdG8gYSBzdXBwb3J0IG9iamVjdC4KCgoKAwQAARIDGwgT
Ck4KBAQAAgASAx0CGBpBIENvbnRlbnQgaW4gdGhpcyBmaWVsZCBzaG91bGQgYmUgcmVuZGVy
ZWQgYW5kIGludGVycHJldGVkIGFzLWlzLgoKDAoFBAACAAUSAx0CCAoMCgUEAAIAARIDHQkT
CgwKBQQAAgADEgMdFhdiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::Content::TextContent ===
    # Fields for TextContent
    # Field: plain_text Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::Content - Compiled Protocol Buffers messages for google/cloud/support/v2beta/content.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::Content;

    my $msg = Google::Cloud::Support::V2beta::Content::TextContent->new({
        plain_text => $plain_text,
    });

    # Read or update a field
    my $val = $msg->plain_text();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::Content::TextContent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/content.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::Content::TextContent

Stores text attached to a support object.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->plain_text() >> / C<< $msg->plain_text($value) >>

Type: C<String>

Content in this field should be rendered and interpreted as-is.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::Content::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
