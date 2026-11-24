package Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Annotations };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvZmlyZWJhc2UvZmNtL2Nvbm5lY3Rpb24vdjFhbHBoYTEvY29ubmVjdGlvbl9h
cGkucHJvdG8SJ2dvb2dsZS5maXJlYmFzZS5mY20uY29ubmVjdGlvbi52MWFscGhhMRocZ29v
Z2xlL2FwaS9hbm5vdGF0aW9ucy5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5w
cm90byJjCg9VcHN0cmVhbVJlcXVlc3QSQAoDYWNrGAEgASgLMiwuZ29vZ2xlLmZpcmViYXNl
LmZjbS5jb25uZWN0aW9uLnYxYWxwaGExLkFja0gAUgNhY2tCDgoMcmVxdWVzdF90eXBlInMK
EkRvd25zdHJlYW1SZXNwb25zZRJMCgdtZXNzYWdlGAEgASgLMjAuZ29vZ2xlLmZpcmViYXNl
LmZjbS5jb25uZWN0aW9uLnYxYWxwaGExLk1lc3NhZ2VIAFIHbWVzc2FnZUIPCg1yZXNwb25z
ZV90eXBlIiQKA0FjaxIdCgptZXNzYWdlX2lkGAEgASgJUgltZXNzYWdlSWQiqwIKB01lc3Nh
Z2USHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEjsKC2NyZWF0ZV90aW1lGAIgASgL
MhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIKY3JlYXRlVGltZRI7CgtleHBpcmVfdGlt
ZRgDIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmV4cGlyZVRpbWUSTgoEZGF0
YRgEIAMoCzI6Lmdvb2dsZS5maXJlYmFzZS5mY20uY29ubmVjdGlvbi52MWFscGhhMS5NZXNz
YWdlLkRhdGFFbnRyeVIEZGF0YRo3CglEYXRhRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoF
dmFsdWUYAiABKAlSBXZhbHVlOgI4ATKYAQoNQ29ubmVjdGlvbkFwaRKGAQoHQ29ubmVjdBI4
Lmdvb2dsZS5maXJlYmFzZS5mY20uY29ubmVjdGlvbi52MWFscGhhMS5VcHN0cmVhbVJlcXVl
c3QaOy5nb29nbGUuZmlyZWJhc2UuZmNtLmNvbm5lY3Rpb24udjFhbHBoYTEuRG93bnN0cmVh
bVJlc3BvbnNlIgAoATABQoIBCitjb20uZ29vZ2xlLmZpcmViYXNlLmZjbS5jb25uZWN0aW9u
LnYxYWxwaGExUAFaUWdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMvZmly
ZWJhc2UvZmNtL2Nvbm5lY3Rpb24vdjFhbHBoYTE7Y29ubmVjdGlvbkrRFgoGEgQPAFgBCr0E
CgEMEgMPABIysgQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCggKAQISAxEAMAoJCgIDABIDEwAm
CgkKAgMBEgMUACkKCAoBCBIDFgBoCgkKAggLEgMWAGgKCAoBCBIDFwAiCgkKAggKEgMXACIK
CAoBCBIDGABECgkKAggBEgMYAEQKUgoCBgASBBsAKgEaRiBGQ00ncyBzZXJ2aWNlIHRvIGNy
ZWF0ZSBjbGllbnQgY29ubmVjdGlvbnMgdG8gc2VuZC9yZWNlaXZlIG1lc3NhZ2VzLgoKCgoD
BgABEgMbCBUKuwMKBAYAAgASBCgCKQMarAMgQ3JlYXRlcyBhIHN0cmVhbWluZyBjb25uZWN0
aW9uIHdpdGggRkNNIHRvIHNlbmQgbWVzc2FnZXMgYW5kIHRoZWlyCiByZXNwZWN0aXZlIEFD
S3MuCgogVGhlIGNsaWVudCBjcmVkZW50aWFscyBuZWVkIHRvIGJlIHBhc3NlZCBpbiB0aGUg
W2dSUEMKIE1ldGFkYXRhXShodHRwczovL2dycGMuaW8vZG9jcy9ndWlkZXMvY29uY2VwdHMu
aHRtbCNtZXRhZGF0YSkuIFRoZSBGb3JtYXQKIG9mIHRoZSBoZWFkZXIgaXM6CiAgIEtleTog
ImF1dGhvcml6YXRpb24iCiAgIFZhbHVlOiAiQ2hlY2tpbiBbY2xpZW50X2lkOnNlY3JldF0i
CgoKIFRoZSBwcm9qZWN0J3MgQVBJIGtleSBhbHNvIG5lZWRzIHRvIGJlIHNlbnQgdG8gYXV0
aG9yaXplIHRoZSBwcm9qZWN0LgogVGhhdCBjYW4gYmUgc2V0IGluIHRoZSBYLUdvb2ctQXBp
LUtleSBNZXRhZGF0YSBoZWFkZXIuCgoMCgUGAAIAARIDKAYNCgwKBQYAAgAFEgMoDhQKDAoF
BgACAAISAygVJAoMCgUGAAIABhIDKC81CgwKBQYAAgADEgMoNkgKPAoCBAASBC0AMwEaMCBS
ZXF1ZXN0IHNlbnQgdG8gRkNNIGZyb20gdGhlIGNvbm5lY3RlZCBjbGllbnQuCgoKCgMEAAES
Ay0IFwpACgQEAAgAEgQvAjIDGjIgVGhlIHR5cGUgb2YgcmVxdWVzdCB0aGUgY2xpZW50IGlz
IG1ha2luZyB0byBGQ00uCgoMCgUEAAgAARIDLwgUCicKBAQAAgASAzEEEBoaIE1lc3NhZ2Ug
YWNrbm93bGVkZ2VtZW50LgoKDAoFBAACAAYSAzEEBwoMCgUEAAIAARIDMQgLCgwKBQQAAgAD
EgMxDg8KPQoCBAESBDYAPgEaMSBSZXNwb25zZSBzZW50IHRvIHRoZSBjb25uZWN0ZWQgY2xp
ZW50IGZyb20gRkNNLgoKCgoDBAEBEgM2CBoKQgoEBAEIABIEOAI9Axo0IFRoZSB0eXBlIG9m
IHJlc3BvbnNlIEZDTSBpcyBzZW5kaW5nIHRvIHRoZSBjbGllbnQuCgoMCgUEAQgAARIDOAgV
Co4BCgQEAQIAEgM8BBgagAEgTWVzc2FnZSBzZW50IHRvIEZDTSB2aWEgdGhlIFtTZW5kCiBB
UEldKGh0dHBzOi8vZmlyZWJhc2UuZ29vZ2xlLmNvbS9kb2NzL2Nsb3VkLW1lc3NhZ2luZy9z
ZW5kLW1lc3NhZ2UpCiB0YXJnZXRpbmcgdGhpcyBjbGllbnQuCgoMCgUEAQIABhIDPAQLCgwK
BQQBAgABEgM8DBMKDAoFBAECAAMSAzwWFwrpAQoCBAISBEQARwEa3AEgQWNrbm93bGVkZ2Vt
ZW50IHRvIGluZGljYXRlIGEgY2xpZW50IHN1Y2Nlc3NmdWxseSByZWNlaXZlZCBhbiBGQ00g
bWVzc2FnZS4KCiBJZiBhIG1lc3NhZ2UgaXMgbm90IGFja2VkLCBGQ00gd2lsbCBjb250aW5v
dXNseSByZXNlbmQgdGhlIG1lc3NhZ2UgdW50aWwKIGl0IGV4cGlyZXMuIER1cGxpY2F0ZSBk
ZWxpdmVyeSBpbiB0aGlzIGNhc2UgaXMgd29ya2luZyBhcyBpbnRlbmRlZC4KCgoKAwQCARID
RAgLCi8KBAQCAgASA0YCGBoiIElkIG9mIG1lc3NhZ2UgYmVpbmcgYWNrbm93bGVkZ2VkCgoM
CgUEAgIABRIDRgIICgwKBQQCAgABEgNGCRMKDAoFBAICAAMSA0YWFwqSAQoCBAMSBEsAWAEa
hQEgTWVzc2FnZSBjcmVhdGVkIHRocm91Z2ggdGhlIFtTZW5kCiBBUEldKGh0dHBzOi8vZmly
ZWJhc2UuZ29vZ2xlLmNvbS9kb2NzL3JlZmVyZW5jZS9mY20vcmVzdC92MS9wcm9qZWN0cy5t
ZXNzYWdlcyNyZXNvdXJjZS1tZXNzYWdlKS4KCgoKAwQDARIDSwgPCkYKBAQDAgASA00CGBo5
IFRoZSBpZGVudGlmaWVyIG9mIHRoZSBtZXNzYWdlLiBVc2VkIHRvIGFjayB0aGUgbWVzc2Fn
ZS4KCgwKBQQDAgAFEgNNAggKDAoFBAMCAAESA00JEwoMCgUEAwIAAxIDTRYXCjQKBAQDAgES
A1ACLBonIFRpbWUgdGhlIG1lc3NhZ2Ugd2FzIHJlY2VpdmVkIGluIEZDTS4KCgwKBQQDAgEG
EgNQAhsKDAoFBAMCAQESA1AcJwoMCgUEAwIBAxIDUCorCkoKBAQDAgISA1MCLBo9IEV4cGly
eSB0aW1lIG9mIHRoZSBtZXNzYWdlLiBDdXJyZW50bHkgaXQgaXMgYWx3YXlzIDQgd2Vla3Mu
CgoMCgUEAwICBhIDUwIbCgwKBQQDAgIBEgNTHCcKDAoFBAMCAgMSA1MqKwqYAQoEBAMCAxID
VwIfGooBIFRoZSBhcmJpdHJhcnkgcGF5bG9hZCBzZXQgaW4gdGhlIFtTZW5kCiBBUEldKGh0
dHBzOi8vZmlyZWJhc2UuZ29vZ2xlLmNvbS9kb2NzL3JlZmVyZW5jZS9mY20vcmVzdC92MS9w
cm9qZWN0cy5tZXNzYWdlcyNyZXNvdXJjZS1tZXNzYWdlKS4KCgwKBQQDAgMGEgNXAhUKDAoF
BAMCAwESA1cWGgoMCgUEAwIDAxIDVx0eYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::UpstreamRequest ===
    # Fields for UpstreamRequest
    # Field: ack Type: 11 (.google.firebase.fcm.connection.v1alpha1.Ack)

