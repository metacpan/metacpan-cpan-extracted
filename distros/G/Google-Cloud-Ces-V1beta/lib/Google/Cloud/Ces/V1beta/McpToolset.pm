package Google::Cloud::Ces::V1beta::McpToolset;

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
Cilnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9tY3BfdG9vbHNldC5wcm90bxIXZ29vZ2xlLmNs
b3VkLmNlcy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aImdvb2ds
ZS9jbG91ZC9jZXMvdjFiZXRhL2F1dGgucHJvdG8aJGdvb2dsZS9jbG91ZC9jZXMvdjFiZXRh
L2NvbW1vbi5wcm90bxokZ29vZ2xlL2Nsb3VkL2Nlcy92MWJldGEvc2NoZW1hLnByb3RvIswE
CgpNY3BUb29sc2V0EioKDnNlcnZlcl9hZGRyZXNzGAEgASgJQgPgQQJSDXNlcnZlckFkZHJl
c3MSXgoSYXBpX2F1dGhlbnRpY2F0aW9uGAIgASgLMiouZ29vZ2xlLmNsb3VkLmNlcy52MWJl
dGEuQXBpQXV0aGVudGljYXRpb25CA+BBAVIRYXBpQXV0aGVudGljYXRpb24SbgoYc2Vydmlj
ZV9kaXJlY3RvcnlfY29uZmlnGAMgASgLMi8uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuU2Vy
dmljZURpcmVjdG9yeUNvbmZpZ0ID4EEBUhZzZXJ2aWNlRGlyZWN0b3J5Q29uZmlnEkYKCnRs
c19jb25maWcYBCABKAsyIi5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5UbHNDb25maWdCA+BB
AVIJdGxzQ29uZmlnEmIKDmN1c3RvbV9oZWFkZXJzGAUgAygLMjYuZ29vZ2xlLmNsb3VkLmNl
cy52MWJldGEuTWNwVG9vbHNldC5DdXN0b21IZWFkZXJzRW50cnlCA+BBAVINY3VzdG9tSGVh
ZGVycxJUCg50b29sX292ZXJyaWRlcxgGIAMoCzIoLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRh
Lk1jcFRvb2xPdmVycmlkZUID4EEBUg10b29sT3ZlcnJpZGVzGkAKEkN1c3RvbUhlYWRlcnNF
bnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBItkBCg9N
Y3BUb29sT3ZlcnJpZGUSFwoEdG9vbBgBIAEoCUID4EECUgR0b29sEigKDW5hbWVfb3ZlcnJp
ZGUYAiABKAlCA+BBAVIMbmFtZU92ZXJyaWRlEjYKFGRlc2NyaXB0aW9uX292ZXJyaWRlGAMg
ASgJQgPgQQFSE2Rlc2NyaXB0aW9uT3ZlcnJpZGUSSwoIc25hcHNob3QYBCABKAsyKi5nb29n
bGUuY2xvdWQuY2VzLnYxYmV0YS5NY3BUb29sRGVmaW5pdGlvbkID4EEDUghzbmFwc2hvdCLO
AQoRTWNwVG9vbERlZmluaXRpb24SJQoLZGVzY3JpcHRpb24YASABKAlCA+BBA1ILZGVzY3Jp
cHRpb24SRwoMaW5wdXRfc2NoZW1hGAIgASgLMh8uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEu
U2NoZW1hQgPgQQNSC2lucHV0U2NoZW1hEkkKDW91dHB1dF9zY2hlbWEYAyABKAsyHy5nb29n
bGUuY2xvdWQuY2VzLnYxYmV0YS5TY2hlbWFCA+BBA1IMb3V0cHV0U2NoZW1hQl8KG2NvbS5n
b29nbGUuY2xvdWQuY2VzLnYxYmV0YUIPTWNwVG9vbHNldFByb3RvUAFaLWNsb3VkLmdvb2ds
ZS5jb20vZ28vY2VzL2FwaXYxYmV0YS9jZXNwYjtjZXNwYkriIgoGEgQOAGgBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMSACkKCQoCAwES
AxMALAoJCgIDAhIDFAAuCgkKAgMDEgMVAC4KCAoBCBIDFwBECgkKAggLEgMXAEQKCAoBCBID
GAAiCgkKAggKEgMYACIKCAoBCBIDGQAwCgkKAggIEgMZADAKCAoBCBIDGgA0CgkKAggBEgMa
ADQKWgoCBAASBB4ARAEaTiBBIHRvb2xzZXQgdGhhdCBjb250YWlucyBhIGxpc3Qgb2YgdG9v
bHMgdGhhdCBhcmUgb2ZmZXJlZCBieSB0aGUgTUNQCiBzZXJ2ZXIuCgoKCgMEAAESAx4IEgrk
AgoEBAACABIDJQJFGtYCIFJlcXVpcmVkLiBUaGUgYWRkcmVzcyBvZiB0aGUgTUNQIHNlcnZl
ciwgZm9yIGV4YW1wbGUsCiAiaHR0cHM6Ly9leGFtcGxlLmNvbS9tY3AvIi4gSWYgdGhlIHNl
cnZlciBpcyBidWlsdCB3aXRoIHRoZSBNQ1AgU0RLLCB0aGUKIHVybCBzaG91bGQgYmUgc3Vm
Zml4ZWQgd2l0aAogIi9tY3AvIi4gT25seSBTdHJlYW1hYmxlIEhUVFAgdHJhbnNwb3J0IGJh
c2VkIHNlcnZlcnMgYXJlIHN1cHBvcnRlZC4gU2VlCiBodHRwczovL21vZGVsY29udGV4dHBy
b3RvY29sLmlvL3NwZWNpZmljYXRpb24vMjAyNS0wMy0yNi9iYXNpYy90cmFuc3BvcnRzI3N0
cmVhbWFibGUtaHR0cAogZm9yIG1vcmUgZGV0YWlscy4KCgwKBQQAAgAFEgMlAggKDAoFBAAC
AAESAyUJFwoMCgUEAAIAAxIDJRobCgwKBQQAAgAIEgMlHEQKDwoIBAACAAicCAASAyUdQwqc
AgoEBAACARIEKwIsLxqNAiBPcHRpb25hbC4gQXV0aGVudGljYXRpb24gaW5mb3JtYXRpb24g
cmVxdWlyZWQgdG8gYWNjZXNzIHRvb2xzIGFuZCBleGVjdXRlIGEKIHRvb2wgYWdhaW5zdCB0
aGUgTUNQIHNlcnZlci4gRm9yIGJlYXJlciB0b2tlbiBhdXRoZW50aWNhdGlvbiwgdGhlIHRv
a2VuCiBhcHBsaWVzIG9ubHkgdG8gdG9vbCBleGVjdXRpb24sIG5vdCB0byBsaXN0aW5nIHRv
b2xzLiBUaGlzIHJlcXVpcmVzIHRoYXQKIHRvb2xzIGNhbiBiZSBsaXN0ZWQgd2l0aG91dCBh
dXRoZW50aWNhdGlvbi4KCgwKBQQAAgEGEgMrAhMKDAoFBAACAQESAysUJgoMCgUEAAIBAxID
KykqCgwKBQQAAgEIEgMsBi4KDwoIBAACAQicCAASAywHLQp4CgQEAAICEgQwAjEvGmogT3B0
aW9uYWwuIFNlcnZpY2UgRGlyZWN0b3J5IGNvbmZpZ3VyYXRpb24gZm9yIFZQQy1TQywgdXNl
ZCB0byByZXNvbHZlCiBzZXJ2aWNlIG5hbWVzIHdpdGhpbiBhIHBlcmltZXRlci4KCgwKBQQA
AgIGEgMwAhgKDAoFBAACAgESAzAZMQoMCgUEAAICAxIDMDQ1CgwKBQQAAgIIEgMxBi4KDwoI
BAACAgicCAASAzEHLQp2CgQEAAIDEgM1AkQaaSBPcHRpb25hbC4gVGhlIFRMUyBjb25maWd1
cmF0aW9uLiBJbmNsdWRlcyB0aGUgY3VzdG9tIHNlcnZlciBjZXJ0aWZpY2F0ZXMKIHRoYXQg
dGhlIGNsaWVudCBzaG91bGQgdHJ1c3QuCgoMCgUEAAIDBhIDNQILCgwKBQQAAgMBEgM1DBYK
DAoFBAACAwMSAzUZGgoMCgUEAAIDCBIDNRtDCg8KCAQAAgMInAgAEgM1HEIK0QIKBAQAAgQS
BDwCPS8awgIgT3B0aW9uYWwuIFRoZSBjdXN0b20gaGVhZGVycyB0byBzZW5kIGluIHRoZSBy
ZXF1ZXN0IHRvIHRoZSBNQ1Agc2VydmVyLiBUaGUKIHZhbHVlcyBtdXN0IGJlIGluIHRoZSBm
b3JtYXQgYCRjb250ZXh0LnZhcmlhYmxlcy48bmFtZV9vZl92YXJpYWJsZT5gIGFuZAogY2Fu
IGJlIHNldCBpbiB0aGUgc2Vzc2lvbiB2YXJpYWJsZXMuIFNlZQogaHR0cHM6Ly9kb2NzLmNs
b3VkLmdvb2dsZS5jb20vY3VzdG9tZXItZW5nYWdlbWVudC1haS9jb252ZXJzYXRpb25hbC1h
Z2VudHMvcHMvdG9vbC9vcGVuLWFwaSNvcGVuYXBpLWluamVjdGlvbgogZm9yIG1vcmUgZGV0
YWlscy4KCgwKBQQAAgQGEgM8AhUKDAoFBAACBAESAzwWJAoMCgUEAAIEAxIDPCcoCgwKBQQA
AgQIEgM9Bi4KDwoIBAACBAicCAASAz0HLQrNAQoEBAACBRIEQgJDLxq+ASBPcHRpb25hbC4g
T3ZlcnJpZGVzIGZvciBpbmRpdmlkdWFsIHRvb2xzIHdpdGhpbiB0aGlzIHRvb2xzZXQuCiBU
aGlzIGFsbG93cyBvdmVycmlkaW5nIHNwZWNpZmljIGRldGFpbHMgbGlrZSBkZXNjcmlwdGlv
bnMsIG5hbWVzLAogb3IgcGlubmluZyB0aGUgdG9vbHMnIHN0YXRlcyBzbyB0aGV5IGFyZW4n
dCBmdWxseSBkeW5hbWljLgoKDAoFBAACBQQSA0ICCgoMCgUEAAIFBhIDQgsaCgwKBQQAAgUB
EgNCGykKDAoFBAACBQMSA0IsLQoMCgUEAAIFCBIDQwYuCg8KCAQAAgUInAgAEgNDBy0KogEK
AgQBEgRJAFoBGpUBIE92ZXJyaWRlcyBhc3NvY2lhdGVkIHdpdGggYSBnaXZlbiB0b29sIGlu
IGEgVG9vbHNldC4KIFRoaXMgZW5hYmxlcyAicGlubmluZyIgb3IgIm92ZXJyaWRpbmciIG9m
IHRvb2wgZGVmaW5pdGlvbnMgZnJvbSB0aGUgZXh0ZXJuYWwKIGR5bmFtaWMgc2VydmVyLgoK
CgoDBAEBEgNJCBcKWgoEBAECABIDSwI7Gk0gUmVxdWlyZWQuIFRoZSBvcmlnaW5hbCBuYW1l
IG9mIHRoZSB0b29sIGFzIGl0IGlzIGVtaXR0ZWQgYnkgdGhlIE1DUCBzZXJ2ZXIuCgoMCgUE
AQIABRIDSwIICgwKBQQBAgABEgNLCQ0KDAoFBAECAAMSA0sQEQoMCgUEAQIACBIDSxI6Cg8K
CAQBAgAInAgAEgNLEzkKuwEKBAQBAgESA1ACRBqtASBPcHRpb25hbC4gSWYgcHJlc2VudCwg
dGhpcyB0b29sIHVzZXMgdGhpcyBuYW1lIGluIHRoZSBBZ2VudCBpbnN0ZWFkIG9mIHRoZQog
b3JpZ2luYWwgbmFtZS4gVGhpcyBpcyBwcmltYXJpbHkgdXNlZCBhcyBhbiBhbGlhcyBpZiB0
aGUgTUNQIHNlcnZlciBvZmZlcnMKIHBvb3JseSBuYW1lZCB0b29scy4KCgwKBQQBAgEFEgNQ
AggKDAoFBAECAQESA1AJFgoMCgUEAQIBAxIDUBkaCgwKBQQBAgEIEgNQG0MKDwoIBAECAQic
CAASA1AcQgp6CgQEAQICEgNUAksabSBPcHRpb25hbC4gSWYgcHJlc2VudCwgdGhpcyB0b29s
IHVzZXMgdGhpcyBkZXNjcmlwdGlvbiBpbnN0ZWFkIG9mIHRoZQogb3JpZ2luYWwgZGVzY3Jp
cHRpb24gZnJvbSB0aGUgc2VydmVyLgoKDAoFBAECAgUSA1QCCAoMCgUEAQICARIDVAkdCgwK
BQQBAgIDEgNUICEKDAoFBAECAggSA1QiSgoPCggEAQICCJwIABIDVCNJCrYBCgQEAQIDEgNZ
Ak0aqAEgT3V0cHV0IG9ubHkuIElmIHByZXNlbnQsIHRoaXMgdG9vbCBpcyAiUGlubmVkIiBh
bmQgdXNlcyB0aGUgc25hcHNob3QgdmFsdWVzCiBhcyBmYWxsYmFja3MgaWYgdGhlIHNlcnZl
ciBiZWNvbWVzIHRlbXBvcmFyaWx5IHVuYXZhaWxhYmxlIG9yIGlmIG5vCiBPdmVycmlkZSBp
cyBwcmVzZW50LgoKDAoFBAECAwYSA1kCEwoMCgUEAQIDARIDWRQcCgwKBQQBAgMDEgNZHyAK
DAoFBAECAwgSA1khTAoPCggEAQIDCJwIABIDWSJLCpMBCgIEAhIEXgBoARqGASBDb250YWlu
ZXIgZm9yIGEgdG9vbCdzIGNvcmUgZGVmaW5pdGlvbiBlbGVtZW50cyB0aGF0IGFyZSBzbmFw
c2hvdC4KIFNjaGVtYXMgaW4gdGhlIHNuYXBzaG90IGFyZSB1c2VkIGFzLWlzIGFuZCBjYW5u
b3QgYmUgb3ZlcnJpZGRlbi4KCgoKAwQCARIDXggZCoQBCgQEAgIAEgNhAkUadyBPdXRwdXQg
b25seS4gVGhlIGRlc2NyaXB0aW9uIG9mIHRoZSBNQ1AgdG9vbC4gVGhpcyBjYW4gYmUgb3Zl
cnJpZGRlbgogYnkgYGRlc2NyaXB0aW9uX292ZXJyaWRlYCBpbiBgTWNwVG9vbE92ZXJyaWRl
YC4KCgwKBQQCAgAFEgNhAggKDAoFBAICAAESA2EJFAoMCgUEAgIAAxIDYRcYCgwKBQQCAgAI
EgNhGUQKDwoIBAICAAicCAASA2EaQwpOCgQEAgIBEgNkAkYaQSBPdXRwdXQgb25seS4gVGhl
IHNjaGVtYSBvZiB0aGUgaW5wdXQgYXJndW1lbnRzIG9mIHRoZSBNQ1AgdG9vbC4KCgwKBQQC
AgEGEgNkAggKDAoFBAICAQESA2QJFQoMCgUEAgIBAxIDZBgZCgwKBQQCAgEIEgNkGkUKDwoI
BAICAQicCAASA2QbRApPCgQEAgICEgNnAkcaQiBPdXRwdXQgb25seS4gVGhlIHNjaGVtYSBv
ZiB0aGUgb3V0cHV0IGFyZ3VtZW50cyBvZiB0aGUgTUNQIHRvb2wuCgoMCgUEAgICBhIDZwII
CgwKBQQCAgIBEgNnCRYKDAoFBAICAgMSA2cZGgoMCgUEAgICCBIDZxtGCg8KCAQCAgIInAgA
EgNnHEViBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::McpToolset::McpToolset ===
    # Fields for McpToolset
    # Field: server_address Type: 9 ()
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1beta.ApiAuthentication)
    # Field: service_directory_config Type: 11 (.google.cloud.ces.v1beta.ServiceDirectoryConfig)
    # Field: tls_config Type: 11 (.google.cloud.ces.v1beta.TlsConfig)
    # Field: custom_headers Type: 11 (.google.cloud.ces.v1beta.McpToolset.CustomHeadersEntry)
    # Field: tool_overrides Type: 11 (.google.cloud.ces.v1beta.McpToolOverride)

