package Google::Cloud::Channel::V1::SubscriberEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::Resource };
    my $descriptor_b64 = <<'EOF';
Ci5nb29nbGUvY2xvdWQvY2hhbm5lbC92MS9zdWJzY3JpYmVyX2V2ZW50LnByb3RvEhdnb29n
bGUuY2xvdWQuY2hhbm5lbC52MRoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byL5AQoNQ3Vz
dG9tZXJFdmVudBJFCghjdXN0b21lchgBIAEoCUIp+kEmCiRjbG91ZGNoYW5uZWwuZ29vZ2xl
YXBpcy5jb20vQ3VzdG9tZXJSCGN1c3RvbWVyEkoKCmV2ZW50X3R5cGUYAiABKA4yKy5nb29n
bGUuY2xvdWQuY2hhbm5lbC52MS5DdXN0b21lckV2ZW50LlR5cGVSCWV2ZW50VHlwZSJVCgRU
eXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQABIaChZQUklNQVJZX0RPTUFJTl9DSEFOR0VEEAES
GwoXUFJJTUFSWV9ET01BSU5fVkVSSUZJRUQQAiLJAwoQRW50aXRsZW1lbnRFdmVudBJOCgtl
bnRpdGxlbWVudBgBIAEoCUIs+kEpCidjbG91ZGNoYW5uZWwuZ29vZ2xlYXBpcy5jb20vRW50
aXRsZW1lbnRSC2VudGl0bGVtZW50Ek0KCmV2ZW50X3R5cGUYAiABKA4yLi5nb29nbGUuY2xv
dWQuY2hhbm5lbC52MS5FbnRpdGxlbWVudEV2ZW50LlR5cGVSCWV2ZW50VHlwZSKVAgoEVHlw
ZRIUChBUWVBFX1VOU1BFQ0lGSUVEEAASCwoHQ1JFQVRFRBABEhcKE1BSSUNFX1BMQU5fU1dJ
VENIRUQQAxIWChJDT01NSVRNRU5UX0NIQU5HRUQQBBILCgdSRU5FV0VEEAUSDQoJU1VTUEVO
REVEEAYSDQoJQUNUSVZBVEVEEAcSDQoJQ0FOQ0VMTEVEEAgSDwoLU0tVX0NIQU5HRUQQCRIb
ChdSRU5FV0FMX1NFVFRJTkdfQ0hBTkdFRBAKEhgKFFBBSURfU0VSVklDRV9TVEFSVEVEEAsS
HgoaTElDRU5TRV9BU1NJR05NRU5UX0NIQU5HRUQQDBIXChNMSUNFTlNFX0NBUF9DSEFOR0VE
EA0ixQEKD1N1YnNjcmliZXJFdmVudBJPCg5jdXN0b21lcl9ldmVudBgBIAEoCzImLmdvb2ds
ZS5jbG91ZC5jaGFubmVsLnYxLkN1c3RvbWVyRXZlbnRIAFINY3VzdG9tZXJFdmVudBJYChFl
bnRpdGxlbWVudF9ldmVudBgCIAEoCzIpLmdvb2dsZS5jbG91ZC5jaGFubmVsLnYxLkVudGl0
bGVtZW50RXZlbnRIAFIQZW50aXRsZW1lbnRFdmVudEIHCgVldmVudEJsChtjb20uZ29vZ2xl
LmNsb3VkLmNoYW5uZWwudjFCFFN1YnNjcmliZXJFdmVudFByb3RvUAFaNWNsb3VkLmdvb2ds
ZS5jb20vZ28vY2hhbm5lbC9hcGl2MS9jaGFubmVscGI7Y2hhbm5lbHBiSr8cCgYSBA4AdgEK
vAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5k
ZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5
b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhl
IExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAg
ICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNz
IHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBz
b2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQg
b24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05T
IE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNl
bnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFu
ZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIA
IwoICgEIEgMUAEwKCQoCCAsSAxQATAoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWADUK
CQoCCAgSAxYANQoICgEIEgMXADQKCQoCCAESAxcANApMCgIEABIEGgAvARpAIFJlcHJlc2Vu
dHMgUHViL1N1YiBtZXNzYWdlIGNvbnRlbnQgZGVzY3JpYmluZyBjdXN0b21lciB1cGRhdGUu
CgoKCgMEAAESAxoIFQonCgQEAAQAEgQcAiUDGhkgVHlwZSBvZiBjdXN0b21lciBldmVudC4K
CgwKBQQABAABEgMcBwsKGgoGBAAEAAIAEgMeBBkaCyBOb3QgdXNlZC4KCg4KBwQABAACAAES
Ax4EFAoOCgcEAAQAAgACEgMeFxgKOQoGBAAEAAIBEgMhBB8aKiBQcmltYXJ5IGRvbWFpbiBm
b3IgY3VzdG9tZXIgd2FzIGNoYW5nZWQuCgoOCgcEAAQAAgEBEgMhBBoKDgoHBAAEAAIBAhID
IR0eCkIKBgQABAACAhIDJAQgGjMgUHJpbWFyeSBkb21haW4gb2YgdGhlIGN1c3RvbWVyIGhh
cyBiZWVuIHZlcmlmaWVkLgoKDgoHBAAEAAICARIDJAQbCg4KBwQABAACAgISAyQeHwplCgQE
AAIAEgQpAisFGlcgUmVzb3VyY2UgbmFtZSBvZiB0aGUgY3VzdG9tZXIuCiBGb3JtYXQ6IGFj
Y291bnRzL3thY2NvdW50X2lkfS9jdXN0b21lcnMve2N1c3RvbWVyX2lkfQoKDAoFBAACAAUS
AykCCAoMCgUEAAIAARIDKQkRCgwKBQQAAgADEgMpFBUKDQoFBAACAAgSBCkWKwQKDwoHBAAC
AAifCBIEKRcrAwo9CgQEAAIBEgMuAhYaMCBUeXBlIG9mIGV2ZW50IHdoaWNoIGhhcHBlbmVk
IGZvciB0aGUgY3VzdG9tZXIuCgoMCgUEAAIBBhIDLgIGCgwKBQQAAgEBEgMuBxEKDAoFBAAC
AQMSAy4UFQpPCgIEARIEMgBoARpDIFJlcHJlc2VudHMgUHViL1N1YiBtZXNzYWdlIGNvbnRl
bnQgZGVzY3JpYmluZyBlbnRpdGxlbWVudCB1cGRhdGUuCgoKCgMEAQESAzIIGAoqCgQEAQQA
EgQ0Al4DGhwgVHlwZSBvZiBlbnRpdGxlbWVudCBldmVudC4KCgwKBQQBBAABEgM0BwsKGgoG
BAEEAAIAEgM2BBkaCyBOb3QgdXNlZC4KCg4KBwQBBAACAAESAzYEFAoOCgcEAQQAAgACEgM2
FxgKLwoGBAEEAAIBEgM5BBAaICBBIG5ldyBlbnRpdGxlbWVudCB3YXMgY3JlYXRlZC4KCg4K
BwQBBAACAQESAzkECwoOCgcEAQQAAgECEgM5Dg8KvQEKBgQBBAACAhIDPgQcGq0BIFRoZSBv
ZmZlciB0eXBlIGFzc29jaWF0ZWQgd2l0aCBhbiBlbnRpdGxlbWVudCB3YXMgY2hhbmdlZC4K
IFRoaXMgaXMgbm90IHRyaWdnZXJlZCBpZiBhbiBlbnRpdGxlbWVudCBjb252ZXJ0cyBmcm9t
IGEgY29tbWl0IG9mZmVyIHRvIGEKIGZsZXhpYmxlIG9mZmVyIGFzIHBhcnQgb2YgYSByZW5l
d2FsLgoKDgoHBAEEAAICARIDPgQXCg4KBwQBBAACAgISAz4aGwpBCgYEAQQAAgMSA0EEGxoy
IEFubnVhbCBjb21taXRtZW50IGZvciBhIGNvbW1pdCBwbGFuIHdhcyBjaGFuZ2VkLgoKDgoH
BAEEAAIDARIDQQQWCg4KBwQBBAACAwISA0EZGgozCgYEAQQAAgQSA0QEEBokIEFuIGFubnVh
bCBlbnRpdGxlbWVudCB3YXMgcmVuZXdlZC4KCg4KBwQBBAACBAESA0QECwoOCgcEAQQAAgQC
EgNEDg8KKwoGBAEEAAIFEgNHBBIaHCBFbnRpdGxlbWVudCB3YXMgc3VzcGVuZGVkLgoKDgoH
BAEEAAIFARIDRwQNCg4KBwQBBAACBQISA0cQEQotCgYEAQQAAgYSA0oEEhoeIEVudGl0bGVt
ZW50IHdhcyB1bnN1c3BlbmRlZC4KCg4KBwQBBAACBgESA0oEDQoOCgcEAQQAAgYCEgNKEBEK
KwoGBAEEAAIHEgNNBBIaHCBFbnRpdGxlbWVudCB3YXMgY2FuY2VsbGVkLgoKDgoHBAEEAAIH
ARIDTQQNCg4KBwQBBAACBwISA00QEQqKAQoGBAEEAAIIEgNRBBQaeyBFbnRpdGxlbWVudCB3
YXMgdXBncmFkZWQgb3IgZG93bmdyYWRlZCAoZS5nLiBmcm9tIEdvb2dsZSBXb3Jrc3BhY2UK
IEJ1c2luZXNzIFN0YW5kYXJkIHRvIEdvb2dsZSBXb3Jrc3BhY2UgQnVzaW5lc3MgUGx1cyku
CgoOCgcEAQQAAggBEgNRBA8KDgoHBAEEAAIIAhIDURITCkQKBgQBBAACCRIDVAQhGjUgVGhl
IHJlbmV3YWwgc2V0dGluZ3Mgb2YgYW4gZW50aXRsZW1lbnQgaGFzIGNoYW5nZWQuCgoOCgcE
AQQAAgkBEgNUBBsKDgoHBAEEAAIJAhIDVB4gCj8KBgQBBAACChIDVwQeGjAgUGFpZCBzZXJ2
aWNlIGhhcyBzdGFydGVkIG9uIHRyaWFsIGVudGl0bGVtZW50LgoKDgoHBAEEAAIKARIDVwQY
Cg4KBwQBBAACCgISA1cbHQpACgYEAQQAAgsSA1oEJBoxIExpY2Vuc2Ugd2FzIGFzc2lnbmVk
IHRvIG9yIHJldm9rZWQgZnJvbSBhIHVzZXIuCgoOCgcEAQQAAgsBEgNaBB4KDgoHBAEEAAIL
AhIDWiEjCj0KBgQBBAACDBIDXQQdGi4gTGljZW5zZSBjYXAgd2FzIGNoYW5nZWQgZm9yIHRo
ZSBlbnRpdGxlbWVudC4KCg4KBwQBBAACDAESA10EFwoOCgcEAQQAAgwCEgNdGhwKiQEKBAQB
AgASBGICZAUaeyBSZXNvdXJjZSBuYW1lIG9mIGFuIGVudGl0bGVtZW50IG9mIHRoZSBmb3Jt
OgogYWNjb3VudHMve2FjY291bnRfaWR9L2N1c3RvbWVycy97Y3VzdG9tZXJfaWR9L2VudGl0
bGVtZW50cy97ZW50aXRsZW1lbnRfaWR9CgoMCgUEAQIABRIDYgIICgwKBQQBAgABEgNiCRQK
DAoFBAECAAMSA2IXGAoNCgUEAQIACBIEYhlkBAoPCgcEAQIACJ8IEgRiGmQDCkAKBAQBAgES
A2cCFhozIFR5cGUgb2YgZXZlbnQgd2hpY2ggaGFwcGVuZWQgZm9yIHRoZSBlbnRpdGxlbWVu
dC4KCgwKBQQBAgEGEgNnAgYKDAoFBAECAQESA2cHEQoMCgUEAQIBAxIDZxQVCmQKAgQCEgRs
AHYBGlggUmVwcmVzZW50cyBpbmZvcm1hdGlvbiB3aGljaCByZXNlbGxlcnMgd2lsbCBnZXQg
YXMgcGFydCBvZiBub3RpZmljYXRpb24gZnJvbQogUHViL1N1Yi4KCgoKAwQCARIDbAgXCmAK
BAQCCAASBG8CdQMaUiBTcGVjaWZpZXMgdGhlIFB1Yi9TdWIgZXZlbnQgcHJvdmlkZWQgdG8g
dGhlIHBhcnRuZXJzLgogVGhpcyBpcyBhIHJlcXVpcmVkIGZpZWxkLgoKDAoFBAIIAAESA28I
DQpICgQEAgIAEgNxBCUaOyBDdXN0b21lciBldmVudCBzZW50IGFzIHBhcnQgb2YgUHViL1N1
YiBldmVudCB0byBwYXJ0bmVycy4KCgwKBQQCAgAGEgNxBBEKDAoFBAICAAESA3ESIAoMCgUE
AgIAAxIDcSMkCksKBAQCAgESA3QEKxo+IEVudGl0bGVtZW50IGV2ZW50IHNlbnQgYXMgcGFy
dCBvZiBQdWIvU3ViIGV2ZW50IHRvIHBhcnRuZXJzLgoKDAoFBAICAQYSA3QEFAoMCgUEAgIB
ARIDdBUmCgwKBQQCAgEDEgN0KSpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Channel::V1::SubscriberEvent::CustomerEvent ===
    # Fields for CustomerEvent
    # Field: customer Type: 9 ()
    # Field: event_type Type: 14 (.google.cloud.channel.v1.CustomerEvent.Type)

