package Google::Cloud::Dataplex::V1::Content;

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
CiZnb29nbGUvY2xvdWQvZGF0YXBsZXgvdjEvY29udGVudC5wcm90bxIYZ29vZ2xlLmNsb3Vk
LmRhdGFwbGV4LnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUvYXBp
L2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90bzIsCg5Db250ZW50U2VydmljZRoaykEXZGF0YXBsZXguZ29v
Z2xlYXBpcy5jb21CaAocY29tLmdvb2dsZS5jbG91ZC5kYXRhcGxleC52MUIMQ29udGVudFBy
b3RvUAFaOGNsb3VkLmdvb2dsZS5jb20vZ28vZGF0YXBsZXgvYXBpdjEvZGF0YXBsZXhwYjtk
YXRhcGxleHBiStcGCgYSBA4AIAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAhCgkKAgMCEgMUACkKCQoCAwMSAxUA
IwoICgEIEgMXAE8KCQoCCAsSAxcATwoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAC0K
CQoCCAgSAxkALQoICgEIEgMaADUKCQoCCAESAxoANQpeCgIGABIEHgAgARpSIENvbnRlbnRT
ZXJ2aWNlIG1hbmFnZXMgTm90ZWJvb2sgYW5kIFNRTCBTY3JpcHRzIGZvciBEYXRhcGxleCBV
bml2ZXJzYWwKIENhdGFsb2cuCgoKCgMGAAESAx4IFgoKCgMGAAMSAx8CPwoMCgUGAAOZCBID
HwI/YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Dataplex::V1::Content::ContentServiceClient ===
package Google::Cloud::Dataplex::V1::Content::ContentServiceClient;

=pod

=head1 NAME

Google::Cloud::Dataplex::V1::Content::ContentServiceClient - Client stub representing the remote ContentService service

=head1 DESCRIPTION

This class acts as a local client stub for the remote gRPC service.
It delegates call dispatching to an underlying L<Google::gRPC::Client>
instance, ensuring type-safe request parsing and response mapping.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 target

The endpoint target address. Defaults to C<dataplex.googleapis.com:443>.

=head2 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'dataplex.googleapis.com:443' );

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

Google::Cloud::Dataplex::V1::Content - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
