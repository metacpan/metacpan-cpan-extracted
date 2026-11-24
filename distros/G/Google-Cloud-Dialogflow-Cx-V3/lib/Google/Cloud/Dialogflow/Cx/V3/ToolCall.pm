package Google::Cloud::Dialogflow::Cx::V3::ToolCall;

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
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
Ci1nb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92My90b29sX2NhbGwucHJvdG8SHWdvb2ds
ZS5jbG91ZC5kaWFsb2dmbG93LmN4LnYzGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0
LnByb3RvIqwBCghUb29sQ2FsbBI6CgR0b29sGAEgASgJQibgQQL6QSAKHmRpYWxvZ2Zsb3cu
Z29vZ2xlYXBpcy5jb20vVG9vbFIEdG9vbBIbCgZhY3Rpb24YAiABKAlCA+BBAlIGYWN0aW9u
EkcKEGlucHV0X3BhcmFtZXRlcnMYAyABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0QgPg
QQFSD2lucHV0UGFyYW1ldGVycyKwAgoOVG9vbENhbGxSZXN1bHQSOgoEdG9vbBgBIAEoCUIm
4EEC+kEgCh5kaWFsb2dmbG93Lmdvb2dsZWFwaXMuY29tL1Rvb2xSBHRvb2wSGwoGYWN0aW9u
GAIgASgJQgPgQQJSBmFjdGlvbhJLCgVlcnJvchgDIAEoCzIzLmdvb2dsZS5jbG91ZC5kaWFs
b2dmbG93LmN4LnYzLlRvb2xDYWxsUmVzdWx0LkVycm9ySABSBWVycm9yEkYKEW91dHB1dF9w
YXJhbWV0ZXJzGAQgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEgAUhBvdXRwdXRQYXJh
bWV0ZXJzGiYKBUVycm9yEh0KB21lc3NhZ2UYASABKAlCA+BBAVIHbWVzc2FnZUIICgZyZXN1
bHRCsAEKIWNvbS5nb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52M0INVG9vbENhbGxQcm90
b1ABWjFjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zsb3cvY3gvYXBpdjMvY3hwYjtjeHBi
ogICREaqAh1Hb29nbGUuQ2xvdWQuRGlhbG9nZmxvdy5DeC5WM+oCIUdvb2dsZTo6Q2xvdWQ6
OkRpYWxvZ2Zsb3c6OkNYOjpWM0r5EgoGEgQOAEsBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0
IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwg
VmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmls
ZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRh
aW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9y
Zy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxl
IGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVu
ZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBX
SVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4
cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxh
bmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRo
ZSBMaWNlbnNlLgoKCAoBAhIDEAAmCgkKAgMAEgMSACkKCQoCAwESAxMAIwoJCgIDAhIDFAAm
CggKAQgSAxYAOgoJCgIIJRIDFgA6CggKAQgSAxcASAoJCgIICxIDFwBICggKAQgSAxgAIgoJ
CgIIChIDGAAiCggKAQgSAxkALgoJCgIICBIDGQAuCggKAQgSAxoAOgoJCgIIARIDGgA6CggK
AQgSAxsAIAoJCgIIJBIDGwAgCggKAQgSAxwAOgoJCgIILRIDHAA6ClYKAgQAEgQfAC4BGkog
UmVwcmVzZW50cyBhIGNhbGwgb2YgYSBzcGVjaWZpYyB0b29sJ3MgYWN0aW9uIHdpdGggdGhl
IHNwZWNpZmllZCBpbnB1dHMuCgoKCgMEAAESAx8IEAq9AQoEBAACABIEIwImBBquASBSZXF1
aXJlZC4gVGhlIFt0b29sXVtnb29nbGUuY2xvdWQuZGlhbG9nZmxvdy5jeC52My5Ub29sXSBh
c3NvY2lhdGVkIHdpdGgKIHRoaXMgY2FsbC4gRm9ybWF0OgogYHByb2plY3RzLzxQcm9qZWN0
SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRzLzxBZ2VudElEPi90b29scy88VG9v
bElEPmAuCgoMCgUEAAIABRIDIwIICgwKBQQAAgABEgMjCQ0KDAoFBAACAAMSAyMQEQoNCgUE
AAIACBIEIxImAwoPCggEAAIACJwIABIDJAQqCg4KBwQAAgAInwgSAyUEUApRCgQEAAIBEgMp
Aj0aRCBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHRvb2wncyBhY3Rpb24gYXNzb2NpYXRl
ZCB3aXRoIHRoaXMgY2FsbC4KCgwKBQQAAgEFEgMpAggKDAoFBAACAQESAykJDwoMCgUEAAIB
AxIDKRITCgwKBQQAAgEIEgMpFDwKDwoIBAACAQicCAASAykVOwo4CgQEAAICEgQsAi0vGiog
T3B0aW9uYWwuIFRoZSBhY3Rpb24ncyBpbnB1dCBwYXJhbWV0ZXJzLgoKDAoFBAACAgYSAywC
GAoMCgUEAAICARIDLBkpCgwKBQQAAgIDEgMsLC0KDAoFBAACAggSAy0GLgoPCggEAAICCJwI
ABIDLQctClkKAgQBEgQxAEsBGk0gVGhlIHJlc3VsdCBvZiBjYWxsaW5nIGEgdG9vbCdzIGFj
dGlvbiB0aGF0IGhhcyBiZWVuIGV4ZWN1dGVkIGJ5IHRoZSBjbGllbnQuCgoKCgMEAQESAzEI
FgozCgQEAQMAEgQzAjYDGiUgQW4gZXJyb3IgcHJvZHVjZWQgYnkgdGhlIHRvb2wgY2FsbC4K
CgwKBQQBAwABEgMzCg8KPQoGBAEDAAIAEgM1BEAaLiBPcHRpb25hbC4gVGhlIGVycm9yIG1l
c3NhZ2Ugb2YgdGhlIGZ1bmN0aW9uLgoKDgoHBAEDAAIABRIDNQQKCg4KBwQBAwACAAESAzUL
EgoOCgcEAQMAAgADEgM1FRYKDgoHBAEDAAIACBIDNRc/ChEKCgQBAwACAAicCAASAzUYPgq9
AQoEBAECABIEOwI+BBquASBSZXF1aXJlZC4gVGhlIFt0b29sXVtnb29nbGUuY2xvdWQuZGlh
bG9nZmxvdy5jeC52My5Ub29sXSBhc3NvY2lhdGVkIHdpdGgKIHRoaXMgY2FsbC4gRm9ybWF0
OgogYHByb2plY3RzLzxQcm9qZWN0SUQ+L2xvY2F0aW9ucy88TG9jYXRpb25JRD4vYWdlbnRz
LzxBZ2VudElEPi90b29scy88VG9vbElEPmAuCgoMCgUEAQIABRIDOwIICgwKBQQBAgABEgM7
CQ0KDAoFBAECAAMSAzsQEQoNCgUEAQIACBIEOxI+AwoPCggEAQIACJwIABIDPAQqCg4KBwQB
AgAInwgSAz0EUApRCgQEAQIBEgNBAj0aRCBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIHRv
b2wncyBhY3Rpb24gYXNzb2NpYXRlZCB3aXRoIHRoaXMgY2FsbC4KCgwKBQQBAgEFEgNBAggK
DAoFBAECAQESA0EJDwoMCgUEAQIBAxIDQRITCgwKBQQBAgEIEgNBFDwKDwoIBAECAQicCAAS
A0EVOwonCgQEAQgAEgREAkoDGhkgVGhlIHRvb2wgY2FsbCdzIHJlc3VsdC4KCgwKBQQBCAAB
EgNECA4KJQoEBAECAhIDRgQUGhggVGhlIHRvb2wgY2FsbCdzIGVycm9yLgoKDAoFBAECAgYS
A0YECQoMCgUEAQICARIDRgoPCgwKBQQBAgIDEgNGEhMKMQoEBAECAxIDSQQxGiQgVGhlIHRv
b2wgY2FsbCdzIG91dHB1dCBwYXJhbWV0ZXJzLgoKDAoFBAECAwYSA0kEGgoMCgUEAQIDARID
SRssCgwKBQQBAgMDEgNJLzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3::ToolCall::ToolCall ===
    # Fields for ToolCall
    # Field: tool Type: 9 ()
    # Field: action Type: 9 ()
    # Field: input_parameters Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Dialogflow::Cx::V3::ToolCall::ToolCallResult ===
    # Fields for ToolCallResult
    # Field: tool Type: 9 ()
    # Field: action Type: 9 ()
    # Field: error Type: 11 (.google.cloud.dialogflow.cx.v3.ToolCallResult.Error)
    # Field: output_parameters Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3::ToolCall - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3/tool_call.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3::ToolCall;

    my $msg = Google::Cloud::Dialogflow::Cx::V3::ToolCall::ToolCall->new({
        tool => $tool,
        action => $action,
        input_parameters => $input_parameters,
    });

    # Read or update a field
    my $val = $msg->tool();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3::ToolCall::ToolCall->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3/tool_call.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3::ToolCall::ToolCall

Represents a call of a specific tool's action with the specified inputs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Required. The [tool][google.cloud.dialogflow.cx.v3.Tool] associated with
this call. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/tools/<ToolID>`.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Required. The name of the tool's action associated with this call.

=item * C<< $msg->input_parameters() >> / C<< $msg->input_parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Optional. The action's input parameters.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3::ToolCall::ToolCallResult

The result of calling a tool's action that has been executed by the client.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Required. The [tool][google.cloud.dialogflow.cx.v3.Tool] associated with
this call. Format:
`projects/<ProjectID>/locations/<LocationID>/agents/<AgentID>/tools/<ToolID>`.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

Required. The name of the tool's action associated with this call.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3::ToolCall::ToolCallResult::Error>)

The tool call's error.

=item * C<< $msg->output_parameters() >> / C<< $msg->output_parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The tool call's output parameters.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3::ToolCall::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