# === Message: Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::DownstreamResponse ===
    # Fields for DownstreamResponse
    # Field: message Type: 11 (.google.firebase.fcm.connection.v1alpha1.Message)

# === Message: Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Ack ===
    # Fields for Ack
    # Field: message_id Type: 9 ()

# === Message: Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Message ===
    # Fields for Message
    # Field: message_id Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: expire_time Type: 11 (.google.protobuf.Timestamp)
    # Field: data Type: 11 (.google.firebase.fcm.connection.v1alpha1.Message.DataEntry)

# === Service Client: Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::ConnectionApiClient ===
package Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::ConnectionApiClient;

=pod

=head2 Service Client: Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::ConnectionApiClient

Client stub representing the remote C<ConnectionApi> gRPC service. Delegates call dispatching to L<Google::gRPC::Client>.

=head3 target

The endpoint target address. Defaults to C<firebase.googleapis.com:443>.

=head3 credentials

The authentication credentials provider. Defaults to application default credentials via L<Google::Auth>.

=cut

use Moo;
use Google::Auth;
use Google::gRPC::Client;

has credentials => ( is => 'ro', default => sub { Google::Auth->default() } );
has target      => ( is => 'ro', default => 'firebase.googleapis.com:443' );

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

sub connect {
    my ($self, $args) = @_;
    my $req = ref($args) eq 'HASH'
        ? Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::UpstreamRequest->new($args)
        : $args;
    return $self->_grpc_client->call({
        service        => 'google.firebase.fcm.connection.v1alpha1.ConnectionApi',
        method         => 'Connect',
        request        => $req,
        response_class => 'Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::DownstreamResponse',
    });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi - Compiled Protocol Buffers messages for google/firebase/fcm/connection/v1alpha1/connection_api.proto

=head1 SYNOPSIS

    use Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi;

    my $msg = Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::UpstreamRequest->new({
        ack => $ack,
    });

    # Read or update a field
    my $val = $msg->ack();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::UpstreamRequest->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/firebase/fcm/connection/v1alpha1/connection_api.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::UpstreamRequest

Request sent to FCM from the connected client.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->ack() >> / C<< $msg->ack($value) >>

Type: C<Message> (L<Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Ack>)

Message acknowledgement.

=back

=head2 Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::DownstreamResponse

Response sent to the connected client from FCM.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<Message> (L<Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Message>)

Message sent to FCM via the [Send
API](https://firebase.google.com/docs/cloud-messaging/send-message)
targeting this client.

=back

=head2 Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Ack

Acknowledgement to indicate a client successfully received an FCM message.

If a message is not acked, FCM will continously resend the message until
it expires. Duplicate delivery in this case is working as intended.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message_id() >> / C<< $msg->message_id($value) >>

Type: C<String>

Id of message being acknowledged

=back

=head2 Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Message

Message created through the [Send
API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#resource-message).

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message_id() >> / C<< $msg->message_id($value) >>

Type: C<String>

The identifier of the message. Used to ack the message.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Time the message was received in FCM.

=item * C<< $msg->expire_time() >> / C<< $msg->expire_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Expiry time of the message. Currently it is always 4 weeks.

=item * C<< $msg->data() >> / C<< $msg->data($value) >>

Type: C<Message> (L<Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Message::DataEntry>)

The arbitrary payload set in the [Send
API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#resource-message).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Firebase::Fcm::Connection::V1alpha1::ConnectionApi::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
