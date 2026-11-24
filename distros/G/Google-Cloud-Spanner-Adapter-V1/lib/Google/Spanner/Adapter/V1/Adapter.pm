package Google::Spanner::Adapter::V1::Adapter;

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
Cidnb29nbGUvc3Bhbm5lci9hZGFwdGVyL3YxL2FkYXB0ZXIucHJvdG8SGWdvb2dsZS5zcGFu
bmVyLmFkYXB0ZXIudjEaHGdvb2dsZS9hcGkvYW5ub3RhdGlvbnMucHJvdG8aF2dvb2dsZS9h
cGkvY2xpZW50LnByb3RvGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29n
bGUvYXBpL3Jlc291cmNlLnByb3RvIrkCChNBZGFwdE1lc3NhZ2VSZXF1ZXN0EjoKBG5hbWUY
ASABKAlCJuBBAvpBIAoec3Bhbm5lci5nb29nbGVhcGlzLmNvbS9TZXNzaW9uUgRuYW1lEh8K
CHByb3RvY29sGAIgASgJQgPgQQJSCHByb3RvY29sEh0KB3BheWxvYWQYAyABKAxCA+BBAVIH
cGF5bG9hZBJmCgthdHRhY2htZW50cxgEIAMoCzI/Lmdvb2dsZS5zcGFubmVyLmFkYXB0ZXIu
djEuQWRhcHRNZXNzYWdlUmVxdWVzdC5BdHRhY2htZW50c0VudHJ5QgPgQQFSC2F0dGFjaG1l
bnRzGj4KEEF0dGFjaG1lbnRzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiAB
KAlSBXZhbHVlOgI4ASL8AQoUQWRhcHRNZXNzYWdlUmVzcG9uc2USHQoHcGF5bG9hZBgBIAEo
DEID4EEBUgdwYXlsb2FkEmsKDXN0YXRlX3VwZGF0ZXMYAiADKAsyQS5nb29nbGUuc3Bhbm5l
ci5hZGFwdGVyLnYxLkFkYXB0TWVzc2FnZVJlc3BvbnNlLlN0YXRlVXBkYXRlc0VudHJ5QgPg
QQFSDHN0YXRlVXBkYXRlcxIXCgRsYXN0GAMgASgIQgPgQQFSBGxhc3QaPwoRU3RhdGVVcGRh
dGVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ASKt
AQoHU2Vzc2lvbhIXCgRuYW1lGAEgASgJQgPgQQhSBG5hbWU6iAHqQYQBCh5zcGFubmVyLmdv
b2dsZWFwaXMuY29tL1Nlc3Npb24ST3Byb2plY3RzL3twcm9qZWN0fS9pbnN0YW5jZXMve2lu
c3RhbmNlfS9kYXRhYmFzZXMve2RhdGFiYXNlfS9zZXNzaW9ucy97c2Vzc2lvbn0qCHNlc3Np
b25zMgdzZXNzaW9uIpoBChRDcmVhdGVTZXNzaW9uUmVxdWVzdBI/CgZwYXJlbnQYASABKAlC
J+BBAvpBIQofc3Bhbm5lci5nb29nbGVhcGlzLmNvbS9EYXRhYmFzZVIGcGFyZW50EkEKB3Nl
c3Npb24YAiABKAsyIi5nb29nbGUuc3Bhbm5lci5hZGFwdGVyLnYxLlNlc3Npb25CA+BBAlIH
c2Vzc2lvbjKTBAoHQWRhcHRlchLIAQoNQ3JlYXRlU2Vzc2lvbhIvLmdvb2dsZS5zcGFubmVy
LmFkYXB0ZXIudjEuQ3JlYXRlU2Vzc2lvblJlcXVlc3QaIi5nb29nbGUuc3Bhbm5lci5hZGFw
dGVyLnYxLlNlc3Npb24iYoLT5JMCSyJAL3YxL3twYXJlbnQ9cHJvamVjdHMvKi9pbnN0YW5j
ZXMvKi9kYXRhYmFzZXMvKn0vc2Vzc2lvbnM6YWRhcHRlcjoHc2Vzc2lvbtpBDnBhcmVudCxz
ZXNzaW9uEsMBCgxBZGFwdE1lc3NhZ2USLi5nb29nbGUuc3Bhbm5lci5hZGFwdGVyLnYxLkFk
YXB0TWVzc2FnZVJlcXVlc3QaLy5nb29nbGUuc3Bhbm5lci5hZGFwdGVyLnYxLkFkYXB0TWVz
c2FnZVJlc3BvbnNlIlCC0+STAkoiRS92MS97bmFtZT1wcm9qZWN0cy8qL2luc3RhbmNlcy8q
L2RhdGFiYXNlcy8qL3Nlc3Npb25zLyp9OmFkYXB0TWVzc2FnZToBKjABGnfKQRZzcGFubmVy
Lmdvb2dsZWFwaXMuY29t0kFbaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9jbG91
ZC1wbGF0Zm9ybSxodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9hdXRoL3NwYW5uZXIuZGF0
YUK6AgodY29tLmdvb2dsZS5zcGFubmVyLmFkYXB0ZXIudjFCDEFkYXB0ZXJQcm90b1ABWj1j
bG91ZC5nb29nbGUuY29tL2dvL3NwYW5uZXIvYWRhcHRlci9hcGl2MS9hZGFwdGVycGI7YWRh
cHRlcnBiqgIfR29vZ2xlLkNsb3VkLlNwYW5uZXIuQWRhcHRlci5WMcoCH0dvb2dsZVxDbG91
ZFxTcGFubmVyXEFkYXB0ZXJcVjHqAiNHb29nbGU6OkNsb3VkOjpTcGFubmVyOjpBZGFwdGVy
OjpWMepBXwofc3Bhbm5lci5nb29nbGVhcGlzLmNvbS9EYXRhYmFzZRI8cHJvamVjdHMve3By
b2plY3R9L2luc3RhbmNlcy97aW5zdGFuY2V9L2RhdGFiYXNlcy97ZGF0YWJhc2V9Ss0dCgcS
BQ4AgAEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vu
c2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5z
ZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3
aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNl
IGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoK
IFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3Jp
dGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3Ry
aWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09O
RElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0
aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNz
aW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAiCgkK
AgMAEgMSACYKCQoCAwESAxMAIQoJCgIDAhIDFAApCgkKAgMDEgMVACMKCAoBCBIDFwA8CgkK
AgglEgMXADwKCAoBCBIDGABUCgkKAggLEgMYAFQKCAoBCBIDGQAiCgkKAggKEgMZACIKCAoB
CBIDGgAtCgkKAggIEgMaAC0KCAoBCBIDGwA2CgkKAggBEgMbADYKCAoBCBIDHAA9CgkKAggp
EgMcAD0KCAoBCBIDHQA8CgkKAggtEgMdADwKCQoBCBIEHgAhAgoMCgQInQgAEgQeACECCvkB
CgIGABIEKABCARrsASBDbG91ZCBTcGFubmVyIEFkYXB0ZXIgQVBJCgogVGhlIENsb3VkIFNw
YW5uZXIgQWRhcHRlciBzZXJ2aWNlIGFsbG93cyBuYXRpdmUgZHJpdmVycyBvZiBzdXBwb3J0
ZWQgZGF0YWJhc2UKIGRpYWxlY3RzIHRvIGludGVyYWN0IGRpcmVjdGx5IHdpdGggQ2xvdWQg
U3Bhbm5lciBieSB3cmFwcGluZyB0aGUgdW5kZXJseWluZwogd2lyZSBwcm90b2NvbCB1c2Vk
IGJ5IHRoZSBkcml2ZXIgaW4gYSBnUlBDIHN0cmVhbS4KCgoKAwYAARIDKAgPCgoKAwYAAxID
KQI+CgwKBQYAA5kIEgMpAj4KCwoDBgADEgQqAiw1Cg0KBQYAA5oIEgQqAiw1CtQBCgQGAAIA
EgQxAjcDGsUBIENyZWF0ZXMgYSBuZXcgc2Vzc2lvbiB0byBiZSB1c2VkIGZvciByZXF1ZXN0
cyBtYWRlIGJ5IHRoZSBhZGFwdGVyLgogQSBzZXNzaW9uIGlkZW50aWZpZXMgYSBzcGVjaWZp
YyBpbmNhcm5hdGlvbiBvZiBhIGRhdGFiYXNlIHJlc291cmNlIGFuZCBpcwogbWVhbnQgdG8g
YmUgcmV1c2VkIGFjcm9zcyBtYW55IGBBZGFwdE1lc3NhZ2VgIGNhbGxzLgoKDAoFBgACAAES
AzEGEwoMCgUGAAIAAhIDMRQoCgwKBQYAAgADEgMxMzoKDQoFBgACAAQSBDIENQYKEQoJBgAC
AASwyrwiEgQyBDUGCgwKBQYAAgAEEgM2BDwKDwoIBgACAASbCAASAzYEPAq6AQoEBgACARIE
PAJBAxqrASBIYW5kbGVzIGEgc2luZ2xlIG1lc3NhZ2UgZnJvbSB0aGUgY2xpZW50IGFuZCBy
ZXR1cm5zIHRoZSByZXN1bHQgYXMgYQogc3RyZWFtLiBUaGUgc2VydmVyIHdpbGwgaW50ZXJw
cmV0IHRoZSBtZXNzYWdlIGZyYW1lIGFuZCByZXNwb25kIHdpdGgKIG1lc3NhZ2UgZnJhbWVz
IHRvIHRoZSBjbGllbnQuCgoMCgUGAAIBARIDPAYSCgwKBQYAAgECEgM8EyYKDAoFBgACAQYS
AzwxNwoMCgUGAAIBAxIDPDhMCg0KBQYAAgEEEgQ9BEAGChEKCQYAAgEEsMq8IhIEPQRABgo4
CgIEABIERQBUARosIE1lc3NhZ2Ugc2VudCBieSB0aGUgY2xpZW50IHRvIHRoZSBhZGFwdGVy
LgoKCgoDBAABEgNFCBsKWQoEBAACABIERwJKBBpLIFJlcXVpcmVkLiBUaGUgZGF0YWJhc2Ug
c2Vzc2lvbiBpbiB3aGljaCB0aGUgYWRhcHRlciByZXF1ZXN0IGlzIHByb2Nlc3NlZC4KCgwK
BQQAAgAFEgNHAggKDAoFBAACAAESA0cJDQoMCgUEAAIAAxIDRxARCg0KBQQAAgAIEgRHEkoD
Cg8KCAQAAgAInAgAEgNIBCoKDgoHBAACAAifCBIDSQRQCkUKBAQAAgESA00CPxo4IFJlcXVp
cmVkLiBJZGVudGlmaWVyIGZvciB0aGUgdW5kZXJseWluZyB3aXJlIHByb3RvY29sLgoKDAoF
BAACAQUSA00CCAoMCgUEAAIBARIDTQkRCgwKBQQAAgEDEgNNFBUKDAoFBAACAQgSA00WPgoP
CggEAAIBCJwIABIDTRc9Ck8KBAQAAgISA1ACPRpCIE9wdGlvbmFsLiBVbmludGVycHJldGVk
IGJ5dGVzIGZyb20gdGhlIHVuZGVybHlpbmcgd2lyZSBwcm90b2NvbC4KCgwKBQQAAgIFEgNQ
AgcKDAoFBAACAgESA1AIDwoMCgUEAAICAxIDUBITCgwKBQQAAgIIEgNQFDwKDwoIBAACAgic
CAASA1AVOwpRCgQEAAIDEgNTAk8aRCBPcHRpb25hbC4gT3BhcXVlIHJlcXVlc3Qgc3RhdGUg
cGFzc2VkIGJ5IHRoZSBjbGllbnQgdG8gdGhlIHNlcnZlci4KCgwKBQQAAgMGEgNTAhUKDAoF
BAACAwESA1MWIQoMCgUEAAIDAxIDUyQlCgwKBQQAAgMIEgNTJk4KDwoIBAACAwicCAASA1Mn
TQo4CgIEARIEVwBkARosIE1lc3NhZ2Ugc2VudCBieSB0aGUgYWRhcHRlciB0byB0aGUgY2xp
ZW50LgoKCgoDBAEBEgNXCBwKTwoEBAECABIDWQI9GkIgT3B0aW9uYWwuIFVuaW50ZXJwcmV0
ZWQgYnl0ZXMgZnJvbSB0aGUgdW5kZXJseWluZyB3aXJlIHByb3RvY29sLgoKDAoFBAECAAUS
A1kCBwoMCgUEAQIAARIDWQgPCgwKBQQBAgADEgNZEhMKDAoFBAECAAgSA1kUPAoPCggEAQIA
CJwIABIDWRU7CksKBAQBAgESBFwCXS8aPSBPcHRpb25hbC4gT3BhcXVlIHN0YXRlIHVwZGF0
ZXMgdG8gYmUgYXBwbGllZCBieSB0aGUgY2xpZW50LgoKDAoFBAECAQYSA1wCFQoMCgUEAQIB
ARIDXBYjCgwKBQQBAgEDEgNcJicKDAoFBAECAQgSA10GLgoPCggEAQIBCJwIABIDXQctCoMC
CgQEAQICEgNjAjka9QEgT3B0aW9uYWwuIEluZGljYXRlcyB3aGV0aGVyIHRoaXMgaXMgdGhl
IGxhc3QKIFtBZGFwdE1lc3NhZ2VSZXNwb25zZV1bZ29vZ2xlLnNwYW5uZXIuYWRhcHRlci52
MS5BZGFwdE1lc3NhZ2VSZXNwb25zZV0gaW4KIHRoZSBzdHJlYW0uIFRoaXMgZmllbGQgbWF5
IGJlIG9wdGlvbmFsbHkgc2V0IGJ5IHRoZSBzZXJ2ZXIuIENsaWVudHMgc2hvdWxkCiBub3Qg
cmVseSBvbiB0aGlzIGZpZWxkIGJlaW5nIHNldCBpbiBhbGwgY2FzZXMuCgoMCgUEAQICBRID
YwIGCgwKBQQBAgIBEgNjBwsKDAoFBAECAgMSA2MODwoMCgUEAQICCBIDYxA4Cg8KCAQBAgII
nAgAEgNjETcKOQoCBAISBGcAcQEaLSBBIHNlc3Npb24gaW4gdGhlIENsb3VkIFNwYW5uZXIg
QWRhcHRlciBBUEkuCgoKCgMEAgESA2cIDwoLCgMEAgcSBGgCbQQKDQoFBAIHnQgSBGgCbQQK
UwoEBAICABIDcAI9GkYgSWRlbnRpZmllci4gVGhlIG5hbWUgb2YgdGhlIHNlc3Npb24uIFRo
aXMgaXMgYWx3YXlzIHN5c3RlbS1hc3NpZ25lZC4KCgwKBQQCAgAFEgNwAggKDAoFBAICAAES
A3AJDQoMCgUEAgIAAxIDcBARCgwKBQQCAgAIEgNwEjwKDwoIBAICAAicCAASA3ATOwpVCgIE
AxIFdQCAAQEaSCBUaGUgcmVxdWVzdCBmb3IKIFtDcmVhdGVTZXNzaW9uUmVxdWVzdF1bQWRh
cHRlci5DcmVhdGVTZXNzaW9uUmVxdWVzdF0uCgoKCgMEAwESA3UIHApLCgQEAwIAEgR3AnwE
Gj0gUmVxdWlyZWQuIFRoZSBkYXRhYmFzZSBpbiB3aGljaCB0aGUgbmV3IHNlc3Npb24gaXMg
Y3JlYXRlZC4KCgwKBQQDAgAFEgN3AggKDAoFBAMCAAESA3cJDwoMCgUEAwIAAxIDdxITCg0K
BQQDAgAIEgR3FHwDCg8KCAQDAgAInAgAEgN4BCoKDwoHBAMCAAifCBIEeQR7BQovCgQEAwIB
EgN/Aj8aIiBSZXF1aXJlZC4gVGhlIHNlc3Npb24gdG8gY3JlYXRlLgoKDAoFBAMCAQYSA38C
CQoMCgUEAwIBARIDfwoRCgwKBQQDAgEDEgN/FBUKDAoFBAMCAQgSA38WPgoPCggEAwIBCJwI
ABIDfxc9YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest ===
    # Fields for AdaptMessageRequest
    # Field: name Type: 9 ()
    # Field: protocol Type: 9 ()
    # Field: payload Type: 12 ()
    # Field: attachments Type: 11 (.google.spanner.adapter.v1.AdaptMessageRequest.AttachmentsEntry)

