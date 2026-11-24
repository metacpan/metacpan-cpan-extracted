package Google::Cloud::Ces::V1::McpTool;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Ces::V1::Auth };
    eval { require Google::Cloud::Ces::V1::Common };
    eval { require Google::Cloud::Ces::V1::Schema };
    my $descriptor_b64 = <<'EOF';
CiJnb29nbGUvY2xvdWQvY2VzL3YxL21jcF90b29sLnByb3RvEhNnb29nbGUuY2xvdWQuY2Vz
LnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh5nb29nbGUvY2xvdWQvY2Vz
L3YxL2F1dGgucHJvdG8aIGdvb2dsZS9jbG91ZC9jZXMvdjEvY29tbW9uLnByb3RvGiBnb29n
bGUvY2xvdWQvY2VzL3YxL3NjaGVtYS5wcm90byLaBgoHTWNwVG9vbBIXCgRuYW1lGAEgASgJ
QgPgQQJSBG5hbWUSKAoNbmFtZV9vdmVycmlkZRgNIAEoCUID4EEBUgxuYW1lT3ZlcnJpZGUS
JQoLZGVzY3JpcHRpb24YAiABKAlCA+BBAVILZGVzY3JpcHRpb24SQwoMaW5wdXRfc2NoZW1h
GAMgASgLMhsuZ29vZ2xlLmNsb3VkLmNlcy52MS5TY2hlbWFCA+BBAVILaW5wdXRTY2hlbWES
RQoNb3V0cHV0X3NjaGVtYRgEIAEoCzIbLmdvb2dsZS5jbG91ZC5jZXMudjEuU2NoZW1hQgPg
QQFSDG91dHB1dFNjaGVtYRIqCg5zZXJ2ZXJfYWRkcmVzcxgFIAEoCUID4EECUg1zZXJ2ZXJB
ZGRyZXNzEloKEmFwaV9hdXRoZW50aWNhdGlvbhgGIAEoCzImLmdvb2dsZS5jbG91ZC5jZXMu
djEuQXBpQXV0aGVudGljYXRpb25CA+BBAVIRYXBpQXV0aGVudGljYXRpb24SQgoKdGxzX2Nv
bmZpZxgHIAEoCzIeLmdvb2dsZS5jbG91ZC5jZXMudjEuVGxzQ29uZmlnQgPgQQFSCXRsc0Nv
bmZpZxJqChhzZXJ2aWNlX2RpcmVjdG9yeV9jb25maWcYCCABKAsyKy5nb29nbGUuY2xvdWQu
Y2VzLnYxLlNlcnZpY2VEaXJlY3RvcnlDb25maWdCA+BBAVIWc2VydmljZURpcmVjdG9yeUNv
bmZpZxJbCg5jdXN0b21faGVhZGVycxgJIAMoCzIvLmdvb2dsZS5jbG91ZC5jZXMudjEuTWNw
VG9vbC5DdXN0b21IZWFkZXJzRW50cnlCA+BBAVINY3VzdG9tSGVhZGVycxI9CgVzdGF0ZRgM
IAEoDjIiLmdvb2dsZS5jbG91ZC5jZXMudjEuTWNwVG9vbC5TdGF0ZUID4EEDUgVzdGF0ZRpA
ChJDdXN0b21IZWFkZXJzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlS
BXZhbHVlOgI4ASJDCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgoKBkFDVElWRRAB
EgwKCElOQUNUSVZFEAISCQoFU1RBTEUQA0JUChdjb20uZ29vZ2xlLmNsb3VkLmNlcy52MUIM
TWNwVG9vbFByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nl
c3BiSuEeCgYSBA4AZQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
CgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhl
ICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21w
bGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhl
IExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VO
U0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0
byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2Ug
aXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElF
UyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVk
LgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5n
IHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgEC
EgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAoCgkKAgMCEgMUACoKCQoCAwMSAxUAKgoICgEI
EgMXAEAKCQoCCAsSAxcAQAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC0KCQoCCAgS
AxkALQoICgEIEgMaADAKCQoCCAESAxoAMAp4CgIEABIEHwBlARpsIEFuIE1DUCB0b29sLgog
U2VlIGh0dHBzOi8vbW9kZWxjb250ZXh0cHJvdG9jb2wuaW8vc3BlY2lmaWNhdGlvbi8yMDI1
LTA2LTE4L3NlcnZlci90b29scyBmb3IKIG1vcmUgZGV0YWlscy4KCgoKAwQAARIDHwgPCkYK
BAQABAASBCECLwMaOCBSZXByZXNlbnRzIHRoZSBkeW5hbWljIGF2YWlsYWJpbGl0eSBzdGF0
ZSBvZiB0aGUgdG9vbC4KCgwKBQQABAABEgMhBwwKHwoGBAAEAAIAEgMjBBoaECBEZWZhdWx0
IHN0YXRlLgoKDgoHBAAEAAIAARIDIwQVCg4KBwQABAACAAISAyMYGQpKCgYEAAQAAgESAyYE
Dxo7IFRoZSB0b29sIGlzIGF2YWlsYWJsZSBhbmQgYWN0aXZlbHkgb2ZmZXJlZCBieSB0aGUg
c2VydmVyLgoKDgoHBAAEAAIBARIDJgQKCg4KBwQABAACAQISAyYNDgpcCgYEAAQAAgISAyoE
ERpNIFRoZSB0b29sIGlzIGNvbmZpZ3VyZWQgb3IgcGlubmVkLCBidXQgY3VycmVudGx5IG5v
dCBvZmZlcmVkIGJ5IHRoZQogc2VydmVyLgoKDgoHBAAEAAICARIDKgQMCg4KBwQABAACAgIS
AyoPEApeCgYEAAQAAgMSAy4EDhpPIFRoZSB0b29sIGV4aXN0cyBvbiB0aGUgc2VydmVyLCBi
dXQgZG9lcyBub3QgbWF0Y2ggdGhlIHZlcnNpb24gb24gdGhlCiBzZXJ2ZXIuCgoOCgcEAAQA
AgMBEgMuBAkKDgoHBAAEAAIDAhIDLgwNCjIKBAQAAgASAzICOxolIFJlcXVpcmVkLiBUaGUg
bmFtZSBvZiB0aGUgTUNQIHRvb2wuCgoMCgUEAAIABRIDMgIICgwKBQQAAgABEgMyCQ0KDAoF
BAACAAMSAzIQEQoMCgUEAAIACBIDMhI6Cg8KCAQAAgAInAgAEgMyEzkKgAEKBAQAAgESAzYC
RRpzIE9wdGlvbmFsLiBUaGUgbmFtZSBvdmVycmlkZSBvZiB0aGUgTUNQIHRvb2wuCiBUaGlz
IGlzIHBvcHVsYXRlZCBpZiB0aGUgbmFtZSB3YXMgb3ZlcnJpZGRlbiBieSBhIFRvb2xzZXQg
b3ZlcnJpZGUuCgoMCgUEAAIBBRIDNgIICgwKBQQAAgEBEgM2CRYKDAoFBAACAQMSAzYZGwoM
CgUEAAIBCBIDNhxECg8KCAQAAgEInAgAEgM2HUMKOQoEBAACAhIDOQJCGiwgT3B0aW9uYWwu
IFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgTUNQIHRvb2wuCgoMCgUEAAICBRIDOQIICgwKBQQA
AgIBEgM5CRQKDAoFBAACAgMSAzkXGAoMCgUEAAICCBIDORlBCg8KCAQAAgIInAgAEgM5GkAK
SwoEBAACAxIDPAJDGj4gT3B0aW9uYWwuIFRoZSBzY2hlbWEgb2YgdGhlIGlucHV0IGFyZ3Vt
ZW50cyBvZiB0aGUgTUNQIHRvb2wuCgoMCgUEAAIDBhIDPAIICgwKBQQAAgMBEgM8CRUKDAoF
BAACAwMSAzwYGQoMCgUEAAIDCBIDPBpCCg8KCAQAAgMInAgAEgM8G0EKTAoEBAACBBIDPwJE
Gj8gT3B0aW9uYWwuIFRoZSBzY2hlbWEgb2YgdGhlIG91dHB1dCBhcmd1bWVudHMgb2YgdGhl
IE1DUCB0b29sLgoKDAoFBAACBAYSAz8CCAoMCgUEAAIEARIDPwkWCgwKBQQAAgQDEgM/GRoK
DAoFBAACBAgSAz8bQwoPCggEAAIECJwIABIDPxxCCp8DCgQEAAIFEgNIAkUakQMgUmVxdWly
ZWQuIFRoZSBzZXJ2ZXIgYWRkcmVzcyBvZiB0aGUgTUNQIHNlcnZlciwgZS5nLiwKICJodHRw
czovL2V4YW1wbGUuY29tL21jcC8iLiBJZiB0aGUgc2VydmVyIGlzIGJ1aWx0IHdpdGggdGhl
IE1DUCBTREssIHRoZQogdXJsIHNob3VsZCBiZSBzdWZmaXhlZCB3aXRoCiAiL21jcC8iLiBP
bmx5IFN0cmVhbWFibGUgSFRUUCB0cmFuc3BvcnQgYmFzZWQgc2VydmVycyBhcmUgc3VwcG9y
dGVkLiBUaGlzCiBpcyB0aGUgc2FtZSBhcyB0aGUgc2VydmVyX2FkZHJlc3MgaW4gdGhlIE1j
cFRvb2xzZXQuIFNlZQogaHR0cHM6Ly9tb2RlbGNvbnRleHRwcm90b2NvbC5pby9zcGVjaWZp
Y2F0aW9uLzIwMjUtMDMtMjYvYmFzaWMvdHJhbnNwb3J0cyNzdHJlYW1hYmxlLWh0dHAKIGZv
ciBtb3JlIGRldGFpbHMuCgoMCgUEAAIFBRIDSAIICgwKBQQAAgUBEgNICRcKDAoFBAACBQMS
A0gaGwoMCgUEAAIFCBIDSBxECg8KCAQAAgUInAgAEgNIHUMKjQIKBAQAAgYSBE4CTy8a/gEg
T3B0aW9uYWwuIEF1dGhlbnRpY2F0aW9uIGluZm9ybWF0aW9uIHJlcXVpcmVkIHRvIGV4ZWN1
dGUgdGhlIHRvb2wgYWdhaW5zdAogdGhlIE1DUCBzZXJ2ZXIuIEZvciBiZWFyZXIgdG9rZW4g
YXV0aGVudGljYXRpb24sIHRoZSB0b2tlbiBhcHBsaWVzIG9ubHkgdG8KIHRvb2wgZXhlY3V0
aW9uLCBub3QgdG8gbGlzdGluZyB0b29scy4gVGhpcyByZXF1aXJlcyB0aGF0IHRvb2xzIGNh
biBiZQogbGlzdGVkIHdpdGhvdXQgYXV0aGVudGljYXRpb24uCgoMCgUEAAIGBhIDTgITCgwK
BQQAAgYBEgNOFCYKDAoFBAACBgMSA04pKgoMCgUEAAIGCBIDTwYuCg8KCAQAAgYInAgAEgNP
By0KdgoEBAACBxIDUwJEGmkgT3B0aW9uYWwuIFRoZSBUTFMgY29uZmlndXJhdGlvbi4gSW5j
bHVkZXMgdGhlIGN1c3RvbSBzZXJ2ZXIgY2VydGlmaWNhdGVzCiB0aGF0IHRoZSBjbGllbnQg
c2hvdWxkIHRydXN0LgoKDAoFBAACBwYSA1MCCwoMCgUEAAIHARIDUwwWCgwKBQQAAgcDEgNT
GRoKDAoFBAACBwgSA1MbQwoPCggEAAIHCJwIABIDUxxCCngKBAQAAggSBFcCWC8aaiBPcHRp
b25hbC4gU2VydmljZSBEaXJlY3RvcnkgY29uZmlndXJhdGlvbiBmb3IgVlBDLVNDLCB1c2Vk
IHRvIHJlc29sdmUKIHNlcnZpY2UgbmFtZXMgd2l0aGluIGEgcGVyaW1ldGVyLgoKDAoFBAAC
CAYSA1cCGAoMCgUEAAIIARIDVxkxCgwKBQQAAggDEgNXNDUKDAoFBAACCAgSA1gGLgoPCggE
AAIICJwIABIDWActCtECCgQEAAIJEgRfAmAvGsICIE9wdGlvbmFsLiBUaGUgY3VzdG9tIGhl
YWRlcnMgdG8gc2VuZCBpbiB0aGUgcmVxdWVzdCB0byB0aGUgTUNQIHNlcnZlci4gVGhlCiB2
YWx1ZXMgbXVzdCBiZSBpbiB0aGUgZm9ybWF0IGAkY29udGV4dC52YXJpYWJsZXMuPG5hbWVf
b2ZfdmFyaWFibGU+YCBhbmQKIGNhbiBiZSBzZXQgaW4gdGhlIHNlc3Npb24gdmFyaWFibGVz
LiBTZWUKIGh0dHBzOi8vZG9jcy5jbG91ZC5nb29nbGUuY29tL2N1c3RvbWVyLWVuZ2FnZW1l
bnQtYWkvY29udmVyc2F0aW9uYWwtYWdlbnRzL3BzL3Rvb2wvb3Blbi1hcGkjb3BlbmFwaS1p
bmplY3Rpb24KIGZvciBtb3JlIGRldGFpbHMuCgoMCgUEAAIJBhIDXwIVCgwKBQQAAgkBEgNf
FiQKDAoFBAACCQMSA18nKAoMCgUEAAIJCBIDYAYuCg8KCAQAAgkInAgAEgNgBy0KXwoEBAAC
ChIDZAI/GlIgT3V0cHV0IG9ubHkuIFRoZSBkeW5hbWljIGF2YWlsYWJpbGl0eSBzdGF0ZSBv
ZiB0aGUgdG9vbCBvbiB0aGUgZXh0ZXJuYWwKIHNlcnZlci4KCgwKBQQAAgoGEgNkAgcKDAoF
BAACCgESA2QIDQoMCgUEAAIKAxIDZBASCgwKBQQAAgoIEgNkEz4KDwoIBAACCgicCAASA2QU
PWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::McpTool::McpTool ===
    # Fields for McpTool
    # Field: name Type: 9 ()
    # Field: name_override Type: 9 ()
    # Field: description Type: 9 ()
    # Field: input_schema Type: 11 (.google.cloud.ces.v1.Schema)
    # Field: output_schema Type: 11 (.google.cloud.ces.v1.Schema)
    # Field: server_address Type: 9 ()
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1.ApiAuthentication)
    # Field: tls_config Type: 11 (.google.cloud.ces.v1.TlsConfig)
    # Field: service_directory_config Type: 11 (.google.cloud.ces.v1.ServiceDirectoryConfig)
    # Field: custom_headers Type: 11 (.google.cloud.ces.v1.McpTool.CustomHeadersEntry)
    # Field: state Type: 14 (.google.cloud.ces.v1.McpTool.State)