# Enum: CustomerEvent::Type
our $CustomerEvent_TYPE_UNSPECIFIED = 0;
our $CustomerEvent_PRIMARY_DOMAIN_CHANGED = 1;
our $CustomerEvent_PRIMARY_DOMAIN_VERIFIED = 2;

# === Message: Google::Cloud::Channel::V1::SubscriberEvent::EntitlementEvent ===
    # Fields for EntitlementEvent
    # Field: entitlement Type: 9 ()
    # Field: event_type Type: 14 (.google.cloud.channel.v1.EntitlementEvent.Type)

# Enum: EntitlementEvent::Type
our $EntitlementEvent_TYPE_UNSPECIFIED = 0;
our $EntitlementEvent_CREATED = 1;
our $EntitlementEvent_PRICE_PLAN_SWITCHED = 3;
our $EntitlementEvent_COMMITMENT_CHANGED = 4;
our $EntitlementEvent_RENEWED = 5;
our $EntitlementEvent_SUSPENDED = 6;
our $EntitlementEvent_ACTIVATED = 7;
our $EntitlementEvent_CANCELLED = 8;
our $EntitlementEvent_SKU_CHANGED = 9;
our $EntitlementEvent_RENEWAL_SETTING_CHANGED = 10;
our $EntitlementEvent_PAID_SERVICE_STARTED = 11;
our $EntitlementEvent_LICENSE_ASSIGNMENT_CHANGED = 12;
our $EntitlementEvent_LICENSE_CAP_CHANGED = 13;