# === Message: Google::Spanner::Adapter::V1::Adapter::AdaptMessageResponse ===
    # Fields for AdaptMessageResponse
    # Field: payload Type: 12 ()
    # Field: state_updates Type: 11 (.google.spanner.adapter.v1.AdaptMessageResponse.StateUpdatesEntry)
    # Field: last Type: 8 ()

# === Message: Google::Spanner::Adapter::V1::Adapter::Session ===
    # Fields for Session
    # Field: name Type: 9 ()

# === Message: Google::Spanner::Adapter::V1::Adapter::CreateSessionRequest ===
    # Fields for CreateSessionRequest
    # Field: parent Type: 9 ()
    # Field: session Type: 11 (.google.spanner.adapter.v1.Session)

# === Service Client: Google::Spanner::Adapter::V1::Adapter::AdapterClient ===
package Google::Spanner::Adapter::V1::Adapter::AdapterClient;

=pod

=head2 Service Client: Google::Spanner::Adapter::V1::Adapter::AdapterClient

Client stub representing the remote C<Adapter> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<spanner.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'spanner.googleapis.com:443' );

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

sub create_session {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Spanner::Adapter::V1::Adapter::CreateSessionRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.spanner.adapter.v1.Adapter',
        method         => 'CreateSession',
        request        => $req,
        response_class => 'Google::Spanner::Adapter::V1::Adapter::Session',
    });
}

