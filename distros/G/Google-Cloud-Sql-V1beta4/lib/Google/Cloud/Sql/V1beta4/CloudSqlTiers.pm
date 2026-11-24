package Google::Cloud::Sql::V1beta4::CloudSqlTiers;

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
Ci5nb29nbGUvY2xvdWQvc3FsL3YxYmV0YTQvY2xvdWRfc3FsX3RpZXJzLnByb3RvEhhnb29n
bGUuY2xvdWQuc3FsLnYxYmV0YTQaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dv
b2dsZS9hcGkvY2xpZW50LnByb3RvIi8KE1NxbFRpZXJzTGlzdFJlcXVlc3QSGAoHcHJvamVj
dBgBIAEoCVIHcHJvamVjdCJdChFUaWVyc0xpc3RSZXNwb25zZRISCgRraW5kGAEgASgJUgRr
aW5kEjQKBWl0ZW1zGAIgAygLMh4uZ29vZ2xlLmNsb3VkLnNxbC52MWJldGE0LlRpZXJSBWl0
ZW1zIncKBFRpZXISEgoEdGllchgBIAEoCVIEdGllchIQCgNSQU0YAiABKANSA1JBTRISCgRr
aW5kGAMgASgJUgRraW5kEh0KCkRpc2tfUXVvdGEYBCABKANSCURpc2tRdW90YRIWCgZyZWdp
b24YBSADKAlSBnJlZ2lvbjKjAgoPU3FsVGllcnNTZXJ2aWNlEpEBCgRMaXN0Ei0uZ29vZ2xl
LmNsb3VkLnNxbC52MWJldGE0LlNxbFRpZXJzTGlzdFJlcXVlc3QaKy5nb29nbGUuY2xvdWQu
c3FsLnYxYmV0YTQuVGllcnNMaXN0UmVzcG9uc2UiLYLT5JMCJxIlL3NxbC92MWJldGE0L3By
b2plY3RzL3twcm9qZWN0fS90aWVycxp8ykEXc3FsYWRtaW4uZ29vZ2xlYXBpcy5jb23SQV9o
dHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL2Nsb3VkLXBsYXRmb3JtLGh0dHBzOi8v
d3d3Lmdvb2dsZWFwaXMuY29tL2F1dGgvc3Fsc2VydmljZS5hZG1pbkJkChxjb20uZ29vZ2xl
LmNsb3VkLnNxbC52MWJldGE0QhJDbG91ZFNxbFRpZXJzUHJvdG9QAVouY2xvdWQuZ29vZ2xl
LmNvbS9nby9zcWwvYXBpdjFiZXRhNC9zcWxwYjtzcWxwYkr+EAoGEgQOAEkBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACYKCQoCAwES
AxMAIQoICgEIEgMVAEUKCQoCCAsSAxUARQoICgEIEgMWACIKCQoCCAoSAxYAIgoICgEIEgMX
ADMKCQoCCAgSAxcAMwoICgEIEgMYADUKCQoCCAESAxgANQpICgIGABIEGwAoARo8IFNlcnZp
Y2UgZm9yIHByb3ZpZGluZyBtYWNoaW5lIHR5cGVzICh0aWVycykgZm9yIENsb3VkIFNRTC4K
CgoKAwYAARIDGwgXCgoKAwYAAxIDHAI/CgwKBQYAA5kIEgMcAj8KCwoDBgADEgQdAh85Cg0K
BQYAA5oIEgQdAh85CqEBCgQGAAIAEgQjAicDGpIBIExpc3RzIGFsbCBhdmFpbGFibGUgbWFj
aGluZSB0eXBlcyAodGllcnMpIGZvciBDbG91ZCBTUUwsIGZvciBleGFtcGxlLAogYGRiLWN1
c3RvbS0xLTM4NDBgLiBGb3IgcmVsYXRlZCBpbmZvcm1hdGlvbiwgc2VlIFtQcmljaW5nXSgv
c3FsL3ByaWNpbmcpLgoKDAoFBgACAAESAyMGCgoMCgUGAAIAAhIDIwseCgwKBQYAAgADEgMj
KToKDQoFBgACAAQSBCQEJgYKEQoJBgACAASwyrwiEgQkBCYGCgoKAgQAEgQqAC0BCgoKAwQA
ARIDKggbCkEKBAQAAgASAywCFRo0IFByb2plY3QgSUQgb2YgdGhlIHByb2plY3QgZm9yIHdo
aWNoIHRvIGxpc3QgdGllcnMuCgoMCgUEAAIABRIDLAIICgwKBQQAAgABEgMsCRAKDAoFBAAC
AAMSAywTFAoiCgIEARIEMAA2ARoWIFRpZXJzIGxpc3QgcmVzcG9uc2UuCgoKCgMEAQESAzAI
GQouCgQEAQIAEgMyAhIaISBUaGlzIGlzIGFsd2F5cyBgc3FsI3RpZXJzTGlzdGAuCgoMCgUE
AQIABRIDMgIICgwKBQQBAgABEgMyCQ0KDAoFBAECAAMSAzIQEQodCgQEAQIBEgM1AhoaECBM
aXN0IG9mIHRpZXJzLgoKDAoFBAECAQQSAzUCCgoMCgUEAQIBBhIDNQsPCgwKBQQBAgEBEgM1
EBUKDAoFBAECAQMSAzUYGQo3CgIEAhIEOQBJARorIEEgR29vZ2xlIENsb3VkIFNRTCBzZXJ2
aWNlIHRpZXIgcmVzb3VyY2UuCgoKCgMEAgESAzkIDAqKAQoEBAICABIDPAISGn0gQW4gaWRl
bnRpZmllciBmb3IgdGhlIG1hY2hpbmUgdHlwZSwgZm9yIGV4YW1wbGUsIGBkYi1jdXN0b20t
MS0zODQwYC4gRm9yCiByZWxhdGVkIGluZm9ybWF0aW9uLCBzZWUgW1ByaWNpbmddKC9zcWwv
cHJpY2luZykuCgoMCgUEAgIABRIDPAIICgwKBQQCAgABEgM8CQ0KDAoFBAICAAMSAzwQEQo7
CgQEAgIBEgM/AiQaLiBUaGUgbWF4aW11bSBSQU0gdXNhZ2Ugb2YgdGhpcyB0aWVyIGluIGJ5
dGVzLgoKDAoFBAICAQUSAz8CBwoMCgUEAgIBARIDPwgLCgwKBQQCAgEDEgM/Dg8KDAoFBAIC
AQgSAz8QIwoMCgUEAgIBChIDPxEiCgwKBQQCAgEKEgM/HSIKKQoEBAICAhIDQgISGhwgVGhp
cyBpcyBhbHdheXMgYHNxbCN0aWVyYC4KCgwKBQQCAgIFEgNCAggKDAoFBAICAgESA0IJDQoM
CgUEAgICAxIDQhARCjsKBAQCAgMSA0UCMRouIFRoZSBtYXhpbXVtIGRpc2sgc2l6ZSBvZiB0
aGlzIHRpZXIgaW4gYnl0ZXMuCgoMCgUEAgIDBRIDRQIHCgwKBQQCAgMBEgNFCBIKDAoFBAIC
AwMSA0UVFgoMCgUEAgIDCBIDRRcwCgwKBQQCAgMKEgNFGC8KDAoFBAICAwoSA0UkLwo0CgQE
AgIEEgNIAh0aJyBUaGUgYXBwbGljYWJsZSByZWdpb25zIGZvciB0aGlzIHRpZXIuCgoMCgUE
AgIEBBIDSAIKCgwKBQQCAgQFEgNICxEKDAoFBAICBAESA0gSGAoMCgUEAgIEAxIDSBscYgZw
cm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlTiers::SqlTiersListRequest ===
    # Fields for SqlTiersListRequest
    # Field: project Type: 9 ()

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlTiers::TiersListResponse ===
    # Fields for TiersListResponse
    # Field: kind Type: 9 ()
    # Field: items Type: 11 (.google.cloud.sql.v1beta4.Tier)

