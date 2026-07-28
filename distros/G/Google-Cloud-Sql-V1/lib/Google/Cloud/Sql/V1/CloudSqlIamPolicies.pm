package Google::Cloud::Sql::V1::CloudSqlIamPolicies;

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
    my $descriptor_b64 = <<'EOF';
CjBnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9pYW1fcG9saWNpZXMucHJvdG8SE2dv
b2dsZS5jbG91ZC5zcWwudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2ds
ZS9hcGkvY2xpZW50LnByb3RvMjMKFVNxbElhbVBvbGljaWVzU2VydmljZRoaykEXc3FsYWRt
aW4uZ29vZ2xlYXBpcy5jb21CYAoXY29tLmdvb2dsZS5jbG91ZC5zcWwudjFCGENsb3VkU3Fs
SWFtUG9saWNpZXNQcm90b1ABWiljbG91ZC5nb29nbGUuY29tL2dvL3NxbC9hcGl2MS9zcWxw
YjtzcWxwYkqjBgoGEgQOAB0BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xl
IExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAg
KHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4g
Y29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9m
IHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9M
SUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3Jl
ZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNl
bnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJB
TlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1w
bGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVy
bmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoK
CAoBAhIDEAAcCgkKAgMAEgMSACYKCQoCAwESAxMAIQoICgEIEgMVAEAKCQoCCAsSAxUAQAoI
CgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMXADkKCQoCCAgSAxcAOQoICgEIEgMYADAKCQoC
CAESAxgAMApACgIGABIEGwAdARo0IFNlcnZpY2UgZm9yIHByb3ZpZGluZyBJQU0gTWV0YSBB
UElzIGZvciBDbG91ZCBTUUwuCgoKCgMGAAESAxsIHQoKCgMGAAMSAxwCPwoMCgUGAAOZCBID
HAI/YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Sql::V1::CloudSqlIamPolicies::SqlIamPoliciesServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlIamPolicies::SqlIamPoliciesServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlIamPolicies::SqlIamPoliciesServiceClient - Client stub representing the remote SqlIamPoliciesService service

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

Google::Cloud::Sql::V1::CloudSqlIamPolicies - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
