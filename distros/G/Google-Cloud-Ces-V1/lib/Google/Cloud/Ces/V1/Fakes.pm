package Google::Cloud::Ces::V1::Fakes;

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
Ch9nb29nbGUvY2xvdWQvY2VzL3YxL2Zha2VzLnByb3RvEhNnb29nbGUuY2xvdWQuY2VzLnYx
Gh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvIjEKCUNvZGVCbG9jaxIkCgtweXRo
b25fY29kZRgBIAEoCUID4EECUgpweXRob25Db2RlIpYBCg5Ub29sRmFrZUNvbmZpZxJECgpj
b2RlX2Jsb2NrGAEgASgLMh4uZ29vZ2xlLmNsb3VkLmNlcy52MS5Db2RlQmxvY2tCA+BBAUgA
Ugljb2RlQmxvY2sSLQoQZW5hYmxlX2Zha2VfbW9kZRgCIAEoCEID4EEBUg5lbmFibGVGYWtl
TW9kZUIPCg10b29sX3Jlc3BvbnNlQlIKF2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxQgpGYWtl
c1Byb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nlc3BiSpgO
CgYSBA4AMQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwK
CQoCAwASAxIAKQoICgEIEgMUAEAKCQoCCAsSAxQAQAoICgEIEgMVACIKCQoCCAoSAxUAIgoI
CgEIEgMWACsKCQoCCAgSAxYAKwoICgEIEgMXADAKCQoCCAESAxcAMApGCgIEABIEGgAlARo6
IEEgY29kZSBibG9jayB0byBiZSBleGVjdXRlZCBpbnN0ZWFkIG9mIGEgcmVhbCB0b29sIGNh
bGwuCgoKCgMEAAESAxoIEQrwAwoEBAACABIDJAJCGuIDIFJlcXVpcmVkLiBQeXRob24gY29k
ZSB3aGljaCB3aWxsIGJlIGludm9rZWQgaW4gdG9vbCBmYWtlIG1vZGUuCiBFeHBlY3RlZCBQ
eXRob24gZnVuY3Rpb24gc2lnbmF0dXJlIC0KIFRvIGNhdGNoIGFsbCB0b29sIGNhbGxzOgog
ICBkZWYgZmFrZV90b29sX2NhbGwodG9vbDogVG9vbCwgaW5wdXQ6IGRpY3Rbc3RyLCBBbnld
LAogICAgIGNhbGxiYWNrX2NvbnRleHQ6IENhbGxiYWNrQ29udGV4dCkgLT4gT3B0aW9uYWxb
ZGljdFtzdHIsIEFueV1dOgogVG8gY2F0Y2ggYSBzcGVjaWZpYyB0b29sIGNhbGw6CiAgIGRl
ZiBmYWtlX3t0b29sX2lkfSh0b29sOiBUb29sLCBpbnB1dDogZGljdFtzdHIsIEFueV0sCiAg
ICAgY2FsbGJhY2tfY29udGV4dDogQ2FsbGJhY2tDb250ZXh0KSAtPiBPcHRpb25hbFtkaWN0
W3N0ciwgQW55XV06CiBJZiB0aGUgZnVuY3Rpb24gcmV0dXJucyBOb25lLCB0aGUgcmVhbCB0
b29sIHdpbGwgYmUgaW52b2tlZCBpbnN0ZWFkLgoKDAoFBAACAAUSAyQCCAoMCgUEAAIAARID
JAkUCgwKBQQAAgADEgMkFxgKDAoFBAACAAgSAyQZQQoPCggEAAIACJwIABIDJBpACjsKAgQB
EgQoADEBGi8gQ29uZmlndXJhdGlvbiBmb3IgdG9vbCBiZWhhdmlvciBpbiBmYWtlIG1vZGUu
CgoKCgMEAQESAygIFgpVCgQEAQgAEgQqAi0DGkcgVGhlIHJlc3BvbnNlIGlzIGVpdGhlciBz
dGF0aWMgb3IgaXQgaXMgcHJvdmlkZWQgYnkgYSBweXRob24gZnVuY3Rpb24uCgoMCgUEAQgA
ARIDKggVClcKBAQBAgASAywERhpKIE9wdGlvbmFsLiBDb2RlIGJsb2NrIHdoaWNoIHdpbGwg
YmUgZXhlY3V0ZWQgaW5zdGVhZCBvZiBhIHJlYWwgdG9vbCBjYWxsLgoKDAoFBAECAAYSAywE
DQoMCgUEAQIAARIDLA4YCgwKBQQBAgADEgMsGxwKDAoFBAECAAgSAywdRQoPCggEAQIACJwI
ABIDLB5ECj0KBAQBAgESAzACRRowIE9wdGlvbmFsLiBXaGV0aGVyIHRoZSB0b29sIGlzIHVz
aW5nIGZha2UgbW9kZS4KCgwKBQQBAgEFEgMwAgYKDAoFBAECAQESAzAHFwoMCgUEAQIBAxID
MBobCgwKBQQBAgEIEgMwHEQKDwoIBAECAQicCAASAzAdQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Fakes::CodeBlock ===
    # Fields for CodeBlock
    # Field: python_code Type: 9 ()

# === Message: Google::Cloud::Ces::V1::Fakes::ToolFakeConfig ===
    # Fields for ToolFakeConfig
    # Field: code_block Type: 11 (.google.cloud.ces.v1.CodeBlock)
    # Field: enable_fake_mode Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Fakes - Compiled Protocol Buffers messages for google/cloud/ces/v1/fakes.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Fakes;

    my $msg = Google::Cloud::Ces::V1::Fakes::CodeBlock->new({
        python_code => $python_code,
    });

    # Read or update a field
    my $val = $msg->python_code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Fakes::CodeBlock->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/fakes.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Fakes::CodeBlock

A code block to be executed instead of a real tool call.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->python_code() >> / C<< $msg->python_code($value) >>

Type: C<String>

Required. Python code which will be invoked in tool fake mode.
Expected Python function signature -
To catch all tool calls:
  def fake_tool_call(tool: Tool, input: dict[str, Any],
    callback_context: CallbackContext) -> Optional[dict[str, Any]]:
To catch a specific tool call:
  def fake_{tool_id}(tool: Tool, input: dict[str, Any],
    callback_context: CallbackContext) -> Optional[dict[str, Any]]:
If the function returns None, the real tool will be invoked instead.

=back

=head2 Google::Cloud::Ces::V1::Fakes::ToolFakeConfig

Configuration for tool behavior in fake mode.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code_block() >> / C<< $msg->code_block($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Fakes::CodeBlock>)

Optional. Code block which will be executed instead of a real tool call.

=item * C<< $msg->enable_fake_mode() >> / C<< $msg->enable_fake_mode($value) >>

Type: C<Bool>

Optional. Whether the tool is using fake mode.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Fakes::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
