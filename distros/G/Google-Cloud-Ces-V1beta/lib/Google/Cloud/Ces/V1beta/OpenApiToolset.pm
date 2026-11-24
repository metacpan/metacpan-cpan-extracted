package Google::Cloud::Ces::V1beta::OpenApiToolset;

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
Ci5nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9vcGVuX2FwaV90b29sc2V0LnByb3RvEhdnb29n
bGUuY2xvdWQuY2VzLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoi
Z29vZ2xlL2Nsb3VkL2Nlcy92MWJldGEvYXV0aC5wcm90bxokZ29vZ2xlL2Nsb3VkL2Nlcy92
MWJldGEvY29tbW9uLnByb3RvIqUDCg5PcGVuQXBpVG9vbHNldBIrCg9vcGVuX2FwaV9zY2hl
bWEYASABKAlCA+BBAlINb3BlbkFwaVNjaGVtYRJeChJhcGlfYXV0aGVudGljYXRpb24YAiAB
KAsyKi5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5BcGlBdXRoZW50aWNhdGlvbkID4EEBUhFh
cGlBdXRoZW50aWNhdGlvbhJGCgp0bHNfY29uZmlnGAMgASgLMiIuZ29vZ2xlLmNsb3VkLmNl
cy52MWJldGEuVGxzQ29uZmlnQgPgQQFSCXRsc0NvbmZpZxJuChhzZXJ2aWNlX2RpcmVjdG9y
eV9jb25maWcYBCABKAsyLy5nb29nbGUuY2xvdWQuY2VzLnYxYmV0YS5TZXJ2aWNlRGlyZWN0
b3J5Q29uZmlnQgPgQQFSFnNlcnZpY2VEaXJlY3RvcnlDb25maWcSNwoVaWdub3JlX3Vua25v
d25fZmllbGRzGAUgASgIQgPgQQFSE2lnbm9yZVVua25vd25GaWVsZHMSFQoDdXJsGAYgASgJ
QgPgQQFSA3VybEJjChtjb20uZ29vZ2xlLmNsb3VkLmNlcy52MWJldGFCE09wZW5BcGlUb29s
c2V0UHJvdG9QAVotY2xvdWQuZ29vZ2xlLmNvbS9nby9jZXMvYXBpdjFiZXRhL2Nlc3BiO2Nl
c3BiSo0QCgYSBA4ANwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExD
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
EgMQACAKCQoCAwASAxIAKQoJCgIDARIDEwAsCgkKAgMCEgMUAC4KCAoBCBIDFgBECgkKAggL
EgMWAEQKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA0CgkKAggIEgMYADQKCAoBCBID
GQA0CgkKAggBEgMZADQKXQoCBAASBB0ANwEaUSBBIHRvb2xzZXQgdGhhdCBjb250YWlucyBh
IGxpc3Qgb2YgdG9vbHMgdGhhdCBhcmUgZGVmaW5lZCBieSBhbiBPcGVuQVBJCiBzY2hlbWEu
CgoKCgMEAAESAx0IFgo7CgQEAAIAEgMfAkYaLiBSZXF1aXJlZC4gVGhlIE9wZW5BUEkgc2No
ZW1hIG9mIHRoZSB0b29sc2V0LgoKDAoFBAACAAUSAx8CCAoMCgUEAAIAARIDHwkYCgwKBQQA
AgADEgMfGxwKDAoFBAACAAgSAx8dRQoPCggEAAIACJwIABIDHx5ECkkKBAQAAgESBCICIy8a
OyBPcHRpb25hbC4gQXV0aGVudGljYXRpb24gaW5mb3JtYXRpb24gcmVxdWlyZWQgYnkgdGhl
IEFQSS4KCgwKBQQAAgEGEgMiAhMKDAoFBAACAQESAyIUJgoMCgUEAAIBAxIDIikqCgwKBQQA
AgEIEgMjBi4KDwoIBAACAQicCAASAyMHLQpXCgQEAAICEgMmAkQaSiBPcHRpb25hbC4gVGhl
IFRMUyBjb25maWd1cmF0aW9uLiBJbmNsdWRlcyB0aGUgY3VzdG9tIHNlcnZlciBjZXJ0aWZp
Y2F0ZXMKCgwKBQQAAgIGEgMmAgsKDAoFBAACAgESAyYMFgoMCgUEAAICAxIDJhkaCgwKBQQA
AgIIEgMmG0MKDwoIBAACAgicCAASAyYcQgo6CgQEAAIDEgQpAiovGiwgT3B0aW9uYWwuIFNl
cnZpY2UgRGlyZWN0b3J5IGNvbmZpZ3VyYXRpb24uCgoMCgUEAAIDBhIDKQIYCgwKBQQAAgMB
EgMpGTEKDAoFBAACAwMSAyk0NQoMCgUEAAIDCBIDKgYuCg8KCAQAAgMInAgAEgMqBy0KjgEK
BAQAAgQSAy4CShqAASBPcHRpb25hbC4gSWYgdHJ1ZSwgdGhlIGFnZW50IHdpbGwgaWdub3Jl
IHVua25vd24gZmllbGRzIGluIHRoZSBBUEkgcmVzcG9uc2UKIGZvciBhbGwgb3BlcmF0aW9u
cyBkZWZpbmVkIGluIHRoZSBPcGVuQVBJIHNjaGVtYS4KCgwKBQQAAgQFEgMuAgYKDAoFBAAC
BAESAy4HHAoMCgUEAAIEAxIDLh8gCgwKBQQAAgQIEgMuIUkKDwoIBAACBAicCAASAy4iSAr1
AgoEBAACBRIDNgI6GucCIE9wdGlvbmFsLiBUaGUgc2VydmVyIFVSTCBvZiB0aGUgT3BlbiBB
UEkgc2NoZW1hLgogVGhpcyBmaWVsZCBpcyBvbmx5IHNldCBpbiB0b29sc2V0cyBpbiB0aGUg
ZW52aXJvbm1lbnQgZGVwZW5kZW5jaWVzIGR1cmluZwogdGhlIGV4cG9ydCBwcm9jZXNzIGlm
IHRoZSBzY2hlbWEgY29udGFpbnMgYSBzZXJ2ZXIgdXJsLiBEdXJpbmcgdGhlIGltcG9ydAog
cHJvY2VzcywgaWYgdGhpcyB1cmwgaXMgcHJlc2VudCBpbiB0aGUgZW52aXJvbm1lbnQgZGVw
ZW5kZW5jaWVzIGFuZCB0aGUKIHNjaGVtYSBoYXMgdGhlICRlbnZfdmFyIHBsYWNlaG9sZGVy
LCBpdCB3aWxsIHJlcGxhY2UgdGhlIHBsYWNlaG9sZGVyIGluIHRoZQogc2NoZW1hLgoKDAoF
BAACBQUSAzYCCAoMCgUEAAIFARIDNgkMCgwKBQQAAgUDEgM2DxAKDAoFBAACBQgSAzYROQoP
CggEAAIFCJwIABIDNhI4YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::OpenApiToolset::OpenApiToolset ===
    # Fields for OpenApiToolset
    # Field: open_api_schema Type: 9 ()
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1beta.ApiAuthentication)
    # Field: tls_config Type: 11 (.google.cloud.ces.v1beta.TlsConfig)
    # Field: service_directory_config Type: 11 (.google.cloud.ces.v1beta.ServiceDirectoryConfig)
    # Field: ignore_unknown_fields Type: 8 ()
    # Field: url Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::OpenApiToolset - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/open_api_toolset.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::OpenApiToolset;

    my $msg = Google::Cloud::Ces::V1beta::OpenApiToolset::OpenApiToolset->new({
        open_api_schema => $open_api_schema,
        api_authentication => $api_authentication,
        tls_config => $tls_config,
        service_directory_config => $service_directory_config,
    });

    # Read or update a field
    my $val = $msg->open_api_schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::OpenApiToolset::OpenApiToolset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/open_api_toolset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::OpenApiToolset::OpenApiToolset