# Enum: McpTool::State
our $McpTool_STATE_UNSPECIFIED = 0;
our $McpTool_ACTIVE = 1;
our $McpTool_INACTIVE = 2;
our $McpTool_STALE = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::McpTool - Compiled Protocol Buffers messages for google/cloud/ces/v1/mcp_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::McpTool;

    my $msg = Google::Cloud::Ces::V1::McpTool::McpTool->new({
        name => $name,
        name_override => $name_override,
        description => $description,
        input_schema => $input_schema,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::McpTool::McpTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/mcp_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::McpTool::McpTool

An MCP tool.
See https://modelcontextprotocol.io/specification/2025-06-18/server/tools for
more details.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the MCP tool.

=item * C<< $msg->name_override() >> / C<< $msg->name_override($value) >>

Type: C<String>

Optional. The name override of the MCP tool.
This is populated if the name was overridden by a Toolset override.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the MCP tool.

=item * C<< $msg->input_schema() >> / C<< $msg->input_schema($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

Optional. The schema of the input arguments of the MCP tool.

=item * C<< $msg->output_schema() >> / C<< $msg->output_schema($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

Optional. The schema of the output arguments of the MCP tool.

=item * C<< $msg->server_address() >> / C<< $msg->server_address($value) >>

Type: C<String>

Required. The server address of the MCP server, e.g.,
"https://example.com/mcp/". If the server is built with the MCP SDK, the
url should be suffixed with
"/mcp/". Only Streamable HTTP transport based servers are supported. This
is the same as the server_address in the McpToolset. See
https://modelcontextprotocol.io/specification/2025-03-26/basic/transports#streamable-http
for more details.

=item * C<< $msg->api_authentication() >> / C<< $msg->api_authentication($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::ApiAuthentication>)

Optional. Authentication information required to execute the tool against
the MCP server. For bearer token authentication, the token applies only to
tool execution, not to listing tools. This requires that tools can be
listed without authentication.

=item * C<< $msg->tls_config() >> / C<< $msg->tls_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::TlsConfig>)

Optional. The TLS configuration. Includes the custom server certificates
that the client should trust.

=item * C<< $msg->service_directory_config() >> / C<< $msg->service_directory_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ServiceDirectoryConfig>)

Optional. Service Directory configuration for VPC-SC, used to resolve
service names within a perimeter.

=item * C<< $msg->custom_headers() >> / C<< $msg->custom_headers($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::McpTool::McpTool::CustomHeadersEntry>)

Optional. The custom headers to send in the request to the MCP server. The
values must be in the format `$context.variables.<name_of_variable>` and
can be set in the session variables. See
https://docs.cloud.google.com/customer-engagement-ai/conversational-agents/ps/tool/open-api#openapi-injection
for more details.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1::McpTool::State>)

Output only. The dynamic availability state of the tool on the external
server.

=back

=head3 Enum: McpTool::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<ACTIVE> => C<1>

=item * C<INACTIVE> => C<2>

=item * C<STALE> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::McpTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
