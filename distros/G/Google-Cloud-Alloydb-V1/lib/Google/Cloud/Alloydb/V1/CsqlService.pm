package Google::Cloud::Alloydb::V1::CsqlService;

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
    eval { require Google::Cloud::Alloydb::V1::CsqlResources };
    eval { require Google::Cloud::Alloydb::V1::Resources };
    eval { require Google::Cloud::Alloydb::V1::Service };
    eval { require Google::Longrunning::Operations };
    my $descriptor_b64 = <<'EOF';
Cipnb29nbGUvY2xvdWQvYWxsb3lkYi92MS9jc3FsX3NlcnZpY2UucHJvdG8SF2dvb2dsZS5j
bG91ZC5hbGxveWRiLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUv
YXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxosZ29vZ2xlL2Nsb3VkL2FsbG95ZGIvdjEvY3NxbF9y
ZXNvdXJjZXMucHJvdG8aJ2dvb2dsZS9jbG91ZC9hbGxveWRiL3YxL3Jlc291cmNlcy5wcm90
bxolZ29vZ2xlL2Nsb3VkL2FsbG95ZGIvdjEvc2VydmljZS5wcm90bxojZ29vZ2xlL2xvbmdy
dW5uaW5nL29wZXJhdGlvbnMucHJvdG8ivAIKGlJlc3RvcmVGcm9tQ2xvdWRTUUxSZXF1ZXN0
Em8KGmNsb3Vkc3FsX2JhY2t1cF9ydW5fc291cmNlGGUgASgLMjAuZ29vZ2xlLmNsb3VkLmFs
bG95ZGIudjEuQ2xvdWRTUUxCYWNrdXBSdW5Tb3VyY2VIAFIXY2xvdWRzcWxCYWNrdXBSdW5T
b3VyY2USPgoGcGFyZW50GAEgASgJQibgQQL6QSASHmFsbG95ZGIuZ29vZ2xlYXBpcy5jb20v
Q2x1c3RlclIGcGFyZW50EiIKCmNsdXN0ZXJfaWQYAiABKAlCA+BBAlIJY2x1c3RlcklkEj8K
B2NsdXN0ZXIYAyABKAsyIC5nb29nbGUuY2xvdWQuYWxsb3lkYi52MS5DbHVzdGVyQgPgQQJS
B2NsdXN0ZXJCCAoGc291cmNlMsoCChBBbGxveURCQ1NRTEFkbWluEukBChNSZXN0b3JlRnJv
bUNsb3VkU1FMEjMuZ29vZ2xlLmNsb3VkLmFsbG95ZGIudjEuUmVzdG9yZUZyb21DbG91ZFNR
TFJlcXVlc3QaHS5nb29nbGUubG9uZ3J1bm5pbmcuT3BlcmF0aW9uIn6C0+STAkUiQC92MS97
cGFyZW50PXByb2plY3RzLyovbG9jYXRpb25zLyp9L2NsdXN0ZXJzOnJlc3RvcmVGcm9tQ2xv
dWRTUUw6ASraQRFwYXJlbnQsY2x1c3Rlcl9pZMpBHAoHQ2x1c3RlchIRT3BlcmF0aW9uTWV0
YWRhdGEaSspBFmFsbG95ZGIuZ29vZ2xlYXBpcy5jb23SQS5odHRwczovL3d3dy5nb29nbGVh
cGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtQrkBChtjb20uZ29vZ2xlLmNsb3VkLmFsbG95
ZGIudjFCEENTUUxTZXJ2aWNlUHJvdG9QAVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9hbGxveWRi
L2FwaXYxL2FsbG95ZGJwYjthbGxveWRicGKqAhdHb29nbGUuQ2xvdWQuQWxsb3lEYi5WMcoC
F0dvb2dsZVxDbG91ZFxBbGxveURiXFYx6gIaR29vZ2xlOjpDbG91ZDo6QWxsb3lEQjo6VjFK
4w4KBhIEDgBOAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBM
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
IAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQAKQoJCgIDAxIDFQAjCgkKAgMEEgMW
ADYKCQoCAwUSAxcAMQoJCgIDBhIDGAAvCgkKAgMHEgMZAC0KCAoBCBIDGwA0CgkKAgglEgMb
ADQKCAoBCBIDHABMCgkKAggLEgMcAEwKCAoBCBIDHQAiCgkKAggKEgMdACIKCAoBCBIDHgAx
CgkKAggIEgMeADEKCAoBCBIDHwA0CgkKAggBEgMfADQKCAoBCBIDIAA0CgkKAggpEgMgADQK
CAoBCBIDIQAzCgkKAggtEgMhADMKNQoCBgASBCQANgEaKSBTZXJ2aWNlIGZvciBpbnRlcmFj
dGlvbnMgd2l0aCBDbG91ZFNRTC4KCgoKAwYAARIDJAgYCgoKAwYAAxIDJQI+CgwKBQYAA5kI
EgMlAj4KCwoDBgADEgQmAic3Cg0KBQYAA5oIEgQmAic3CkUKBAYAAgASBCoCNQMaNyBSZXN0
b3JlcyBhbiBBbGxveURCIGNsdXN0ZXIgZnJvbSBhIENsb3VkU1FMIHJlc291cmNlLgoKDAoF
BgACAAESAyoGGQoMCgUGAAIAAhIDKho0CgwKBQYAAgADEgMrDysKDQoFBgACAAQSBCwELwYK
EQoJBgACAASwyrwiEgQsBC8GCgwKBQYAAgAEEgMwBD8KDwoIBgACAASbCAASAzAEPwoNCgUG
AAIABBIEMQQ0BgoPCgcGAAIABJkIEgQxBDQGCkcKAgQAEgQ5AE4BGjsgTWVzc2FnZSBmb3Ig
cmVnaXN0ZXJpbmcgUmVzdG9yaW5nIGZyb20gQ2xvdWRTUUwgcmVzb3VyY2UuCgoKCgMEAAES
AzkIIgo9CgQEAAgAEgQ7Aj4DGi8gVGhlIHNvdXJjZSBDbG91ZFNRTCByZXNvdXJjZSB0byBy
ZXN0b3JlIGZyb20uCgoMCgUEAAgAARIDOwgOCjgKBAQAAgASAz0EPRorIENsdXN0ZXIgY3Jl
YXRlZCBmcm9tIENsb3VkU1FMIGJhY2t1cCBydW4uCgoMCgUEAAIABhIDPQQbCgwKBQQAAgAB
EgM9HDYKDAoFBAACAAMSAz05PAp7CgQEAAIBEgRCAkcEGm0gUmVxdWlyZWQuIFRoZSBsb2Nh
dGlvbiBvZiB0aGUgbmV3IGNsdXN0ZXIuIEZvciB0aGUgcmVxdWlyZWQgZm9ybWF0LCBzZWUg
dGhlCiBjb21tZW50IG9uIENsdXN0ZXIubmFtZSBmaWVsZC4KCgwKBQQAAgEFEgNCAggKDAoF
BAACAQESA0IJDwoMCgUEAAIBAxIDQhITCg0KBQQAAgEIEgRCFEcDCg8KCAQAAgEInAgAEgND
BCoKDwoHBAACAQifCBIERARGBQo1CgQEAAICEgNKAkEaKCBSZXF1aXJlZC4gSUQgb2YgdGhl
IHJlcXVlc3Rpbmcgb2JqZWN0LgoKDAoFBAACAgUSA0oCCAoMCgUEAAICARIDSgkTCgwKBQQA
AgIDEgNKFhcKDAoFBAACAggSA0oYQAoPCggEAAICCJwIABIDShk/CjMKBAQAAgMSA00CPxom
IFJlcXVpcmVkLiBUaGUgcmVzb3VyY2UgYmVpbmcgY3JlYXRlZAoKDAoFBAACAwYSA00CCQoM
CgUEAAIDARIDTQoRCgwKBQQAAgMDEgNNFBUKDAoFBAACAwgSA00WPgoPCggEAAIDCJwIABID
TRc9YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Alloydb::V1::CsqlService::RestoreFromCloudSQLRequest ===
    # Fields for RestoreFromCloudSQLRequest
    # Field: cloudsql_backup_run_source Type: 11 (.google.cloud.alloydb.v1.CloudSQLBackupRunSource)
    # Field: parent Type: 9 ()
    # Field: cluster_id Type: 9 ()
    # Field: cluster Type: 11 (.google.cloud.alloydb.v1.Cluster)

