package Google::Cloud::Ces::V1beta::OpenApiTool;

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
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9vcGVuX2FwaV90b29sLnByb3RvEhdnb29nbGUu
Y2xvdWQuY2VzLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoiZ29v
Z2xlL2Nsb3VkL2Nlcy92MWJldGEvYXV0aC5wcm90bxokZ29vZ2xlL2Nsb3VkL2Nlcy92MWJl
dGEvY29tbW9uLnByb3RvIuIDCgtPcGVuQXBpVG9vbBIrCg9vcGVuX2FwaV9zY2hlbWEYASAB
KAlCA+BBAlINb3BlbkFwaVNjaGVtYRIXCgRuYW1lGAIgASgJQgPgQQFSBG5hbWUSJQoLZGVz
Y3JpcHRpb24YAyABKAlCA+BBAVILZGVzY3JpcHRpb24SXgoSYXBpX2F1dGhlbnRpY2F0aW9u
GAQgASgLMiouZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuQXBpQXV0aGVudGljYXRpb25CA+BB
AVIRYXBpQXV0aGVudGljYXRpb24SRgoKdGxzX2NvbmZpZxgFIAEoCzIiLmdvb2dsZS5jbG91
ZC5jZXMudjFiZXRhLlRsc0NvbmZpZ0ID4EEBUgl0bHNDb25maWcSbgoYc2VydmljZV9kaXJl
Y3RvcnlfY29uZmlnGAYgASgLMi8uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGEuU2VydmljZURp
cmVjdG9yeUNvbmZpZ0ID4EEBUhZzZXJ2aWNlRGlyZWN0b3J5Q29uZmlnEjcKFWlnbm9yZV91
bmtub3duX2ZpZWxkcxgHIAEoCEID4EEBUhNpZ25vcmVVbmtub3duRmllbGRzEhUKA3VybBgI
IAEoCUID4EEBUgN1cmxCYAobY29tLmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhQhBPcGVuQXBp
VG9vbFByb3RvUAFaLWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxYmV0YS9jZXNwYjtj
ZXNwYkrUEwoGEgQOAEABCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExM
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
AhIDEAAgCgkKAgMAEgMSACkKCQoCAwESAxMALAoJCgIDAhIDFAAuCggKAQgSAxYARAoJCgII
CxIDFgBECggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAMQoJCgIICBIDGAAxCggKAQgS
AxkANAoJCgIIARIDGQA0Cj0KAgQAEgQcAEABGjEgQSByZW1vdGUgQVBJIHRvb2wgZGVmaW5l
ZCBieSBhbiBPcGVuQVBJIHNjaGVtYS4KCgoKAwQAARIDHAgTCkMKBAQAAgASAx4CRho2IFJl
cXVpcmVkLiBUaGUgT3BlbkFQSSBzY2hlbWEgaW4gSlNPTiBvciBZQU1MIGZvcm1hdC4KCgwK
BQQAAgAFEgMeAggKDAoFBAACAAESAx4JGAoMCgUEAAIAAxIDHhscCgwKBQQAAgAIEgMeHUUK
DwoIBAACAAicCAASAx4eRAqdAQoEBAACARIDIgI7Go8BIE9wdGlvbmFsLiBUaGUgbmFtZSBv
ZiB0aGUgdG9vbC4gSWYgbm90IHByb3ZpZGVkLCB0aGUgbmFtZSBvZiB0aGUgdG9vbCB3aWxs
CiBiZSBkZXJpdmVkIGZyb20gdGhlIE9wZW5BUEkgc2NoZW1hLCBmcm9tIGBvcGVyYXRpb24u
b3BlcmF0aW9uSWRgLgoKDAoFBAACAQUSAyICCAoMCgUEAAIBARIDIgkNCgwKBQQAAgEDEgMi
EBEKDAoFBAACAQgSAyISOgoPCggEAAIBCJwIABIDIhM5CsMBCgQEAAICEgMnAkIatQEgT3B0
aW9uYWwuIFRoZSBkZXNjcmlwdGlvbiBvZiB0aGUgdG9vbC4gSWYgbm90IHByb3ZpZGVkLCB0
aGUgZGVzY3JpcHRpb24gb2YKIHRoZSB0b29sIHdpbGwgYmUgZGVyaXZlZCBmcm9tIHRoZSBP
cGVuQVBJIHNjaGVtYSwgZnJvbQogYG9wZXJhdGlvbi5kZXNjcmlwdGlvbmAgb3IgYG9wZXJh
dGlvbi5zdW1tYXJ5YC4KCgwKBQQAAgIFEgMnAggKDAoFBAACAgESAycJFAoMCgUEAAICAxID
JxcYCgwKBQQAAgIIEgMnGUEKDwoIBAACAgicCAASAycaQApJCgQEAAIDEgQqAisvGjsgT3B0
aW9uYWwuIEF1dGhlbnRpY2F0aW9uIGluZm9ybWF0aW9uIHJlcXVpcmVkIGJ5IHRoZSBBUEku
CgoMCgUEAAIDBhIDKgITCgwKBQQAAgMBEgMqFCYKDAoFBAACAwMSAyopKgoMCgUEAAIDCBID
KwYuCg8KCAQAAgMInAgAEgMrBy0KdAoEBAACBBIDLwJEGmcgT3B0aW9uYWwuIFRoZSBUTFMg
Y29uZmlndXJhdGlvbi4gSW5jbHVkZXMgdGhlIGN1c3RvbSBzZXJ2ZXIgY2VydGlmaWNhdGVz
CiB0aGF0IHRoZSBjbGllbnQgd2lsbCB0cnVzdC4KCgwKBQQAAgQGEgMvAgsKDAoFBAACBAES
Ay8MFgoMCgUEAAIEAxIDLxkaCgwKBQQAAgQIEgMvG0MKDwoIBAACBAicCAASAy8cQgo6CgQE
AAIFEgQyAjMvGiwgT3B0aW9uYWwuIFNlcnZpY2UgRGlyZWN0b3J5IGNvbmZpZ3VyYXRpb24u
CgoMCgUEAAIFBhIDMgIYCgwKBQQAAgUBEgMyGTEKDAoFBAACBQMSAzI0NQoMCgUEAAIFCBID
MwYuCg8KCAQAAgUInAgAEgMzBy0KXAoEBAACBhIDNwJKGk8gT3B0aW9uYWwuIElmIHRydWUs
IHRoZSBhZ2VudCB3aWxsIGlnbm9yZSB1bmtub3duIGZpZWxkcyBpbiB0aGUgQVBJCiByZXNw
b25zZS4KCgwKBQQAAgYFEgM3AgYKDAoFBAACBgESAzcHHAoMCgUEAAIGAxIDNx8gCgwKBQQA
AgYIEgM3IUkKDwoIBAACBgicCAASAzciSAryAgoEBAACBxIDPwI6GuQCIE9wdGlvbmFsLiBU
aGUgc2VydmVyIFVSTCBvZiB0aGUgT3BlbiBBUEkgc2NoZW1hLgogVGhpcyBmaWVsZCBpcyBv
bmx5IHNldCBpbiB0b29scyBpbiB0aGUgZW52aXJvbm1lbnQgZGVwZW5kZW5jaWVzIGR1cmlu
ZyB0aGUKIGV4cG9ydCBwcm9jZXNzIGlmIHRoZSBzY2hlbWEgY29udGFpbnMgYSBzZXJ2ZXIg
dXJsLiBEdXJpbmcgdGhlIGltcG9ydAogcHJvY2VzcywgaWYgdGhpcyB1cmwgaXMgcHJlc2Vu
dCBpbiB0aGUgZW52aXJvbm1lbnQgZGVwZW5kZW5jaWVzIGFuZCB0aGUKIHNjaGVtYSBoYXMg
dGhlICRlbnZfdmFyIHBsYWNlaG9sZGVyLCBpdCB3aWxsIHJlcGxhY2UgdGhlIHBsYWNlaG9s
ZGVyIGluIHRoZQogc2NoZW1hLgoKDAoFBAACBwUSAz8CCAoMCgUEAAIHARIDPwkMCgwKBQQA
AgcDEgM/DxAKDAoFBAACBwgSAz8ROQoPCggEAAIHCJwIABIDPxI4YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::OpenApiTool::OpenApiTool ===
    # Fields for OpenApiTool
    # Field: open_api_schema Type: 9 ()
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1beta.ApiAuthentication)
    # Field: tls_config Type: 11 (.google.cloud.ces.v1beta.TlsConfig)
    # Field: service_directory_config Type: 11 (.google.cloud.ces.v1beta.ServiceDirectoryConfig)
    # Field: ignore_unknown_fields Type: 8 ()
    # Field: url Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::OpenApiTool - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/open_api_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::OpenApiTool;

    my $msg = Google::Cloud::Ces::V1beta::OpenApiTool::OpenApiTool->new({
        open_api_schema => $open_api_schema,
        name => $name,
        description => $description,
        api_authentication => $api_authentication,
    });

    # Read or update a field
    my $val = $msg->open_api_schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::OpenApiTool::OpenApiTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/open_api_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::OpenApiTool::OpenApiTool

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

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::ApiAuthentication>)

Optional. Authentication information required by the API.

=item * C<< $msg->tls_config() >> / C<< $msg->tls_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::TlsConfig>)

Optional. The TLS configuration. Includes the custom server certificates
that the client will trust.

=item * C<< $msg->service_directory_config() >> / C<< $msg->service_directory_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::ServiceDirectoryConfig>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::OpenApiTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
