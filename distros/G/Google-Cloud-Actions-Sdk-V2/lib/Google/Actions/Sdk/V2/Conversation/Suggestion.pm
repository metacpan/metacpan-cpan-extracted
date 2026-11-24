package Google::Actions::Sdk::V2::Conversation::Suggestion;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uL3Byb21wdC9zdWdnZXN0aW9u
LnByb3RvEiJnb29nbGUuYWN0aW9ucy5zZGsudjIuY29udmVyc2F0aW9uIiIKClN1Z2dlc3Rp
b24SFAoFdGl0bGUYASABKAlSBXRpdGxlQosBCiZjb20uZ29vZ2xlLmFjdGlvbnMuc2RrLnYy
LmNvbnZlcnNhdGlvbkIPU3VnZ2VzdGlvblByb3RvUAFaTmdvb2dsZS5nb2xhbmcub3JnL2dl
bnByb3RvL2dvb2dsZWFwaXMvYWN0aW9ucy9zZGsvdjIvY29udmVyc2F0aW9uO2NvbnZlcnNh
dGlvbkqNCAoGEgQOAB4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
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
AhIDEAArCggKAQgSAxIAZQoJCgIICxIDEgBlCggKAQgSAxMAIgoJCgIIChIDEwAiCggKAQgS
AxQAMAoJCgIICBIDFAAwCggKAQgSAxUAPwoJCgIIARIDFQA/CjsKAgQAEgQYAB4BGi8gSW5w
dXQgc3VnZ2VzdGlvbiB0byBiZSBwcmVzZW50ZWQgdG8gdGhlIHVzZXIuCgoKCgMEAAESAxgI
EgryAQoEBAACABIDHQITGuQBIFJlcXVpcmVkLiBUaGUgdGV4dCBzaG93biBpbiB0aGUgc3Vn
Z2VzdGlvbiBjaGlwLiBXaGVuIHRhcHBlZCwgdGhpcyB0ZXh0IHdpbGwgYmUKIHBvc3RlZCBi
YWNrIHRvIHRoZSBjb252ZXJzYXRpb24gdmVyYmF0aW0gYXMgaWYgdGhlIHVzZXIgaGFkIHR5
cGVkIGl0LgogRWFjaCB0aXRsZSBtdXN0IGJlIHVuaXF1ZSBhbW9uZyB0aGUgc2V0IG9mIHN1
Z2dlc3Rpb24gY2hpcHMuCiBNYXggMjUgY2hhcnMKCgwKBQQAAgAFEgMdAggKDAoFBAACAAES
Ax0JDgoMCgUEAAIAAxIDHRESYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Actions::Sdk::V2::Conversation::Suggestion::Suggestion ===
    # Fields for Suggestion
    # Field: title Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Actions::Sdk::V2::Conversation::Suggestion - Compiled Protocol Buffers messages for google/actions/sdk/v2/conversation/prompt/suggestion.proto

=head1 SYNOPSIS

    use Google::Actions::Sdk::V2::Conversation::Suggestion;

    my $msg = Google::Actions::Sdk::V2::Conversation::Suggestion::Suggestion->new({
        title => $title,
    });

    # Read or update a field
    my $val = $msg->title();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Actions::Sdk::V2::Conversation::Suggestion::Suggestion->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/actions/sdk/v2/conversation/prompt/suggestion.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Actions::Sdk::V2::Conversation::Suggestion::Suggestion

Input suggestion to be presented to the user.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->title() >> / C<< $msg->title($value) >>

Type: C<String>

Required. The text shown in the suggestion chip. When tapped, this text will be
posted back to the conversation verbatim as if the user had typed it.
Each title must be unique among the set of suggestion chips.
Max 25 chars

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Actions::Sdk::V2::Conversation::Suggestion::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
