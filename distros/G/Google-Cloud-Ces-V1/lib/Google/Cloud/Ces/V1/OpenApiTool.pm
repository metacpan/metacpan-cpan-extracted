package Google::Cloud::Ces::V1::OpenApiTool;

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
    my $descriptor_b64 = <<'EOF';
Cidnb29nbGUvY2xvdWQvY2VzL3YxL29wZW5fYXBpX3Rvb2wucHJvdG8SE2dvb2dsZS5jbG91
ZC5jZXMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aHmdvb2dsZS9jbG91
ZC9jZXMvdjEvYXV0aC5wcm90bxogZ29vZ2xlL2Nsb3VkL2Nlcy92MS9jb21tb24ucHJvdG8i
1gMKC09wZW5BcGlUb29sEisKD29wZW5fYXBpX3NjaGVtYRgBIAEoCUID4EECUg1vcGVuQXBp
U2NoZW1hEhcKBG5hbWUYAiABKAlCA+BBAVIEbmFtZRIlCgtkZXNjcmlwdGlvbhgDIAEoCUID
4EEBUgtkZXNjcmlwdGlvbhJaChJhcGlfYXV0aGVudGljYXRpb24YBCABKAsyJi5nb29nbGUu
Y2xvdWQuY2VzLnYxLkFwaUF1dGhlbnRpY2F0aW9uQgPgQQFSEWFwaUF1dGhlbnRpY2F0aW9u
EkIKCnRsc19jb25maWcYBSABKAsyHi5nb29nbGUuY2xvdWQuY2VzLnYxLlRsc0NvbmZpZ0ID
4EEBUgl0bHNDb25maWcSagoYc2VydmljZV9kaXJlY3RvcnlfY29uZmlnGAYgASgLMisuZ29v
Z2xlLmNsb3VkLmNlcy52MS5TZXJ2aWNlRGlyZWN0b3J5Q29uZmlnQgPgQQFSFnNlcnZpY2VE
aXJlY3RvcnlDb25maWcSNwoVaWdub3JlX3Vua25vd25fZmllbGRzGAcgASgIQgPgQQFSE2ln
bm9yZVVua25vd25GaWVsZHMSFQoDdXJsGAggASgJQgPgQQFSA3VybEJYChdjb20uZ29vZ2xl
LmNsb3VkLmNlcy52MUIQT3BlbkFwaVRvb2xQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dv
L2Nlcy9hcGl2MS9jZXNwYjtjZXNwYkrUEwoGEgQOAEABCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMSACkKCQoCAwESAxMAKAoJCgIDAhID
FAAqCggKAQgSAxYAQAoJCgIICxIDFgBACggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgA
MQoJCgIICBIDGAAxCggKAQgSAxkAMAoJCgIIARIDGQAwCj0KAgQAEgQcAEABGjEgQSByZW1v
dGUgQVBJIHRvb2wgZGVmaW5lZCBieSBhbiBPcGVuQVBJIHNjaGVtYS4KCgoKAwQAARIDHAgT
CkMKBAQAAgASAx4CRho2IFJlcXVpcmVkLiBUaGUgT3BlbkFQSSBzY2hlbWEgaW4gSlNPTiBv
ciBZQU1MIGZvcm1hdC4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAESAx4JGAoMCgUEAAIAAxID
HhscCgwKBQQAAgAIEgMeHUUKDwoIBAACAAicCAASAx4eRAqdAQoEBAACARIDIgI7Go8BIE9w
dGlvbmFsLiBUaGUgbmFtZSBvZiB0aGUgdG9vbC4gSWYgbm90IHByb3ZpZGVkLCB0aGUgbmFt
ZSBvZiB0aGUgdG9vbCB3aWxsCiBiZSBkZXJpdmVkIGZyb20gdGhlIE9wZW5BUEkgc2NoZW1h
LCBmcm9tIGBvcGVyYXRpb24ub3BlcmF0aW9uSWRgLgoKDAoFBAACAQUSAyICCAoMCgUEAAIB
ARIDIgkNCgwKBQQAAgEDEgMiEBEKDAoFBAACAQgSAyISOgoPCggEAAIBCJwIABIDIhM5CsMB
CgQEAAICEgMnAkIatQEgT3B0aW9uYWwuIFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgdG9vbC4g
SWYgbm90IHByb3ZpZGVkLCB0aGUgZGVzY3JpcHRpb24gb2YKIHRoZSB0b29sIHdpbGwgYmUg
ZGVyaXZlZCBmcm9tIHRoZSBPcGVuQVBJIHNjaGVtYSwgZnJvbQogYG9wZXJhdGlvbi5kZXNj
cmlwdGlvbmAgb3IgYG9wZXJhdGlvbi5zdW1tYXJ5YC4KCgwKBQQAAgIFEgMnAggKDAoFBAAC
AgESAycJFAoMCgUEAAICAxIDJxcYCgwKBQQAAgIIEgMnGUEKDwoIBAACAgicCAASAycaQApJ
CgQEAAIDEgQqAisvGjsgT3B0aW9uYWwuIEF1dGhlbnRpY2F0aW9uIGluZm9ybWF0aW9uIHJl
cXVpcmVkIGJ5IHRoZSBBUEkuCgoMCgUEAAIDBhIDKgITCgwKBQQAAgMBEgMqFCYKDAoFBAAC
AwMSAyopKgoMCgUEAAIDCBIDKwYuCg8KCAQAAgMInAgAEgMrBy0KdAoEBAACBBIDLwJEGmcg
T3B0aW9uYWwuIFRoZSBUTFMgY29uZmlndXJhdGlvbi4gSW5jbHVkZXMgdGhlIGN1c3RvbSBz
ZXJ2ZXIgY2VydGlmaWNhdGVzCiB0aGF0IHRoZSBjbGllbnQgd2lsbCB0cnVzdC4KCgwKBQQA
AgQGEgMvAgsKDAoFBAACBAESAy8MFgoMCgUEAAIEAxIDLxkaCgwKBQQAAgQIEgMvG0MKDwoI
BAACBAicCAASAy8cQgo6CgQEAAIFEgQyAjMvGiwgT3B0aW9uYWwuIFNlcnZpY2UgRGlyZWN0
b3J5IGNvbmZpZ3VyYXRpb24uCgoMCgUEAAIFBhIDMgIYCgwKBQQAAgUBEgMyGTEKDAoFBAAC
BQMSAzI0NQoMCgUEAAIFCBIDMwYuCg8KCAQAAgUInAgAEgMzBy0KXAoEBAACBhIDNwJKGk8g
T3B0aW9uYWwuIElmIHRydWUsIHRoZSBhZ2VudCB3aWxsIGlnbm9yZSB1bmtub3duIGZpZWxk
cyBpbiB0aGUgQVBJCiByZXNwb25zZS4KCgwKBQQAAgYFEgM3AgYKDAoFBAACBgESAzcHHAoM
CgUEAAIGAxIDNx8gCgwKBQQAAgYIEgM3IUkKDwoIBAACBgicCAASAzciSAryAgoEBAACBxID
PwI6GuQCIE9wdGlvbmFsLiBUaGUgc2VydmVyIFVSTCBvZiB0aGUgT3BlbiBBUEkgc2NoZW1h
LgogVGhpcyBmaWVsZCBpcyBvbmx5IHNldCBpbiB0b29scyBpbiB0aGUgZW52aXJvbm1lbnQg
ZGVwZW5kZW5jaWVzIGR1cmluZyB0aGUKIGV4cG9ydCBwcm9jZXNzIGlmIHRoZSBzY2hlbWEg
Y29udGFpbnMgYSBzZXJ2ZXIgdXJsLiBEdXJpbmcgdGhlIGltcG9ydAogcHJvY2VzcywgaWYg
dGhpcyB1cmwgaXMgcHJlc2VudCBpbiB0aGUgZW52aXJvbm1lbnQgZGVwZW5kZW5jaWVzIGFu
ZCB0aGUKIHNjaGVtYSBoYXMgdGhlICRlbnZfdmFyIHBsYWNlaG9sZGVyLCBpdCB3aWxsIHJl
cGxhY2UgdGhlIHBsYWNlaG9sZGVyIGluIHRoZQogc2NoZW1hLgoKDAoFBAACBwUSAz8CCAoM
CgUEAAIHARIDPwkMCgwKBQQAAgcDEgM/DxAKDAoFBAACBwgSAz8ROQoPCggEAAIHCJwIABID
PxI4YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::OpenApiTool::OpenApiTool ===
    # Fields for OpenApiTool
    # Field: open_api_schema Type: 9 ()
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1.ApiAuthentication)
    # Field: tls_config Type: 11 (.google.cloud.ces.v1.TlsConfig)
    # Field: service_directory_config Type: 11 (.google.cloud.ces.v1.ServiceDirectoryConfig)
    # Field: ignore_unknown_fields Type: 8 ()
    # Field: url Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::OpenApiTool - Compiled Protocol Buffers messages for google/cloud/ces/v1/open_api_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::OpenApiTool;

    my $msg = Google::Cloud::Ces::V1::OpenApiTool::OpenApiTool->new({
        open_api_schema => $open_api_schema,
        name => $name,
        description => $description,
        api_authentication => $api_authentication,
    });

    # Read or update a field
    my $val = $msg->open_api_schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::OpenApiTool::OpenApiTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/open_api_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::OpenApiTool::OpenApiTool

