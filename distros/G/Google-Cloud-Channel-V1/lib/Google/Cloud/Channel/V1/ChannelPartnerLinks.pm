package Google::Cloud::Channel::V1::ChannelPartnerLinks;

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
    eval { require Google::Cloud::Channel::V1::Common };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjNnb29nbGUvY2xvdWQvY2hhbm5lbC92MS9jaGFubmVsX3BhcnRuZXJfbGlua3MucHJvdG8S
F2dvb2dsZS5jbG91ZC5jaGFubmVsLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnBy
b3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3RvGiRnb29nbGUvY2xvdWQvY2hhbm5lbC92
MS9jb21tb24ucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iiwUKEkNo
YW5uZWxQYXJ0bmVyTGluaxIXCgRuYW1lGAEgASgJQgPgQQNSBG5hbWUSQAoacmVzZWxsZXJf
Y2xvdWRfaWRlbnRpdHlfaWQYAiABKAlCA+BBAlIXcmVzZWxsZXJDbG91ZElkZW50aXR5SWQS
VAoKbGlua19zdGF0ZRgDIAEoDjIwLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLkNoYW5uZWxQ
YXJ0bmVyTGlua1N0YXRlQgPgQQJSCWxpbmtTdGF0ZRIrCg9pbnZpdGVfbGlua191cmkYBCAB
KAlCA+BBA1INaW52aXRlTGlua1VyaRJACgtjcmVhdGVfdGltZRgFIAEoCzIaLmdvb2dsZS5w
cm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKY3JlYXRlVGltZRJACgt1cGRhdGVfdGltZRgGIAEo
CzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCA+BBA1IKdXBkYXRlVGltZRIgCglwdWJs
aWNfaWQYByABKAlCA+BBA1IIcHVibGljSWQSfQojY2hhbm5lbF9wYXJ0bmVyX2Nsb3VkX2lk
ZW50aXR5X2luZm8YCCABKAsyKi5nb29nbGUuY2xvdWQuY2hhbm5lbC52MS5DbG91ZElkZW50
aXR5SW5mb0ID4EEDUh9jaGFubmVsUGFydG5lckNsb3VkSWRlbnRpdHlJbmZvOnLqQW8KLmNs
b3VkY2hhbm5lbC5nb29nbGVhcGlzLmNvbS9DaGFubmVsUGFydG5lckxpbmsSPWFjY291bnRz
L3thY2NvdW50fS9jaGFubmVsUGFydG5lckxpbmtzL3tjaGFubmVsX3BhcnRuZXJfbGlua30q
PgoWQ2hhbm5lbFBhcnRuZXJMaW5rVmlldxIPCgtVTlNQRUNJRklFRBAAEgkKBUJBU0lDEAES
CAoERlVMTBACKnoKF0NoYW5uZWxQYXJ0bmVyTGlua1N0YXRlEioKJkNIQU5ORUxfUEFSVE5F
Ul9MSU5LX1NUQVRFX1VOU1BFQ0lGSUVEEAASCwoHSU5WSVRFRBABEgoKBkFDVElWRRACEgsK
B1JFVk9LRUQQAxINCglTVVNQRU5ERUQQBEJwChtjb20uZ29vZ2xlLmNsb3VkLmNoYW5uZWwu
djFCGENoYW5uZWxQYXJ0bmVyTGlua3NQcm90b1ABWjVjbG91ZC5nb29nbGUuY29tL2dvL2No
YW5uZWwvYXBpdjEvY2hhbm5lbHBiO2NoYW5uZWxwYkr+GQoGEgQOAGUBCrwECgEMEgMOABIy
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
b25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAgCgkKAgMAEgMSACkKCQoCAwESAxMA
IwoJCgIDAhIDFAAuCgkKAgMDEgMVACkKCAoBCBIDFwBMCgkKAggLEgMXAEwKCAoBCBIDGAAi
CgkKAggKEgMYACIKCAoBCBIDGQA5CgkKAggIEgMZADkKCAoBCBIDGgA0CgkKAggBEgMaADQK
ewoCBQASBB8AKgEabyBUaGUgbGV2ZWwgb2YgZ3JhbnVsYXJpdHkgdGhlCiBbQ2hhbm5lbFBh
cnRuZXJMaW5rXVtnb29nbGUuY2xvdWQuY2hhbm5lbC52MS5DaGFubmVsUGFydG5lckxpbmtd
IHdpbGwKIGRpc3BsYXkuCgoKCgMFAAESAx8FGwpSCgQFAAIAEgMiAhIaRSBUaGUgZGVmYXVs
dCAvIHVuc2V0IHZhbHVlLgogVGhlIEFQSSB3aWxsIGRlZmF1bHQgdG8gdGhlIEJBU0lDIHZp
ZXcuCgoMCgUFAAIAARIDIgINCgwKBQUAAgACEgMiEBEKuQEKBAUAAgESAyYCDBqrASBJbmNs
dWRlcyBhbGwgZmllbGRzIGV4Y2VwdCB0aGUKIFtDaGFubmVsUGFydG5lckxpbmsuY2hhbm5l
bF9wYXJ0bmVyX2Nsb3VkX2lkZW50aXR5X2luZm9dW2dvb2dsZS5jbG91ZC5jaGFubmVsLnYx
LkNoYW5uZWxQYXJ0bmVyTGluay5jaGFubmVsX3BhcnRuZXJfY2xvdWRfaWRlbnRpdHlfaW5m
b10uCgoMCgUFAAIBARIDJgIHCgwKBQUAAgECEgMmCgsKIwoEBQACAhIDKQILGhYgSW5jbHVk
ZXMgYWxsIGZpZWxkcy4KCgwKBQUAAgIBEgMpAgYKDAoFBQACAgISAykJCgpRCgIFARIELQA9
ARpFIENoYW5uZWxQYXJ0bmVyTGlua1N0YXRlIHJlcHJlc2VudHMgc3RhdGUgb2YgYSBjaGFu
bmVsIHBhcnRuZXIgbGluay4KCgoKAwUBARIDLQUcChgKBAUBAgASAy8CLRoLIE5vdCB1c2Vk
LgoKDAoFBQECAAESAy8CKAoMCgUFAQIAAhIDLyssCl0KBAUBAgESAzMCDhpQIEFuIGludml0
YXRpb24gaGFzIGJlZW4gc2VudCB0byB0aGUgcmVzZWxsZXIgdG8gY3JlYXRlIGEgY2hhbm5l
bCBwYXJ0bmVyCiBsaW5rLgoKDAoFBQECAQESAzMCCQoMCgUFAQIBAhIDMwwNCjIKBAUBAgIS
AzYCDRolIFN0YXR1cyB3aGVuIHRoZSByZXNlbGxlciBpcyBhY3RpdmUuCgoMCgUFAQICARID
NgIICgwKBQUBAgICEgM2CwwKTAoEBQECAxIDOQIOGj8gU3RhdHVzIHdoZW4gdGhlIHJlc2Vs
bGVyIGhhcyBiZWVuIHJldm9rZWQgYnkgdGhlIGRpc3RyaWJ1dG9yLgoKDAoFBQECAwESAzkC
CQoMCgUFAQIDAhIDOQwNCk4KBAUBAgQSAzwCEBpBIFN0YXR1cyB3aGVuIHRoZSByZXNlbGxl
ciBpcyBzdXNwZW5kZWQgYnkgR29vZ2xlIG9yIGRpc3RyaWJ1dG9yLgoKDAoFBQECBAESAzwC
CwoMCgUFAQIEAhIDPA4PCngKAgQAEgRBAGUBGmwgRW50aXR5IHJlcHJlc2VudGluZyBhIGxp
bmsgYmV0d2VlbiBkaXN0cmlidXRvcnMgYW5kIHRoZWlyIGluZGlyZWN0CiByZXNlbGxlcnMg
aW4gYW4gbi10aWVyIHJlc2FsZSBjaGFubmVsLgoKCgoDBAABEgNBCBoKCwoDBAAHEgRCAkUE
Cg0KBQQAB50IEgRCAkUECoYBCgQEAAIAEgNJAj4aeSBPdXRwdXQgb25seS4gUmVzb3VyY2Ug
bmFtZSBmb3IgdGhlIGNoYW5uZWwgcGFydG5lciBsaW5rLCBpbiB0aGUgZm9ybWF0CiBhY2Nv
dW50cy97YWNjb3VudF9pZH0vY2hhbm5lbFBhcnRuZXJMaW5rcy97aWR9LgoKDAoFBAACAAUS
A0kCCAoMCgUEAAIAARIDSQkNCgwKBQQAAgADEgNJEBEKDAoFBAACAAgSA0kSPQoPCggEAAIA
CJwIABIDSRM8CkMKBAQAAgESBEwCTS8aNSBSZXF1aXJlZC4gQ2xvdWQgSWRlbnRpdHkgSUQg
b2YgdGhlIGxpbmtlZCByZXNlbGxlci4KCgwKBQQAAgEFEgNMAggKDAoFBAACAQESA0wJIwoM
CgUEAAIBAxIDTCYnCgwKBQQAAgEIEgNNBi4KDwoIBAACAQicCAASA00HLQo8CgQEAAICEgRQ
AlEvGi4gUmVxdWlyZWQuIFN0YXRlIG9mIHRoZSBjaGFubmVsIHBhcnRuZXIgbGluay4KCgwK
BQQAAgIGEgNQAhkKDAoFBAACAgESA1AaJAoMCgUEAAICAxIDUCcoCgwKBQQAAgIIEgNRBi4K
DwoIBAACAgicCAASA1EHLQpaCgQEAAIDEgNUAkkaTSBPdXRwdXQgb25seS4gVVJJIG9mIHRo
ZSB3ZWIgcGFnZSB3aGVyZSBwYXJ0bmVyIGFjY2VwdHMgdGhlIGxpbmsgaW52aXRhdGlvbi4K
CgwKBQQAAgMFEgNUAggKDAoFBAACAwESA1QJGAoMCgUEAAIDAxIDVBscCgwKBQQAAgMIEgNU
HUgKDwoIBAACAwicCAASA1QeRwpTCgQEAAIEEgRXAlgyGkUgT3V0cHV0IG9ubHkuIFRpbWVz
dGFtcCBvZiB3aGVuIHRoZSBjaGFubmVsIHBhcnRuZXIgbGluayBpcyBjcmVhdGVkLgoKDAoF
BAACBAYSA1cCGwoMCgUEAAIEARIDVxwnCgwKBQQAAgQDEgNXKisKDAoFBAACBAgSA1gGMQoP
CggEAAIECJwIABIDWAcwClMKBAQAAgUSBFsCXDIaRSBPdXRwdXQgb25seS4gVGltZXN0YW1w
IG9mIHdoZW4gdGhlIGNoYW5uZWwgcGFydG5lciBsaW5rIGlzIHVwZGF0ZWQuCgoMCgUEAAIF
BhIDWwIbCgwKBQQAAgUBEgNbHCcKDAoFBAACBQMSA1sqKwoMCgUEAAIFCBIDXAYxCg8KCAQA
AgUInAgAEgNcBzAKlwEKBAQAAgYSA2ACQxqJASBPdXRwdXQgb25seS4gUHVibGljIGlkZW50
aWZpZXIgdGhhdCBhIGN1c3RvbWVyIG11c3QgdXNlIHRvIGdlbmVyYXRlIGEKIHRyYW5zZmVy
IHRva2VuIHRvIG1vdmUgdG8gdGhpcyBkaXN0cmlidXRvci1yZXNlbGxlciBjb21iaW5hdGlv
bi4KCgwKBQQAAgYFEgNgAggKDAoFBAACBgESA2AJEgoMCgUEAAIGAxIDYBUWCgwKBQQAAgYI
EgNgF0IKDwoIBAACBgicCAASA2AYQQpNCgQEAAIHEgRjAmQyGj8gT3V0cHV0IG9ubHkuIENs
b3VkIElkZW50aXR5IGluZm8gb2YgdGhlIGNoYW5uZWwgcGFydG5lciAoSVIpLgoKDAoFBAAC
BwYSA2MCEwoMCgUEAAIHARIDYxQ3CgwKBQQAAgcDEgNjOjsKDAoFBAACBwgSA2QGMQoPCggE
AAIHCJwIABIDZAcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::ChannelPartnerLinks::ChannelPartnerLink ===
    # Fields for ChannelPartnerLink
    # Field: name Type: 9 ()
    # Field: reseller_cloud_identity_id Type: 9 ()
    # Field: link_state Type: 14 (.google.cloud.channel.v1.ChannelPartnerLinkState)
    # Field: invite_link_uri Type: 9 ()
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: public_id Type: 9 ()
    # Field: channel_partner_cloud_identity_info Type: 11 (.google.cloud.channel.v1.CloudIdentityInfo)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::ChannelPartnerLinks - Compiled Protocol Buffers messages for google/cloud/channel/v1/channel_partner_links.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::ChannelPartnerLinks;

    my $msg = Google::Cloud::Channel::V1::ChannelPartnerLinks::ChannelPartnerLink->new({
        name => $name,
        reseller_cloud_identity_id => $reseller_cloud_identity_id,
        link_state => $link_state,
        invite_link_uri => $invite_link_uri,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::ChannelPartnerLinks::ChannelPartnerLink->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/channel_partner_links.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::ChannelPartnerLinks::ChannelPartnerLink

Entity representing a link between distributors and their indirect
resellers in an n-tier resale channel.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. Resource name for the channel partner link, in the format
accounts/{account_id}/channelPartnerLinks/{id}.

=item * C<< $msg->reseller_cloud_identity_id() >> / C<< $msg->reseller_cloud_identity_id($value) >>

Type: C<String>

Required. Cloud Identity ID of the linked reseller.

=item * C<< $msg->link_state() >> / C<< $msg->link_state($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::ChannelPartnerLinkState>)

Required. State of the channel partner link.

=item * C<< $msg->invite_link_uri() >> / C<< $msg->invite_link_uri($value) >>

Type: C<String>

Output only. URI of the web page where partner accepts the link invitation.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of when the channel partner link is created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. Timestamp of when the channel partner link is updated.

=item * C<< $msg->public_id() >> / C<< $msg->public_id($value) >>

Type: C<String>

Output only. Public identifier that a customer must use to generate a
transfer token to move to this distributor-reseller combination.

=item * C<< $msg->channel_partner_cloud_identity_info() >> / C<< $msg->channel_partner_cloud_identity_info($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::Common::CloudIdentityInfo>)

Output only. Cloud Identity info of the channel partner (IR).

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::ChannelPartnerLinks::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
