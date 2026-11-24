package Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy9jeC92M2JldGExL3Rvb2xfY2FsbC5wcm90bxIi
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMRocZ29vZ2xlL2FwaS9hbm5vdGF0
aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRf
YmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aHGdvb2dsZS9wcm90
b2J1Zi9zdHJ1Y3QucHJvdG8irAEKCFRvb2xDYWxsEjoKBHRvb2wYASABKAlCJuBBAvpBIAoe
ZGlhbG9nZmxvdy5nb29nbGVhcGlzLmNvbS9Ub29sUgR0b29sEhsKBmFjdGlvbhgCIAEoCUID
4EECUgZhY3Rpb24SRwoQaW5wdXRfcGFyYW1ldGVycxgDIAEoCzIXLmdvb2dsZS5wcm90b2J1
Zi5TdHJ1Y3RCA+BBAVIPaW5wdXRQYXJhbWV0ZXJzIrUCCg5Ub29sQ2FsbFJlc3VsdBI6CgR0
b29sGAEgASgJQibgQQL6QSAKHmRpYWxvZ2Zsb3cuZ29vZ2xlYXBpcy5jb20vVG9vbFIEdG9v
bBIbCgZhY3Rpb24YAiABKAlCA+BBAlIGYWN0aW9uElAKBWVycm9yGAMgASgLMjguZ29vZ2xl
LmNsb3VkLmRpYWxvZ2Zsb3cuY3gudjNiZXRhMS5Ub29sQ2FsbFJlc3VsdC5FcnJvckgAUgVl
cnJvchJGChFvdXRwdXRfcGFyYW1ldGVycxgEIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1
Y3RIAFIQb3V0cHV0UGFyYW1ldGVycxomCgVFcnJvchIdCgdtZXNzYWdlGAEgASgJQgPgQQFS
B21lc3NhZ2VCCAoGcmVzdWx0QscBCiZjb20uZ29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cuY3gu
djNiZXRhMUINVG9vbENhbGxQcm90b1ABWjZjbG91ZC5nb29nbGUuY29tL2dvL2RpYWxvZ2Zs
b3cvY3gvYXBpdjNiZXRhMS9jeHBiO2N4cGL4AQGiAgJERqoCIkdvb2dsZS5DbG91ZC5EaWFs
b2dmbG93LkN4LlYzQmV0YTHqAiZHb29nbGU6OkNsb3VkOjpEaWFsb2dmbG93OjpDWDo6VjNi
ZXRhMUq0EgoGEgQOAEgBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExM
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
AhIDEAArCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCQoC
AwQSAxYAJgoICgEIEgMYAB8KCQoCCB8SAxgAHwoICgEIEgMZAD8KCQoCCCUSAxkAPwoICgEI
EgMaAE0KCQoCCAsSAxoATQoICgEIEgMbACIKCQoCCAoSAxsAIgoICgEIEgMcAC4KCQoCCAgS
AxwALgoICgEIEgMdAD8KCQoCCAESAx0APwoICgEIEgMeACAKCQoCCCQSAx4AIAoICgEIEgMf
AD8KCQoCCC0SAx8APwpWCgIEABIEIgAvARpKIFJlcHJlc2VudHMgYSBjYWxsIG9mIGEgc3Bl
Y2lmaWMgdG9vbCdzIGFjdGlvbiB3aXRoIHRoZSBzcGVjaWZpZWQgaW5wdXRzLgoKCgoDBAAB
EgMiCBAKmQEKBAQAAgASBCYCKQQaigEgVGhlIFt0b29sXVtUb29sXSBhc3NvY2lhdGVkIHdp
dGggdGhpcyBjYWxsLgogRm9ybWF0OiBgcHJvamVjdHMvPFByb2plY3QgSUQ+L2xvY2F0aW9u
cy88TG9jYXRpb24gSUQ+L2FnZW50cy88QWdlbnQKIElEPi90b29scy88VG9vbCBJRD5gLgoK
DAoFBAACAAUSAyYCCAoMCgUEAAIAARIDJgkNCgwKBQQAAgADEgMmEBEKDQoFBAACAAgSBCYS
KQMKDwoIBAACAAicCAASAycEKgoOCgcEAAIACJ8IEgMoBFAKRwoEBAACARIDKwI9GjogVGhl
IG5hbWUgb2YgdGhlIHRvb2wncyBhY3Rpb24gYXNzb2NpYXRlZCB3aXRoIHRoaXMgY2FsbC4K
CgwKBQQAAgEFEgMrAggKDAoFBAACAQESAysJDwoMCgUEAAIBAxIDKxITCgwKBQQAAgEIEgMr
FDwKDwoIBAACAQicCAASAysVOwouCgQEAAICEgQtAi4vGiAgVGhlIGFjdGlvbidzIGlucHV0
IHBhcmFtZXRlcnMuCgoMCgUEAAICBhIDLQIYCgwKBQQAAgIBEgMtGSkKDAoFBAACAgMSAy0s
LQoMCgUEAAICCBIDLgYuCg8KCAQAAgIInAgAEgMuBy0KWQoCBAESBDIASAEaTSBUaGUgcmVz
dWx0IG9mIGNhbGxpbmcgYSB0b29sJ3MgYWN0aW9uIHRoYXQgaGFzIGJlZW4gZXhlY3V0ZWQg
YnkgdGhlIGNsaWVudC4KCgoKAwQBARIDMggWCpkBCgQEAQIAEgQ2AjkEGooBIFRoZSBbdG9v
bF1bVG9vbF0gYXNzb2NpYXRlZCB3aXRoIHRoaXMgY2FsbC4KIEZvcm1hdDogYHByb2plY3Rz
LzxQcm9qZWN0IElEPi9sb2NhdGlvbnMvPExvY2F0aW9uIElEPi9hZ2VudHMvPEFnZW50CiBJ
RD4vdG9vbHMvPFRvb2wgSUQ+YC4KCgwKBQQBAgAFEgM2AggKDAoFBAECAAESAzYJDQoMCgUE
AQIAAxIDNhARCg0KBQQBAgAIEgQ2EjkDCg8KCAQBAgAInAgAEgM3BCoKDgoHBAECAAifCBID
OARQCkcKBAQBAgESAzsCPRo6IFRoZSBuYW1lIG9mIHRoZSB0b29sJ3MgYWN0aW9uIGFzc29j
aWF0ZWQgd2l0aCB0aGlzIGNhbGwuCgoMCgUEAQIBBRIDOwIICgwKBQQBAgEBEgM7CQ8KDAoF
BAECAQMSAzsSEwoMCgUEAQIBCBIDOxQ8Cg8KCAQBAgEInAgAEgM7FTsKMwoEBAEDABIEPQJA
AxolIEFuIGVycm9yIHByb2R1Y2VkIGJ5IHRoZSB0b29sIGNhbGwuCgoMCgUEAQMAARIDPQoP
CjMKBgQBAwACABIDPwRAGiQgVGhlIGVycm9yIG1lc3NhZ2Ugb2YgdGhlIGZ1bmN0aW9uLgoK
DgoHBAEDAAIABRIDPwQKCg4KBwQBAwACAAESAz8LEgoOCgcEAQMAAgADEgM/FRYKDgoHBAED
AAIACBIDPxc/ChEKCgQBAwACAAicCAASAz8YPgonCgQEAQgAEgRCAkcDGhkgVGhlIHRvb2wg
Y2FsbCdzIHJlc3VsdC4KCgwKBQQBCAABEgNCCA4KJQoEBAECAhIDRAQUGhggVGhlIHRvb2wg
Y2FsbCdzIGVycm9yLgoKDAoFBAECAgYSA0QECQoMCgUEAQICARIDRAoPCgwKBQQBAgIDEgNE
EhMKMQoEBAECAxIDRgQxGiQgVGhlIHRvb2wgY2FsbCdzIG91dHB1dCBwYXJhbWV0ZXJzLgoK
DAoFBAECAwYSA0YEGgoMCgUEAQIDARIDRhssCgwKBQQBAgMDEgNGLzBiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall::ToolCall ===
    # Fields for ToolCall
    # Field: tool Type: 9 ()
    # Field: action Type: 9 ()
    # Field: input_parameters Type: 11 (.google.protobuf.Struct)

