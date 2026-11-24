package Google::Cloud::Ces::V1::OpenApiToolset;

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
Cipnb29nbGUvY2xvdWQvY2VzL3YxL29wZW5fYXBpX3Rvb2xzZXQucHJvdG8SE2dvb2dsZS5j
bG91ZC5jZXMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aHmdvb2dsZS9j
bG91ZC9jZXMvdjEvYXV0aC5wcm90bxogZ29vZ2xlL2Nsb3VkL2Nlcy92MS9jb21tb24ucHJv
dG8imQMKDk9wZW5BcGlUb29sc2V0EisKD29wZW5fYXBpX3NjaGVtYRgBIAEoCUID4EECUg1v
cGVuQXBpU2NoZW1hEloKEmFwaV9hdXRoZW50aWNhdGlvbhgCIAEoCzImLmdvb2dsZS5jbG91
ZC5jZXMudjEuQXBpQXV0aGVudGljYXRpb25CA+BBAVIRYXBpQXV0aGVudGljYXRpb24SQgoK
dGxzX2NvbmZpZxgDIAEoCzIeLmdvb2dsZS5jbG91ZC5jZXMudjEuVGxzQ29uZmlnQgPgQQFS
CXRsc0NvbmZpZxJqChhzZXJ2aWNlX2RpcmVjdG9yeV9jb25maWcYBCABKAsyKy5nb29nbGUu
Y2xvdWQuY2VzLnYxLlNlcnZpY2VEaXJlY3RvcnlDb25maWdCA+BBAVIWc2VydmljZURpcmVj
dG9yeUNvbmZpZxI3ChVpZ25vcmVfdW5rbm93bl9maWVsZHMYBSABKAhCA+BBAVITaWdub3Jl
VW5rbm93bkZpZWxkcxIVCgN1cmwYBiABKAlCA+BBAVIDdXJsQlsKF2NvbS5nb29nbGUuY2xv
dWQuY2VzLnYxQhNPcGVuQXBpVG9vbHNldFByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28v
Y2VzL2FwaXYxL2Nlc3BiO2Nlc3BiSo0QCgYSBA4ANwEKvAQKAQwSAw4AEjKxBCBDb3B5cmln
aHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNl
LCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBm
aWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9i
dGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUu
b3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2Fi
bGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQg
dW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywK
IFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIg
ZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMg
bGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIg
dGhlIExpY2Vuc2UuCgoICgECEgMQABwKCQoCAwASAxIAKQoJCgIDARIDEwAoCgkKAgMCEgMU
ACoKCAoBCBIDFgBACgkKAggLEgMWAEAKCAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA0
CgkKAggIEgMYADQKCAoBCBIDGQAwCgkKAggBEgMZADAKXQoCBAASBB0ANwEaUSBBIHRvb2xz
ZXQgdGhhdCBjb250YWlucyBhIGxpc3Qgb2YgdG9vbHMgdGhhdCBhcmUgZGVmaW5lZCBieSBh
biBPcGVuQVBJCiBzY2hlbWEuCgoKCgMEAAESAx0IFgo7CgQEAAIAEgMfAkYaLiBSZXF1aXJl
ZC4gVGhlIE9wZW5BUEkgc2NoZW1hIG9mIHRoZSB0b29sc2V0LgoKDAoFBAACAAUSAx8CCAoM
CgUEAAIAARIDHwkYCgwKBQQAAgADEgMfGxwKDAoFBAACAAgSAx8dRQoPCggEAAIACJwIABID
Hx5ECkkKBAQAAgESBCICIy8aOyBPcHRpb25hbC4gQXV0aGVudGljYXRpb24gaW5mb3JtYXRp
b24gcmVxdWlyZWQgYnkgdGhlIEFQSS4KCgwKBQQAAgEGEgMiAhMKDAoFBAACAQESAyIUJgoM
CgUEAAIBAxIDIikqCgwKBQQAAgEIEgMjBi4KDwoIBAACAQicCAASAyMHLQpXCgQEAAICEgMm
AkQaSiBPcHRpb25hbC4gVGhlIFRMUyBjb25maWd1cmF0aW9uLiBJbmNsdWRlcyB0aGUgY3Vz
dG9tIHNlcnZlciBjZXJ0aWZpY2F0ZXMKCgwKBQQAAgIGEgMmAgsKDAoFBAACAgESAyYMFgoM
CgUEAAICAxIDJhkaCgwKBQQAAgIIEgMmG0MKDwoIBAACAgicCAASAyYcQgo6CgQEAAIDEgQp
AiovGiwgT3B0aW9uYWwuIFNlcnZpY2UgRGlyZWN0b3J5IGNvbmZpZ3VyYXRpb24uCgoMCgUE
AAIDBhIDKQIYCgwKBQQAAgMBEgMpGTEKDAoFBAACAwMSAyk0NQoMCgUEAAIDCBIDKgYuCg8K
CAQAAgMInAgAEgMqBy0KjgEKBAQAAgQSAy4CShqAASBPcHRpb25hbC4gSWYgdHJ1ZSwgdGhl
IGFnZW50IHdpbGwgaWdub3JlIHVua25vd24gZmllbGRzIGluIHRoZSBBUEkgcmVzcG9uc2UK
IGZvciBhbGwgb3BlcmF0aW9ucyBkZWZpbmVkIGluIHRoZSBPcGVuQVBJIHNjaGVtYS4KCgwK
BQQAAgQFEgMuAgYKDAoFBAACBAESAy4HHAoMCgUEAAIEAxIDLh8gCgwKBQQAAgQIEgMuIUkK
DwoIBAACBAicCAASAy4iSAr1AgoEBAACBRIDNgI6GucCIE9wdGlvbmFsLiBUaGUgc2VydmVy
IFVSTCBvZiB0aGUgT3BlbiBBUEkgc2NoZW1hLgogVGhpcyBmaWVsZCBpcyBvbmx5IHNldCBp
biB0b29sc2V0cyBpbiB0aGUgZW52aXJvbm1lbnQgZGVwZW5kZW5jaWVzIGR1cmluZwogdGhl
IGV4cG9ydCBwcm9jZXNzIGlmIHRoZSBzY2hlbWEgY29udGFpbnMgYSBzZXJ2ZXIgdXJsLiBE
dXJpbmcgdGhlIGltcG9ydAogcHJvY2VzcywgaWYgdGhpcyB1cmwgaXMgcHJlc2VudCBpbiB0
aGUgZW52aXJvbm1lbnQgZGVwZW5kZW5jaWVzIGFuZCB0aGUKIHNjaGVtYSBoYXMgdGhlICRl
bnZfdmFyIHBsYWNlaG9sZGVyLCBpdCB3aWxsIHJlcGxhY2UgdGhlIHBsYWNlaG9sZGVyIGlu
IHRoZQogc2NoZW1hLgoKDAoFBAACBQUSAzYCCAoMCgUEAAIFARIDNgkMCgwKBQQAAgUDEgM2
DxAKDAoFBAACBQgSAzYROQoPCggEAAIFCJwIABIDNhI4YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::OpenApiToolset::OpenApiToolset ===
    # Fields for OpenApiToolset
    # Field: open_api_schema Type: 9 ()
    # Field: api_authentication Type: 11 (.google.cloud.ces.v1.ApiAuthentication)
    # Field: tls_config Type: 11 (.google.cloud.ces.v1.TlsConfig)
    # Field: service_directory_config Type: 11 (.google.cloud.ces.v1.ServiceDirectoryConfig)
    # Field: ignore_unknown_fields Type: 8 ()
    # Field: url Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::OpenApiToolset - Compiled Protocol Buffers messages for google/cloud/ces/v1/open_api_toolset.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::OpenApiToolset;

    my $msg = Google::Cloud::Ces::V1::OpenApiToolset::OpenApiToolset->new({
        open_api_schema => $open_api_schema,
        api_authentication => $api_authentication,
        tls_config => $tls_config,
        service_directory_config => $service_directory_config,
    });

    # Read or update a field
    my $val = $msg->open_api_schema();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::OpenApiToolset::OpenApiToolset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/open_api_toolset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::OpenApiToolset::OpenApiToolset

A toolset that contains a list of tools that are defined by an OpenAPI
schema.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->open_api_schema() >> / C<< $msg->open_api_schema($value) >>

Type: C<String>

Required. The OpenAPI schema of the toolset.

=item * C<< $msg->api_authentication() >> / C<< $msg->api_authentication($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::ApiAuthentication>)

Optional. Authentication information required by the API.

=item * C<< $msg->tls_config() >> / C<< $msg->tls_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::TlsConfig>)

Optional. The TLS configuration. Includes the custom server certificates

=item * C<< $msg->service_directory_config() >> / C<< $msg->service_directory_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Common::ServiceDirectoryConfig>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::OpenApiToolset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
