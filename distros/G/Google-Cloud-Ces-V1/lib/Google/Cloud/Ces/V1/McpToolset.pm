package Google::Cloud::Ces::V1::McpToolset;

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
CiVnb29nbGUvY2xvdWQvY2VzL3YxL21jcF90b29sc2V0LnByb3RvEhNnb29nbGUuY2xvdWQu
Y2VzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh5nb29nbGUvY2xvdWQv
Y2VzL3YxL2F1dGgucHJvdG8aIGdvb2dsZS9jbG91ZC9jZXMvdjEvY29tbW9uLnByb3RvGiBn
b29nbGUvY2xvdWQvY2VzL3YxL3NjaGVtYS5wcm90byK4BAoKTWNwVG9vbHNldBIqCg5zZXJ2
ZXJfYWRkcmVzcxgBIAEoCUID4EECUg1zZXJ2ZXJBZGRyZXNzEloKEmFwaV9hdXRoZW50aWNh
dGlvbhgCIAEoCzImLmdvb2dsZS5jbG91ZC5jZXMudjEuQXBpQXV0aGVudGljYXRpb25CA+BB
AVIRYXBpQXV0aGVudGljYXRpb24SagoYc2VydmljZV9kaXJlY3RvcnlfY29uZmlnGAMgASgL
MisuZ29vZ2xlLmNsb3VkLmNlcy52MS5TZXJ2aWNlRGlyZWN0b3J5Q29uZmlnQgPgQQFSFnNl
cnZpY2VEaXJlY3RvcnlDb25maWcSQgoKdGxzX2NvbmZpZxgEIAEoCzIeLmdvb2dsZS5jbG91
ZC5jZXMudjEuVGxzQ29uZmlnQgPgQQFSCXRsc0NvbmZpZxJeCg5jdXN0b21faGVhZGVycxgF
IAMoCzIyLmdvb2dsZS5jbG91ZC5jZXMudjEuTWNwVG9vbHNldC5DdXN0b21IZWFkZXJzRW50
cnlCA+BBAVINY3VzdG9tSGVhZGVycxJQCg50b29sX292ZXJyaWRlcxgGIAMoCzIkLmdvb2ds
ZS5jbG91ZC5jZXMudjEuTWNwVG9vbE92ZXJyaWRlQgPgQQFSDXRvb2xPdmVycmlkZXMaQAoS
Q3VzdG9tSGVhZGVyc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2
YWx1ZToCOAEi1QEKD01jcFRvb2xPdmVycmlkZRIXCgR0b29sGAEgASgJQgPgQQJSBHRvb2wS
KAoNbmFtZV9vdmVycmlkZRgCIAEoCUID4EEBUgxuYW1lT3ZlcnJpZGUSNgoUZGVzY3JpcHRp
b25fb3ZlcnJpZGUYAyABKAlCA+BBAVITZGVzY3JpcHRpb25PdmVycmlkZRJHCghzbmFwc2hv
dBgEIAEoCzImLmdvb2dsZS5jbG91ZC5jZXMudjEuTWNwVG9vbERlZmluaXRpb25CA+BBA1II
c25hcHNob3QixgEKEU1jcFRvb2xEZWZpbml0aW9uEiUKC2Rlc2NyaXB0aW9uGAEgASgJQgPg
QQNSC2Rlc2NyaXB0aW9uEkMKDGlucHV0X3NjaGVtYRgCIAEoCzIbLmdvb2dsZS5jbG91ZC5j
ZXMudjEuU2NoZW1hQgPgQQNSC2lucHV0U2NoZW1hEkUKDW91dHB1dF9zY2hlbWEYAyABKAsy
Gy5nb29nbGUuY2xvdWQuY2VzLnYxLlNjaGVtYUID4EEDUgxvdXRwdXRTY2hlbWFCVwoXY29t
Lmdvb2dsZS5jbG91ZC5jZXMudjFCD01jcFRvb2xzZXRQcm90b1ABWiljbG91ZC5nb29nbGUu
Y29tL2dvL2Nlcy9hcGl2MS9jZXNwYjtjZXNwYkriIgoGEgQOAGgBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSACkKCQoCAwESAxMAKAoJ
CgIDAhIDFAAqCgkKAgMDEgMVACoKCAoBCBIDFwBACgkKAggLEgMXAEAKCAoBCBIDGAAiCgkK
AggKEgMYACIKCAoBCBIDGQAwCgkKAggIEgMZADAKCAoBCBIDGgAwCgkKAggBEgMaADAKWgoC
BAASBB4ARAEaTiBBIHRvb2xzZXQgdGhhdCBjb250YWlucyBhIGxpc3Qgb2YgdG9vbHMgdGhh
dCBhcmUgb2ZmZXJlZCBieSB0aGUgTUNQCiBzZXJ2ZXIuCgoKCgMEAAESAx4IEgrkAgoEBAAC
ABIDJQJFGtYCIFJlcXVpcmVkLiBUaGUgYWRkcmVzcyBvZiB0aGUgTUNQIHNlcnZlciwgZm9y
IGV4YW1wbGUsCiAiaHR0cHM6Ly9leGFtcGxlLmNvbS9tY3AvIi4gSWYgdGhlIHNlcnZlciBp
cyBidWlsdCB3aXRoIHRoZSBNQ1AgU0RLLCB0aGUKIHVybCBzaG91bGQgYmUgc3VmZml4ZWQg
d2l0aAogIi9tY3AvIi4gT25seSBTdHJlYW1hYmxlIEhUVFAgdHJhbnNwb3J0IGJhc2VkIHNl
cnZlcnMgYXJlIHN1cHBvcnRlZC4gU2VlCiBodHRwczovL21vZGVsY29udGV4dHByb3RvY29s
LmlvL3NwZWNpZmljYXRpb24vMjAyNS0wMy0yNi9iYXNpYy90cmFuc3BvcnRzI3N0cmVhbWFi
bGUtaHR0cAogZm9yIG1vcmUgZGV0YWlscy4KCgwKBQQAAgAFEgMlAggKDAoFBAACAAESAyUJ
FwoMCgUEAAIAAxIDJRobCgwKBQQAAgAIEgMlHEQKDwoIBAACAAicCAASAyUdQwqcAgoEBAAC
ARIEKwIsLxqNAiBPcHRpb25hbC4gQXV0aGVudGljYXRpb24gaW5mb3JtYXRpb24gcmVxdWly
ZWQgdG8gYWNjZXNzIHRvb2xzIGFuZCBleGVjdXRlIGEKIHRvb2wgYWdhaW5zdCB0aGUgTUNQ
IHNlcnZlci4gRm9yIGJlYXJlciB0b2tlbiBhdXRoZW50aWNhdGlvbiwgdGhlIHRva2VuCiBh
cHBsaWVzIG9ubHkgdG8gdG9vbCBleGVjdXRpb24sIG5vdCB0byBsaXN0aW5nIHRvb2xzLiBU
aGlzIHJlcXVpcmVzIHRoYXQKIHRvb2xzIGNhbiBiZSBsaXN0ZWQgd2l0aG91dCBhdXRoZW50
aWNhdGlvbi4KCgwKBQQAAgEGEgMrAhMKDAoFBAACAQESAysUJgoMCgUEAAIBAxIDKykqCgwK
BQQAAgEIEgMsBi4KDwoIBAACAQicCAASAywHLQp4CgQEAAICEgQwAjEvGmogT3B0aW9uYWwu
IFNlcnZpY2UgRGlyZWN0b3J5IGNvbmZpZ3VyYXRpb24gZm9yIFZQQy1TQywgdXNlZCB0byBy
ZXNvbHZlCiBzZXJ2aWNlIG5hbWVzIHdpdGhpbiBhIHBlcmltZXRlci4KCgwKBQQAAgIGEgMw
AhgKDAoFBAACAgESAzAZMQoMCgUEAAICAxIDMDQ1CgwKBQQAAgIIEgMxBi4KDwoIBAACAgic
CAASAzEHLQp2CgQEAAIDEgM1AkQaaSBPcHRpb25hbC4gVGhlIFRMUyBjb25maWd1cmF0aW9u
LiBJbmNsdWRlcyB0aGUgY3VzdG9tIHNlcnZlciBjZXJ0aWZpY2F0ZXMKIHRoYXQgdGhlIGNs
aWVudCBzaG91bGQgdHJ1c3QuCgoMCgUEAAIDBhIDNQILCgwKBQQAAgMBEgM1DBYKDAoFBAAC
AwMSAzUZGgoMCgUEAAIDCBIDNRtDCg8KCAQAAgMInAgAEgM1HEIK0QIKBAQAAgQSBDwCPS8a
wgIgT3B0aW9uYWwuIFRoZSBjdXN0b20gaGVhZGVycyB0byBzZW5kIGluIHRoZSByZXF1ZXN0
IHRvIHRoZSBNQ1Agc2VydmVyLiBUaGUKIHZhbHVlcyBtdXN0IGJlIGluIHRoZSBmb3JtYXQg
YCRjb250ZXh0LnZhcmlhYmxlcy48bmFtZV9vZl92YXJpYWJsZT5gIGFuZAogY2FuIGJlIHNl
dCBpbiB0aGUgc2Vzc2lvbiB2YXJpYWJsZXMuIFNlZQogaHR0cHM6Ly9kb2NzLmNsb3VkLmdv
b2dsZS5jb20vY3VzdG9tZXItZW5nYWdlbWVudC1haS9jb252ZXJzYXRpb25hbC1hZ2VudHMv
cHMvdG9vbC9vcGVuLWFwaSNvcGVuYXBpLWluamVjdGlvbgogZm9yIG1vcmUgZGV0YWlscy4K
CgwKBQQAAgQGEgM8AhUKDAoFBAACBAESAzwWJAoMCgUEAAIEAxIDPCcoCgwKBQQAAgQIEgM9
Bi4KDwoIBAACBAicCAASAz0HLQrNAQoEBAACBRIEQgJDLxq+ASBPcHRpb25hbC4gT3ZlcnJp
ZGVzIGZvciBpbmRpdmlkdWFsIHRvb2xzIHdpdGhpbiB0aGlzIHRvb2xzZXQuCiBUaGlzIGFs
bG93cyBvdmVycmlkaW5nIHNwZWNpZmljIGRldGFpbHMgbGlrZSBkZXNjcmlwdGlvbnMsIG5h
bWVzLAogb3IgcGlubmluZyB0aGUgdG9vbHMnIHN0YXRlcyBzbyB0aGV5IGFyZW4ndCBmdWxs
eSBkeW5hbWljLgoKDAoFBAACBQQSA0ICCgoMCgUEAAIFBhIDQgsaCgwKBQQAAgUBEgNCGykK
DAoFBAACBQMSA0IsLQoMCgUEAAIFCBIDQwYuCg8KCAQAAgUInAgAEgNDBy0KogEKAgQBEgRJ
AFoBGpUBIE92ZXJyaWRlcyBhc3NvY2lhdGVkIHdpdGggYSBnaXZlbiB0b29sIGluIGEgVG9v
bHNldC4KIFRoaXMgZW5hYmxlcyAicGlubmluZyIgb3IgIm92ZXJyaWRpbmciIG9mIHRvb2wg
ZGVmaW5pdGlvbnMgZnJvbSB0aGUgZXh0ZXJuYWwKIGR5bmFtaWMgc2VydmVyLgoKCgoDBAEB
EgNJCBcKWgoEBAECABIDSwI7Gk0gUmVxdWlyZWQuIFRoZSBvcmlnaW5hbCBuYW1lIG9mIHRo
ZSB0b29sIGFzIGl0IGlzIGVtaXR0ZWQgYnkgdGhlIE1DUCBzZXJ2ZXIuCgoMCgUEAQIABRID
SwIICgwKBQQBAgABEgNLCQ0KDAoFBAECAAMSA0sQEQoMCgUEAQIACBIDSxI6Cg8KCAQBAgAI
nAgAEgNLEzkKuwEKBAQBAgESA1ACRBqtASBPcHRpb25hbC4gSWYgcHJlc2VudCwgdGhpcyB0
b29sIHVzZXMgdGhpcyBuYW1lIGluIHRoZSBBZ2VudCBpbnN0ZWFkIG9mIHRoZQogb3JpZ2lu
YWwgbmFtZS4gVGhpcyBpcyBwcmltYXJpbHkgdXNlZCBhcyBhbiBhbGlhcyBpZiB0aGUgTUNQ
IHNlcnZlciBvZmZlcnMKIHBvb3JseSBuYW1lZCB0b29scy4KCgwKBQQBAgEFEgNQAggKDAoF
BAECAQESA1AJFgoMCgUEAQIBAxIDUBkaCgwKBQQBAgEIEgNQG0MKDwoIBAECAQicCAASA1Ac
Qgp6CgQEAQICEgNUAksabSBPcHRpb25hbC4gSWYgcHJlc2VudCwgdGhpcyB0b29sIHVzZXMg
dGhpcyBkZXNjcmlwdGlvbiBpbnN0ZWFkIG9mIHRoZQogb3JpZ2luYWwgZGVzY3JpcHRpb24g
ZnJvbSB0aGUgc2VydmVyLgoKDAoFBAECAgUSA1QCCAoMCgUEAQICARIDVAkdCgwKBQQBAgID
EgNUICEKDAoFBAECAggSA1QiSgoPCggEAQICCJwIABIDVCNJCrYBCgQEAQIDEgNZAk0aqAEg
T3V0cHV0IG9ubHkuIElmIHByZXNlbnQsIHRoaXMgdG9vbCBpcyAiUGlubmVkIiBhbmQgdXNl
cyB0aGUgc25hcHNob3QgdmFsdWVzCiBhcyBmYWxsYmFja3MgaWYgdGhlIHNlcnZlciBiZWNv
bWVzIHRlbXBvcmFyaWx5IHVuYXZhaWxhYmxlIG9yIGlmIG5vCiBPdmVycmlkZSBpcyBwcmVz
ZW50LgoKDAoFBAECAwYSA1kCEwoMCgUEAQIDARIDWRQcCgwKBQQBAgMDEgNZHyAKDAoFBAEC
AwgSA1khTAoPCggEAQIDCJwIABIDWSJLCpMBCgIEAhIEXgBoARqGASBDb250YWluZXIgZm9y
IGEgdG9vbCdzIGNvcmUgZGVmaW5pdGlvbiBlbGVtZW50cyB0aGF0IGFyZSBzbmFwc2hvdC4K
IFNjaGVtYXMgaW4gdGhlIHNuYXBzaG90IGFyZSB1c2VkIGFzLWlzIGFuZCBjYW5ub3QgYmUg
b3ZlcnJpZGRlbi4KCgoKAwQCARIDXggZCoQBCgQEAgIAEgNhAkUadyBPdXRwdXQgb25seS4g
VGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBNQ1AgdG9vbC4gVGhpcyBjYW4gYmUgb3ZlcnJpZGRl
bgogYnkgYGRlc2NyaXB0aW9uX292ZXJyaWRlYCBpbiBgTWNwVG9vbE92ZXJyaWRlYC4KCgwK
BQQCAgAFEgNhAggKDAoFBAICAAESA2EJFAoMCgUEAgIAAxIDYRcYCgwKBQQCAgAIEgNhGUQK
DwoIBAICAAicCAASA2EaQwpOCgQEAgIBEgNkAkYaQSBPdXRwdXQgb25seS4gVGhlIHNjaGVt
YSBvZiB0aGUgaW5wdXQgYXJndW1lbnRzIG9mIHRoZSBNQ1AgdG9vbC4KCgwKBQQCAgEGEgNk
AggKDAoFBAICAQESA2QJFQoMCgUEAgIBAxIDZBgZCgwKBQQCAgEIEgNkGkUKDwoIBAICAQic
CAASA2QbRApPCgQEAgICEgNnAkcaQiBPdXRwdXQgb25seS4gVGhlIHNjaGVtYSBvZiB0aGUg
b3V0cHV0IGFyZ3VtZW50cyBvZiB0aGUgTUNQIHRvb2wuCgoMCgUEAgICBhIDZwIICgwKBQQC
AgIBEgNnCRYKDAoFBAICAgMSA2cZGgoMCgUEAgICCBIDZxtGCg8KCAQCAgIInAgAEgNnHEVi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::McpToolset::McpToolset ===
    # Fields for McpToolset
    # Field: server_address Type: 9 ()
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1.ApiAuthentication)
    # Field: service_directory_config Type: 11 (.google.cloud.ces.v1.ServiceDirectoryConfig)
    # Field: tls_config Type: 11 (.google.cloud.ces.v1.TlsConfig)
    # Field: custom_headers Type: 11 (.google.cloud.ces.v1.McpToolset.CustomHeadersEntry)
    # Field: tool_overrides Type: 11 (.google.cloud.ces.v1.McpToolOverride)

