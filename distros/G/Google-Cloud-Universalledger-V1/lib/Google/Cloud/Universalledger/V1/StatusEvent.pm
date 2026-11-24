package Google::Cloud::Universalledger::V1::StatusEvent;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvdW5pdmVyc2FsbGVkZ2VyL3YxL3N0YXR1c19ldmVudC5wcm90bxIf
Z29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MRofZ29vZ2xlL2FwaS9maWVsZF9iZWhh
dmlvci5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90byL2AQoLU3RhdHVz
RXZlbnQSPgoKZXZlbnRfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBC
A+BBA1IJZXZlbnRUaW1lEk4KCmV2ZW50X3R5cGUYAiABKA4yKi5nb29nbGUuY2xvdWQudW5p
dmVyc2FsbGVkZ2VyLnYxLkV2ZW50VHlwZUID4EEDUglldmVudFR5cGUSVwoNZXZlbnRfZGV0
YWlscxgDIAEoCzItLmdvb2dsZS5jbG91ZC51bml2ZXJzYWxsZWRnZXIudjEuRXZlbnREZXRh
aWxzQgPgQQNSDGV2ZW50RGV0YWlscyKGAQoMRXZlbnREZXRhaWxzEmUKEWV4ZWN1dGlvbl9k
ZXRhaWxzGAEgASgLMjEuZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MS5FeGVjdXRp
b25EZXRhaWxzQgPgQQNIAFIQZXhlY3V0aW9uRGV0YWlsc0IPCg1ldmVudF9kZXRhaWxzIjIK
EEV4ZWN1dGlvbkRldGFpbHMSHgoIcm91bmRfaWQYASABKANCA+BBA1IHcm91bmRJZCrUAQoJ
RXZlbnRUeXBlEhoKFkVWRU5UX1RZUEVfVU5TUEVDSUZJRUQQABIXChNFVkVOVF9UWVBFX1JF
Q0VJVkVEEAESGgoWRVZFTlRfVFlQRV9CUk9BRENBU1RFRBACEhYKEkVWRU5UX1RZUEVfT1JE
RVJFRBADEiAKHEVWRU5UX1RZUEVfRVhFQ1VUSU9OX1NUQVJURUQQBBIiCh5FVkVOVF9UWVBF
X0VYRUNVVElPTl9DT01QTEVURUQQBRIYChRFVkVOVF9UWVBFX0ZJTkFMSVpFRBAGQvEBCiNj
b20uZ29vZ2xlLmNsb3VkLnVuaXZlcnNhbGxlZGdlci52MUIQU3RhdHVzRXZlbnRQcm90b1AB
Wk1jbG91ZC5nb29nbGUuY29tL2dvL3VuaXZlcnNhbGxlZGdlci9hcGl2MS91bml2ZXJzYWxs
ZWRnZXJwYjt1bml2ZXJzYWxsZWRnZXJwYqoCH0dvb2dsZS5DbG91ZC5Vbml2ZXJzYWxMZWRn
ZXIuVjHKAh9Hb29nbGVcQ2xvdWRcVW5pdmVyc2FsTGVkZ2VyXFYx6gIiR29vZ2xlOjpDbG91
ZDo6VW5pdmVyc2FsTGVkZ2VyOjpWMUr1FQoGEgQOAFUBCrwECgEMEgMOABIysQQgQ29weXJp
Z2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUgTGljZW5z
ZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNlIHRoaXMg
ZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91IG1heSBv
YnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cuYXBhY2hl
Lm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNh
YmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3RyaWJ1dGVk
IHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMs
CiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwgZWl0aGVy
IGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmlj
IGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25zIHVuZGVy
IHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAoCgkKAgMAEgMSACkKCQoCAwESAxMAKQoICgEIEgMV
ADwKCQoCCCUSAxUAPAoICgEIEgMWAGQKCQoCCAsSAxYAZAoICgEIEgMXACIKCQoCCAoSAxcA
IgoICgEIEgMYADEKCQoCCAgSAxgAMQoICgEIEgMZADwKCQoCCAESAxkAPAoICgEIEgMaADwK
CQoCCCkSAxoAPAoICgEIEgMbADsKCQoCCC0SAxsAOwqQAQoCBQASBB8ANAEagwEgUmVwcmVz
ZW50cyB0aGUgdHlwZSBvZiBhbiBldmVudCBpbiB0aGUgcHJvY2Vzc2luZyBvZiBhIHRyYW5z
YWN0aW9uLCBhcwogb2JzZXJ2ZWQgYnkgdGhlIHZhbGlkYXRvciB0aGF0IHRoZSByZXF1ZXN0
IHdhcyByb3V0ZWQgdG8uCgoKCgMFAAESAx8FDgosCgQFAAIAEgMhAh0aHyBVbmtub3duIG9y
IHVuc3BlY2lmaWVkIGV2ZW50LgoKDAoFBQACAAESAyECGAoMCgUFAAIAAhIDIRscClUKBAUA
AgESAyQCGhpIIFRoZSB0cmFuc2FjdGlvbiB3YXMgcmVjZWl2ZWQgYnkgdGhpcyB2YWxpZGF0
b3IgZGlyZWN0bHkgZnJvbSBhIGNsaWVudC4KCgwKBQUAAgEBEgMkAhUKDAoFBQACAQISAyQY
GQpLCgQFAAICEgMnAh0aPiBUaGUgdHJhbnNhY3Rpb24gd2FzIGJyb2FkY2FzdGVkIGJ5IHRo
aXMgdG8gb3RoZXIgdmFsaWRhdG9ycy4KCgwKBQUAAgIBEgMnAhgKDAoFBQACAgISAycbHApZ
CgQFAAIDEgMqAhkaTCBUaGUgdHJhbnNhY3Rpb24gd2FzIG9yZGVyZWQgYW5kIHNjaGVkdWxl
ZCBmb3IgZXhlY3V0aW9uIGJ5IHRoaXMgdmFsaWRhdG9yLgoKDAoFBQACAwESAyoCFAoMCgUF
AAIDAhIDKhcYCjwKBAUAAgQSAy0CIxovIFRoZSBleGVjdXRpb24gb2YgdGhlIHRyYW5zYWN0
aW9uIGhhcyBzdGFydGVkLgoKDAoFBQACBAESAy0CHgoMCgUFAAIEAhIDLSEiCj4KBAUAAgUS
AzACJRoxIFRoZSBleGVjdXRpb24gb2YgdGhlIHRyYW5zYWN0aW9uIGhhcyBjb21wbGV0ZWQu
CgoMCgUFAAIFARIDMAIgCgwKBQUAAgUCEgMwIyQKRAoEBQACBhIDMwIbGjcgVGhlIHRyYW5z
YWN0aW9uIGhhcyBiZWVuIGZpbmFsaXplZCBieSB0aGlzIHZhbGlkYXRvci4KCgwKBQUAAgYB
EgMzAhYKDAoFBQACBgISAzMZGgrxAQoCBAASBDsARQEa5AEgUmVwcmVzZW50cyBhbiBldmVu
dCBpbiB0aGUgcHJvY2Vzc2luZyBvZiBhIHRyYW5zYWN0aW9uIGFzIG9ic2VydmVkIGJ5IGEK
IHNpbmdsZSB2YWxpZGF0b3IuCgogQWxsIHZhbHVlcyByZXBvcnRlZCBhcmUgZnJvbSB0aGUg
cGVyc3BlY3RpdmUgb2YgdGhlIHZhbGlkYXRvciBoYW5kbGluZyB0aGUKIHJlcXVlc3QgYW5k
IG1heSBkaWZmZXIgZnJvbSB0aGUgdmlldyBvZiBvdGhlciB2YWxpZGF0b3JzLgoKCgoDBAAB
EgM7CBMKVAoEBAACABIEPQI+MhpGIE91dHB1dCBvbmx5LiBUaGUgdGltZSB3aGVuIHRoZSBl
dmVudCB3YXMgcmVjb3JkZWQgYnkgdGhpcyB2YWxpZGF0b3IuCgoMCgUEAAIABhIDPQIbCgwK
BQQAAgABEgM9HCYKDAoFBAACAAMSAz0pKgoMCgUEAAIACBIDPgYxCg8KCAQAAgAInAgAEgM+
BzAKMgoEBAACARIDQQJHGiUgT3V0cHV0IG9ubHkuIFRoZSB0eXBlIG9mIHRoZSBldmVudC4K
CgwKBQQAAgEGEgNBAgsKDAoFBAACAQESA0EMFgoMCgUEAAIBAxIDQRkaCgwKBQQAAgEIEgNB
G0YKDwoIBAACAQicCAASA0EcRQpJCgQEAAICEgNEAk0aPCBPdXRwdXQgb25seS4gQWRkaXRp
b25hbCBkZXRhaWxzIGFzc29jaWF0ZWQgd2l0aCB0aGUgZXZlbnQuCgoMCgUEAAICBhIDRAIO
CgwKBQQAAgIBEgNEDxwKDAoFBAACAgMSA0QfIAoMCgUEAAICCBIDRCFMCg8KCAQAAgIInAgA
EgNEIksKPgoCBAESBEgATwEaMiBSZXByZXNlbnRzIGFkZGl0aW9uYWwgZGV0YWlscyBvZiBh
IHN0YXR1cyBldmVudC4KCgoKAwQBARIDSAgUCikKBAQBCAASBEoCTgMaGyBUaGUgZGV0YWls
cyBvZiB0aGUgZXZlbnQuCgoMCgUEAQgAARIDSggVCkcKBAQBAgASBEwETTQaOSBPdXRwdXQg
b25seS4gQWRkaXRpb25hbCBkZXRhaWxzIGZvciBhbiBleGVjdXRpb24gZXZlbnQuCgoMCgUE
AQIABhIDTAQUCgwKBQQBAgABEgNMFSYKDAoFBAECAAMSA0wpKgoMCgUEAQIACBIDTQgzCg8K
CAQBAgAInAgAEgNNCTIKOAoCBAISBFIAVQEaLCBBZGRpdGlvbmFsIGRldGFpbHMgZm9yIGFu
IGV4ZWN1dGlvbiBldmVudC4KCgoKAwQCARIDUggYCk8KBAQCAgASA1QCQRpCIE91dHB1dCBv
bmx5LiBUaGUgcm91bmQgSUQgYXQgd2hpY2ggdGhlIGV4ZWN1dGlvbiBldmVudCBvY2N1cnJl
ZC4KCgwKBQQCAgAFEgNUAgcKDAoFBAICAAESA1QIEAoMCgUEAgIAAxIDVBMUCgwKBQQCAgAI
EgNUFUAKDwoIBAICAAicCAASA1QWP2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Universalledger::V1::StatusEvent::StatusEvent ===
    # Fields for StatusEvent
    # Field: event_time Type: 11 (.google.protobuf.Timestamp)
    # Field: event_type Type: 14 (.google.cloud.universalledger.v1.EventType)
    # Field: event_details Type: 11 (.google.cloud.universalledger.v1.EventDetails)

