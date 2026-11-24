package Google::Cloud::Ces::V1::Toolset;

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
    eval { require Google::Cloud::Ces::V1::Common };
    eval { require Google::Cloud::Ces::V1::ConnectorToolset };
    eval { require Google::Cloud::Ces::V1::Fakes };
    eval { require Google::Cloud::Ces::V1::McpToolset };
    eval { require Google::Cloud::Ces::V1::OpenApiToolset };
    eval { require Google::Protobuf::Duration };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CiFnb29nbGUvY2xvdWQvY2VzL3YxL3Rvb2xzZXQucHJvdG8SE2dvb2dsZS5jbG91ZC5jZXMu
djEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3Vy
Y2UucHJvdG8aIGdvb2dsZS9jbG91ZC9jZXMvdjEvY29tbW9uLnByb3RvGitnb29nbGUvY2xv
dWQvY2VzL3YxL2Nvbm5lY3Rvcl90b29sc2V0LnByb3RvGh9nb29nbGUvY2xvdWQvY2VzL3Yx
L2Zha2VzLnByb3RvGiVnb29nbGUvY2xvdWQvY2VzL3YxL21jcF90b29sc2V0LnByb3RvGipn
b29nbGUvY2xvdWQvY2VzL3YxL29wZW5fYXBpX3Rvb2xzZXQucHJvdG8aHmdvb2dsZS9wcm90
b2J1Zi9kdXJhdGlvbi5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byLs
BgoHVG9vbHNldBJHCgttY3BfdG9vbHNldBgGIAEoCzIfLmdvb2dsZS5jbG91ZC5jZXMudjEu
TWNwVG9vbHNldEID4EEBSABSCm1jcFRvb2xzZXQSVAoQb3Blbl9hcGlfdG9vbHNldBgHIAEo
CzIjLmdvb2dsZS5jbG91ZC5jZXMudjEuT3BlbkFwaVRvb2xzZXRCA+BBAUgAUg5vcGVuQXBp
VG9vbHNldBJZChFjb25uZWN0b3JfdG9vbHNldBgIIAEoCzIlLmdvb2dsZS5jbG91ZC5jZXMu
djEuQ29ubmVjdG9yVG9vbHNldEID4EEBSABSEGNvbm5lY3RvclRvb2xzZXQSFwoEbmFtZRgB
IAEoCUID4EEIUgRuYW1lEiYKDGRpc3BsYXlfbmFtZRgCIAEoCUID4EEBUgtkaXNwbGF5TmFt
ZRIlCgtkZXNjcmlwdGlvbhgKIAEoCUID4EEBUgtkZXNjcmlwdGlvbhI4Cgd0aW1lb3V0GAwg
ASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uQgPgQQFSB3RpbWVvdXQSQAoLY3JlYXRl
X3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRp
bWUSQAoLdXBkYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSCnVwZGF0ZVRpbWUSEgoEZXRhZxgFIAEoCVIEZXRhZxJOCg5leGVjdXRpb25fdHlwZRgJ
IAEoDjIiLmdvb2dsZS5jbG91ZC5jZXMudjEuRXhlY3V0aW9uVHlwZUID4EEBUg1leGVjdXRp
b25UeXBlElIKEHRvb2xfZmFrZV9jb25maWcYCyABKAsyIy5nb29nbGUuY2xvdWQuY2VzLnYx
LlRvb2xGYWtlQ29uZmlnQgPgQQFSDnRvb2xGYWtlQ29uZmlnOnnqQXYKGmNlcy5nb29nbGVh
cGlzLmNvbS9Ub29sc2V0EkVwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlv
bn0vYXBwcy97YXBwfS90b29sc2V0cy97dG9vbHNldH0qCHRvb2xzZXRzMgd0b29sc2V0Qg4K
DHRvb2xzZXRfdHlwZUJUChdjb20uZ29vZ2xlLmNsb3VkLmNlcy52MUIMVG9vbHNldFByb3Rv
UAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nlc3BiSpUYCgYSBA4A
YAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwAS
AxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACoKCQoCAwMSAxUANQoJCgIDBBIDFgApCgkKAgMF
EgMXAC8KCQoCAwYSAxgANAoJCgIDBxIDGQAoCgkKAgMIEgMaACkKCAoBCBIDHABACgkKAggL
EgMcAEAKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgAtCgkKAggIEgMeAC0KCAoBCBID
HwAwCgkKAggBEgMfADAKZwoCBAASBCMAYAEaWyBBIHRvb2xzZXQgcmVwcmVzZW50cyBhIGdy
b3VwIG9mIGR5bmFtaWNhbGx5IG1hbmFnZWQgdG9vbHMgdGhhdCBjYW4gYmUgdXNlZAogYnkg
dGhlIGFnZW50LgoKCgoDBAABEgMjCA8KCwoDBAAHEgQkAikECg0KBQQAB50IEgQkAikECigK
BAQACAASBCwCOgMaGiBUaGUgdHlwZSBvZiB0aGUgdG9vbHNldC4KCgwKBQQACAABEgMsCBQK
ZQoEBAACABIDLwRIGlggT3B0aW9uYWwuIEEgdG9vbHNldCB0aGF0IGNvbnRhaW5zIGEgbGlz
dCBvZiB0b29scyB0aGF0IGFyZSBvZmZlcmVkIGJ5IHRoZQogTUNQIHNlcnZlci4KCgwKBQQA
AgAGEgMvBA4KDAoFBAACAAESAy8PGgoMCgUEAAIAAxIDLx0eCgwKBQQAAgAIEgMvH0cKDwoI
BAACAAicCAASAy8gRgppCgQEAAIBEgQzBDQxGlsgT3B0aW9uYWwuIEEgdG9vbHNldCB0aGF0
IGNvbnRhaW5zIGEgbGlzdCBvZiB0b29scyB0aGF0IGFyZSBkZWZpbmVkIGJ5IGFuCiBPcGVu
QVBJIHNjaGVtYS4KCgwKBQQAAgEGEgMzBBIKDAoFBAACAQESAzMTIwoMCgUEAAIBAxIDMyYn
CgwKBQQAAgEIEgM0CDAKDwoIBAACAQicCAASAzQJLwpkCgQEAAICEgQ4BDkxGlYgT3B0aW9u
YWwuIEEgdG9vbHNldCB0aGF0IGdlbmVyYXRlcyB0b29scyBmcm9tIGFuIEludGVncmF0aW9u
IENvbm5lY3RvcnMKIENvbm5lY3Rpb24uCgoMCgUEAAICBhIDOAQUCgwKBQQAAgIBEgM4FSYK
DAoFBAACAgMSAzgpKgoMCgUEAAICCBIDOQgwCg8KCAQAAgIInAgAEgM5CS8KkwEKBAQAAgMS
Az8CPRqFASBJZGVudGlmaWVyLiBUaGUgdW5pcXVlIGlkZW50aWZpZXIgb2YgdGhlIHRvb2xz
ZXQuCiBGb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259
L2FwcHMve2FwcH0vdG9vbHNldHMve3Rvb2xzZXR9YAoKDAoFBAACAwUSAz8CCAoMCgUEAAID
ARIDPwkNCgwKBQQAAgMDEgM/EBEKDAoFBAACAwgSAz8SPAoPCggEAAIDCJwIABIDPxM7Cl4K
BAQAAgQSA0MCQxpRIE9wdGlvbmFsLiBUaGUgZGlzcGxheSBuYW1lIG9mIHRoZSB0b29sc2V0
LiBNdXN0IGJlIHVuaXF1ZSB3aXRoaW4gdGhlIHNhbWUKIGFwcC4KCgwKBQQAAgQFEgNDAggK
DAoFBAACBAESA0MJFQoMCgUEAAIEAxIDQxgZCgwKBQQAAgQIEgNDGkIKDwoIBAACBAicCAAS
A0MbQQo4CgQEAAIFEgNGAkMaKyBPcHRpb25hbC4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSB0
b29sc2V0LgoKDAoFBAACBQUSA0YCCAoMCgUEAAIFARIDRgkUCgwKBQQAAgUDEgNGFxkKDAoF
BAACBQgSA0YaQgoPCggEAAIFCJwIABIDRhtBCrgBCgQEAAIGEgRLAkwvGqkBIE9wdGlvbmFs
LiBUaGUgdGltZW91dCBmb3IgdGhlIHRvb2xzZXQgZXhlY3V0aW9uLiBJZiBub3Qgc2V0LCB0
aGUgZGVmYXVsdAogdGltZW91dCBpcyAzMCBzZWNvbmRzIGZvciBgU1lOQ0hST05PVVNgIHRv
b2xzZXRzIGFuZCA2MCBzZWNvbmRzIGZvcgogYEFTWU5DSFJPTk9VU2AgdG9vbHNldHMuCgoM
CgUEAAIGBhIDSwIaCgwKBQQAAgYBEgNLGyIKDAoFBAACBgMSA0slJwoMCgUEAAIGCBIDTAYu
Cg8KCAQAAgYInAgAEgNMBy0KRAoEBAACBxIETwJQMho2IE91dHB1dCBvbmx5LiBUaW1lc3Rh
bXAgd2hlbiB0aGUgdG9vbHNldCB3YXMgY3JlYXRlZC4KCgwKBQQAAgcGEgNPAhsKDAoFBAAC
BwESA08cJwoMCgUEAAIHAxIDTyorCgwKBQQAAgcIEgNQBjEKDwoIBAACBwicCAASA1AHMApJ
CgQEAAIIEgRTAlQyGjsgT3V0cHV0IG9ubHkuIFRpbWVzdGFtcCB3aGVuIHRoZSB0b29sc2V0
IHdhcyBsYXN0IHVwZGF0ZWQuCgoMCgUEAAIIBhIDUwIbCgwKBQQAAggBEgNTHCcKDAoFBAAC
CAMSA1MqKwoMCgUEAAIICBIDVAYxCg8KCAQAAggInAgAEgNUBzAKrQEKBAQAAgkSA1kCEhqf
ASBFVGFnIHVzZWQgdG8gZW5zdXJlIHRoZSBvYmplY3QgaGFzbid0IGNoYW5nZWQgZHVyaW5n
IGEgcmVhZC1tb2RpZnktd3JpdGUKIG9wZXJhdGlvbi4gSWYgdGhlIGV0YWcgaXMgZW1wdHks
IHRoZSB1cGRhdGUgd2lsbCBvdmVyd3JpdGUgYW55IGNvbmN1cnJlbnQKIGNoYW5nZXMuCgoM
CgUEAAIJBRIDWQIICgwKBQQAAgkBEgNZCQ0KDAoFBAACCQMSA1kQEQpICgQEAAIKEgNcAkwa
OyBPcHRpb25hbC4gVGhlIGV4ZWN1dGlvbiB0eXBlIG9mIHRoZSB0b29scyBpbiB0aGUgdG9v
bHNldC4KCgwKBQQAAgoGEgNcAg8KDAoFBAACCgESA1wQHgoMCgUEAAIKAxIDXCEiCgwKBQQA
AgoIEgNcI0sKDwoIBAACCgicCAASA1wkSgpHCgQEAAILEgNfAlAaOiBPcHRpb25hbC4gQ29u
ZmlndXJhdGlvbiBmb3IgdG9vbHMgYmVoYXZpb3IgaW4gZmFrZSBtb2RlLgoKDAoFBAACCwYS
A18CEAoMCgUEAAILARIDXxEhCgwKBQQAAgsDEgNfJCYKDAoFBAACCwgSA18nTwoPCggEAAIL
CJwIABIDXyhOYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::Toolset::Toolset ===
    # Fields for Toolset
    # Field: mcp_toolset Type: 11 (.google.cloud.ces.v1.McpToolset)
    # Field: open_api_toolset Type: 11 (.google.cloud.ces.v1.OpenApiToolset)
    # Field: connector_toolset Type: 11 (.google.cloud.ces.v1.ConnectorToolset)
    # Field: name Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: timeout Type: 11 (.google.protobuf.Duration)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: etag Type: 9 ()
    # Field: execution_type Type: 14 (.google.cloud.ces.v1.ExecutionType)
    # Field: tool_fake_config Type: 11 (.google.cloud.ces.v1.ToolFakeConfig)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::Toolset - Compiled Protocol Buffers messages for google/cloud/ces/v1/toolset.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::Toolset;

    my $msg = Google::Cloud::Ces::V1::Toolset::Toolset->new({
        mcp_toolset => $mcp_toolset,
        open_api_toolset => $open_api_toolset,
        connector_toolset => $connector_toolset,
        name => $name,
    });

    # Read or update a field
    my $val = $msg->mcp_toolset();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::Toolset::Toolset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/toolset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::Toolset::Toolset

