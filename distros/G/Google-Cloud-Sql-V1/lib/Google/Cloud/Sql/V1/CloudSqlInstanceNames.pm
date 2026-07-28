package Google::Cloud::Sql::V1::CloudSqlInstanceNames;

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
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9pbnN0YW5jZV9uYW1lcy5wcm90bxIT
Z29vZ2xlLmNsb3VkLnNxbC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29v
Z2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8y
NQoXU3FsSW5zdGFuY2VOYW1lc1NlcnZpY2UaGspBF3NxbGFkbWluLmdvb2dsZWFwaXMuY29t
QmkKF2NvbS5nb29nbGUuY2xvdWQuc3FsLnYxQiFDbG91ZFNxbEluc3RhbmNlTmFtZXNTZXJ2
aWNlUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9zcWwvYXBpdjEvc3FscGI7c3FscGJK
nQYKBhIEDgAeAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBM
aWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxp
Y2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFu
Y2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGlj
ZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0y
LjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGlu
IHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBk
aXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9S
IENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBT
ZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVy
bWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAA
HAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoICgEIEgMWAEAKCQoCCAsSAxYA
QAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYAEIKCQoCCAgSAxgAQgoICgEIEgMZADAK
CQoCCAESAxkAMAovCgIGABIEHAAeARojIENsb3VkIFNRTCBpbnN0YW5jZSBuYW1lcyBzZXJ2
aWNlLgoKCgoDBgABEgMcCB8KCgoDBgADEgMdAj8KDAoFBgADmQgSAx0CP2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Sql::V1::CloudSqlInstanceNames::SqlInstanceNamesServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlInstanceNames::SqlInstanceNamesServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlInstanceNames::SqlInstanceNamesServiceClient - Client stub representing the remote SqlInstanceNamesService service

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

Google::Cloud::Sql::V1::CloudSqlInstanceNames - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