# === Message: Google::Cloud::Ces::V1::McpToolset::McpToolOverride ===
    # Fields for McpToolOverride
    # Field: tool Type: 9 ()
    # Field: name_override Type: 9 ()
    # Field: description_override Type: 9 ()
    # Field: snapshot Type: 11 (.google.cloud.ces.v1.McpToolDefinition)

# === Message: Google::Cloud::Ces::V1::McpToolset::McpToolDefinition ===
    # Fields for McpToolDefinition
    # Field: description Type: 9 ()
    # Field: input_schema Type: 11 (.google.cloud.ces.v1.Schema)
    # Field: output_schema Type: 11 (.google.cloud.ces.v1.Schema)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::McpToolset - Compiled Protocol Buffers messages for google/cloud/ces/v1/mcp_toolset.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::McpToolset;

    my $msg = Google::Cloud::Ces::V1::McpToolset::McpToolset->new({
        server_address => $server_address,
        api_authentication => $api_authentication,
        service_directory_config => $service_directory_config,
        tls_config => $tls_config,
    });

    # Read or update a field
    my $val = $msg->server_address();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::McpToolset::McpToolset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/mcp_toolset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::McpToolset::McpToolset

A toolset that contains a list of tools that are offered by the MCP
server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->server_address() >> / C<< $msg->server_address($value) >>

