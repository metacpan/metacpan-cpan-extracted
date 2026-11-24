package Google::Cloud::Alloydb::V1alpha::CsqlService;

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
    eval { require Google::Api::Resource };
    eval { require Google::Cloud::Alloydb::V1alpha::CsqlResources };
    eval { require Google::Cloud::Alloydb::V1alpha::Resources };
    eval { require Google::Cloud::Alloydb::V1alpha::Service };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Ci9nb29nbGUvY2xvdWQvYWxsb3lkYi92MWFscGhhL2NzcWxfc2VydmljZS5wcm90bxIcZ29v
Z2xlLmNsb3VkLmFsbG95ZGIudjFhbHBoYRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90
bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aMWdvb2dsZS9jbG91ZC9hbGxveWRi
L3YxYWxwaGEvY3NxbF9yZXNvdXJjZXMucHJvdG8aLGdvb2dsZS9jbG91ZC9hbGxveWRiL3Yx
YWxwaGEvcmVzb3VyY2VzLnByb3RvGipnb29nbGUvY2xvdWQvYWxsb3lkYi92MWFscGhhL3Nl
cnZpY2UucHJvdG8aI2dvb2dsZS9sb25ncnVubmluZy9vcGVyYXRpb25zLnByb3RvIsYCChpS
ZXN0b3JlRnJvbUNsb3VkU1FMUmVxdWVzdBJ0ChpjbG91ZHNxbF9iYWNrdXBfcnVuX3NvdXJj
ZRhlIAEoCzI1Lmdvb2dsZS5jbG91ZC5hbGxveWRiLnYxYWxwaGEuQ2xvdWRTUUxCYWNrdXBS
dW5Tb3VyY2VIAFIXY2xvdWRzcWxCYWNrdXBSdW5Tb3VyY2USPgoGcGFyZW50GAEgASgJQibg
QQL6QSASHmFsbG95ZGIuZ29vZ2xlYXBpcy5jb20vQ2x1c3RlclIGcGFyZW50EiIKCmNsdXN0
ZXJfaWQYAiABKAlCA+BBAlIJY2x1c3RlcklkEkQKB2NsdXN0ZXIYAyABKAsyJS5nb29nbGUu
Y2xvdWQuYWxsb3lkYi52MWFscGhhLkNsdXN0ZXJCA+BBAlIHY2x1c3RlckIICgZzb3VyY2Uy
1QIKEEFsbG95REJDU1FMQWRtaW4S9AEKE1Jlc3RvcmVGcm9tQ2xvdWRTUUwSOC5nb29nbGUu
Y2xvdWQuYWxsb3lkYi52MWFscGhhLlJlc3RvcmVGcm9tQ2xvdWRTUUxSZXF1ZXN0Gh0uZ29v
Z2xlLmxvbmdydW5uaW5nLk9wZXJhdGlvbiKDAYLT5JMCSiJFL3YxYWxwaGEve3BhcmVudD1w
cm9qZWN0cy8qL2xvY2F0aW9ucy8qfS9jbHVzdGVyczpyZXN0b3JlRnJvbUNsb3VkU1FMOgEq
2kERcGFyZW50LGNsdXN0ZXJfaWTKQRwKB0NsdXN0ZXISEU9wZXJhdGlvbk1ldGFkYXRhGkrK
QRZhbGxveWRiLmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20v
YXV0aC9jbG91ZC1wbGF0Zm9ybULSAQogY29tLmdvb2dsZS5jbG91ZC5hbGxveWRiLnYxYWxw
aGFCEENTUUxTZXJ2aWNlUHJvdG9QAVo6Y2xvdWQuZ29vZ2xlLmNvbS9nby9hbGxveWRiL2Fw
aXYxYWxwaGEvYWxsb3lkYnBiO2FsbG95ZGJwYqoCHEdvb2dsZS5DbG91ZC5BbGxveURiLlYx
QWxwaGHKAhxHb29nbGVcQ2xvdWRcQWxsb3lEYlxWMWFscGhh6gIfR29vZ2xlOjpDbG91ZDo6
QWxsb3lEQjo6VjFhbHBoYUrjDgoGEgQOAE4BCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIw
MjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVy
c2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBl
eGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4g
YSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9s
aWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxh
dyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVy
IHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRI
T1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJl
c3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1
YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBM
aWNlbnNlLgoKCAoBAhIDEAAlCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkK
AgMDEgMVACMKCQoCAwQSAxYAOwoJCgIDBRIDFwA2CgkKAgMGEgMYADQKCQoCAwcSAxkALQoI
CgEIEgMbADkKCQoCCCUSAxsAOQoICgEIEgMcAFEKCQoCCAsSAxwAUQoICgEIEgMdACIKCQoC
CAoSAx0AIgoICgEIEgMeADEKCQoCCAgSAx4AMQoICgEIEgMfADkKCQoCCAESAx8AOQoICgEI
EgMgADkKCQoCCCkSAyAAOQoICgEIEgMhADgKCQoCCC0SAyEAOAo1CgIGABIEJAA2ARopIFNl
cnZpY2UgZm9yIGludGVyYWN0aW9ucyB3aXRoIENsb3VkU1FMLgoKCgoDBgABEgMkCBgKCgoD
BgADEgMlAj4KDAoFBgADmQgSAyUCPgoLCgMGAAMSBCYCJzcKDQoFBgADmggSBCYCJzcKRQoE
BgACABIEKgI1Axo3IFJlc3RvcmVzIGFuIEFsbG95REIgY2x1c3RlciBmcm9tIGEgQ2xvdWRT
UUwgcmVzb3VyY2UuCgoMCgUGAAIAARIDKgYZCgwKBQYAAgACEgMqGjQKDAoFBgACAAMSAysP
KwoNCgUGAAIABBIELAQvBgoRCgkGAAIABLDKvCISBCwELwYKDAoFBgACAAQSAzAEPwoPCggG
AAIABJsIABIDMAQ/Cg0KBQYAAgAEEgQxBDQGCg8KBwYAAgAEmQgSBDEENAYKRwoCBAASBDkA
TgEaOyBNZXNzYWdlIGZvciByZWdpc3RlcmluZyBSZXN0b3JpbmcgZnJvbSBDbG91ZFNRTCBy
ZXNvdXJjZS4KCgoKAwQAARIDOQgiCj0KBAQACAASBDsCPgMaLyBUaGUgc291cmNlIENsb3Vk
U1FMIHJlc291cmNlIHRvIHJlc3RvcmUgZnJvbS4KCgwKBQQACAABEgM7CA4KOAoEBAACABID
PQQ9GisgQ2x1c3RlciBjcmVhdGVkIGZyb20gQ2xvdWRTUUwgYmFja3VwIHJ1bi4KCgwKBQQA
AgAGEgM9BBsKDAoFBAACAAESAz0cNgoMCgUEAAIAAxIDPTk8CnsKBAQAAgESBEICRwQabSBS
ZXF1aXJlZC4gVGhlIGxvY2F0aW9uIG9mIHRoZSBuZXcgY2x1c3Rlci4gRm9yIHRoZSByZXF1
aXJlZCBmb3JtYXQsIHNlZSB0aGUKIGNvbW1lbnQgb24gQ2x1c3Rlci5uYW1lIGZpZWxkLgoK
DAoFBAACAQUSA0ICCAoMCgUEAAIBARIDQgkPCgwKBQQAAgEDEgNCEhMKDQoFBAACAQgSBEIU
RwMKDwoIBAACAQicCAASA0MEKgoPCgcEAAIBCJ8IEgREBEYFCjUKBAQAAgISA0oCQRooIFJl
cXVpcmVkLiBJRCBvZiB0aGUgcmVxdWVzdGluZyBvYmplY3QuCgoMCgUEAAICBRIDSgIICgwK
BQQAAgIBEgNKCRMKDAoFBAACAgMSA0oWFwoMCgUEAAICCBIDShhACg8KCAQAAgIInAgAEgNK
GT8KMwoEBAACAxIDTQI/GiYgUmVxdWlyZWQuIFRoZSByZXNvdXJjZSBiZWluZyBjcmVhdGVk
CgoMCgUEAAIDBhIDTQIJCgwKBQQAAgMBEgNNChEKDAoFBAACAwMSA00UFQoMCgUEAAIDCBID
TRY+Cg8KCAQAAgMInAgAEgNNFz1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1alpha::CsqlService::RestoreFromCloudSQLRequest ===
    # Fields for RestoreFromCloudSQLRequest
    # Field: cloudsql_backup_run_source Type: 11 (.google.cloud.alloydb.v1alpha.CloudSQLBackupRunSource)
    # Field: parent Type: 9 ()
    # Field: cluster_id Type: 9 ()
    # Field: cluster Type: 11 (.google.cloud.alloydb.v1alpha.Cluster)

