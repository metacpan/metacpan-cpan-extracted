package Google::Cloud::Sql::V1::CloudSqlEvents;

use strict;
use warnings;

our $VERSION = '0.11';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Api::Client };
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9ldmVudHMucHJvdG8SE2dvb2dsZS5j
bG91ZC5zcWwudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9hcGkv
Y2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
YXBpL3Jlc291cmNlLnByb3RvMi4KEFNxbEV2ZW50c1NlcnZpY2UaGspBF3NxbGFkbWluLmdv
b2dsZWFwaXMuY29tQlsKF2NvbS5nb29nbGUuY2xvdWQuc3FsLnYxQhNDbG91ZFNxbEV2ZW50
c1Byb3RvUAFaKWNsb3VkLmdvb2dsZS5jb20vZ28vc3FsL2FwaXYxL3NxbHBiO3NxbHBiSt8G
CgYSBA4AIAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGlj
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
CQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUAIwoICgEIEgMXAEAK
CQoCCAsSAxcAQAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZADQKCQoCCAgSAxkANAoI
CgEIEgMaADAKCQoCCAESAxoAMApmCgIGABIEHgAgARpaIFNlcnZpY2UgdGhhdCBleHBvc2Vz
IENsb3VkIFNRTCBldmVudCBpbmZvcm1hdGlvbi4gVGhpcwogc2VydmljZSBpcyBvbmx5IHVz
ZWQgaW50ZXJuYWxseS4KCgoKAwYAARIDHggYCgoKAwYAAxIDHwI/CgwKBQYAA5kIEgMfAj9i
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Sql::V1::CloudSqlEvents::SqlEventsServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlEvents::SqlEventsServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlEvents::SqlEventsServiceClient - Client stub representing the remote SqlEventsService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'sql.googleapis.com:443' );

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

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlEvents - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