# === Service Client: Google::Cloud::Alloydb::V1::CsqlService::AlloyDBCSQLAdminClient ===
package Google::Cloud::Alloydb::V1::CsqlService::AlloyDBCSQLAdminClient;

=pod

=head2 Service Client: Google::Cloud::Alloydb::V1::CsqlService::AlloyDBCSQLAdminClient

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
        ? Google::Cloud::Alloydb::V1::CsqlService::RestoreFromCloudSQLRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.alloydb.v1.AlloyDBCSQLAdmin',
        method         => 'RestoreFromCloudSQL',
        request        => $req,
        response_class => 'Google::Longrunning::Operations::Operation',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Alloydb::V1::CsqlService - Compiled Protocol Buffers messages for google/cloud/alloydb/v1/csql_service.proto

=head1 SYNOPSIS

    use Google::Cloud::Alloydb::V1::CsqlService;

    my $msg = Google::Cloud::Alloydb::V1::CsqlService::RestoreFromCloudSQLRequest->new({
        cloudsql_backup_run_source => $cloudsql_backup_run_source,
        parent => $parent,
        cluster_id => $cluster_id,
        cluster => $cluster,
    });

    # Read or update a field
    my $val = $msg->cloudsql_backup_run_source();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Alloydb::V1::CsqlService::RestoreFromCloudSQLRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/alloydb/v1/csql_service.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Alloydb::V1::CsqlService::RestoreFromCloudSQLRequest

Message for registering Restoring from CloudSQL resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->cloudsql_backup_run_source() >> / C<< $msg->cloudsql_backup_run_source($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1::CsqlResources::CloudSQLBackupRunSource>)

Cluster created from CloudSQL backup run.

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The location of the new cluster. For the required format, see the
comment on Cluster.name field.

=item * C<< $msg->cluster_id() >> / C<< $msg->cluster_id($value) >>

Type: C<String>

Required. ID of the requesting object.

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<Message> (L<Google::Cloud::Alloydb::V1::Resources::Cluster>)

Required. The resource being created

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Alloydb::V1::CsqlService::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