# === Message: Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall::ToolCallResult ===
    # Fields for ToolCallResult
    # Field: tool Type: 9 ()
    # Field: action Type: 9 ()
    # Field: error Type: 11 (.google.cloud.dialogflow.cx.v3beta1.ToolCallResult.Error)
    # Field: output_parameters Type: 11 (.google.protobuf.Struct)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall - Compiled Protocol Buffers messages for google/cloud/dialogflow/cx/v3beta1/tool_call.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall;

    my $msg = Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall::ToolCall->new({
        tool => $tool,
        action => $action,
        input_parameters => $input_parameters,
    });

    # Read or update a field
    my $val = $msg->tool();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall::ToolCall->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/cx/v3beta1/tool_call.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall::ToolCall

Represents a call of a specific tool's action with the specified inputs.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

The [tool][Tool] associated with this call.
Format: `projects/<Project ID>/locations/<Location ID>/agents/<Agent
ID>/tools/<Tool ID>`.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

The name of the tool's action associated with this call.

=item * C<< $msg->input_parameters() >> / C<< $msg->input_parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The action's input parameters.

=back

=head2 Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall::ToolCallResult

The result of calling a tool's action that has been executed by the client.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

The [tool][Tool] associated with this call.
Format: `projects/<Project ID>/locations/<Location ID>/agents/<Agent
ID>/tools/<Tool ID>`.

=item * C<< $msg->action() >> / C<< $msg->action($value) >>

Type: C<String>

The name of the tool's action associated with this call.

=item * C<< $msg->error() >> / C<< $msg->error($value) >>

Type: C<Message> (L<Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall::ToolCallResult::Error>)

The tool call's error.

=item * C<< $msg->output_parameters() >> / C<< $msg->output_parameters($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

The tool call's output parameters.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::Cx::V3beta1::ToolCall::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
