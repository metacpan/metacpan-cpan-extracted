package Google::Cloud::Sql::V1::CloudSqlTiers;

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
Cilnb29nbGUvY2xvdWQvc3FsL3YxL2Nsb3VkX3NxbF90aWVycy5wcm90bxITZ29vZ2xlLmNs
b3VkLnNxbC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxoXZ29vZ2xlL2FwaS9j
bGllbnQucHJvdG8iLwoTU3FsVGllcnNMaXN0UmVxdWVzdBIYCgdwcm9qZWN0GAEgASgJUgdw
cm9qZWN0IlgKEVRpZXJzTGlzdFJlc3BvbnNlEhIKBGtpbmQYASABKAlSBGtpbmQSLwoFaXRl
bXMYAiADKAsyGS5nb29nbGUuY2xvdWQuc3FsLnYxLlRpZXJSBWl0ZW1zIncKBFRpZXISEgoE
dGllchgBIAEoCVIEdGllchIQCgNSQU0YAiABKANSA1JBTRISCgRraW5kGAMgASgJUgRraW5k
Eh0KCkRpc2tfUXVvdGEYBCABKANSCURpc2tRdW90YRIWCgZyZWdpb24YBSADKAlSBnJlZ2lv
bjKPAgoPU3FsVGllcnNTZXJ2aWNlEn4KBExpc3QSKC5nb29nbGUuY2xvdWQuc3FsLnYxLlNx
bFRpZXJzTGlzdFJlcXVlc3QaJi5nb29nbGUuY2xvdWQuc3FsLnYxLlRpZXJzTGlzdFJlc3Bv
bnNlIiSC0+STAh4SHC92MS9wcm9qZWN0cy97cHJvamVjdH0vdGllcnMafMpBF3NxbGFkbWlu
Lmdvb2dsZWFwaXMuY29t0kFfaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL3NxbHNlcnZpY2Uu
YWRtaW5CWgoXY29tLmdvb2dsZS5jbG91ZC5zcWwudjFCEkNsb3VkU3FsVGllcnNQcm90b1AB
WiljbG91ZC5nb29nbGUuY29tL2dvL3NxbC9hcGl2MS9zcWxwYjtzcWxwYkqqEQoGEgQOAEsB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAcCgkKAgMAEgMS
ACYKCQoCAwESAxMAIQoICgEIEgMVAEAKCQoCCAsSAxUAQAoICgEIEgMWACIKCQoCCAoSAxYA
IgoICgEIEgMXADMKCQoCCAgSAxcAMwoICgEIEgMYADAKCQoCCAESAxgAMApSCgIGABIEGwAp
ARpGIFNlcnZpY2UgZm9yIHByb3ZpZGluZyBtYWNoaW5lIHR5cGVzICh0aWVycykgZm9yIENs
b3VkIFNRTCBpbnN0YW5jZXMuCgoKCgMGAAESAxsIFwoKCgMGAAMSAxwCPwoMCgUGAAOZCBID
HAI/CgsKAwYAAxIEHQIfOQoNCgUGAAOaCBIEHQIfOQqsAQoEBgACABIEJAIoAxqdASBMaXN0
cyBhbGwgYXZhaWxhYmxlIG1hY2hpbmUgdHlwZXMgKHRpZXJzKSBmb3IgQ2xvdWQgU1FMLCBm
b3IgZXhhbXBsZSwKIGBkYi1jdXN0b20tMS0zODQwYC4gRm9yIG1vcmUgaW5mb3JtYXRpb24s
IHNlZQogaHR0cHM6Ly9jbG91ZC5nb29nbGUuY29tL3NxbC9wcmljaW5nLgoKDAoFBgACAAES
AyQGCgoMCgUGAAIAAhIDJAseCgwKBQYAAgADEgMkKToKDQoFBgACAAQSBCUEJwYKEQoJBgAC
AASwyrwiEgQlBCcGCiEKAgQAEgQsAC8BGhUgVGllcnMgbGlzdCByZXF1ZXN0LgoKCgoDBAAB
EgMsCBsKQQoEBAACABIDLgIVGjQgUHJvamVjdCBJRCBvZiB0aGUgcHJvamVjdCBmb3Igd2hp
Y2ggdG8gbGlzdCB0aWVycy4KCgwKBQQAAgAFEgMuAggKDAoFBAACAAESAy4JEAoMCgUEAAIA
AxIDLhMUCiIKAgQBEgQyADgBGhYgVGllcnMgbGlzdCByZXNwb25zZS4KCgoKAwQBARIDMggZ
Ci4KBAQBAgASAzQCEhohIFRoaXMgaXMgYWx3YXlzIGBzcWwjdGllcnNMaXN0YC4KCgwKBQQB
AgAFEgM0AggKDAoFBAECAAESAzQJDQoMCgUEAQIAAxIDNBARCh0KBAQBAgESAzcCGhoQIExp
c3Qgb2YgdGllcnMuCgoMCgUEAQIBBBIDNwIKCgwKBQQBAgEGEgM3Cw8KDAoFBAECAQESAzcQ
FQoMCgUEAQIBAxIDNxgZCjcKAgQCEgQ7AEsBGisgQSBHb29nbGUgQ2xvdWQgU1FMIHNlcnZp
Y2UgdGllciByZXNvdXJjZS4KCgoKAwQCARIDOwgMCooBCgQEAgIAEgM+AhIafSBBbiBpZGVu
dGlmaWVyIGZvciB0aGUgbWFjaGluZSB0eXBlLCBmb3IgZXhhbXBsZSwgYGRiLWN1c3RvbS0x
LTM4NDBgLiBGb3IKIHJlbGF0ZWQgaW5mb3JtYXRpb24sIHNlZSBbUHJpY2luZ10oL3NxbC9w
cmljaW5nKS4KCgwKBQQCAgAFEgM+AggKDAoFBAICAAESAz4JDQoMCgUEAgIAAxIDPhARCjsK
BAQCAgESA0ECJBouIFRoZSBtYXhpbXVtIFJBTSB1c2FnZSBvZiB0aGlzIHRpZXIgaW4gYnl0
ZXMuCgoMCgUEAgIBBRIDQQIHCgwKBQQCAgEBEgNBCAsKDAoFBAICAQMSA0EODwoMCgUEAgIB
CBIDQRAjCgwKBQQCAgEKEgNBESIKDAoFBAICAQoSA0EdIgopCgQEAgICEgNEAhIaHCBUaGlz
IGlzIGFsd2F5cyBgc3FsI3RpZXJgLgoKDAoFBAICAgUSA0QCCAoMCgUEAgICARIDRAkNCgwK
BQQCAgIDEgNEEBEKOwoEBAICAxIDRwIxGi4gVGhlIG1heGltdW0gZGlzayBzaXplIG9mIHRo
aXMgdGllciBpbiBieXRlcy4KCgwKBQQCAgMFEgNHAgcKDAoFBAICAwESA0cIEgoMCgUEAgID
AxIDRxUWCgwKBQQCAgMIEgNHFzAKDAoFBAICAwoSA0cYLwoMCgUEAgIDChIDRyQvCjQKBAQC
AgQSA0oCHRonIFRoZSBhcHBsaWNhYmxlIHJlZ2lvbnMgZm9yIHRoaXMgdGllci4KCgwKBQQC
AgQEEgNKAgoKDAoFBAICBAUSA0oLEQoMCgUEAgIEARIDShIYCgwKBQQCAgQDEgNKGxxiBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1::CloudSqlTiers::SqlTiersListRequest ===
    # Fields for SqlTiersListRequest
    # Field: project Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlTiers::SqlTiersListRequest - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlTiers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlTiers::SqlTiersListRequest->new(
        project => $value,
    );