# === Message: Google::Cloud::Universalledger::V1::StatusEvent::EventDetails ===
    # Fields for EventDetails
    # Field: execution_details Type: 11 (.google.cloud.universalledger.v1.ExecutionDetails)

# === Message: Google::Cloud::Universalledger::V1::StatusEvent::ExecutionDetails ===
    # Fields for ExecutionDetails
    # Field: round_id Type: 3 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Universalledger::V1::StatusEvent - Compiled Protocol Buffers messages for google/cloud/universalledger/v1/status_event.proto

=head1 SYNOPSIS

    use Google::Cloud::Universalledger::V1::StatusEvent;

    my $msg = Google::Cloud::Universalledger::V1::StatusEvent::StatusEvent->new({
        event_time => $event_time,
        event_type => $event_type,
        event_details => $event_details,
    });

    # Read or update a field
    my $val = $msg->event_time();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Universalledger::V1::StatusEvent::StatusEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/universalledger/v1/status_event.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Universalledger::V1::StatusEvent::StatusEvent

Represents an event in the processing of a transaction as observed by a
single validator.

All values reported are from the perspective of the validator handling the
request and may differ from the view of other validators.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->event_time() >> / C<< $msg->event_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time when the event was recorded by this validator.

=item * C<< $msg->event_type() >> / C<< $msg->event_type($value) >>

Type: C<Enum> (L<Google::Cloud::Universalledger::V1::EventType>)

Output only. The type of the event.

=item * C<< $msg->event_details() >> / C<< $msg->event_details($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::StatusEvent::EventDetails>)

Output only. Additional details associated with the event.

=back

=head2 Google::Cloud::Universalledger::V1::StatusEvent::EventDetails

Represents additional details of a status event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->execution_details() >> / C<< $msg->execution_details($value) >>

Type: C<Message> (L<Google::Cloud::Universalledger::V1::StatusEvent::ExecutionDetails>)

Output only. Additional details for an execution event.

=back

=head2 Google::Cloud::Universalledger::V1::StatusEvent::ExecutionDetails

Additional details for an execution event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->round_id() >> / C<< $msg->round_id($value) >>

Type: C<Int64>

Output only. The round ID at which the execution event occurred.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Universalledger::V1::StatusEvent::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