sub adapt_message {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.spanner.adapter.v1.Adapter',
        method         => 'AdaptMessage',
        request        => $req,
        response_class => 'Google::Spanner::Adapter::V1::Adapter::AdaptMessageResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Spanner::Adapter::V1::Adapter - Compiled Protocol Buffers messages for google/spanner/adapter/v1/adapter.proto

=head1 SYNOPSIS

    use Google::Spanner::Adapter::V1::Adapter;

    my $msg = Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest->new({
        name => $name,
        protocol => $protocol,
        payload => $payload,
        attachments => $attachments,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/spanner/adapter/v1/adapter.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest

Message sent by the client to the adapter.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The database session in which the adapter request is processed.

=item * C<< $msg->protocol() >> / C<< $msg->protocol($value) >>

Type: C<String>

Required. Identifier for the underlying wire protocol.

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Bytes>

Optional. Uninterpreted bytes from the underlying wire protocol.

=item * C<< $msg->attachments() >> / C<< $msg->attachments($value) >>

Type: C<Message> (L<Google::Spanner::Adapter::V1::Adapter::AdaptMessageRequest::AttachmentsEntry>)

Optional. Opaque request state passed by the client to the server.

=back

=head2 Google::Spanner::Adapter::V1::Adapter::AdaptMessageResponse

Message sent by the adapter to the client.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->payload() >> / C<< $msg->payload($value) >>

Type: C<Bytes>

Optional. Uninterpreted bytes from the underlying wire protocol.

=item * C<< $msg->state_updates() >> / C<< $msg->state_updates($value) >>

Type: C<Message> (L<Google::Spanner::Adapter::V1::Adapter::AdaptMessageResponse::StateUpdatesEntry>)

Optional. Opaque state updates to be applied by the client.

=item * C<< $msg->last() >> / C<< $msg->last($value) >>

Type: C<Bool>

Optional. Indicates whether this is the last
[AdaptMessageResponse][google.spanner.adapter.v1.AdaptMessageResponse] in
the stream. This field may be optionally set by the server. Clients should
not rely on this field being set in all cases.

=back

=head2 Google::Spanner::Adapter::V1::Adapter::Session

A session in the Cloud Spanner Adapter API.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The name of the session. This is always system-assigned.

=back

=head2 Google::Spanner::Adapter::V1::Adapter::CreateSessionRequest

The request for
[CreateSessionRequest][Adapter.CreateSessionRequest].

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->parent() >> / C<< $msg->parent($value) >>

Type: C<String>

Required. The database in which the new session is created.

=item * C<< $msg->session() >> / C<< $msg->session($value) >>

Type: C<Message> (L<Google::Spanner::Adapter::V1::Adapter::Session>)

Required. The session to create.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Spanner::Adapter::V1::Adapter::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
