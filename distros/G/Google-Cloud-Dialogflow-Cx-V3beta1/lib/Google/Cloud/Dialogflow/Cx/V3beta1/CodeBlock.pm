package Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL2NvZGVfYmxvY2sucHJvdG8S
Imdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTEaH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8iJAoJQ29kZUJsb2NrEhcKBGNvZGUYASABKAlCA+BBAVIEY29kZUKc
AQomY29tLmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzYmV0YTFCDkNvZGVCbG9ja1By
b3RvUAFaNmNsb3VkLmdvb2dsZS5jb20vZ28vZGlhbG9nZmxvdy9jeC9hcGl2M2JldGExL2N4
cGI7Y3hwYqICAkRGqgIiR29vZ2xlLkNsb3VkLkRpYWxvZ2Zsb3cuQ3guVjNCZXRhMUqVBwoG
EgQOAB8BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAArCgkK
AgMAEgMSACkKCAoBCBIDFAA/CgkKAgglEgMUAD8KCAoBCBIDFQBNCgkKAggLEgMVAE0KCAoB
CBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAvCgkKAggIEgMXAC8KCAoBCBIDGAA/CgkKAggB
EgMYAD8KCAoBCBIDGQAgCgkKAggkEgMZACAKJgoCBAASBBwAHwEaGiBSZXByZXNlbnRzIGEg
Y29kZSBibG9jay4KCgoKAwQAARIDHAgRCjwKBAQAAgASAx4COxovIE9wdGlvbmFsLiBTb3Vy
Y2UgY29kZSBvZiB0aGUgYmxvY2sgaW4gUHl0aG9uLgoKDAoFBAACAAUSAx4CCAoMCgUEAAIA
ARIDHgkNCgwKBQQAAgADEgMeEBEKDAoFBAACAAgSAx4SOgoPCggEAAIACJwIABIDHhM5YgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock::CodeBlock ===
    # Fields for CodeBlock
    # Field: code Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/code_block.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock::CodeBlock->new({
        code => $code,
    });

    # Read or update a field
    my $val = $msg->code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock::CodeBlock->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/code_block.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock::CodeBlock

Represents a code block.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code() >> / C<< $msg->code($value) >>

Type: C<String>

Optional. Source code of the block in Python.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::CodeBlock::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
