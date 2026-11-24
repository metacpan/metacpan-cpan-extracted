package Google::Cloud::Ces::V1beta::McpTool;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Ces::V1beta::Auth };
    eval { require Google::Cloud::Ces::V1beta::Common };
    eval { require Google::Cloud::Ces::V1beta::Schema };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9tY3BfdG9vbC5wcm90bxIXZ29vZ2xlLmNsb3Vk
LmNlcy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aImdvb2dsZS9j
bG91ZC9jZXMvdjFiZXRhL2F1dGgucHJvdG8aJGdvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL2Nv
bW1vbi5wcm90bxokZ29vZ2xlL2Nsb3VkL2Nlcy92MWJldGEvc2NoZW1hLnByb3RvIvYGCgdN
Y3BUb29sEhcKBG5hbWUYASABKAlCA+BBAlIEbmFtZRIoCg1uYW1lX292ZXJyaWRlGA0gASgJ
QgPgQQFSDG5hbWVPdmVycmlkZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEBUgtkZXNjcmlw
dGlvbhJHCgxpbnB1dF9zY2hlbWEYAyABKAsyHy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5T
Y2hlbWFCA+BBAVILaW5wdXRTY2hlbWESSQoNb3V0cHV0X3NjaGVtYRgEIAEoCzIfLmdvb2ds
ZS5jbG91ZC5jZXMudjFiZXRhLlNjaGVtYUID4EEBUgxvdXRwdXRTY2hlbWESKgoOc2VydmVy
X2FkZHJlc3MYBSABKAlCA+BBAlINc2VydmVyQWRkcmVzcxJeChJhcGlfYXV0aGVudGljYXRp
b24YBiABKAsyKi5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5BcGlBdXRoZW50aWNhdGlvbkID
4EEBUhFhcGlBdXRoZW50aWNhdGlvbhJGCgp0bHNfY29uZmlnGAcgASgLMiIuZ29vZ2xlLmNs
b3VkLmNlcy52MWJldGEuVGxzQ29uZmlnQgPgQQFSCXRsc0NvbmZpZxJuChhzZXJ2aWNlX2Rp
cmVjdG9yeV9jb25maWcYCCABKAsyLy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5TZXJ2aWNl
RGlyZWN0b3J5Q29uZmlnQgPgQQFSFnNlcnZpY2VEaXJlY3RvcnlDb25maWcSXwoOY3VzdG9t
X2hlYWRlcnMYCSADKAsyMy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5NY3BUb29sLkN1c3Rv
bUhlYWRlcnNFbnRyeUID4EEBUg1jdXN0b21IZWFkZXJzEkEKBXN0YXRlGAwgASgOMiYuZ29v
Z2xlLmNsb3VkLmNlcy52MWJldGEuTWNwVG9vbC5TdGF0ZUID4EEDUgVzdGF0ZRpAChJDdXN0
b21IZWFkZXJzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVl
OgI4ASJDCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgoKBkFDVElWRRABEgwKCElO
QUNUSVZFEAISCQoFU1RBTEUQA0JcChtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCDE1j
cFRvb2xQcm90b1ABWi1jbG91ZC5nb29nbGUuY29tL2dvL2Nlcy9hcGl2MWJldGEvY2VzcGI7
Y2VzcGJK4R4KBhIEDgBlAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAIAoJCgIDABIDEgApCgkKAgMBEgMTACwKCQoCAwISAxQALgoJCgIDAxIDFQAuCggK
AQgSAxcARAoJCgIICxIDFwBECggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkALQoJCgII
CBIDGQAtCggKAQgSAxoANAoJCgIIARIDGgA0CngKAgQAEgQfAGUBGmwgQW4gTUNQIHRvb2wu
CiBTZWUgaHR0cHM6Ly9tb2RlbGNvbnRleHRwcm90b2NvbC5pby9zcGVjaWZpY2F0aW9uLzIw
MjUtMDYtMTgvc2VydmVyL3Rvb2xzIGZvcgogbW9yZSBkZXRhaWxzLgoKCgoDBAABEgMfCA8K
RgoEBAAEABIEIQIvAxo4IFJlcHJlc2VudHMgdGhlIGR5bmFtaWMgYXZhaWxhYmlsaXR5IHN0
YXRlIG9mIHRoZSB0b29sLgoKDAoFBAAEAAESAyEHDAofCgYEAAQAAgASAyMEGhoQIERlZmF1
bHQgc3RhdGUuCgoOCgcEAAQAAgABEgMjBBUKDgoHBAAEAAIAAhIDIxgZCkoKBgQABAACARID
JgQPGjsgVGhlIHRvb2wgaXMgYXZhaWxhYmxlIGFuZCBhY3RpdmVseSBvZmZlcmVkIGJ5IHRo
ZSBzZXJ2ZXIuCgoOCgcEAAQAAgEBEgMmBAoKDgoHBAAEAAIBAhIDJg0OClwKBgQABAACAhID
KgQRGk0gVGhlIHRvb2wgaXMgY29uZmlndXJlZCBvciBwaW5uZWQsIGJ1dCBjdXJyZW50bHkg
bm90IG9mZmVyZWQgYnkgdGhlCiBzZXJ2ZXIuCgoOCgcEAAQAAgIBEgMqBAwKDgoHBAAEAAIC
AhIDKg8QCl4KBgQABAACAxIDLgQOGk8gVGhlIHRvb2wgZXhpc3RzIG9uIHRoZSBzZXJ2ZXIs
IGJ1dCBkb2VzIG5vdCBtYXRjaCB0aGUgdmVyc2lvbiBvbiB0aGUKIHNlcnZlci4KCg4KBwQA
BAACAwESAy4ECQoOCgcEAAQAAgMCEgMuDA0KMgoEBAACABIDMgI7GiUgUmVxdWlyZWQuIFRo
ZSBuYW1lIG9mIHRoZSBNQ1AgdG9vbC4KCgwKBQQAAgAFEgMyAggKDAoFBAACAAESAzIJDQoM
CgUEAAIAAxIDMhARCgwKBQQAAgAIEgMyEjoKDwoIBAACAAicCAASAzITOQqAAQoEBAACARID
NgJFGnMgT3B0aW9uYWwuIFRoZSBuYW1lIG92ZXJyaWRlIG9mIHRoZSBNQ1AgdG9vbC4KIFRo
aXMgaXMgcG9wdWxhdGVkIGlmIHRoZSBuYW1lIHdhcyBvdmVycmlkZGVuIGJ5IGEgVG9vbHNl
dCBvdmVycmlkZS4KCgwKBQQAAgEFEgM2AggKDAoFBAACAQESAzYJFgoMCgUEAAIBAxIDNhkb
CgwKBQQAAgEIEgM2HEQKDwoIBAACAQicCAASAzYdQwo5CgQEAAICEgM5AkIaLCBPcHRpb25h
bC4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBNQ1AgdG9vbC4KCgwKBQQAAgIFEgM5AggKDAoF
BAACAgESAzkJFAoMCgUEAAICAxIDORcYCgwKBQQAAgIIEgM5GUEKDwoIBAACAgicCAASAzka
QApLCgQEAAIDEgM8AkMaPiBPcHRpb25hbC4gVGhlIHNjaGVtYSBvZiB0aGUgaW5wdXQgYXJn
dW1lbnRzIG9mIHRoZSBNQ1AgdG9vbC4KCgwKBQQAAgMGEgM8AggKDAoFBAACAwESAzwJFQoM
CgUEAAIDAxIDPBgZCgwKBQQAAgMIEgM8GkIKDwoIBAACAwicCAASAzwbQQpMCgQEAAIEEgM/
AkQaPyBPcHRpb25hbC4gVGhlIHNjaGVtYSBvZiB0aGUgb3V0cHV0IGFyZ3VtZW50cyBvZiB0
aGUgTUNQIHRvb2wuCgoMCgUEAAIEBhIDPwIICgwKBQQAAgQBEgM/CRYKDAoFBAACBAMSAz8Z
GgoMCgUEAAIECBIDPxtDCg8KCAQAAgQInAgAEgM/HEIKnwMKBAQAAgUSA0gCRRqRAyBSZXF1
aXJlZC4gVGhlIHNlcnZlciBhZGRyZXNzIG9mIHRoZSBNQ1Agc2VydmVyLCBlLmcuLAogImh0
dHBzOi8vZXhhbXBsZS5jb20vbWNwLyIuIElmIHRoZSBzZXJ2ZXIgaXMgYnVpbHQgd2l0aCB0
aGUgTUNQIFNESywgdGhlCiB1cmwgc2hvdWxkIGJlIHN1ZmZpeGVkIHdpdGgKICIvbWNwLyIu
IE9ubHkgU3RyZWFtYWJsZSBIVFRQIHRyYW5zcG9ydCBiYXNlZCBzZXJ2ZXJzIGFyZSBzdXBw
b3J0ZWQuIFRoaXMKIGlzIHRoZSBzYW1lIGFzIHRoZSBzZXJ2ZXJfYWRkcmVzcyBpbiB0aGUg
TWNwVG9vbHNldC4gU2VlCiBodHRwczovL21vZGVsY29udGV4dHByb3RvY29sLmlvL3NwZWNp
ZmljYXRpb24vMjAyNS0wMy0yNi9iYXNpYy90cmFuc3BvcnRzI3N0cmVhbWFibGUtaHR0cAog
Zm9yIG1vcmUgZGV0YWlscy4KCgwKBQQAAgUFEgNIAggKDAoFBAACBQESA0gJFwoMCgUEAAIF
AxIDSBobCgwKBQQAAgUIEgNIHEQKDwoIBAACBQicCAASA0gdQwqNAgoEBAACBhIETgJPLxr+
ASBPcHRpb25hbC4gQXV0aGVudGljYXRpb24gaW5mb3JtYXRpb24gcmVxdWlyZWQgdG8gZXhl
Y3V0ZSB0aGUgdG9vbCBhZ2FpbnN0CiB0aGUgTUNQIHNlcnZlci4gRm9yIGJlYXJlciB0b2tl
biBhdXRoZW50aWNhdGlvbiwgdGhlIHRva2VuIGFwcGxpZXMgb25seSB0bwogdG9vbCBleGVj
dXRpb24sIG5vdCB0byBsaXN0aW5nIHRvb2xzLiBUaGlzIHJlcXVpcmVzIHRoYXQgdG9vbHMg
Y2FuIGJlCiBsaXN0ZWQgd2l0aG91dCBhdXRoZW50aWNhdGlvbi4KCgwKBQQAAgYGEgNOAhMK
DAoFBAACBgESA04UJgoMCgUEAAIGAxIDTikqCgwKBQQAAgYIEgNPBi4KDwoIBAACBgicCAAS
A08HLQp2CgQEAAIHEgNTAkQaaSBPcHRpb25hbC4gVGhlIFRMUyBjb25maWd1cmF0aW9uLiBJ
bmNsdWRlcyB0aGUgY3VzdG9tIHNlcnZlciBjZXJ0aWZpY2F0ZXMKIHRoYXQgdGhlIGNsaWVu
dCBzaG91bGQgdHJ1c3QuCgoMCgUEAAIHBhIDUwILCgwKBQQAAgcBEgNTDBYKDAoFBAACBwMS
A1MZGgoMCgUEAAIHCBIDUxtDCg8KCAQAAgcInAgAEgNTHEIKeAoEBAACCBIEVwJYLxpqIE9w
dGlvbmFsLiBTZXJ2aWNlIERpcmVjdG9yeSBjb25maWd1cmF0aW9uIGZvciBWUEMtU0MsIHVz
ZWQgdG8gcmVzb2x2ZQogc2VydmljZSBuYW1lcyB3aXRoaW4gYSBwZXJpbWV0ZXIuCgoMCgUE
AAIIBhIDVwIYCgwKBQQAAggBEgNXGTEKDAoFBAACCAMSA1c0NQoMCgUEAAIICBIDWAYuCg8K
CAQAAggInAgAEgNYBy0K0QIKBAQAAgkSBF8CYC8awgIgT3B0aW9uYWwuIFRoZSBjdXN0b20g
aGVhZGVycyB0byBzZW5kIGluIHRoZSByZXF1ZXN0IHRvIHRoZSBNQ1Agc2VydmVyLiBUaGUK
IHZhbHVlcyBtdXN0IGJlIGluIHRoZSBmb3JtYXQgYCRjb250ZXh0LnZhcmlhYmxlcy48bmFt
ZV9vZl92YXJpYWJsZT5gIGFuZAogY2FuIGJlIHNldCBpbiB0aGUgc2Vzc2lvbiB2YXJpYWJs
ZXMuIFNlZQogaHR0cHM6Ly9kb2NzLmNsb3VkLmdvb2dsZS5jb20vY3VzdG9tZXItZW5nYWdl
bWVudC1haS9jb252ZXJzYXRpb25hbC1hZ2VudHMvcHMvdG9vbC9vcGVuLWFwaSNvcGVuYXBp
LWluamVjdGlvbgogZm9yIG1vcmUgZGV0YWlscy4KCgwKBQQAAgkGEgNfAhUKDAoFBAACCQES
A18WJAoMCgUEAAIJAxIDXycoCgwKBQQAAgkIEgNgBi4KDwoIBAACCQicCAASA2AHLQpfCgQE
AAIKEgNkAj8aUiBPdXRwdXQgb25seS4gVGhlIGR5bmFtaWMgYXZhaWxhYmlsaXR5IHN0YXRl
IG9mIHRoZSB0b29sIG9uIHRoZSBleHRlcm5hbAogc2VydmVyLgoKDAoFBAACCgYSA2QCBwoM
CgUEAAIKARIDZAgNCgwKBQQAAgoDEgNkEBIKDAoFBAACCggSA2QTPgoPCggEAAIKCJwIABID
ZBQ9YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::McpTool::McpTool ===
    # Fields for McpTool
    # Field: name Type: 9 ()
    # Field: name_override Type: 9 ()
    # Field: description Type: 9 ()
    # Field: input_schema Type: 11 (.google.cloud.ces.v1beta.Schema)
    # Field: output_schema Type: 11 (.google.cloud.ces.v1beta.Schema)
    # Field: server_address Type: 9 ()
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1beta.ApiAuthentication)
    # Field: tls_config Type: 11 (.google.cloud.ces.v1beta.TlsConfig)
    # Field: service_directory_config Type: 11 (.google.cloud.ces.v1beta.ServiceDirectoryConfig)
    # Field: custom_headers Type: 11 (.google.cloud.ces.v1beta.McpTool.CustomHeadersEntry)
    # Field: state Type: 14 (.google.cloud.ces.v1beta.McpTool.State)