A toolset that contains a list of tools that are defined by an OpenAPI
schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->open_api_schema() >> / C<< $msg->open_api_schema($value) >>

Type: C<String>

Required. The OpenAPI schema of the toolset.

=item * C<< $msg->api_authentication() >> / C<< $msg->api_authentication($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::ApiAuthentication>)

Optional. Authentication information required by the API.

=item * C<< $msg->tls_config() >> / C<< $msg->tls_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::TlsConfig>)

Optional. The TLS configuration. Includes the custom server certificates

=item * C<< $msg->service_directory_config() >> / C<< $msg->service_directory_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Common::ServiceDirectoryConfig>)

Optional. Service Directory configuration.

=item * C<< $msg->ignore_unknown_fields() >> / C<< $msg->ignore_unknown_fields($value) >>

Type: C<Bool>

Optional. If true, the agent will ignore unknown fields in the API response
for all operations defined in the OpenAPI schema.

=item * C<< $msg->url() >> / C<< $msg->url($value) >>

Type: C<String>

Optional. The server URL of the Open API schema.
This field is only set in toolsets in the environment dependencies during
the export process if the schema contains a server url. During the import
process, if this url is present in the environment dependencies and the
schema has the $env_var placeholder, it will replace the placeholder in the
schema.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::OpenApiToolset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
