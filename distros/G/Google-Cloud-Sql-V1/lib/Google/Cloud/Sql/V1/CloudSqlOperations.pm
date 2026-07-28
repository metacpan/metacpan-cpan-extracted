package Google::Cloud::Sql::V1::CloudSqlOperations;

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
    eval { require Google::Cloud::Sql::V1::CloudSqlResources };
    eval { require Google::Protobuf::Empty };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF9vcGVyYXRpb25zLnByb3RvEhNnb29n
bGUuY2xvdWQuc3FsLnYxGhxnb29nbGUvYXBpL2Fubm90YXRpb25zLnByb3RvGhdnb29nbGUv
YXBpL2NsaWVudC5wcm90bxofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxotZ29v
Z2xlL2Nsb3VkL3NxbC92MS9jbG91ZF9zcWxfcmVzb3VyY2VzLnByb3RvGhtnb29nbGUvcHJv
dG9idWYvZW1wdHkucHJvdG8ifAoXU3FsT3BlcmF0aW9uc0dldFJlcXVlc3QSIQoJb3BlcmF0
aW9uGAEgASgJQgPgQQJSCW9wZXJhdGlvbhIdCgdwcm9qZWN0GAIgASgJQgPgQQJSB3Byb2pl
Y3QSHwoIbG9jYXRpb24YBCABKAlCA+BBAVIIbG9jYXRpb24isQEKGFNxbE9wZXJhdGlvbnNM
aXN0UmVxdWVzdBIaCghpbnN0YW5jZRgBIAEoCVIIaW5zdGFuY2USHwoLbWF4X3Jlc3VsdHMY
AiABKA1SCm1heFJlc3VsdHMSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2VuEhgKB3By
b2plY3QYBCABKAlSB3Byb2plY3QSHwoIbG9jYXRpb24YBiABKAlCA+BBAVIIbG9jYXRpb24i
igEKFk9wZXJhdGlvbnNMaXN0UmVzcG9uc2USEgoEa2luZBgBIAEoCVIEa2luZBI0CgVpdGVt
cxgCIAMoCzIeLmdvb2dsZS5jbG91ZC5zcWwudjEuT3BlcmF0aW9uUgVpdGVtcxImCg9uZXh0
X3BhZ2VfdG9rZW4YAyABKAlSDW5leHRQYWdlVG9rZW4idQoaU3FsT3BlcmF0aW9uc0NhbmNl
bFJlcXVlc3QSHAoJb3BlcmF0aW9uGAEgASgJUglvcGVyYXRpb24SGAoHcHJvamVjdBgCIAEo
CVIHcHJvamVjdBIfCghsb2NhdGlvbhgDIAEoCUID4EEBUghsb2NhdGlvbjLDBAoUU3FsT3Bl
cmF0aW9uc1NlcnZpY2USigEKA0dldBIsLmdvb2dsZS5jbG91ZC5zcWwudjEuU3FsT3BlcmF0
aW9uc0dldFJlcXVlc3QaHi5nb29nbGUuY2xvdWQuc3FsLnYxLk9wZXJhdGlvbiI1gtPkkwIv
Ei0vdjEvcHJvamVjdHMve3Byb2plY3R9L29wZXJhdGlvbnMve29wZXJhdGlvbn0SjQEKBExp
c3QSLS5nb29nbGUuY2xvdWQuc3FsLnYxLlNxbE9wZXJhdGlvbnNMaXN0UmVxdWVzdBorLmdv
b2dsZS5jbG91ZC5zcWwudjEuT3BlcmF0aW9uc0xpc3RSZXNwb25zZSIpgtPkkwIjEiEvdjEv
cHJvamVjdHMve3Byb2plY3R9L29wZXJhdGlvbnMSjwEKBkNhbmNlbBIvLmdvb2dsZS5jbG91
ZC5zcWwudjEuU3FsT3BlcmF0aW9uc0NhbmNlbFJlcXVlc3QaFi5nb29nbGUucHJvdG9idWYu
RW1wdHkiPILT5JMCNiI0L3YxL3Byb2plY3RzL3twcm9qZWN0fS9vcGVyYXRpb25zL3tvcGVy
YXRpb259L2NhbmNlbBp8ykEXc3FsYWRtaW4uZ29vZ2xlYXBpcy5jb23SQV9odHRwczovL3d3
dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8vd3d3Lmdvb2ds
ZWFwaXMuY29tL2F1dGgvc3Fsc2VydmljZS5hZG1pbkJfChdjb20uZ29vZ2xlLmNsb3VkLnNx
bC52MUIXQ2xvdWRTcWxPcGVyYXRpb25zUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNvbS9nby9z
cWwvYXBpdjEvc3FscGI7c3FscGJKuxoKBhIEDgBxAQq8BAoBDBIDDgASMrEEIENvcHlyaWdo
dCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2Us
IFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZp
bGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0
YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5v
cmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJs
ZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1
bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAog
V0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBl
eHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBs
YW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0
aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgAmCgkKAgMBEgMTACEKCQoCAwISAxQA
KQoJCgIDAxIDFQA3CgkKAgMEEgMWACUKCAoBCBIDGABACgkKAggLEgMYAEAKCAoBCBIDGQAi
CgkKAggKEgMZACIKCAoBCBIDGgA4CgkKAggIEgMaADgKCAoBCBIDGwAwCgkKAggBEgMbADAK
QQoCBgASBB4AOQEaNSBTZXJ2aWNlIHRvIGZldGNoIG9wZXJhdGlvbnMgZm9yIGRhdGFiYXNl
IGluc3RhbmNlcy4KCgoKAwYAARIDHggcCgoKAwYAAxIDHwI/CgwKBQYAA5kIEgMfAj8KCwoD
BgADEgQgAiI5Cg0KBQYAA5oIEgQgAiI5ClcKBAYAAgASBCUCKQMaSSBSZXRyaWV2ZXMgYW4g
aW5zdGFuY2Ugb3BlcmF0aW9uIHRoYXQgaGFzIGJlZW4gcGVyZm9ybWVkIG9uIGFuIGluc3Rh
bmNlLgoKDAoFBgACAAESAyUGCQoMCgUGAAIAAhIDJQohCgwKBQYAAgADEgMlLDUKDQoFBgAC
AAQSBCYEKAYKEQoJBgACAASwyrwiEgQmBCgGCp4BCgQGAAIBEgQtAjEDGo8BIExpc3RzIGFs
bCBpbnN0YW5jZSBvcGVyYXRpb25zIHRoYXQgaGF2ZSBiZWVuIHBlcmZvcm1lZCBvbiB0aGUg
Z2l2ZW4gQ2xvdWQKIFNRTCBpbnN0YW5jZSBpbiB0aGUgcmV2ZXJzZSBjaHJvbm9sb2dpY2Fs
IG9yZGVyIG9mIHRoZSBzdGFydCB0aW1lLgoKDAoFBgACAQESAy0GCgoMCgUGAAIBAhIDLQsj
CgwKBQYAAgEDEgMtLkQKDQoFBgACAQQSBC4EMAYKEQoJBgACAQSwyrwiEgQuBDAGClUKBAYA
AgISBDQCOAMaRyBDYW5jZWxzIGFuIGluc3RhbmNlIG9wZXJhdGlvbiB0aGF0IGhhcyBiZWVu
IHBlcmZvcm1lZCBvbiBhbiBpbnN0YW5jZS4KCgwKBQYAAgIBEgM0BgwKDAoFBgACAgISAzQN
JwoMCgUGAAICAxIDNDJHCg0KBQYAAgIEEgQ1BDcGChEKCQYAAgIEsMq8IhIENQQ3BgolCgIE
ABIEPABFARoZIE9wZXJhdGlvbnMgZ2V0IHJlcXVlc3QuCgoKCgMEAAESAzwIHwovCgQEAAIA
EgM+AkAaIiBSZXF1aXJlZC4gSW5zdGFuY2Ugb3BlcmF0aW9uIElELgoKDAoFBAACAAUSAz4C
CAoMCgUEAAIAARIDPgkSCgwKBQQAAgADEgM+FRYKDAoFBAACAAgSAz4XPwoPCggEAAIACJwI
ABIDPhg+Ck4KBAQAAgESA0ECPhpBIFJlcXVpcmVkLiBQcm9qZWN0IElEIG9mIHRoZSBwcm9q
ZWN0IHRoYXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAACAQUSA0ECCAoMCgUEAAIB
ARIDQQkQCgwKBQQAAgEDEgNBExQKDAoFBAACAQgSA0EVPQoPCggEAAIBCJwIABIDQRY8CjoK
BAQAAgISA0QCPxotIE9wdGlvbmFsLiBSZWdpb24gb2YgdGhlIENsb3VkIFNRTCBpbnN0YW5j
ZS4KCgwKBQQAAgIFEgNEAggKDAoFBAACAgESA0QJEQoMCgUEAAICAxIDRBQVCgwKBQQAAgII
EgNEFj4KDwoIBAACAgicCAASA0QXPQomCgIEARIESABYARoaIE9wZXJhdGlvbnMgbGlzdCBy
ZXF1ZXN0LgoKCgoDBAEBEgNICCAKSwoEBAECABIDSgIWGj4gQ2xvdWQgU1FMIGluc3RhbmNl
IElELiBUaGlzIGRvZXMgbm90IGluY2x1ZGUgdGhlIHByb2plY3QgSUQuCgoMCgUEAQIABRID
SgIICgwKBQQBAgABEgNKCREKDAoFBAECAAMSA0oUFQo5CgQEAQIBEgNNAhkaLCBNYXhpbXVt
IG51bWJlciBvZiBvcGVyYXRpb25zIHBlciByZXNwb25zZS4KCgwKBQQBAgEFEgNNAggKDAoF
BAECAQESA00JFAoMCgUEAQIBAxIDTRcYCmgKBAQBAgISA1ECGBpbIEEgcHJldmlvdXNseS1y
ZXR1cm5lZCBwYWdlIHRva2VuIHJlcHJlc2VudGluZyBwYXJ0IG9mIHRoZSBsYXJnZXIgc2V0
IG9mCiByZXN1bHRzIHRvIHZpZXcuCgoMCgUEAQICBRIDUQIICgwKBQQBAgIBEgNRCRMKDAoF
BAECAgMSA1EWFwpECgQEAQIDEgNUAhUaNyBQcm9qZWN0IElEIG9mIHRoZSBwcm9qZWN0IHRo
YXQgY29udGFpbnMgdGhlIGluc3RhbmNlLgoKDAoFBAECAwUSA1QCCAoMCgUEAQIDARIDVAkQ
CgwKBQQBAgMDEgNUExQKOgoEBAECBBIDVwI/Gi0gT3B0aW9uYWwuIFJlZ2lvbiBvZiB0aGUg
Q2xvdWQgU1FMIGluc3RhbmNlLgoKDAoFBAECBAUSA1cCCAoMCgUEAQIEARIDVwkRCgwKBQQB
AgQDEgNXFBUKDAoFBAECBAgSA1cWPgoPCggEAQIECJwIABIDVxc9CicKAgQCEgRbAGUBGhsg
T3BlcmF0aW9ucyBsaXN0IHJlc3BvbnNlLgoKCgoDBAIBEgNbCB4KMwoEBAICABIDXQISGiYg
VGhpcyBpcyBhbHdheXMgYHNxbCNvcGVyYXRpb25zTGlzdGAuCgoMCgUEAgIABRIDXQIICgwK
BQQCAgABEgNdCQ0KDAoFBAICAAMSA10QEQorCgQEAgIBEgNgAh8aHiBMaXN0IG9mIG9wZXJh
dGlvbiByZXNvdXJjZXMuCgoMCgUEAgIBBBIDYAIKCgwKBQQCAgEGEgNgCxQKDAoFBAICAQES
A2AVGgoMCgUEAgIBAxIDYB0eCp8BCgQEAgICEgNkAh0akQEgVGhlIGNvbnRpbnVhdGlvbiB0
b2tlbiwgdXNlZCB0byBwYWdlIHRocm91Z2ggbGFyZ2UgcmVzdWx0IHNldHMuIFByb3ZpZGUK
IHRoaXMgdmFsdWUgaW4gYSBzdWJzZXF1ZW50IHJlcXVlc3QgdG8gcmV0dXJuIHRoZSBuZXh0
IHBhZ2Ugb2YgcmVzdWx0cy4KCgwKBQQCAgIFEgNkAggKDAoFBAICAgESA2QJGAoMCgUEAgIC
AxIDZBscCigKAgQDEgRoAHEBGhwgT3BlcmF0aW9ucyBjYW5jZWwgcmVxdWVzdC4KCgoKAwQD
ARIDaAgiCiUKBAQDAgASA2oCFxoYIEluc3RhbmNlIG9wZXJhdGlvbiBJRC4KCgwKBQQDAgAF
EgNqAggKDAoFBAMCAAESA2oJEgoMCgUEAwIAAxIDahUWCkQKBAQDAgESA20CFRo3IFByb2pl
Y3QgSUQgb2YgdGhlIHByb2plY3QgdGhhdCBjb250YWlucyB0aGUgaW5zdGFuY2UuCgoMCgUE
AwIBBRIDbQIICgwKBQQDAgEBEgNtCRAKDAoFBAMCAQMSA20TFAo6CgQEAwICEgNwAj8aLSBP
cHRpb25hbC4gUmVnaW9uIG9mIHRoZSBDbG91ZCBTUUwgaW5zdGFuY2UuCgoMCgUEAwICBRID
cAIICgwKBQQDAgIBEgNwCREKDAoFBAMCAgMSA3AUFQoMCgUEAwICCBIDcBY+Cg8KCAQDAgII
nAgAEgNwFz1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsGetRequest ===
    # Fields for SqlOperationsGetRequest
    # Field: operation Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsGetRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlOperations;

    my $msg = Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsGetRequest->new(
        operation => $value,
    );