Type: C<String>

Required. The address of the MCP server, for example,
"https://example.com/mcp/". If the server is built with the MCP SDK, the
url should be suffixed with
"/mcp/". Only Streamable HTTP transport based servers are supported. See
https://modelcontextprotocol.io/specification/2025-03-26/basic/transports#streamable-http
for more details.

=item * C<< $msg->api_authentication() >> / C<< $msg->api_authentication($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::ApiAuthentication>)

Optional. Authentication information required to access tools and execute a
tool against the MCP server. For bearer token authentication, the token
applies only to tool execution, not to listing tools. This requires that
tools can be listed without authentication.

=item * C<< $msg->service_directory_config() >> / C<< $msg->service_directory_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ServiceDirectoryConfig>)

Optional. Service Directory configuration for VPC-SC, used to resolve
service names within a perimeter.

=item * C<< $msg->tls_config() >> / C<< $msg->tls_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::TlsConfig>)

Optional. The TLS configuration. Includes the custom server certificates
that the client should trust.

=item * C<< $msg->custom_headers() >> / C<< $msg->custom_headers($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::McpToolset::McpToolset::CustomHeadersEntry>)

Optional. The custom headers to send in the request to the MCP server. The
values must be in the format `$context.variables.<name_of_variable>` and
can be set in the session variables. See
https://docs.cloud.google.com/customer-engagement-ai/conversational-agents/ps/tool/open-api#openapi-injection
for more details.

