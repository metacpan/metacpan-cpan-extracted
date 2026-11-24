package Google::Cloud::Dialogflow::V2::CesTool;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Dialogflow::V2::Tool };
    my $descriptor_b64 = <<'EOF';
Cilnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi9jZXNfdG9vbC5wcm90bxIaZ29vZ2xlLmNs
b3VkLmRpYWxvZ2Zsb3cudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdv
b2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aJWdvb2dsZS9jbG91ZC9kaWFsb2dmbG93L3YyL3Rv
b2wucHJvdG8iwwEKC0Nlc1Rvb2xTcGVjEjoKCGNlc190b29sGAEgASgJQh/gQQH6QRkKF2Nl
cy5nb29nbGVhcGlzLmNvbS9Ub29sUgdjZXNUb29sEngKGGNvbmZpcm1hdGlvbl9yZXF1aXJl
bWVudBgCIAEoDjI4Lmdvb2dsZS5jbG91ZC5kaWFsb2dmbG93LnYyLlRvb2wuQ29uZmlybWF0
aW9uUmVxdWlyZW1lbnRCA+BBAVIXY29uZmlybWF0aW9uUmVxdWlyZW1lbnRCkgEKHmNvbS5n
b29nbGUuY2xvdWQuZGlhbG9nZmxvdy52MkIMQ2VzVG9vbFByb3RvUAFaPmNsb3VkLmdvb2ds
ZS5jb20vZ28vZGlhbG9nZmxvdy9hcGl2Mi9kaWFsb2dmbG93cGI7ZGlhbG9nZmxvd3BiogIC
REaqAhpHb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5WMkqpCQoGEgQOACkBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAjCgkKAgMAEgMSACkKCQoCAwESAxMA
IwoJCgIDAhIDFAAvCggKAQgSAxYANwoJCgIIJRIDFgA3CggKAQgSAxcAVQoJCgIICxIDFwBV
CggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkALQoJCgIICBIDGQAtCggKAQgSAxoANwoJ
CgIIARIDGgA3CggKAQgSAxsAIAoJCgIIJBIDGwAgCkIKAgQAEgQeACkBGjYgU3BlYyBvZiBD
RVMgdG9vbCB0aGF0IHRoZSBnZW5lcmF0b3IgY2FuIGNob29zZSBmcm9tLgoKCgoDBAABEgMe
CBMKcQoEBAACABIEIQIkBBpjIE9wdGlvbmFsLiBGb3JtYXQ6IGBwcm9qZWN0cy88UHJvamVj
dCBJRD4vbG9jYXRpb25zLzxMb2NhdGlvbiBJRD4vYXBwcy88YXBwCiBJRD4vdG9vbHMvPHRv
b2wgSUQ+YC4KCgwKBQQAAgAFEgMhAggKDAoFBAACAAESAyEJEQoMCgUEAAIAAxIDIRQVCg0K
BQQAAgAIEgQhFiQDCg8KCAQAAgAInAgAEgMiBCoKDgoHBAACAAifCBIDIwRJClEKBAQAAgES
BCcCKC8aQyBPcHRpb25hbC4gSW5kaWNhdGVzIHdoZXRoZXIgdGhlIHRvb2wgcmVxdWlyZXMg
aHVtYW4gY29uZmlybWF0aW9uLgoKDAoFBAACAQYSAycCHgoMCgUEAAIBARIDJx83CgwKBQQA
AgEDEgMnOjsKDAoFBAACAQgSAygGLgoPCggEAAIBCJwIABIDKActYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::CesTool::CesToolSpec ===
    # Fields for CesToolSpec
    # Field: ces_tool Type: 9 ()
    # Field: confirmation_requirement Type: 14 (.google.cloud.dialogflow.v2.Tool.ConfirmationRequirement)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::CesTool - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/ces_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::CesTool;

    my $msg = Google::Cloud::Dialogflow::V2::CesTool::CesToolSpec->new({
        ces_tool => $ces_tool,
        confirmation_requirement => $confirmation_requirement,
    });

    # Read or update a field
    my $val = $msg->ces_tool();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::CesTool::CesToolSpec->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/ces_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::CesTool::CesToolSpec

Spec of CES tool that the generator can choose from.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ces_tool() >> / C<< $msg->ces_tool($value) >>

Type: C<String>

Optional. Format: `projects/<Project ID>/locations/<Location ID>/apps/<app
ID>/tools/<tool ID>`.

=item * C<< $msg->confirmation_requirement() >> / C<< $msg->confirmation_requirement($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::Tool::ConfirmationRequirement>)

Optional. Indicates whether the tool requires human confirmation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::CesTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