A remote API tool defined by an OpenAPI schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->open_api_schema() >> / C<< $msg->open_api_schema($value) >>

Type: C<String>

Required. The OpenAPI schema in JSON or YAML format.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Optional. The name of the tool. If not provided, the name of the tool will
be derived from the OpenAPI schema, from `operation.operationId`.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. The description of the tool. If not provided, the description of
the tool will be derived from the OpenAPI schema, from
`operation.description` or `operation.summary`.

=item * C<< $msg->api_authentication() >> / C<< $msg->api_authentication($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::ApiAuthentication>)

Optional. Authentication information required by the API.

=item * C<< $msg->tls_config() >> / C<< $msg->tls_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::TlsConfig>)

Optional. The TLS configuration. Includes the custom server certificates
that the client will trust.

=item * C<< $msg->service_directory_config() >> / C<< $msg->service_directory_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ServiceDirectoryConfig>)

Optional. Service Directory configuration.

=item * C<< $msg->ignore_unknown_fields() >> / C<< $msg->ignore_unknown_fields($value) >>

Type: C<Bool>

Optional. If true, the agent will ignore unknown fields in the API
response.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

Optional. The server URL of the Open API schema.
This field is only set in tools in the environment dependencies during the
export process if the schema contains a server url. During the import
process, if this url is present in the environment dependencies and the
schema has the $env_var placeholder, it will replace the placeholder in the
schema.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::OpenApiTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
