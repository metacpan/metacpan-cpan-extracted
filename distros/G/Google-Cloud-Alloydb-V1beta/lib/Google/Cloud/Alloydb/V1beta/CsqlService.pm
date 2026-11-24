package Google::Cloud::Alloydb::V1beta::CsqlService;

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
    eval { require Google::Cloud::Alloydb::V1beta::CsqlResources };
    eval { require Google::Cloud::Alloydb::V1beta::Resources };
    eval { require Google::Cloud::Alloydb::V1beta::Service };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvYWxsb3lkYi92MWJldGEvY3NxbF9zZXJ2aWNlLnByb3RvEhtnb29n
bGUuY2xvdWQuYWxsb3lkYi52MWJldGEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8a
F2dvb2dsZS9hcGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGjBnb29nbGUvY2xvdWQvYWxsb3lkYi92
MWJldGEvY3NxbF9yZXNvdXJjZXMucHJvdG8aK2dvb2dsZS9jbG91ZC9hbGxveWRiL3YxYmV0
YS9yZXNvdXJjZXMucHJvdG8aKWdvb2dsZS9jbG91ZC9hbGxveWRiL3YxYmV0YS9zZXJ2aWNl
LnByb3RvGiNnb29nbGUvbG9uZ3J1bm5pbmcvb3BlcmF0aW9ucy5wcm90byLEAgoaUmVzdG9y
ZUZyb21DbG91ZFNRTFJlcXVlc3QScwoaY2xvdWRzcWxfYmFja3VwX3J1bl9zb3VyY2UYZSAB
KAsyNC5nb29nbGUuY2xvdWQuYWxsb3lkYi52MWJldGEuQ2xvdWRTUUxCYWNrdXBSdW5Tb3Vy
Y2VIAFIXY2xvdWRzcWxCYWNrdXBSdW5Tb3VyY2USPgoGcGFyZW50GAEgASgJQibgQQL6QSAS
HmFsbG95ZGIuZ29vZ2xlYXBpcy5jb20vQ2x1c3RlclIGcGFyZW50EiIKCmNsdXN0ZXJfaWQY
AiABKAlCA+BBAlIJY2x1c3RlcklkEkMKB2NsdXN0ZXIYAyABKAsyJC5nb29nbGUuY2xvdWQu
YWxsb3lkYi52MWJldGEuQ2x1c3RlckID4EECUgdjbHVzdGVyQggKBnNvdXJjZTLTAgoQQWxs
b3lEQkNTUUxBZG1pbhLyAQoTUmVzdG9yZUZyb21DbG91ZFNRTBI3Lmdvb2dsZS5jbG91ZC5h
bGxveWRiLnYxYmV0YS5SZXN0b3JlRnJvbUNsb3VkU1FMUmVxdWVzdBodLmdvb2dsZS5sb25n
cnVubmluZy5PcGVyYXRpb24iggGC0+STAkkiRC92MWJldGEve3BhcmVudD1wcm9qZWN0cy8q
L2xvY2F0aW9ucy8qfS9jbHVzdGVyczpyZXN0b3JlRnJvbUNsb3VkU1FMOgEq2kERcGFyZW50
LGNsdXN0ZXJfaWTKQRwKB0NsdXN0ZXISEU9wZXJhdGlvbk1ldGFkYXRhGkrKQRZhbGxveWRi
Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybULNAQofY29tLmdvb2dsZS5jbG91ZC5hbGxveWRiLnYxYmV0YUIQQ1NRTFNl
cnZpY2VQcm90b1ABWjljbG91ZC5nb29nbGUuY29tL2dvL2FsbG95ZGIvYXBpdjFiZXRhL2Fs
bG95ZGJwYjthbGxveWRicGKqAhtHb29nbGUuQ2xvdWQuQWxsb3lEYi5WMUJldGHKAhtHb29n
bGVcQ2xvdWRcQWxsb3lEYlxWMWJldGHqAh5Hb29nbGU6OkNsb3VkOjpBbGxveURCOjpWMWJl
dGFK4w4KBhIEDgBOAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMK
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
AxAAJAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgME
EgMWADoKCQoCAwUSAxcANQoJCgIDBhIDGAAzCgkKAgMHEgMZAC0KCAoBCBIDGwA4CgkKAggl
EgMbADgKCAoBCBIDHABQCgkKAggLEgMcAFAKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBID
HgAxCgkKAggIEgMeADEKCAoBCBIDHwA4CgkKAggBEgMfADgKCAoBCBIDIAA4CgkKAggpEgMg
ADgKCAoBCBIDIQA3CgkKAggtEgMhADcKNQoCBgASBCQANgEaKSBTZXJ2aWNlIGZvciBpbnRl
cmFjdGlvbnMgd2l0aCBDbG91ZFNRTC4KCgoKAwYAARIDJAgYCgoKAwYAAxIDJQI+CgwKBQYA
A5kIEgMlAj4KCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3CkUKBAYAAgASBCoCNQMaNyBS
ZXN0b3JlcyBhbiBBbGxveURCIGNsdXN0ZXIgZnJvbSBhIENsb3VkU1FMIHJlc291cmNlLgoK
DAoFBgACAAESAyoGGQoMCgUGAAIAAhIDKho0CgwKBQYAAgADEgMrDysKDQoFBgACAAQSBCwE
LwYKEQoJBgACAASwyrwiEgQsBC8GCgwKBQYAAgAEEgMwBD8KDwoIBgACAASbCAASAzAEPwoN
CgUGAAIABBIEMQQ0BgoPCgcGAAIABJkIEgQxBDQGCkcKAgQAEgQ5AE4BGjsgTWVzc2FnZSBm
b3IgcmVnaXN0ZXJpbmcgUmVzdG9yaW5nIGZyb20gQ2xvdWRTUUwgcmVzb3VyY2UuCgoKCgME
AAESAzkIIgo9CgQEAAgAEgQ7Aj4DGi8gVGhlIHNvdXJjZSBDbG91ZFNRTCByZXNvdXJjZSB0
byByZXN0b3JlIGZyb20uCgoMCgUEAAgAARIDOwgOCjgKBAQAAgASAz0EPRorIENsdXN0ZXIg
Y3JlYXRlZCBmcm9tIENsb3VkU1FMIGJhY2t1cCBydW4uCgoMCgUEAAIABhIDPQQbCgwKBQQA
AgABEgM9HDYKDAoFBAACAAMSAz05PAp7CgQEAAIBEgRCAkcEGm0gUmVxdWlyZWQuIFRoZSBs
b2NhdGlvbiBvZiB0aGUgbmV3IGNsdXN0ZXIuIEZvciB0aGUgcmVxdWlyZWQgZm9ybWF0LCBz
ZWUgdGhlCiBjb21tZW50IG9uIENsdXN0ZXIubmFtZSBmaWVsZC4KCgwKBQQAAgEFEgNCAggK
DAoFBAACAQESA0IJDwoMCgUEAAIBAxIDQhITCg0KBQQAAgEIEgRCFEcDCg8KCAQAAgEInAgA
EgNDBCoKDwoHBAACAQifCBIERARGBQo1CgQEAAICEgNKAkEaKCBSZXF1aXJlZC4gSUQgb2Yg
dGhlIHJlcXVlc3Rpbmcgb2JqZWN0LgoKDAoFBAACAgUSA0oCCAoMCgUEAAICARIDSgkTCgwK
BQQAAgIDEgNKFhcKDAoFBAACAggSA0oYQAoPCggEAAICCJwIABIDShk/CjMKBAQAAgMSA00C
PxomIFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgYmVpbmcgY3JlYXRlZAoKDAoFBAACAwYSA00C
CQoMCgUEAAIDARIDTQoRCgwKBQQAAgMDEgNNFBUKDAoFBAACAwgSA00WPgoPCggEAAIDCJwI
ABIDTRc9YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1beta::CsqlService::RestoreFromCloudSQLRequest ===
    # Fields for RestoreFromCloudSQLRequest
    # Field: cloudsql_backup_run_source Type: 11 (.google.cloud.alloydb.v1beta.CloudSQLBackupRunSource)
    # Field: parent Type: 9 ()
    # Field: cluster_id Type: 9 ()
    # Field: cluster Type: 11 (.google.cloud.alloydb.v1beta.Cluster)

