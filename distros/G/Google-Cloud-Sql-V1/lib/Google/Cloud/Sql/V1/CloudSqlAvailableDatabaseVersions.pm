package Google::Cloud::Sql::V1::CloudSqlAvailableDatabaseVersions;

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
Cj9nb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9hdmFpbGFibGVfZGF0YWJhc2VfdmVy
c2lvbnMucHJvdG8SE2dvb2dsZS5jbG91ZC5zcWwudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlv
bnMucHJvdG8aF2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2Jl
aGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvMkEKI1NxbEF2YWlsYWJs
ZURhdGFiYXNlVmVyc2lvbnNTZXJ2aWNlGhrKQRdzcWxhZG1pbi5nb29nbGVhcGlzLmNvbUJu
Chdjb20uZ29vZ2xlLmNsb3VkLnNxbC52MUImQ2xvdWRTcWxBdmFpbGFibGVEYXRhYmFzZVZl
cnNpb25zUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9zcWwvYXBpdjEvc3FscGI7c3Fs
cGJK6wYKBhIEDgAgAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMK
CiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUg
IkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBs
aWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUg
TGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5T
RS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRv
IGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBp
cyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVT
IE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQu
CiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcg
cGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQIS
AxAAHAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCggKAQgS
AxcAQAoJCgIICxIDFwBACggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkARwoJCgIICBID
GQBHCggKAQgSAxoAMAoJCgIIARIDGgAwCnIKAgYAEgQeACABGmYgU2VydmljZSB0aGF0IGV4
cG9zZXMgQ2xvdWQgU1FMIGRhdGFiYXNlIHZlcnNpb25zIGluZm9ybWF0aW9uLiBUaGlzCiBz
ZXJ2aWNlIGlzIG9ubHkgdXNlZCBpbnRlcm5hbGx5LgoKCgoDBgABEgMeCCsKCgoDBgADEgMf
Aj8KDAoFBgADmQgSAx8CP2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Sql::V1::CloudSqlAvailableDatabaseVersions::SqlAvailableDatabaseVersionsServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlAvailableDatabaseVersions::SqlAvailableDatabaseVersionsServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlAvailableDatabaseVersions::SqlAvailableDatabaseVersionsServiceClient - Client stub representing the remote SqlAvailableDatabaseVersionsService service

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

Google::Cloud::Sql::V1::CloudSqlAvailableDatabaseVersions - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
