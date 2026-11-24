package Google::Cloud::Ces::V1beta::Mocks;

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
    eval { require Google::Cloud::Ces::V1beta::ToolsetTool };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CiNnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9tb2Nrcy5wcm90bxIXZ29vZ2xlLmNsb3VkLmNl
cy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkv
cmVzb3VyY2UucHJvdG8aKmdvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL3Rvb2xzZXRfdG9vbC5w
cm90bxocZ29vZ2xlL3Byb3RvYnVmL3N0cnVjdC5wcm90byLyAgoOTW9ja2VkVG9vbENhbGwS
OgoHdG9vbF9pZBgEIAEoCUIf4EEB+kEZChdjZXMuZ29vZ2xlYXBpcy5jb20vVG9vbEgAUgZ0
b29sSWQSRQoHdG9vbHNldBgFIAEoCzIkLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLlRvb2xz
ZXRUb29sQgPgQQFIAFIHdG9vbHNldBI1CgR0b29sGAEgASgJQiEYAeBBAfpBGQoXY2VzLmdv
b2dsZWFwaXMuY29tL1Rvb2xSBHRvb2wSUAoVZXhwZWN0ZWRfYXJnc19wYXR0ZXJuGAIgASgL
MhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EECUhNleHBlY3RlZEFyZ3NQYXR0ZXJuEkEK
DW1vY2tfcmVzcG9uc2UYAyABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0QgPgQQFSDG1v
Y2tSZXNwb25zZUIRCg90b29sX2lkZW50aWZpZXJCWgobY29tLmdvb2dsZS5jbG91ZC5jZXMu
djFiZXRhQgpNb2Nrc1Byb3RvUAFaLWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxYmV0
YS9jZXNwYjtjZXNwYkqeDwoGEgQOAEABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAA0CgkKAgMD
EgMVACYKCAoBCBIDFwBECgkKAggLEgMXAEQKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBID
GQArCgkKAggIEgMZACsKCAoBCBIDGgA0CgkKAggBEgMaADQKuQEKAgQAEgQhAEABGqwBIEEg
bW9ja2VkIHRvb2wgY2FsbC4KCiBFeHByZXNzZXMgdGhlIHRhcmdldCB0b29sICsgYSBwYXR0
ZXJuIHRvIG1hdGNoIGFnYWluc3QgdGhhdCB0b29sJ3MKIGFyZ3MgLyBpbnB1dHMuIElmIHRo
ZSBwYXR0ZXJuIG1hdGNoZXMsIHRoZW4gdGhlIG1vY2sgcmVzcG9uc2Ugd2lsbCBiZQogcmV0
dXJuZWQuCgoKCgMEAAESAyEIFgozCgQEAAgAEgQjAi0DGiUgVGhlIGlkZW50aWZpZXIgb2Yg
dGhlIHRvb2wgdG8gbW9jay4KCgwKBQQACAABEgMjCBcKggEKBAQAAgASBCYEKQYadCBPcHRp
b25hbC4gVGhlIG5hbWUgb2YgdGhlIHRvb2wgdG8gbW9jay4KIEZvcm1hdDogYHByb2plY3Rz
L3twcm9qZWN0fS9sb2NhdGlvbnMve2xvY2F0aW9ufS9hcHBzL3thcHB9L3Rvb2xzL3t0b29s
fWAKCgwKBQQAAgAFEgMmBAoKDAoFBAACAAESAyYLEgoMCgUEAAIAAxIDJhUWCg0KBQQAAgAI
EgQmFykFCg8KCAQAAgAInAgAEgMnBiwKDgoHBAACAAifCBIDKAZLCi0KBAQAAgESAywERRog
IE9wdGlvbmFsLiBUaGUgdG9vbHNldCB0byBtb2NrLgoKDAoFBAACAQYSAywEDwoMCgUEAAIB
ARIDLBAXCgwKBQQAAgEDEgMsGhsKDAoFBAACAQgSAywcRAoPCggEAAIBCJwIABIDLB1DCkIK
BAQAAgISBDACNAQaNCBPcHRpb25hbC4gRGVwcmVjYXRlZC4gVXNlIHRvb2xfaWRlbnRpZmll
ciBpbnN0ZWFkLgoKDAoFBAACAgUSAzACCAoMCgUEAAICARIDMAkNCgwKBQQAAgIDEgMwEBEK
DQoFBAACAggSBDASNAMKDQoGBAACAggDEgMxBBUKDwoIBAACAgicCAASAzIEKgoOCgcEAAIC
CJ8IEgMzBEkKtgEKBAQAAgMSBDkCOi8apwEgUmVxdWlyZWQuIEEgcGF0dGVybiB0byBtYXRj
aCBhZ2FpbnN0IHRoZSBhcmdzIC8gaW5wdXRzIG9mIGFsbCBkaXNwYXRjaGVkCiB0b29sIGNh
bGxzLiBJZiB0aGUgdG9vbCBjYWxsIGlucHV0cyBtYXRjaCB0aGlzIHBhdHRlcm4sIHRoZW4g
bW9jayBvdXRwdXQKIHdpbGwgYmUgcmV0dXJuZWQuCgoMCgUEAAIDBhIDOQIYCgwKBQQAAgMB
EgM5GS4KDAoFBAACAwMSAzkxMgoMCgUEAAIDCBIDOgYuCg8KCAQAAgMInAgAEgM6By0KcQoE
BAACBBIEPgI/LxpjIE9wdGlvbmFsLiBUaGUgbW9jayByZXNwb25zZSAvIG91dHB1dCB0byBy
ZXR1cm4gaWYgdGhlIHRvb2wgY2FsbCBhcmdzIC8KIGlucHV0cyBtYXRjaCB0aGUgcGF0dGVy
bi4KCgwKBQQAAgQGEgM+AhgKDAoFBAACBAESAz4ZJgoMCgUEAAIEAxIDPikqCgwKBQQAAgQI
EgM/Bi4KDwoIBAACBAicCAASAz8HLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Mocks::MockedToolCall ===
    # Fields for MockedToolCall
    # Field: tool_id Type: 9 ()
    # Field: toolset Type: 11 (.google.cloud.ces.v1beta.ToolsetTool)
    # Field: tool Type: 9 ()
    # Field: expected_args_pattern Type: 11 (.google.protobuf.Struct)
    # Field: mock_response Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Mocks - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/mocks.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Mocks;

    my $msg = Google::Cloud::Ces::V1beta::Mocks::MockedToolCall->new({
        tool_id => $tool_id,
        toolset => $toolset,
        tool => $tool,
        expected_args_pattern => $expected_args_pattern,
    });

    # Read or update a field
    my $val = $msg->tool_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Mocks::MockedToolCall->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/mocks.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Mocks::MockedToolCall

A mocked tool call.

Expresses the target tool + a pattern to match against that tool's
args / inputs. If the pattern matches, then the mock response will be
returned.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool_id() >> / C<< $msg->tool_id($value) >>

Type: C<String>

Optional. The name of the tool to mock.
Format: `projects/{project}/locations/{location}/apps/{app}/tools/{tool}`

=item * C<< $msg->toolset() >> / C<< $msg->toolset($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ToolsetTool::ToolsetTool>)

Optional. The toolset to mock.

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Optional. Deprecated. Use tool_identifier instead.

=item * C<< $msg->expected_args_pattern() >> / C<< $msg->expected_args_pattern($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Required. A pattern to match against the args / inputs of all dispatched
tool calls. If the tool call inputs match this pattern, then mock output
will be returned.

=item * C<< $msg->mock_response() >> / C<< $msg->mock_response($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The mock response / output to return if the tool call args /
inputs match the pattern.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Mocks::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
