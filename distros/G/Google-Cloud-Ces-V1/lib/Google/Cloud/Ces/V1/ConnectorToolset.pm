package Google::Cloud::Ces::V1::ConnectorToolset;

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
    eval { require Google::Cloud::Ces::V1::ConnectorTool };
    my $descriptor_b64 = <<'EOF';
Citnb29nbGUvY2xvdWQvY2VzL3YxL2Nvbm5lY3Rvcl90b29sc2V0LnByb3RvEhNnb29nbGUu
Y2xvdWQuY2VzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGh5nb29nbGUv
Y2xvdWQvY2VzL3YxL2F1dGgucHJvdG8aKGdvb2dsZS9jbG91ZC9jZXMvdjEvY29ubmVjdG9y
X3Rvb2wucHJvdG8i1AEKEENvbm5lY3RvclRvb2xzZXQSIwoKY29ubmVjdGlvbhgBIAEoCUID
4EECUgpjb25uZWN0aW9uEkwKC2F1dGhfY29uZmlnGAIgASgLMiYuZ29vZ2xlLmNsb3VkLmNl
cy52MS5FbmRVc2VyQXV0aENvbmZpZ0ID4EEBUgphdXRoQ29uZmlnEk0KEWNvbm5lY3Rvcl9h
Y3Rpb25zGAMgAygLMhsuZ29vZ2xlLmNsb3VkLmNlcy52MS5BY3Rpb25CA+BBAlIQY29ubmVj
dG9yQWN0aW9uc0JdChdjb20uZ29vZ2xlLmNsb3VkLmNlcy52MUIVQ29ubmVjdG9yVG9vbHNl
dFByb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vY2VzL2FwaXYxL2Nlc3BiO2Nlc3BiSsgO
CgYSBA4AMQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
ZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNl
bnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNl
IHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vu
c2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4w
CgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3
cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlz
dHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBD
T05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2Vl
IHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1p
c3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQABwK
CQoCAwASAxIAKQoJCgIDARIDEwAoCgkKAgMCEgMUADIKCAoBCBIDFgBACgkKAggLEgMWAEAK
CAoBCBIDFwAiCgkKAggKEgMXACIKCAoBCBIDGAA2CgkKAggIEgMYADYKCAoBCBIDGQAwCgkK
AggBEgMZADAKVwoCBAASBBwAMQEaSyBBIHRvb2xzZXQgdGhhdCBnZW5lcmF0ZXMgdG9vbHMg
ZnJvbSBhbiBJbnRlZ3JhdGlvbiBDb25uZWN0b3JzIENvbm5lY3Rpb24uCgoKCgMEAAESAxwI
GAqzAQoEBAACABIDIQJBGqUBIFJlcXVpcmVkLiBUaGUgZnVsbCByZXNvdXJjZSBuYW1lIG9m
IHRoZSByZWZlcmVuY2VkIEludGVncmF0aW9uIENvbm5lY3RvcnMKIENvbm5lY3Rpb24uCiBG
b3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2Nvbm5l
Y3Rpb25zL3tjb25uZWN0aW9ufWAKCgwKBQQAAgAFEgMhAggKDAoFBAACAAESAyEJEwoMCgUE
AAIAAxIDIRYXCgwKBQQAAgAIEgMhGEAKDwoIBAACAAicCAASAyEZPwqYBAoEBAACARIDKwJN
GooEIE9wdGlvbmFsLiBDb25maWd1cmVzIGhvdyBhdXRoZW50aWNhdGlvbiBpcyBoYW5kbGVk
IGluIEludGVncmF0aW9uCiBDb25uZWN0b3JzLiBCeSBkZWZhdWx0LCBhbiBhZG1pbiBhdXRo
ZW50aWNhdGlvbiBpcyBwYXNzZWQgaW4gdGhlCiBJbnRlZ3JhdGlvbiBDb25uZWN0b3JzIEFQ
SSByZXF1ZXN0cy4gWW91IGNhbiBvdmVycmlkZSBpdCB3aXRoIGEgZGlmZmVyZW50CiBlbmQt
dXNlciBhdXRoZW50aWNhdGlvbiBjb25maWcuCiAqKk5vdGUqKjogVGhlIENvbm5lY3Rpb24g
bXVzdCBoYXZlIGF1dGhlbnRpY2F0aW9uIG92ZXJyaWRlIGVuYWJsZWQgaW4KIG9yZGVyIHRv
IHNwZWNpZnkgYW4gRVVDIGNvbmZpZ3VyYXRpb24gaGVyZSAtIG90aGVyd2lzZSwgdGhlIFRv
b2xzZXQKIGNyZWF0aW9uIHdpbGwgZmFpbC4gU2VlOgogaHR0cHM6Ly9jbG91ZC5nb29nbGUu
Y29tL2FwcGxpY2F0aW9uLWludGVncmF0aW9uL2RvY3MvY29uZmlndXJlLWNvbm5lY3RvcnMt
dGFzayNjb25maWd1cmUtYXV0aGVudGljYXRpb24tb3ZlcnJpZGUKCgwKBQQAAgEGEgMrAhMK
DAoFBAACAQESAysUHwoMCgUEAAIBAxIDKyIjCgwKBQQAAgEIEgMrJEwKDwoIBAACAQicCAAS
AyslSwphCgQEAAICEgQvAjAvGlMgUmVxdWlyZWQuIFRoZSBsaXN0IG9mIGNvbm5lY3RvciBh
Y3Rpb25zL2VudGl0eSBvcGVyYXRpb25zIHRvIGdlbmVyYXRlIHRvb2xzCiBmb3IuCgoMCgUE
AAICBBIDLwIKCgwKBQQAAgIGEgMvCxEKDAoFBAACAgESAy8SIwoMCgUEAAICAxIDLyYnCgwK
BQQAAgIIEgMwBi4KDwoIBAACAgicCAASAzAHLWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::ConnectorToolset::ConnectorToolset ===
    # Fields for ConnectorToolset
    # Field: connection Type: 9 ()
    # Field: auth_config Type: 11 (.google.cloud.ces.v1.EndUserAuthConfig)
    # Field: connector_actions Type: 11 (.google.cloud.ces.v1.Action)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::ConnectorToolset - Compiled Protocol Buffers messages for google/cloud/ces/v1/connector_toolset.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::ConnectorToolset;

    my $msg = Google::Cloud::Ces::V1::ConnectorToolset::ConnectorToolset->new({
        connection => $connection,
        auth_config => $auth_config,
        connector_actions => $connector_actions,
    });

    # Read or update a field
    my $val = $msg->connection();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::ConnectorToolset::ConnectorToolset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/connector_toolset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::ConnectorToolset::ConnectorToolset

A toolset that generates tools from an Integration Connectors Connection.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connection() >> / C<< $msg->connection($value) >>

Type: C<String>

Required. The full resource name of the referenced Integration Connectors
Connection.
Format:
`projects/{project}/locations/{location}/connections/{connection}`

=item * C<< $msg->auth_config() >> / C<< $msg->auth_config($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::Auth::EndUserAuthConfig>)

Optional. Configures how authentication is handled in Integration
Connectors. By default, an admin authentication is passed in the
Integration Connectors API requests. You can override it with a different
end-user authentication config.
B<Note>: The Connection must have authentication override enabled in
order to specify an EUC configuration here - otherwise, the Toolset
creation will fail. See:
https://cloud.google.com/application-integration/docs/configure-connectors-task#configure-authentication-override

=item * C<< $msg->connector_actions() >> / C<< $msg->connector_actions($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1::ConnectorTool::Action>)

Required. The list of connector actions/entity operations to generate tools
for.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::ConnectorToolset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