# === Message: Google::Cloud::Ces::V1beta::McpToolset::McpToolOverride ===
    # Fields for McpToolOverride
    # Field: tool Type: 9 ()
    # Field: name_override Type: 9 ()
    # Field: description_override Type: 9 ()
    # Field: snapshot Type: 11 (.google.cloud.ces.v1beta.McpToolDefinition)

# === Message: Google::Cloud::Ces::V1beta::McpToolset::McpToolDefinition ===
    # Fields for McpToolDefinition
    # Field: description Type: 9 ()
    # Field: input_schema Type: 11 (.google.cloud.ces.v1beta.Schema)
    # Field: output_schema Type: 11 (.google.cloud.ces.v1beta.Schema)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::McpToolset - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/mcp_toolset.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::McpToolset;

    my $msg = Google::Cloud::Ces::V1beta::McpToolset::McpToolset->new({
        server_address => $server_address,
        api_authentication => $api_authentication,
        service_directory_config => $service_directory_config,
        tls_config => $tls_config,
    });

    # Read or update a field
    my $val = $msg->server_address();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::McpToolset::McpToolset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/mcp_toolset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::McpToolset::McpToolset

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

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::ApiAuthentication>)

Optional. Authentication information required to access tools and execute a
tool against the MCP server. For bearer token authentication, the token
applies only to tool execution, not to listing tools. This requires that
tools can be listed without authentication.

