package Google::Cloud::Bigquery::V2::Project;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    my $descriptor_b64 = <<'EOF';
CiZnb29nbGUvY2xvdWQvYmlncXVlcnkvdjIvcHJvamVjdC5wcm90bxIYZ29vZ2xlLmNsb3Vk
LmJpZ3F1ZXJ5LnYyGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBp
L2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90byI+ChhHZXRT
ZXJ2aWNlQWNjb3VudFJlcXVlc3QSIgoKcHJvamVjdF9pZBgBIAEoCUID4EECUglwcm9qZWN0
SWQiRQoZR2V0U2VydmljZUFjY291bnRSZXNwb25zZRISCgRraW5kGAEgASgJUgRraW5kEhQK
BWVtYWlsGAIgASgJUgVlbWFpbDL9AgoOUHJvamVjdFNlcnZpY2USuQEKEUdldFNlcnZpY2VB
Y2NvdW50EjIuZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5LnYyLkdldFNlcnZpY2VBY2NvdW50UmVx
dWVzdBozLmdvb2dsZS5jbG91ZC5iaWdxdWVyeS52Mi5HZXRTZXJ2aWNlQWNjb3VudFJlc3Bv
bnNlIjuC0+STAjUSMy9iaWdxdWVyeS92Mi9wcm9qZWN0cy97cHJvamVjdF9pZD0qfS9zZXJ2
aWNlQWNjb3VudBquAcpBF2JpZ3F1ZXJ5Lmdvb2dsZWFwaXMuY29t0kGQAWh0dHBzOi8vd3d3
Lmdvb2dsZWFwaXMuY29tL2F1dGgvYmlncXVlcnksaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5j
b20vYXV0aC9jbG91ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRo
L2Nsb3VkLXBsYXRmb3JtLnJlYWQtb25seUJpChxjb20uZ29vZ2xlLmNsb3VkLmJpZ3F1ZXJ5
LnYyQgxQcm9qZWN0UHJvdG9aO2Nsb3VkLmdvb2dsZS5jb20vZ28vYmlncXVlcnkvdjIvYXBp
djIvYmlncXVlcnlwYjtiaWdxdWVyeXBiSpkNCgYSBA4APAEKvAQKAQwSAw4AEjKxBCBDb3B5
cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNl
bnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhp
cyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5
IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFj
aGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxp
Y2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0
ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJ
UywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRo
ZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lm
aWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5k
ZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMC
EgMUACkKCAoBCBIDFgBSCgkKAggLEgMWAFIKCAoBCBIDFwAtCgkKAggIEgMXAC0KCAoBCBID
GAA1CgkKAggBEgMYADUKWQoCBgASBBsALQEaTSBUaGlzIHNlcnZpY2UgcHJvdmlkZXMgYWNj
ZXNzIHRvIEJpZ1F1ZXJ5IGZ1bmN0aW9uYWxpdHkgcmVsYXRlZCB0byBwcm9qZWN0cy4KCgoK
AwYAARIDGwgWCgoKAwYAAxIDHAI/CgwKBQYAA5kIEgMcAj8KCwoDBgADEgQdAiBBCg0KBQYA
A5oIEgQdAiBBCs0CCgQGAAIAEgQnAiwDGr4CIFJQQyB0byBnZXQgdGhlIHNlcnZpY2UgYWNj
b3VudCBmb3IgYSBwcm9qZWN0IHVzZWQgZm9yIGludGVyYWN0aW9ucyB3aXRoCiBHb29nbGUg
Q2xvdWQgS01TLiBSZXF1aXJlcyB0aGUgYGJpZ3F1ZXJ5LmpvYnMuY3JlYXRlYCBwZXJtaXNz
aW9uIG9uIHRoZQogcHJvamVjdCByZXNvdXJjZS4gVGhpcyBwZXJtaXNzaW9uIGlzIHJlcXVp
cmVkIHRvIGF1dGhvcml6ZSB0aGUgcmV0cmlldmFsCiBvZiB0aGUgcHJvamVjdCdzIHNlcnZp
Y2UgaWRlbnRpdHkgZm9yIHRlY2huaWNhbCBtYW5hZ2VtZW50IHRhc2tzIGxpa2UKIGVuY3J5
cHRpb24gY29uZmlndXJhdGlvbi4KCgwKBQYAAgABEgMnBhcKDAoFBgACAAISAycYMAoMCgUG
AAIAAxIDKA8oCg0KBQYAAgAEEgQpBCsGChEKCQYAAgAEsMq8IhIEKQQrBgoxCgIEABIEMAAz
ARolIFJlcXVlc3Qgb2JqZWN0IG9mIEdldFNlcnZpY2VBY2NvdW50CgoKCgMEAAESAzAIIAor
CgQEAAIAEgMyAkEaHiBSZXF1aXJlZC4gSUQgb2YgdGhlIHByb2plY3QuCgoMCgUEAAIABRID
MgIICgwKBQQAAgABEgMyCRMKDAoFBAACAAMSAzIWFwoMCgUEAAIACBIDMhhACg8KCAQAAgAI
nAgAEgMyGT8KMgoCBAESBDYAPAEaJiBSZXNwb25zZSBvYmplY3Qgb2YgR2V0U2VydmljZUFj
Y291bnQKCgoKAwQBARIDNgghCjEKBAQBAgASAzgCEhokIFRoZSByZXNvdXJjZSB0eXBlIG9m
IHRoZSByZXNwb25zZS4KCgwKBQQBAgAFEgM4AggKDAoFBAECAAESAzgJDQoMCgUEAQIAAxID
OBARCjEKBAQBAgESAzsCExokIFRoZSBzZXJ2aWNlIGFjY291bnQgZW1haWwgYWRkcmVzcy4K
CgwKBQQBAgEFEgM7AggKDAoFBAECAQESAzsJDgoMCgUEAQIBAxIDOxESYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest ===
    # Fields for GetServiceAccountRequest
    # Field: project_id Type: 9 ()

# === Message: Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse ===
    # Fields for GetServiceAccountResponse
    # Field: kind Type: 9 ()
    # Field: email Type: 9 ()

# === Service Client: Google::Cloud::Bigquery::V2::Project::ProjectServiceClient ===
package Google::Cloud::Bigquery::V2::Project::ProjectServiceClient;

=pod

=head2 Service Client: Google::Cloud::Bigquery::V2::Project::ProjectServiceClient

Client stub representing the remote C<ProjectService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'bigquery.googleapis.com:443' );

has _grpc_client => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        return Google::gRPC::Client->new(
            target     => $self->target,
            auth_token => $self->credentials->get_token(),
        );
    }
);

sub get_service_account {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.ProjectService',
        method         => 'GetServiceAccount',
        request        => $req,
        response_class => 'Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Bigquery::V2::Project - Compiled Protocol Buffers messages for google/cloud/bigquery/v2/project.proto

=head1 SYNOPSIS

    use Google::Cloud::Bigquery::V2::Project;

    my $msg = Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest->new({
        project_id => $project_id,
    });

    # Read or update a field
    my $val = $msg->project_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/bigquery/v2/project.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Bigquery::V2::Project::GetServiceAccountRequest

Request object of GetServiceAccount

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project_id() >> / C<< $msg->project_id($value) >>

Type: C<String>

Required. ID of the project.

=back

=head2 Google::Cloud::Bigquery::V2::Project::GetServiceAccountResponse

Response object of GetServiceAccount

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

The resource type of the response.

=item * C<< $msg->email() >> / C<< $msg->email($value) >>

Type: C<String>

The service account email address.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Bigquery::V2::Project::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