=item * C<< $msg->tool_overrides() >> / C<< $msg->tool_overrides($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::McpToolset::McpToolOverride>)

Optional. Overrides for individual tools within this toolset.
This allows overriding specific details like descriptions, names,
or pinning the tools' states so they aren't fully dynamic.

=back

=head2 Google::Cloud::Ces::V1::McpToolset::McpToolOverride

Overrides associated with a given tool in a Toolset.
This enables "pinning" or "overriding" of tool definitions from the external
dynamic server.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tool() >> / C<< $msg->tool($value) >>

Type: C<String>

Required. The original name of the tool as it is emitted by the MCP server.

=item * C<< $msg->name_override() >> / C<< $msg->name_override($value) >>

Type: C<String>

Optional. If present, this tool uses this name in the Agent instead of the
original name. This is primarily used as an alias if the MCP server offers
poorly named tools.

=item * C<< $msg->description_override() >> / C<< $msg->description_override($value) >>

Type: C<String>

Optional. If present, this tool uses this description instead of the
original description from the server.

=item * C<< $msg->snapshot() >> / C<< $msg->snapshot($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::McpToolset::McpToolDefinition>)

Output only. If present, this tool is "Pinned" and uses the snapshot values
as fallbacks if the server becomes temporarily unavailable or if no
Override is present.

=back

=head2 Google::Cloud::Ces::V1::McpToolset::McpToolDefinition

Container for a tool's core definition elements that are snapshot.
Schemas in the snapshot are used as-is and cannot be overridden.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description of the MCP tool. This can be overridden
by `description_override` in `McpToolOverride`.

=item * C<< $msg->input_schema() >> / C<< $msg->input_schema($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

Output only. The schema of the input arguments of the MCP tool.

=item * C<< $msg->output_schema() >> / C<< $msg->output_schema($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Schema::Schema>)

Output only. The schema of the output arguments of the MCP tool.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::McpToolset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
