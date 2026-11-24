package Google::Cloud::Apigeeconnect::V1::Connection;

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
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvYXBpZ2VlY29ubmVjdC92MS9jb25uZWN0aW9uLnByb3RvEh1nb29n
bGUuY2xvdWQuYXBpZ2VlY29ubmVjdC52MRocZ29vZ2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90
bxoXZ29vZ2xlL2FwaS9jbGllbnQucHJvdG8aH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3Iu
cHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8imwEKFkxpc3RDb25uZWN0aW9uc1Jl
cXVlc3QSRQoGcGFyZW50GAEgASgJQi3gQQL6QScKJWFwaWdlZWNvbm5lY3QuZ29vZ2xlYXBp
cy5jb20vRW5kcG9pbnRSBnBhcmVudBIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0K
CnBhZ2VfdG9rZW4YAyABKAlSCXBhZ2VUb2tlbiKOAQoXTGlzdENvbm5lY3Rpb25zUmVzcG9u
c2USSwoLY29ubmVjdGlvbnMYASADKAsyKS5nb29nbGUuY2xvdWQuYXBpZ2VlY29ubmVjdC52
MS5Db25uZWN0aW9uUgtjb25uZWN0aW9ucxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5l
eHRQYWdlVG9rZW4ijQEKCkNvbm5lY3Rpb24SGgoIZW5kcG9pbnQYASABKAlSCGVuZHBvaW50
EkAKB2NsdXN0ZXIYAiABKAsyJi5nb29nbGUuY2xvdWQuYXBpZ2VlY29ubmVjdC52MS5DbHVz
dGVyUgdjbHVzdGVyEiEKDHN0cmVhbV9jb3VudBgDIAEoBVILc3RyZWFtQ291bnQiNQoHQ2x1
c3RlchISCgRuYW1lGAEgASgJUgRuYW1lEhYKBnJlZ2lvbhgCIAEoCVIGcmVnaW9uMqoCChFD
b25uZWN0aW9uU2VydmljZRLCAQoPTGlzdENvbm5lY3Rpb25zEjUuZ29vZ2xlLmNsb3VkLmFw
aWdlZWNvbm5lY3QudjEuTGlzdENvbm5lY3Rpb25zUmVxdWVzdBo2Lmdvb2dsZS5jbG91ZC5h
cGlnZWVjb25uZWN0LnYxLkxpc3RDb25uZWN0aW9uc1Jlc3BvbnNlIkCC0+STAjESLy92MS97
cGFyZW50PXByb2plY3RzLyovZW5kcG9pbnRzLyp9L2Nvbm5lY3Rpb25z2kEGcGFyZW50GlDK
QRxhcGlnZWVjb25uZWN0Lmdvb2dsZWFwaXMuY29t0kEuaHR0cHM6Ly93d3cuZ29vZ2xlYXBp
cy5jb20vYXV0aC9jbG91ZC1wbGF0Zm9ybUK1AgohY29tLmdvb2dsZS5jbG91ZC5hcGlnZWVj
b25uZWN0LnYxQg9Db25uZWN0aW9uUHJvdG9QAVpHY2xvdWQuZ29vZ2xlLmNvbS9nby9hcGln
ZWVjb25uZWN0L2FwaXYxL2FwaWdlZWNvbm5lY3RwYjthcGlnZWVjb25uZWN0cGKqAh1Hb29n
bGUuQ2xvdWQuQXBpZ2VlQ29ubmVjdC5WMcoCHUdvb2dsZVxDbG91ZFxBcGlnZWVDb25uZWN0
XFYx6gIgR29vZ2xlOjpDbG91ZDo6QXBpZ2VlQ29ubmVjdDo6VjHqQVAKJWFwaWdlZWNvbm5l
Y3QuZ29vZ2xlYXBpcy5jb20vRW5kcG9pbnQSJ3Byb2plY3RzL3twcm9qZWN0fS9lbmRwb2lu
dHMve2VuZHBvaW50fUqEFwoGEgQOAGcBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUg
R29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lv
biAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNl
cHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBj
b3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNl
bnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBv
ciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRo
ZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VU
IFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mg
b3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdl
IGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNl
bnNlLgoKCAoBAhIDEAAmCgkKAgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMD
EgMVACMKCAoBCBIDFwA6CgkKAgglEgMXADoKCAoBCBIDGABeCgkKAggLEgMYAF4KCAoBCBID
GQAiCgkKAggKEgMZACIKCAoBCBIDGgAwCgkKAggIEgMaADAKCAoBCBIDGwA6CgkKAggBEgMb
ADoKCAoBCBIDHAA6CgkKAggpEgMcADoKCAoBCBIDHQA5CgkKAggtEgMdADkKCQoBCBIEHgAh
AgoMCgQInQgAEgQeACECClIKAgYAEgQkADABGkYgU2VydmljZSBJbnRlcmZhY2UgZm9yIHRo
ZSBBcGlnZWUgQ29ubmVjdCBjb25uZWN0aW9uIG1hbmFnZW1lbnQgQVBJcy4KCgoKAwYAARID
JAgZCgoKAwYAAxIDJQJECgwKBQYAA5kIEgMlAkQKCgoDBgADEgMmAlYKDAoFBgADmggSAyYC
VgpjCgQGAAIAEgQqAi8DGlUgTGlzdHMgY29ubmVjdGlvbnMgdGhhdCBhcmUgY3VycmVudGx5
IGFjdGl2ZSBmb3IgdGhlIGdpdmVuIEFwaWdlZSBDb25uZWN0CiBlbmRwb2ludC4KCgwKBQYA
AgABEgMqBhUKDAoFBgACAAISAyoWLAoMCgUGAAIAAxIDKjdOCg0KBQYAAgAEEgQrBC0GChEK
CQYAAgAEsMq8IhIEKwQtBgoMCgUGAAIABBIDLgQ0Cg8KCAYAAgAEmwgAEgMuBDQKTAoCBAAS
BDMASAEaQCBUaGUgcmVxdWVzdCBmb3IgW0xpc3RDb25uZWN0aW9uc11bTWFuYWdlbWVudC5M
aXN0Q29ubmVjdGlvbnNdLgoKCgoDBAABEgMzCB4KdwoEBAACABIENgI7BBppIFJlcXVpcmVk
LiBQYXJlbnQgbmFtZSBvZiB0aGUgZm9ybToKICAgICBgcHJvamVjdHMve3Byb2plY3RfbnVt
YmVyIG9yIHByb2plY3RfaWR9L2VuZHBvaW50cy97ZW5kcG9pbnR9YC4KCgwKBQQAAgAFEgM2
AggKDAoFBAACAAESAzYJDwoMCgUEAAIAAxIDNhITCg0KBQQAAgAIEgQ2FDsDCg8KCAQAAgAI
nAgAEgM3BCoKDwoHBAACAAifCBIEOAQ6BQrsAQoEBAACARIDQAIWGt4BIFRoZSBtYXhpbXVt
IG51bWJlciBvZiBjb25uZWN0aW9ucyB0byByZXR1cm4uIFRoZSBzZXJ2aWNlIG1heSByZXR1
cm4gZmV3ZXIKIHRoYW4gdGhpcyB2YWx1ZS4gSWYgdW5zcGVjaWZpZWQsIGF0IG1vc3QgMTAw
IGNvbm5lY3Rpb25zIHdpbGwgYmUgcmV0dXJuZWQuCiBUaGUgbWF4aW11bSB2YWx1ZSBpcyAx
MDAwOyB2YWx1ZXMgYWJvdmUgMTAwMCB3aWxsIGJlIGNvZXJjZWQgdG8gMTAwMC4KCgwKBQQA
AgEFEgNAAgcKDAoFBAACAQESA0AIEQoMCgUEAAIBAxIDQBQVCvYBCgQEAAICEgNHAhga6AEg
QSBwYWdlIHRva2VuLCByZWNlaXZlZCBmcm9tIGEgcHJldmlvdXMgYExpc3RDb25uZWN0aW9u
c2AgY2FsbC4KIFByb3ZpZGUgdGhpcyB0byByZXRyaWV2ZSB0aGUgc3Vic2VxdWVudCBwYWdl
LgoKIFdoZW4gcGFnaW5hdGluZywgYWxsIG90aGVyIHBhcmFtZXRlcnMgcHJvdmlkZWQgdG8g
YExpc3RDb25uZWN0aW9uc2AgbXVzdAogbWF0Y2ggdGhlIGNhbGwgdGhhdCBwcm92aWRlZCB0
aGUgcGFnZSB0b2tlbi4KCgwKBQQAAgIFEgNHAggKDAoFBAACAgESA0cJEwoMCgUEAAICAxID
RxYXCk4KAgQBEgRMAFMBGkIgVGhlIHJlc3BvbnNlIGZvcgogW0xpc3RDb25uZWN0aW9uc11b
TWFuYWdlbWVudC5MaXN0Q29ubmVjdGlvbnNdLgoKCgoDBAEBEgNMCB8KIQoEBAECABIDTgIm
GhQgQSBsaXN0IG9mIGNsaWVudHMuCgoMCgUEAQIABBIDTgIKCgwKBQQBAgAGEgNOCxUKDAoF
BAECAAESA04WIQoMCgUEAQIAAxIDTiQlCowBCgQEAQIBEgNSAh0afyBBIHRva2VuIHRoYXQg
Y2FuIGJlIHNlbnQgYXMgYHBhZ2VfdG9rZW5gIHRvIHJldHJpZXZlIHRoZSBuZXh0IHBhZ2Uu
CiBJZiB0aGlzIGZpZWxkIGlzIG9taXR0ZWQsIHRoZXJlIGFyZSBubyBzdWJzZXF1ZW50IHBh
Z2VzLgoKDAoFBAECAQUSA1ICCAoMCgUEAQIBARIDUgkYCgwKBQQBAgEDEgNSGxwKCgoCBAIS
BFUAXwEKCgoDBAIBEgNVCBIKegoEBAICABIDWAIWGm0gVGhlIGVuZHBvaW50IHRoYXQgdGhl
IGNvbm5lY3Rpb24gaXMgbWFkZSBhZ2FpbnN0LgogRm9ybWF0OiBgcHJvamVjdHMve3Byb2pl
Y3RfbnVtYmVyfS9lbmRwb2ludHMve2VuZHBvaW50fWAKCgwKBQQCAgAFEgNYAggKDAoFBAIC
AAESA1gJEQoMCgUEAgIAAxIDWBQVCiMKBAQCAgESA1sCFhoWIENsdXN0ZXIgaW5mb3JtYXRp
b24uCgoMCgUEAgIBBhIDWwIJCgwKBQQCAgEBEgNbChEKDAoFBAICAQMSA1sUFQokCgQEAgIC
EgNeAhkaFyBUaGUgY291bnQgb2Ygc3RyZWFtcy4KCgwKBQQCAgIFEgNeAgcKDAoFBAICAgES
A14IFAoMCgUEAgICAxIDXhcYCgoKAgQDEgRhAGcBCgoKAwQDARIDYQgPCicKBAQDAgASA2MC
EhoaIFRoZSBuYW1lIG9mIHRoZSBjbHVzdGVyLgoKDAoFBAMCAAUSA2MCCAoMCgUEAwIAARID
YwkNCgwKBQQDAgADEgNjEBEKKQoEBAMCARIDZgIUGhwgVGhlIHJlZ2lvbiBvZiB0aGUgY2x1
c3Rlci4KCgwKBQQDAgEFEgNmAggKDAoFBAMCAQESA2YJDwoMCgUEAwIBAxIDZhITYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsRequest ===
    # Fields for ListConnectionsRequest
    # Field: parent Type: 9 ()
    # Field: page_size Type: 5 ()
    # Field: page_token Type: 9 ()

