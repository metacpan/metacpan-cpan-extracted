package Google::Cloud::Ces::V1beta::Fakes;

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
CiNnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9mYWtlcy5wcm90bxIXZ29vZ2xlLmNsb3VkLmNl
cy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8iMQoJQ29kZUJsb2Nr
EiQKC3B5dGhvbl9jb2RlGAEgASgJQgPgQQJSCnB5dGhvbkNvZGUimgEKDlRvb2xGYWtlQ29u
ZmlnEkgKCmNvZGVfYmxvY2sYASABKAsyIi5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5Db2Rl
QmxvY2tCA+BBAUgAUgljb2RlQmxvY2sSLQoQZW5hYmxlX2Zha2VfbW9kZRgCIAEoCEID4EEB
Ug5lbmFibGVGYWtlTW9kZUIPCg10b29sX3Jlc3BvbnNlKmEKG0V2YWx1YXRpb25Ub29sQ2Fs
bEJlaGF2aW91chIuCipFVkFMVUFUSU9OX1RPT0xfQ0FMTF9CRUhBVklPVVJfVU5TUEVDSUZJ
RUQQABIICgRSRUFMEAESCAoERkFLRRACQloKG2NvbS5nb29nbGUuY2xvdWQuY2VzLnYxYmV0
YUIKRmFrZXNQcm90b1ABWi1jbG91ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MWJldGEvY2Vz
cGI7Y2VzcGJK2hAKBhIEDgA9AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2ds
ZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4w
ICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGlu
IGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBv
ZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMv
TElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdy
ZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGlj
ZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJS
QU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGlt
cGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zl
cm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4K
CggKAQISAxAAIAoJCgIDABIDEgApCggKAQgSAxQARAoJCgIICxIDFABECggKAQgSAxUAIgoJ
CgIIChIDFQAiCggKAQgSAxYAKwoJCgIICBIDFgArCggKAQgSAxcANAoJCgIIARIDFwA0CkUK
AgUAEgQaACMBGjkgQ29uZmlndXJlcyB0aGUgdG9vbCBjYWxsIGJlaGF2aW91ciBmb3IgZXZh
bHVhdGlvbiBydW5zLgoKCgoDBQABEgMaBSAKTwoEBQACABIDHAIxGkIgVW5zcGVjaWZpZWQg
dG9vbCBjYWxsIGJlaGF2aW9yLiBXaWxsIGRlZmF1bHQgdG8gcmVhbCB0b29sIGNhbGxzLgoK
DAoFBQACAAESAxwCLAoMCgUFAAIAAhIDHC8wCiMKBAUAAgESAx8CCxoWIFVzZSByZWFsIHRv
b2wgY2FsbHMuCgoMCgUFAAIBARIDHwIGCgwKBQUAAgECEgMfCQoKIwoEBQACAhIDIgILGhYg
VXNlIGZha2UgdG9vbCBjYWxscy4KCgwKBQUAAgIBEgMiAgYKDAoFBQACAgISAyIJCgpGCgIE
ABIEJgAxARo6IEEgY29kZSBibG9jayB0byBiZSBleGVjdXRlZCBpbnN0ZWFkIG9mIGEgcmVh
bCB0b29sIGNhbGwuCgoKCgMEAAESAyYIEQrwAwoEBAACABIDMAJCGuIDIFJlcXVpcmVkLiBQ
eXRob24gY29kZSB3aGljaCB3aWxsIGJlIGludm9rZWQgaW4gdG9vbCBmYWtlIG1vZGUuCiBF
eHBlY3RlZCBQeXRob24gZnVuY3Rpb24gc2lnbmF0dXJlIC0KIFRvIGNhdGNoIGFsbCB0b29s
IGNhbGxzOgogICBkZWYgZmFrZV90b29sX2NhbGwodG9vbDogVG9vbCwgaW5wdXQ6IGRpY3Rb
c3RyLCBBbnldLAogICAgIGNhbGxiYWNrX2NvbnRleHQ6IENhbGxiYWNrQ29udGV4dCkgLT4g
T3B0aW9uYWxbZGljdFtzdHIsIEFueV1dOgogVG8gY2F0Y2ggYSBzcGVjaWZpYyB0b29sIGNh
bGw6CiAgIGRlZiBmYWtlX3t0b29sX2lkfSh0b29sOiBUb29sLCBpbnB1dDogZGljdFtzdHIs
IEFueV0sCiAgICAgY2FsbGJhY2tfY29udGV4dDogQ2FsbGJhY2tDb250ZXh0KSAtPiBPcHRp
b25hbFtkaWN0W3N0ciwgQW55XV06CiBJZiB0aGUgZnVuY3Rpb24gcmV0dXJucyBOb25lLCB0
aGUgcmVhbCB0b29sIHdpbGwgYmUgaW52b2tlZCBpbnN0ZWFkLgoKDAoFBAACAAUSAzACCAoM
CgUEAAIAARIDMAkUCgwKBQQAAgADEgMwFxgKDAoFBAACAAgSAzAZQQoPCggEAAIACJwIABID
MBpACjsKAgQBEgQ0AD0BGi8gQ29uZmlndXJhdGlvbiBmb3IgdG9vbCBiZWhhdmlvciBpbiBm
YWtlIG1vZGUuCgoKCgMEAQESAzQIFgpVCgQEAQgAEgQ2AjkDGkcgVGhlIHJlc3BvbnNlIGlz
IGVpdGhlciBzdGF0aWMgb3IgaXQgaXMgcHJvdmlkZWQgYnkgYSBweXRob24gZnVuY3Rpb24u
CgoMCgUEAQgAARIDNggVClcKBAQBAgASAzgERhpKIE9wdGlvbmFsLiBDb2RlIGJsb2NrIHdo
aWNoIHdpbGwgYmUgZXhlY3V0ZWQgaW5zdGVhZCBvZiBhIHJlYWwgdG9vbCBjYWxsLgoKDAoF
BAECAAYSAzgEDQoMCgUEAQIAARIDOA4YCgwKBQQBAgADEgM4GxwKDAoFBAECAAgSAzgdRQoP
CggEAQIACJwIABIDOB5ECj0KBAQBAgESAzwCRRowIE9wdGlvbmFsLiBXaGV0aGVyIHRoZSB0
b29sIGlzIHVzaW5nIGZha2UgbW9kZS4KCgwKBQQBAgEFEgM8AgYKDAoFBAECAQESAzwHFwoM
CgUEAQIBAxIDPBobCgwKBQQBAgEIEgM8HEQKDwoIBAECAQicCAASAzwdQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::Fakes::CodeBlock ===
    # Fields for CodeBlock
    # Field: python_code Type: 9 ()

# === Message: Google::Cloud::Ces::V1beta::Fakes::ToolFakeConfig ===
    # Fields for ToolFakeConfig
    # Field: code_block Type: 11 (.google.cloud.ces.v1beta.CodeBlock)
    # Field: enable_fake_mode Type: 8 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::Fakes - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/fakes.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::Fakes;

    my $msg = Google::Cloud::Ces::V1beta::Fakes::CodeBlock->new({
        python_code => $python_code,
    });

    # Read or update a field
    my $val = $msg->python_code();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::Fakes::CodeBlock->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/fakes.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::Fakes::CodeBlock

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

=head2 Google::Cloud::Ces::V1beta::Fakes::ToolFakeConfig

Configuration for tool behavior in fake mode.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->code_block() >> / C<< $msg->code_block($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Fakes::CodeBlock>)

Optional. Code block which will be executed instead of a real tool call.

=item * C<< $msg->enable_fake_mode() >> / C<< $msg->enable_fake_mode($value) >>

Type: C<Bool>

Optional. Whether the tool is using fake mode.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::Fakes::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