A toolset represents a group of dynamically managed tools that can be used
by the agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->mcp_toolset() >> / C<< $msg->mcp_toolset($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::McpToolset::McpToolset>)

Optional. A toolset that contains a list of tools that are offered by the
MCP server.

=item * C<< $msg->open_api_toolset() >> / C<< $msg->open_api_toolset($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::OpenApiToolset::OpenApiToolset>)

Optional. A toolset that contains a list of tools that are defined by an
OpenAPI schema.

=item * C<< $msg->connector_toolset() >> / C<< $msg->connector_toolset($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ConnectorToolset::ConnectorToolset>)

Optional. A toolset that generates tools from an Integration Connectors
Connection.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The unique identifier of the toolset.
Format:
`projects/{project}/locations/{location}/apps/{app}/toolsets/{toolset}`

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Optional. The display name of the toolset. Must be unique within the same
app.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the toolset.

=item * C<< $msg->timeout() >> / C<< $msg->timeout($value) >>

Type: C<Message> (L<Google::Protobuf::Duration::Duration>)

Optional. The timeout for the toolset execution. If not set, the default
timeout is 30 seconds for `SYNCHRONOUS` toolsets and 60 seconds for
`ASYNCHRONOUS` toolsets.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the toolset was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp when the toolset was last updated.

=item * C<< $msg->etag() >> / C<< $msg->etag($value) >>

Type: C<String>

ETag used to ensure the object hasn't changed during a read-modify-write
operation. If the etag is empty, the update will overwrite any concurrent
changes.

=item * C<< $msg->execution_type() >> / C<< $msg->execution_type($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::ExecutionType>)

Optional. The execution type of the tools in the toolset.

=item * C<< $msg->tool_fake_config() >> / C<< $msg->tool_fake_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Fakes::ToolFakeConfig>)

Optional. Configuration for tools behavior in fake mode.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::Toolset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