=head1 FIELDS

=over 4

=item * B<operation>

Type: String

=item * B<project>

Type: String

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsListRequest ===
    # Fields for SqlOperationsListRequest
    # Field: instance Type: 9 ()
    # Field: max_results Type: 13 ()
    # Field: page_token Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsListRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlOperations;

    my $msg = Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsListRequest->new(
        instance => $value,
    );

=head1 FIELDS

=over 4

=item * B<instance>

Type: String

=item * B<max_results>

Type: UInt32

=item * B<page_token>

Type: String

=item * B<project>

Type: String

=item * B<location>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlOperations::OperationsListResponse ===
    # Fields for OperationsListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1.Operation)
    # Field: next_page_token Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlOperations::OperationsListResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlOperations;

    my $msg = Google::Cloud::Sql::V1::CloudSqlOperations::OperationsListResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<items>

Type: Message (.google.cloud.sql.v1.Operation)

=item * B<next_page_token>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsCancelRequest ===
    # Fields for SqlOperationsCancelRequest
    # Field: operation Type: 9 ()
    # Field: project Type: 9 ()
    # Field: location Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsCancelRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlOperations;

    my $msg = Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsCancelRequest->new(
        operation => $value,
    );

=head1 FIELDS

=over 4

=item * B<operation>

Type: String

=item * B<project>

Type: String

=item * B<location>

Type: String

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsServiceClient - Client stub representing the remote SqlOperationsService service

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

sub get {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsGetRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlOperationsService',
        method         => 'Get',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlResources::Operation',
    });
}

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlOperationsService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlOperations::OperationsListResponse',
    });
}

sub cancel {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlOperations::SqlOperationsCancelRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlOperationsService',
        method         => 'Cancel',
        request        => $req,
        response_class => 'Google::Protobuf::Empty::Empty',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlOperations - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
