package Google::Cloud::Sql::V1beta4::CloudSqlIamPolicies;

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
    my $descriptor_b64 = <<'EOF';
CjVnb29nbGUvY2xvdWQvc3FsL3YxYmV0YTQvY2xvdWRfc3FsX2lhbV9wb2xpY2llcy5wcm90
bxIYZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0Ghxnb29nbGUvYXBpL2Fubm90YXRpb25zLnBy
b3RvGhdnb29nbGUvYXBpL2NsaWVudC5wcm90bzIzChVTcWxJYW1Qb2xpY2llc1NlcnZpY2Ua
GspBF3NxbGFkbWluLmdvb2dsZWFwaXMuY29tQmoKHGNvbS5nb29nbGUuY2xvdWQuc3FsLnYx
YmV0YTRCGENsb3VkU3FsSWFtUG9saWNpZXNQcm90b1ABWi5jbG91ZC5nb29nbGUuY29tL2dv
L3NxbC9hcGl2MWJldGE0L3NxbHBiO3NxbHBiSqMGCgYSBA4AHQEKvAQKAQwSAw4AEjKxBCBD
b3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBM
aWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2Ug
dGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3Ug
bWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5h
cGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFw
cGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJp
YnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBC
QVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBl
aXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3Bl
Y2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMg
dW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACEKCQoCAwASAxIAJgoJCgIDARIDEwAhCggK
AQgSAxUARQoJCgIICxIDFQBFCggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcAOQoJCgII
CBIDFwA5CggKAQgSAxgANQoJCgIIARIDGAA1CkAKAgYAEgQbAB0BGjQgU2VydmljZSBmb3Ig
cHJvdmlkaW5nIElBTSBNZXRhIEFQSXMgZm9yIENsb3VkIFNRTC4KCgoKAwYAARIDGwgdCgoK
AwYAAxIDHAI/CgwKBQYAA5kIEgMcAj9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Service Client: Google::Cloud::Sql::V1beta4::CloudSqlIamPolicies::SqlIamPoliciesServiceClient ===
package Google::Cloud::Sql::V1beta4::CloudSqlIamPolicies::SqlIamPoliciesServiceClient;

=pod

=head2 Service Client: Google::Cloud::Sql::V1beta4::CloudSqlIamPolicies::SqlIamPoliciesServiceClient

Client stub representing the remote C<SqlIamPoliciesService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<sql.googleapis.com:443>.

=head3 credentials

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

=encoding UTF-8

=head1 NAME

Google::Cloud::Sql::V1beta4::CloudSqlIamPolicies - Compiled Protocol Buffers messages for google/cloud/sql/v1beta4/cloud_sql_iam_policies.proto

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/sql/v1beta4/cloud_sql_iam_policies.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Sql::V1beta4::CloudSqlIamPolicies::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
