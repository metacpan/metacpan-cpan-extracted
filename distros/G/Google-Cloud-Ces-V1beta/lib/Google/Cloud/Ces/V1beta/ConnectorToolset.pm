package Google::Cloud::Ces::V1beta::ConnectorToolset;

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
    eval { require Google::Cloud::Ces::V1beta::ConnectorTool };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9jb25uZWN0b3JfdG9vbHNldC5wcm90bxIXZ29v
Z2xlLmNsb3VkLmNlcy52MWJldGEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8a
Imdvb2dsZS9jbG91ZC9jZXMvdjFiZXRhL2F1dGgucHJvdG8aLGdvb2dsZS9jbG91ZC9jZXMv
djFiZXRhL2Nvbm5lY3Rvcl90b29sLnByb3RvItwBChBDb25uZWN0b3JUb29sc2V0EiMKCmNv
bm5lY3Rpb24YASABKAlCA+BBAlIKY29ubmVjdGlvbhJQCgthdXRoX2NvbmZpZxgCIAEoCzIq
Lmdvb2dsZS5jbG91ZC5jZXMudjFiZXRhLkVuZFVzZXJBdXRoQ29uZmlnQgPgQQFSCmF1dGhD
b25maWcSUQoRY29ubmVjdG9yX2FjdGlvbnMYAyADKAsyHy5nb29nbGUuY2xvdWQuY2VzLnYx
YmV0YS5BY3Rpb25CA+BBAlIQY29ubmVjdG9yQWN0aW9uc0JlChtjb20uZ29vZ2xlLmNsb3Vk
LmNlcy52MWJldGFCFUNvbm5lY3RvclRvb2xzZXRQcm90b1ABWi1jbG91ZC5nb29nbGUuY29t
L2dvL2Nlcy9hcGl2MWJldGEvY2VzcGI7Y2VzcGJKyA4KBhIEDgAxAQq8BAoBDBIDDgASMrEE
IENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hl
IExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVz
ZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlv
dSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3
LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkg
YXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0
cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMi
IEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQs
IGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBz
cGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9u
cyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAIAoJCgIDABIDEgApCgkKAgMBEgMTACwK
CQoCAwISAxQANgoICgEIEgMWAEQKCQoCCAsSAxYARAoICgEIEgMXACIKCQoCCAoSAxcAIgoI
CgEIEgMYADYKCQoCCAgSAxgANgoICgEIEgMZADQKCQoCCAESAxkANApXCgIEABIEHAAxARpL
IEEgdG9vbHNldCB0aGF0IGdlbmVyYXRlcyB0b29scyBmcm9tIGFuIEludGVncmF0aW9uIENv
bm5lY3RvcnMgQ29ubmVjdGlvbi4KCgoKAwQAARIDHAgYCrMBCgQEAAIAEgMhAkEapQEgUmVx
dWlyZWQuIFRoZSBmdWxsIHJlc291cmNlIG5hbWUgb2YgdGhlIHJlZmVyZW5jZWQgSW50ZWdy
YXRpb24gQ29ubmVjdG9ycwogQ29ubmVjdGlvbi4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJv
amVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vY29ubmVjdGlvbnMve2Nvbm5lY3Rpb259YAoK
DAoFBAACAAUSAyECCAoMCgUEAAIAARIDIQkTCgwKBQQAAgADEgMhFhcKDAoFBAACAAgSAyEY
QAoPCggEAAIACJwIABIDIRk/CpgECgQEAAIBEgMrAk0aigQgT3B0aW9uYWwuIENvbmZpZ3Vy
ZXMgaG93IGF1dGhlbnRpY2F0aW9uIGlzIGhhbmRsZWQgaW4gSW50ZWdyYXRpb24KIENvbm5l
Y3RvcnMuIEJ5IGRlZmF1bHQsIGFuIGFkbWluIGF1dGhlbnRpY2F0aW9uIGlzIHBhc3NlZCBp
biB0aGUKIEludGVncmF0aW9uIENvbm5lY3RvcnMgQVBJIHJlcXVlc3RzLiBZb3UgY2FuIG92
ZXJyaWRlIGl0IHdpdGggYSBkaWZmZXJlbnQKIGVuZC11c2VyIGF1dGhlbnRpY2F0aW9uIGNv
bmZpZy4KICoqTm90ZSoqOiBUaGUgQ29ubmVjdGlvbiBtdXN0IGhhdmUgYXV0aGVudGljYXRp
b24gb3ZlcnJpZGUgZW5hYmxlZCBpbgogb3JkZXIgdG8gc3BlY2lmeSBhbiBFVUMgY29uZmln
dXJhdGlvbiBoZXJlIC0gb3RoZXJ3aXNlLCB0aGUgVG9vbHNldAogY3JlYXRpb24gd2lsbCBm
YWlsLiBTZWU6CiBodHRwczovL2Nsb3VkLmdvb2dsZS5jb20vYXBwbGljYXRpb24taW50ZWdy
YXRpb24vZG9jcy9jb25maWd1cmUtY29ubmVjdG9ycy10YXNrI2NvbmZpZ3VyZS1hdXRoZW50
aWNhdGlvbi1vdmVycmlkZQoKDAoFBAACAQYSAysCEwoMCgUEAAIBARIDKxQfCgwKBQQAAgED
EgMrIiMKDAoFBAACAQgSAyskTAoPCggEAAIBCJwIABIDKyVLCmEKBAQAAgISBC8CMC8aUyBS
ZXF1aXJlZC4gVGhlIGxpc3Qgb2YgY29ubmVjdG9yIGFjdGlvbnMvZW50aXR5IG9wZXJhdGlv
bnMgdG8gZ2VuZXJhdGUgdG9vbHMKIGZvci4KCgwKBQQAAgIEEgMvAgoKDAoFBAACAgYSAy8L
EQoMCgUEAAICARIDLxIjCgwKBQQAAgIDEgMvJicKDAoFBAACAggSAzAGLgoPCggEAAICCJwI
ABIDMActYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::ConnectorToolset::ConnectorToolset ===
    # Fields for ConnectorToolset
    # Field: connection Type: 9 ()
    # Field: auth_config Type: 11 (.google.cloud.ces.v1beta.EndUserAuthConfig)
    # Field: connector_actions Type: 11 (.google.cloud.ces.v1beta.Action)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::ConnectorToolset - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/connector_toolset.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::ConnectorToolset;

    my $msg = Google::Cloud::Ces::V1beta::ConnectorToolset::ConnectorToolset->new({
        connection => $connection,
        auth_config => $auth_config,
        connector_actions => $connector_actions,
    });

    # Read or update a field
    my $val = $msg->connection();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::ConnectorToolset::ConnectorToolset->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/connector_toolset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::ConnectorToolset::ConnectorToolset

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

Type: C<Message> (L<Google::Cloud::Ces::V1beta::Auth::EndUserAuthConfig>)

Optional. Configures how authentication is handled in Integration
Connectors. By default, an admin authentication is passed in the
Integration Connectors API requests. You can override it with a different
end-user authentication config.
B<Note>: The Connection must have authentication override enabled in
order to specify an EUC configuration here - otherwise, the Toolset
creation will fail. See:
https://cloud.google.com/application-integration/docs/configure-connectors-task#configure-authentication-override

=item * C<< $msg->connector_actions() >> / C<< $msg->connector_actions($value) >>

Type: C<Message> (L<Google::Cloud::Ces::V1beta::ConnectorTool::Action>)

Required. The list of connector actions/entity operations to generate tools
for.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::ConnectorToolset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
