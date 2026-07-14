package Google::Cloud::BigQuery::V2::Project;

use strict;
use warnings;

our $VERSION = '0.05';

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
djIvYmlncXVlcnlwYjtiaWdxdWVyeXBiSrQLCgYSBA4AOQEKvAQKAQwSAw4AEjKxBCBDb3B5
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
GAA1CgkKAggBEgMYADUKWQoCBgASBBsAKgEaTSBUaGlzIHNlcnZpY2UgcHJvdmlkZXMgYWNj
ZXNzIHRvIEJpZ1F1ZXJ5IGZ1bmN0aW9uYWxpdHkgcmVsYXRlZCB0byBwcm9qZWN0cy4KCgoK
AwYAARIDGwgWCgoKAwYAAxIDHAI/CgwKBQYAA5kIEgMcAj8KCwoDBgADEgQdAiBBCg0KBQYA
A5oIEgQdAiBBCmkKBAYAAgASBCQCKQMaWyBSUEMgdG8gZ2V0IHRoZSBzZXJ2aWNlIGFjY291
bnQgZm9yIGEgcHJvamVjdCB1c2VkIGZvciBpbnRlcmFjdGlvbnMgd2l0aAogR29vZ2xlIENs
b3VkIEtNUwoKDAoFBgACAAESAyQGFwoMCgUGAAIAAhIDJBgwCgwKBQYAAgADEgMlDygKDQoF
BgACAAQSBCYEKAYKEQoJBgACAASwyrwiEgQmBCgGCjEKAgQAEgQtADABGiUgUmVxdWVzdCBv
YmplY3Qgb2YgR2V0U2VydmljZUFjY291bnQKCgoKAwQAARIDLQggCisKBAQAAgASAy8CQRoe
IFJlcXVpcmVkLiBJRCBvZiB0aGUgcHJvamVjdC4KCgwKBQQAAgAFEgMvAggKDAoFBAACAAES
Ay8JEwoMCgUEAAIAAxIDLxYXCgwKBQQAAgAIEgMvGEAKDwoIBAACAAicCAASAy8ZPwoyCgIE
ARIEMwA5ARomIFJlc3BvbnNlIG9iamVjdCBvZiBHZXRTZXJ2aWNlQWNjb3VudAoKCgoDBAEB
EgMzCCEKMQoEBAECABIDNQISGiQgVGhlIHJlc291cmNlIHR5cGUgb2YgdGhlIHJlc3BvbnNl
LgoKDAoFBAECAAUSAzUCCAoMCgUEAQIAARIDNQkNCgwKBQQBAgADEgM1EBEKMQoEBAECARID
OAITGiQgVGhlIHNlcnZpY2UgYWNjb3VudCBlbWFpbCBhZGRyZXNzLgoKDAoFBAECAQUSAzgC
CAoMCgUEAQIBARIDOAkOCgwKBQQBAgEDEgM4ERJiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::BigQuery::V2::Project::GetServiceAccountRequest ===
    # Fields for GetServiceAccountRequest
    # Field: project_id Type: 9 ()

# === Message: Google::Cloud::BigQuery::V2::Project::GetServiceAccountResponse ===
    # Fields for GetServiceAccountResponse
    # Field: kind Type: 9 ()
    # Field: email Type: 9 ()

# === Service Client: Google::Cloud::BigQuery::V2::Project::ProjectServiceClient ===
package Google::Cloud::BigQuery::V2::Project::ProjectServiceClient;

=pod

=head1 NAME

Google::Cloud::BigQuery::V2::Project::ProjectServiceClient - Client stub representing the remote ProjectService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<bigquery.googleapis.com:443>.

=head2 credentials

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
        ? Google::Cloud::BigQuery::V2::Project::GetServiceAccountRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.bigquery.v2.ProjectService',
        method         => 'GetServiceAccount',
        request        => $req,
        response_class => 'Google::Cloud::BigQuery::V2::Project::GetServiceAccountResponse',
    });
}

1;