# === Message: Google::Cloud::Channel::V1::SubscriberEvent::SubscriberEvent ===
    # Fields for SubscriberEvent
    # Field: customer_event Type: 11 (.google.cloud.channel.v1.CustomerEvent)
    # Field: entitlement_event Type: 11 (.google.cloud.channel.v1.EntitlementEvent)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Channel::V1::SubscriberEvent - Compiled Protocol Buffers messages for google/cloud/channel/v1/subscriber_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Channel::V1::SubscriberEvent;

    my $msg = Google::Cloud::Channel::V1::SubscriberEvent::CustomerEvent->new({
        customer => $customer,
        event_type => $event_type,
    });

    # Read or update a field
    my $val = $msg->customer();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Channel::V1::SubscriberEvent::CustomerEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/channel/v1/subscriber_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Channel::V1::SubscriberEvent::CustomerEvent

Represents Pub/Sub message content describing customer update.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->customer() >> / C<< $msg->customer($value) >>

Type: C<String>

Resource name of the customer.
Format: accounts/{account_id}/customers/{customer_id}

=item * C<< $msg->event_type() >> / C<< $msg->event_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::CustomerEvent::Type>)

Type of event which happened for the customer.

=back

=head3 Enum: CustomerEvent::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<PRIMARY_DOMAIN_CHANGED> => C<1>