# === Service Client: Google::Cloud::Alloydb::V1beta::CsqlService::AlloyDBCSQLAdminClient ===
package Google::Cloud::Alloydb::V1beta::CsqlService::AlloyDBCSQLAdminClient;

=pod

=head2 Service Client: Google::Cloud::Alloydb::V1beta::CsqlService::AlloyDBCSQLAdminClient

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
        ? Google::Cloud::Alloydb::V1beta::CsqlService::RestoreFromCloudSQLRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.alloydb.v1beta.AlloyDBCSQLAdmin',
        method         => 'RestoreFromCloudSQL',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1beta::CsqlService - Compiled Protocol Buffers messages for google/cloud/alloydb/v1beta/csql_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1beta::CsqlService;

    my $msg = Google::Cloud::Alloydb::V1beta::CsqlService::RestoreFromCloudSQLRequest->new({
        cloudsql_backup_run_source => $cloudsql_backup_run_source,
        parent => $parent,
        cluster_id => $cluster_id,
        cluster => $cluster,
    });

    # Read or update a field
    my $val = $msg->cloudsql_backup_run_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1beta::CsqlService::RestoreFromCloudSQLRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1beta/csql_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1beta::CsqlService::RestoreFromCloudSQLRequest

Message for registering Restoring from CloudSQL resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloudsql_backup_run_source() >> / C<< $msg->cloudsql_backup_run_source($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1beta::CsqlResources::CloudSQLBackupRunSource>)

Cluster created from CloudSQL backup run.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location of the new cluster. For the required format, see the
comment on Cluster.name field.

=item * C<< $msg->cluster_id() >> / C<< $msg->cluster_id($value) >>

Type: C<String>

Required. ID of the requesting object.

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1beta::Resources::Cluster>)

Required. The resource being created

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1beta::CsqlService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