# === Message: Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsResponse ===
    # Fields for ListConnectionsResponse
    # Field: connections Type: 11 (.google.cloud.apigeeconnect.v1.Connection)
    # Field: next_page_token Type: 9 ()

# === Message: Google::Cloud::Apigeeconnect::V1::Connection::Connection ===
    # Fields for Connection
    # Field: endpoint Type: 9 ()
    # Field: cluster Type: 11 (.google.cloud.apigeeconnect.v1.Cluster)
    # Field: stream_count Type: 5 ()

# === Message: Google::Cloud::Apigeeconnect::V1::Connection::Cluster ===
    # Fields for Cluster
    # Field: name Type: 9 ()
    # Field: region Type: 9 ()

# === Service Client: Google::Cloud::Apigeeconnect::V1::Connection::ConnectionServiceClient ===
package Google::Cloud::Apigeeconnect::V1::Connection::ConnectionServiceClient;

=pod

=head2 Service Client: Google::Cloud::Apigeeconnect::V1::Connection::ConnectionServiceClient

Client stub representing the remote C<ConnectionService> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<apigeeconnect.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'apigeeconnect.googleapis.com:443' );

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

sub list_connections {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.cloud.apigeeconnect.v1.ConnectionService',
        method         => 'ListConnections',
        request        => $req,
        response_class => 'Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Apigeeconnect::V1::Connection - Compiled Protocol Buffers messages for google/cloud/apigeeconnect/v1/connection.proto

=head1 SYNOPSIS

    use Google::Cloud::Apigeeconnect::V1::Connection;

    my $msg = Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsRequest->new({
        parent => $parent,
        page_size => $page_size,
        page_token => $page_token,
    });

    # Read or update a field
    my $val = $msg->parent();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/apigeeconnect/v1/connection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsRequest

The request for [ListConnections][Management.ListConnections].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. Parent name of the form:
    `projects/{project_number or project_id}/endpoints/{endpoint}`.

=item * C<< $msg->page_size() >> / C<< $msg->page_size($value) >>

Type: C<Int32>

The maximum number of connections to return. The service may return fewer
than this value. If unspecified, at most 100 connections will be returned.
The maximum value is 1000; values above 1000 will be coerced to 1000.

=item * C<< $msg->page_token() >> / C<< $msg->page_token($value) >>

Type: C<String>

A page token, received from a previous `ListConnections` call.
Provide this to retrieve the subsequent page.

When paginating, all other parameters provided to `ListConnections` must
match the call that provided the page token.

=back

=head2 Google::Cloud::Apigeeconnect::V1::Connection::ListConnectionsResponse

The response for
[ListConnections][Management.ListConnections].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->connections() >> / C<< $msg->connections($value) >>

Type: C<Message> (L<Google::Cloud::Apigeeconnect::V1::Connection::Connection>)

A list of clients.

=item * C<< $msg->next_page_token() >> / C<< $msg->next_page_token($value) >>

Type: C<String>

A token that can be sent as `page_token` to retrieve the next page.
If this field is omitted, there are no subsequent pages.

=back

=head2 Google::Cloud::Apigeeconnect::V1::Connection::Connection

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->endpoint() >> / C<< $msg->endpoint($value) >>

Type: C<String>

The endpoint that the connection is made against.
Format: `projects/{project_number}/endpoints/{endpoint}`

=item * C<< $msg->cluster() >> / C<< $msg->cluster($value) >>

Type: C<Message> (L<Google::Cloud::Apigeeconnect::V1::Connection::Cluster>)

Cluster information.

=item * C<< $msg->stream_count() >> / C<< $msg->stream_count($value) >>

Type: C<Int32>

The count of streams.

=back

=head2 Google::Cloud::Apigeeconnect::V1::Connection::Cluster

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The name of the cluster.

=item * C<< $msg->region() >> / C<< $msg->region($value) >>

Type: C<String>

The region of the cluster.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Apigeeconnect::V1::Connection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