=item * C<PRIMARY_DOMAIN_VERIFIED> => C<2>

=back

=head2 Google::Cloud::Channel::V1::SubscriberEvent::EntitlementEvent

Represents Pub/Sub message content describing entitlement update.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->entitlement() >> / C<< $msg->entitlement($value) >>

Type: C<String>

Resource name of an entitlement of the form:
accounts/{account_id}/customers/{customer_id}/entitlements/{entitlement_id}

=item * C<< $msg->event_type() >> / C<< $msg->event_type($value) >>

Type: C<Enum> (L<Google::Cloud::Channel::V1::EntitlementEvent::Type>)

Type of event which happened for the entitlement.

=back

=head3 Enum: EntitlementEvent::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<CREATED> => C<1>

=item * C<PRICE_PLAN_SWITCHED> => C<3>

=item * C<COMMITMENT_CHANGED> => C<4>

=item * C<RENEWED> => C<5>

=item * C<SUSPENDED> => C<6>

=item * C<ACTIVATED> => C<7>

=item * C<CANCELLED> => C<8>

=item * C<SKU_CHANGED> => C<9>

=item * C<RENEWAL_SETTING_CHANGED> => C<10>

=item * C<PAID_SERVICE_STARTED> => C<11>

=item * C<LICENSE_ASSIGNMENT_CHANGED> => C<12>

=item * C<LICENSE_CAP_CHANGED> => C<13>

=back

=head2 Google::Cloud::Channel::V1::SubscriberEvent::SubscriberEvent

Represents information which resellers will get as part of notification from
Pub/Sub.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->customer_event() >> / C<< $msg->customer_event($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::SubscriberEvent::CustomerEvent>)

Customer event sent as part of Pub/Sub event to partners.

=item * C<< $msg->entitlement_event() >> / C<< $msg->entitlement_event($value) >>

Type: C<Message> (L<Google::Cloud::Channel::V1::SubscriberEvent::EntitlementEvent>)

Entitlement event sent as part of Pub/Sub event to partners.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Channel::V1::SubscriberEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