=item * C<< $msg->service_directory_config() >> / C<< $msg->service_directory_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::ServiceDirectoryConfig>)

Optional. Service Directory configuration for VPC-SC, used to resolve
service names within a perimeter.

=item * C<< $msg->tls_config() >> / C<< $msg->tls_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::TlsConfig>)

Optional. The TLS configuration. Includes the custom server certificates
that the client should trust.

=item * C<< $msg->custom_headers() >> / C<< $msg->custom_headers($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::McpToolset::McpToolset::CustomHeadersEntry>)

Optional. The custom headers to send in the request to the MCP server. The
values must be in the format `$context.variables.<name_of_variable>` and
can be set in the session variables. See
https://docs.cloud.google.com/customer-engagement-ai/conversational-agents/ps/tool/open-api#openapi-injection
for more details.

=item * C<< $msg->tool_overrides() >> / C<< $msg->tool_overrides($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::McpToolset::McpToolOverride>)

Optional. Overrides for individual tools within this toolset.
This allows overriding specific details like descriptions, names,
or pinning the tools' states so they aren't fully dynamic.

=back

=head2 Google::Cloud::Ces::V1beta::McpToolset::McpToolOverride

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

Type: C<Message> (L<Google::Cloud::Ces::V1beta::McpToolset::McpToolDefinition>)

Output only. If present, this tool is "Pinned" and uses the snapshot values
as fallbacks if the server becomes temporarily unavailable or if no
Override is present.

=back

=head2 Google::Cloud::Ces::V1beta::McpToolset::McpToolDefinition

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

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

Output only. The schema of the input arguments of the MCP tool.

=item * C<< $msg->output_schema() >> / C<< $msg->output_schema($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Schema::Schema>)

Output only. The schema of the output arguments of the MCP tool.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::McpToolset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
