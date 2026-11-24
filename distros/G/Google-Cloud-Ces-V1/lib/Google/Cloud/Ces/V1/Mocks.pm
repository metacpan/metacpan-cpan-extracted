package Google::Cloud::Ces::V1::Mocks;

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
    eval { require Google::Cloud::Ces::V1::ToolsetTool };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ch9nb29nbGUvY2xvdWQvY2VzL3YxL21vY2tzLnByb3RvEhNnb29nbGUuY2xvdWQuY2VzLnYx
Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNl
LnByb3RvGiZnb29nbGUvY2xvdWQvY2VzL3YxL3Rvb2xzZXRfdG9vbC5wcm90bxocZ29vZ2xl
L3Byb3RvYnVmL3N0cnVjdC5wcm90byLuAgoOTW9ja2VkVG9vbENhbGwSOgoHdG9vbF9pZBgE
IAEoCUIf4EEB+kEZChdjZXMuZ29vZ2xlYXBpcy5jb20vVG9vbEgAUgZ0b29sSWQSQQoHdG9v
bHNldBgFIAEoCzIgLmdvb2dsZS5jbG91ZC5jZXMudjEuVG9vbHNldFRvb2xCA+BBAUgAUgd0
b29sc2V0EjUKBHRvb2wYASABKAlCIRgB4EEB+kEZChdjZXMuZ29vZ2xlYXBpcy5jb20vVG9v
bFIEdG9vbBJQChVleHBlY3RlZF9hcmdzX3BhdHRlcm4YAiABKAsyFy5nb29nbGUucHJvdG9i
dWYuU3RydWN0QgPgQQJSE2V4cGVjdGVkQXJnc1BhdHRlcm4SQQoNbW9ja19yZXNwb25zZRgD
IAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RCA+BBAVIMbW9ja1Jlc3BvbnNlQhEKD3Rv
b2xfaWRlbnRpZmllckJSChdjb20uZ29vZ2xlLmNsb3VkLmNlcy52MUIKTW9ja3NQcm90b1AB
WiljbG91ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MS9jZXNwYjtjZXNwYkqeDwoGEgQOAEAB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMS
ACkKCQoCAwESAxMAIwoJCgIDAhIDFAAwCgkKAgMDEgMVACYKCAoBCBIDFwBACgkKAggLEgMX
AEAKCAoBCBIDGAAiCgkKAggKEgMYACIKCAoBCBIDGQArCgkKAggIEgMZACsKCAoBCBIDGgAw
CgkKAggBEgMaADAKuQEKAgQAEgQhAEABGqwBIEEgbW9ja2VkIHRvb2wgY2FsbC4KCiBFeHBy
ZXNzZXMgdGhlIHRhcmdldCB0b29sICsgYSBwYXR0ZXJuIHRvIG1hdGNoIGFnYWluc3QgdGhh
dCB0b29sJ3MKIGFyZ3MgLyBpbnB1dHMuIElmIHRoZSBwYXR0ZXJuIG1hdGNoZXMsIHRoZW4g
dGhlIG1vY2sgcmVzcG9uc2Ugd2lsbCBiZQogcmV0dXJuZWQuCgoKCgMEAAESAyEIFgozCgQE
AAgAEgQjAi0DGiUgVGhlIGlkZW50aWZpZXIgb2YgdGhlIHRvb2wgdG8gbW9jay4KCgwKBQQA
CAABEgMjCBcKggEKBAQAAgASBCYEKQYadCBPcHRpb25hbC4gVGhlIG5hbWUgb2YgdGhlIHRv
b2wgdG8gbW9jay4KIEZvcm1hdDogYHByb2plY3RzL3twcm9qZWN0fS9sb2NhdGlvbnMve2xv
Y2F0aW9ufS9hcHBzL3thcHB9L3Rvb2xzL3t0b29sfWAKCgwKBQQAAgAFEgMmBAoKDAoFBAAC
AAESAyYLEgoMCgUEAAIAAxIDJhUWCg0KBQQAAgAIEgQmFykFCg8KCAQAAgAInAgAEgMnBiwK
DgoHBAACAAifCBIDKAZLCi0KBAQAAgESAywERRogIE9wdGlvbmFsLiBUaGUgdG9vbHNldCB0
byBtb2NrLgoKDAoFBAACAQYSAywEDwoMCgUEAAIBARIDLBAXCgwKBQQAAgEDEgMsGhsKDAoF
BAACAQgSAywcRAoPCggEAAIBCJwIABIDLB1DCkIKBAQAAgISBDACNAQaNCBPcHRpb25hbC4g
RGVwcmVjYXRlZC4gVXNlIHRvb2xfaWRlbnRpZmllciBpbnN0ZWFkLgoKDAoFBAACAgUSAzAC
CAoMCgUEAAICARIDMAkNCgwKBQQAAgIDEgMwEBEKDQoFBAACAggSBDASNAMKDQoGBAACAggD
EgMxBBUKDwoIBAACAgicCAASAzIEKgoOCgcEAAICCJ8IEgMzBEkKtgEKBAQAAgMSBDkCOi8a
pwEgUmVxdWlyZWQuIEEgcGF0dGVybiB0byBtYXRjaCBhZ2FpbnN0IHRoZSBhcmdzIC8gaW5w
dXRzIG9mIGFsbCBkaXNwYXRjaGVkCiB0b29sIGNhbGxzLiBJZiB0aGUgdG9vbCBjYWxsIGlu
cHV0cyBtYXRjaCB0aGlzIHBhdHRlcm4sIHRoZW4gbW9jayBvdXRwdXQKIHdpbGwgYmUgcmV0
dXJuZWQuCgoMCgUEAAIDBhIDOQIYCgwKBQQAAgMBEgM5GS4KDAoFBAACAwMSAzkxMgoMCgUE
AAIDCBIDOgYuCg8KCAQAAgMInAgAEgM6By0KcQoEBAACBBIEPgI/LxpjIE9wdGlvbmFsLiBU
aGUgbW9jayByZXNwb25zZSAvIG91dHB1dCB0byByZXR1cm4gaWYgdGhlIHRvb2wgY2FsbCBh
cmdzIC8KIGlucHV0cyBtYXRjaCB0aGUgcGF0dGVybi4KCgwKBQQAAgQGEgM+AhgKDAoFBAAC
BAESAz4ZJgoMCgUEAAIEAxIDPikqCgwKBQQAAgQIEgM/Bi4KDwoIBAACBAicCAASAz8HLWIG
cHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Mocks::MockedToolCall ===
    # Fields for MockedToolCall
    # Field: tool_id Type: 9 ()
    # Field: toolset Type: 11 (.google.cloud.ces.v1.ToolsetTool)
    # Field: tool Type: 9 ()
    # Field: expected_args_pattern Type: 11 (.google.protobuf.Struct)
    # Field: mock_response Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Mocks - Compiled Protocol Buffers messages for google/cloud/ces/v1/mocks.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Mocks;

    my $msg = Google::Cloud::Ces::V1::Mocks::MockedToolCall->new({
        tool_id => $tool_id,
        toolset => $toolset,
        tool => $tool,
        expected_args_pattern => $expected_args_pattern,
    });

    # Read or update a field
    my $val = $msg->tool_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Mocks::MockedToolCall->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/mocks.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Mocks::MockedToolCall

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

Type: C<Message> (L<Google::Cloud::Ces::V1::ToolsetTool::ToolsetTool>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Mocks::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