# Enum: McpTool::State
our $McpTool_STATE_UNSPECIFIED = 0;
our $McpTool_ACTIVE = 1;
our $McpTool_INACTIVE = 2;
our $McpTool_STALE = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::McpTool - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/mcp_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::McpTool;

    my $msg = Google::Cloud::Ces::V1beta::McpTool::McpTool->new({
        name => $name,
        name_override => $name_override,
        description => $description,
        input_schema => $input_schema,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::McpTool::McpTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/mcp_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::McpTool::McpTool

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

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

Optional. The schema of the input arguments of the MCP tool.

=item * C<< $msg->output_schema() >> / C<< $msg->output_schema($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

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

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::ApiAuthentication>)

Optional. Authentication information required to execute the tool against
the MCP server. For bearer token authentication, the token applies only to
tool execution, not to listing tools. This requires that tools can be
listed without authentication.

=item * C<< $msg->tls_config() >> / C<< $msg->tls_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::TlsConfig>)

Optional. The TLS configuration. Includes the custom server certificates
that the client should trust.

=item * C<< $msg->service_directory_config() >> / C<< $msg->service_directory_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::ServiceDirectoryConfig>)

Optional. Service Directory configuration for VPC-SC, used to resolve
service names within a perimeter.

=item * C<< $msg->custom_headers() >> / C<< $msg->custom_headers($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::McpTool::McpTool::CustomHeadersEntry>)

Optional. The custom headers to send in the request to the MCP server. The
values must be in the format `$context.variables.<name_of_variable>` and
can be set in the session variables. See
https://docs.cloud.google.com/customer-engagement-ai/conversational-agents/ps/tool/open-api#openapi-injection
for more details.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Ces::V1beta::McpTool::State>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::McpTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