# === Service Client: Google::Cloud::Alloydb::V1alpha::CsqlService::AlloyDBCSQLAdminClient ===
package Google::Cloud::Alloydb::V1alpha::CsqlService::AlloyDBCSQLAdminClient;

=pod

=head2 Service Client: Google::Cloud::Alloydb::V1alpha::CsqlService::AlloyDBCSQLAdminClient

Client stub representing the remote C<AlloyDBCSQLAdmin> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<alloydb.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'alloydb.googleapis.com:443' );

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

sub restore_from_cloud_s_q_l {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Alloydb::V1alpha::CsqlService::RestoreFromCloudSQLRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.alloydb.v1alpha.AlloyDBCSQLAdmin',
        method         => 'RestoreFromCloudSQL',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1alpha::CsqlService - Compiled Protocol Buffers messages for google/cloud/alloydb/v1alpha/csql_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1alpha::CsqlService;

    my $msg = Google::Cloud::Alloydb::V1alpha::CsqlService::RestoreFromCloudSQLRequest->new({
        cloudsql_backup_run_source => $cloudsql_backup_run_source,
        parent => $parent,
        cluster_id => $cluster_id,
        cluster => $cluster,
    });

    # Read or update a field
    my $val = $msg->cloudsql_backup_run_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1alpha::CsqlService::RestoreFromCloudSQLRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1alpha/csql_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1alpha::CsqlService::RestoreFromCloudSQLRequest

Message for registering Restoring from CloudSQL resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloudsql_backup_run_source() >> / C<< $msg->cloudsql_backup_run_source($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1alpha::CsqlResources::CloudSQLBackupRunSource>)

Cluster created from CloudSQL backup run.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location of the new cluster. For the required format, see the
comment on Cluster.name field.

=item * C<< $msg->cluster_id() >> / C<< $msg->cluster_id($value) >>

Type: C<String>

Required. ID of the requesting object.

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1alpha::Resources::Cluster>)

Required. The resource being created

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1alpha::CsqlService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