# === Message: Google::Cloud::Sql::V1beta4::CloudSqlTiers::Tier ===
    # Fields for Tier
    # Field: tier Type: 9 ()
    # Field: RAM Type: 3 ()
    # Field: kind Type: 9 ()
    # Field: Disk_Quota Type: 3 ()
    # Field: region Type: 9 ()

# === Service Client: Google::Cloud::Sql::V1beta4::CloudSqlTiers::SqlTiersServiceClient ===
package Google::Cloud::Sql::V1beta4::CloudSqlTiers::SqlTiersServiceClient;

=pod

=head2 Service Client: Google::Cloud::Sql::V1beta4::CloudSqlTiers::SqlTiersServiceClient

Client stub representing the remote C<SqlTiersService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

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

sub list {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Sql::V1beta4::CloudSqlTiers::SqlTiersListRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.sql.v1beta4.SqlTiersService',
        method         => 'List',
        request        => $req,
        response_class => 'Google::Cloud::Sql::V1beta4::CloudSqlTiers::TiersListResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Sql::V1beta4::CloudSqlTiers - Compiled Protocol Buffers messages for google/cloud/sql/v1beta4/cloud_sql_tiers.proto

=head1 SYNOPSIS

    use Google::Cloud::Sql::V1beta4::CloudSqlTiers;

    my $msg = Google::Cloud::Sql::V1beta4::CloudSqlTiers::SqlTiersListRequest->new({
        project => $project,
    });

    # Read or update a field
    my $val = $msg->project();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Sql::V1beta4::CloudSqlTiers::SqlTiersListRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/sql/v1beta4/cloud_sql_tiers.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Sql::V1beta4::CloudSqlTiers::SqlTiersListRequest

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->project() >> / C<< $msg->project($value) >>

Type: C<String>

Project ID of the project for which to list tiers.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlTiers::TiersListResponse

Tiers list response.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

This is always `sql#tiersList`.

=item * C<< $msg->items() >> / C<< $msg->items($value) >>

Type: C<Message> (L<Google::Cloud::Sql::V1beta4::CloudSqlTiers::Tier>)

List of tiers.

=back

=head2 Google::Cloud::Sql::V1beta4::CloudSqlTiers::Tier

A Google Cloud SQL service tier resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->tier() >> / C<< $msg->tier($value) >>

Type: C<String>

An identifier for the machine type, for example, `db-custom-1-3840`. For
related information, see [Pricing](/sql/pricing).

=item * C<< $msg->RAM() >> / C<< $msg->RAM($value) >>

Type: C<Int64>

The maximum RAM usage of this tier in bytes.

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<String>

This is always `sql#tier`.

=item * C<< $msg->Disk_Quota() >> / C<< $msg->Disk_Quota($value) >>

Type: C<Int64>

The maximum disk size of this tier in bytes.

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

The applicable regions for this tier.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Sql::V1beta4::CloudSqlTiers::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
