package Google::Cloud::Eventarc::V1::ChannelConnection;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvZXZlbnRhcmMvdjEvY2hhbm5lbF9jb25uZWN0aW9uLnByb3RvEhhn
b29nbGUuY2xvdWQuZXZlbnRhcmMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJv
dG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3Rh
bXAucHJvdG8i9QQKEUNoYW5uZWxDb25uZWN0aW9uEhcKBG5hbWUYASABKAlCA+BBAlIEbmFt
ZRIVCgN1aWQYAiABKAlCA+BBA1IDdWlkEkEKB2NoYW5uZWwYBSABKAlCJ+BBAvpBIQofZXZl
bnRhcmMuZ29vZ2xlYXBpcy5jb20vQ2hhbm5lbFIHY2hhbm5lbBJACgtjcmVhdGVfdGltZRgG
IAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1
cGRhdGVfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBk
YXRlVGltZRIuChBhY3RpdmF0aW9uX3Rva2VuGAggASgJQgPgQQRSD2FjdGl2YXRpb25Ub2tl
bhJUCgZsYWJlbHMYCSADKAsyNy5nb29nbGUuY2xvdWQuZXZlbnRhcmMudjEuQ2hhbm5lbENv
bm5lY3Rpb24uTGFiZWxzRW50cnlCA+BBAVIGbGFiZWxzGjkKC0xhYmVsc0VudHJ5EhAKA2tl
eRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE6pwHqQaMBCilldmVudGFy
Yy5nb29nbGVhcGlzLmNvbS9DaGFubmVsQ29ubmVjdGlvbhJPcHJvamVjdHMve3Byb2plY3R9
L2xvY2F0aW9ucy97bG9jYXRpb259L2NoYW5uZWxDb25uZWN0aW9ucy97Y2hhbm5lbF9jb25u
ZWN0aW9ufSoSY2hhbm5lbENvbm5lY3Rpb25zMhFjaGFubmVsQ29ubmVjdGlvbkLGAQocY29t
Lmdvb2dsZS5jbG91ZC5ldmVudGFyYy52MUIWQ2hhbm5lbENvbm5lY3Rpb25Qcm90b1ABWjhj
bG91ZC5nb29nbGUuY29tL2dvL2V2ZW50YXJjL2FwaXYxL2V2ZW50YXJjcGI7ZXZlbnRhcmNw
YqoCGEdvb2dsZS5DbG91ZC5FdmVudGFyYy5WMcoCGEdvb2dsZVxDbG91ZFxFdmVudGFyY1xW
MeoCG0dvb2dsZTo6Q2xvdWQ6OkV2ZW50YXJjOjpWMUrXEgoGEgQOAEsBCrwECgEMEgMOABIy
sQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFj
aGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3Qg
dXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgog
WW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93
d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBi
eSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRp
c3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJ
UyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lO
RCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhl
IHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRp
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAhCgkKAgMAEgMSACkKCQoCAwESAxMA
IwoJCgIDAhIDFAApCggKAQgSAxYANQoJCgIIJRIDFgA1CggKAQgSAxcATwoJCgIICxIDFwBP
CggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkANwoJCgIICBIDGQA3CggKAQgSAxoANQoJ
CgIIARIDGgA1CggKAQgSAxsANQoJCgIIKRIDGwA1CggKAQgSAxwANAoJCgIILRIDHAA0Cu0B
CgIEABIEIgBLARrgASBBIHJlcHJlc2VudGF0aW9uIG9mIHRoZSBDaGFubmVsQ29ubmVjdGlv
biByZXNvdXJjZS4KIEEgQ2hhbm5lbENvbm5lY3Rpb24gaXMgYSByZXNvdXJjZSB3aGljaCBl
dmVudCBwcm92aWRlcnMgY3JlYXRlIGR1cmluZyB0aGUKIGFjdGl2YXRpb24gcHJvY2VzcyB0
byBlc3RhYmxpc2ggYSBjb25uZWN0aW9uIGJldHdlZW4gdGhlIHByb3ZpZGVyIGFuZCB0aGUK
IHN1YnNjcmliZXIgY2hhbm5lbC4KCgoKAwQAARIDIggZCgsKAwQABxIEIwIoBAoNCgUEAAed
CBIEIwIoBAo0CgQEAAIAEgMrAjsaJyBSZXF1aXJlZC4gVGhlIG5hbWUgb2YgdGhlIGNvbm5l
Y3Rpb24uCgoMCgUEAAIABRIDKwIICgwKBQQAAgABEgMrCQ0KDAoFBAACAAMSAysQEQoMCgUE
AAIACBIDKxI6Cg8KCAQAAgAInAgAEgMrEzkKgQEKBAQAAgESAy8CPRp0IE91dHB1dCBvbmx5
LiBTZXJ2ZXIgYXNzaWduZWQgSUQgb2YgdGhlIHJlc291cmNlLgogVGhlIHNlcnZlciBndWFy
YW50ZWVzIHVuaXF1ZW5lc3MgYW5kIGltbXV0YWJpbGl0eSB1bnRpbCBkZWxldGVkLgoKDAoF
BAACAQUSAy8CCAoMCgUEAAIBARIDLwkMCgwKBQQAAgEDEgMvDxAKDAoFBAACAQgSAy8RPAoP
CggEAAIBCJwIABIDLxI7CvEBCgQEAAICEgQ1AjoEGuIBIFJlcXVpcmVkLiBUaGUgbmFtZSBv
ZiB0aGUgY29ubmVjdGVkIHN1YnNjcmliZXIgQ2hhbm5lbC4KIFRoaXMgaXMgYSB3ZWFrIHJl
ZmVyZW5jZSB0byBhdm9pZCBjcm9zcyBwcm9qZWN0IGFuZCBjcm9zcyBhY2NvdW50cwogcmVm
ZXJlbmNlcy4gVGhpcyBtdXN0IGJlIGluCiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9u
L3tsb2NhdGlvbn0vY2hhbm5lbHMve2NoYW5uZWxfaWR9YCBmb3JtYXQuCgoMCgUEAAICBRID
NQIICgwKBQQAAgIBEgM1CRAKDAoFBAACAgMSAzUTFAoNCgUEAAICCBIENRU6AwoPCggEAAIC
CJwIABIDNgQqCg8KBwQAAgIInwgSBDcEOQUKLwoEBAACAxIEPQI+MhohIE91dHB1dCBvbmx5
LiBUaGUgY3JlYXRpb24gdGltZS4KCgwKBQQAAgMGEgM9AhsKDAoFBAACAwESAz0cJwoMCgUE
AAIDAxIDPSorCgwKBQQAAgMIEgM+BjEKDwoIBAACAwicCAASAz4HMAo0CgQEAAIEEgRBAkIy
GiYgT3V0cHV0IG9ubHkuIFRoZSBsYXN0LW1vZGlmaWVkIHRpbWUuCgoMCgUEAAIEBhIDQQIb
CgwKBQQAAgQBEgNBHCcKDAoFBAACBAMSA0EqKwoMCgUEAAIECBIDQgYxCg8KCAQAAgQInAgA
EgNCBzAK5gEKBAQAAgUSA0cCSRrYASBJbnB1dCBvbmx5LiBBY3RpdmF0aW9uIHRva2VuIGZv
ciB0aGUgY2hhbm5lbC4gVGhlIHRva2VuIHdpbGwgYmUgdXNlZAogZHVyaW5nIHRoZSBjcmVh
dGlvbiBvZiBDaGFubmVsQ29ubmVjdGlvbiB0byBiaW5kIHRoZSBjaGFubmVsIHdpdGggdGhl
CiBwcm92aWRlciBwcm9qZWN0LiBUaGlzIGZpZWxkIHdpbGwgbm90IGJlIHN0b3JlZCBpbiB0
aGUgcHJvdmlkZXIgcmVzb3VyY2UuCgoMCgUEAAIFBRIDRwIICgwKBQQAAgUBEgNHCRkKDAoF
BAACBQMSA0ccHQoMCgUEAAIFCBIDRx5ICg8KCAQAAgUInAgAEgNHH0cKKQoEBAACBhIDSgJK
GhwgT3B0aW9uYWwuIFJlc291cmNlIGxhYmVscy4KCgwKBQQAAgYGEgNKAhUKDAoFBAACBgES
A0oWHAoMCgUEAAIGAxIDSh8gCgwKBQQAAgYIEgNKIUkKDwoIBAACBgicCAASA0oiSGIGcHJv
dG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection ===
    # Fields for ChannelConnection
    # Field: name Type: 9 ()
    # Field: uid Type: 9 ()
    # Field: channel Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: activation_token Type: 9 ()
    # Field: labels Type: 11 (.google.cloud.eventarc.v1.ChannelConnection.LabelsEntry)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::V1::ChannelConnection - Compiled Protocol Buffers messages for google/cloud/eventarc/v1/channel_connection.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::V1::ChannelConnection;

    my $msg = Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection->new({
        name => $name,
        uid => $uid,
        channel => $channel,
        create_time => $create_time,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/v1/channel_connection.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection

A representation of the ChannelConnection resource.
A ChannelConnection is a resource which event providers create during the
activation process to establish a connection between the provider and the
subscriber channel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the connection.

=item * C<< $msg->uid() >> / C<< $msg->uid($value) >>

Type: C<String>

Output only. Server assigned ID of the resource.
The server guarantees uniqueness and immutability until deleted.

=item * C<< $msg->channel() >> / C<< $msg->channel($value) >>

Type: C<String>

Required. The name of the connected subscriber Channel.
This is a weak reference to avoid cross project and cross accounts
references. This must be in
`projects/{project}/location/{location}/channels/{channel_id}` format.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The creation time.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The last-modified time.

=item * C<< $msg->activation_token() >> / C<< $msg->activation_token($value) >>

Type: C<String>

Input only. Activation token for the channel. The token will be used
during the creation of ChannelConnection to bind the channel with the
provider project. This field will not be stored in the provider resource.

=item * C<< $msg->labels() >> / C<< $msg->labels($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::V1::ChannelConnection::ChannelConnection::LabelsEntry>)

Optional. Resource labels.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::V1::ChannelConnection::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