=head1 FIELDS

=over 4

=item * B<project>

Type: String

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlTiers::TiersListResponse ===
    # Fields for TiersListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1.Tier)

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlTiers::TiersListResponse - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlTiers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlTiers::TiersListResponse->new(
        kind => $value,
    );

=head1 FIELDS

=over 4

=item * B<kind>

Type: String

=item * B<items>

Type: Message (.google.cloud.sql.v1.Tier)

=back

=cut

# === Message: Google::Cloud::Sql::V1::CloudSqlTiers::Tier ===
    # Fields for Tier
    # Field: tier Type: 9 ()
    # Field: RAM Type: 3 ()
    # Field: kind Type: 9 ()
    # Field: Disk_Quota Type: 3 ()
    # Field: region Type: 9 ()

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlTiers::Tier - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1::CloudSqlTiers;

    my $msg = Google::Cloud::Sql::V1::CloudSqlTiers::Tier->new(
        tier => $value,
    );

=head1 FIELDS

=over 4

=item * B<tier>

Type: String

=item * B<RAM>

Type: Int64

=item * B<kind>

Type: String

=item * B<Disk_Quota>

Type: Int64

=item * B<region>

Type: String

=back

=cut

# === Service Client: Google::Cloud::Sql::V1::CloudSqlTiers::SqlTiersServiceClient ===
package Google::Cloud::Sql::V1::CloudSqlTiers::SqlTiersServiceClient;

=pod

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlTiers::SqlTiersServiceClient - Client stub representing the remote SqlTiersService service

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

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1::CloudSqlTiers::SqlTiersListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1.SqlTiersService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1::CloudSqlTiers::TiersListResponse',
    });
}

1;

__END__

=head1 NAME

Google::Cloud::Sql::V1::CloudSqlTiers - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
