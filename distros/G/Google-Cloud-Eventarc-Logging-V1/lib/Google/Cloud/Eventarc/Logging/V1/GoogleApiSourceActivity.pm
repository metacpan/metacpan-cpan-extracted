package Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldInfo };
    eval { require Google::Protobuf::Timestamp };
    eval { require Google::Rpc::Status };
    my $descriptor_b64 = <<'EOF';
CkFnb29nbGUvY2xvdWQvZXZlbnRhcmMvbG9nZ2luZy92MS9nb29nbGVfYXBpX3NvdXJjZV9h
Y3Rpdml0eS5wcm90bxIgZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLmxvZ2dpbmcudjEaG2dvb2ds
ZS9hcGkvZmllbGRfaW5mby5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90
bxoXZ29vZ2xlL3JwYy9zdGF0dXMucHJvdG8iugQKF0dvb2dsZUFwaVNvdXJjZUFjdGl2aXR5
EikKC21lc3NhZ2VfdWlkGAEgASgJQgjijM/XCAIIAVIKbWVzc2FnZVVpZBJpCgphdHRyaWJ1
dGVzGAIgAygLMkkuZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLmxvZ2dpbmcudjEuR29vZ2xlQXBp
U291cmNlQWN0aXZpdHkuQXR0cmlidXRlc0VudHJ5UgphdHRyaWJ1dGVzEj8KDWFjdGl2aXR5
X3RpbWUYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgxhY3Rpdml0eVRpbWUS
YwoJcHVibGlzaGVkGAQgASgLMkMuZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLmxvZ2dpbmcudjEu
R29vZ2xlQXBpU291cmNlQWN0aXZpdHkuUHVibGlzaGVkSABSCXB1Ymxpc2hlZBqXAQoJUHVi
bGlzaGVkEh8KC21lc3NhZ2VfYnVzGAEgASgJUgptZXNzYWdlQnVzEiUKDmV2ZW50X3Byb3Zp
ZGVyGAIgASgJUg1ldmVudFByb3ZpZGVyEhgKB2RldGFpbHMYAyABKAlSB2RldGFpbHMSKAoF
ZXJyb3IYBCABKAsyEi5nb29nbGUucnBjLlN0YXR1c1IFZXJyb3IaPQoPQXR0cmlidXRlc0Vu
dHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFCCgoIYWN0
aXZpdHlC+wEKJGNvbS5nb29nbGUuY2xvdWQuZXZlbnRhcmMubG9nZ2luZy52MUIkR29vZ2xl
QXBpRXZlbnRQdWJsaXNoZWRBY3Rpdml0eVByb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28v
ZXZlbnRhcmMvbG9nZ2luZy9hcGl2MS9sb2dnaW5ncGI7bG9nZ2luZ3BiqgIgR29vZ2xlLkNs
b3VkLkV2ZW50YXJjLkxvZ2dpbmcuVjHKAiBHb29nbGVcQ2xvdWRcRXZlbnRhcmNcTG9nZ2lu
Z1xWMeoCJEdvb2dsZTo6Q2xvdWQ6OkV2ZW50YXJjOjpMb2dnaW5nOjpWMUrMEAoGEgQOAEEB
CrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVu
ZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwog
eW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRo
ZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0Cgog
ICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVz
cyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywg
c29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVk
IG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9O
UyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGlj
ZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBh
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMS
ACUKCQoCAwESAxMAKQoJCgIDAhIDFAAhCggKAQgSAxYAPQoJCgIIJRIDFgA9CggKAQgSAxcA
VQoJCgIICxIDFwBVCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkARQoJCgIICBIDGQBF
CggKAQgSAxoAPQoJCgIIARIDGgA9CggKAQgSAxsAPgoJCgIIKRIDGwA+CggKAQgSAxwAPQoJ
CgIILRIDHAA9Cl4KAgQAEgQgAEEBGlIgTG9nZ2VkIGR1cmluZyB0aGUgcHJvY2Vzc2luZyBv
ZiBhIEdvb2dsZSBBUEkgZXZlbnQgYmVpbmcgc2VudCB0byBhCiBtZXNzYWdlIGJ1cy4KCgoK
AwQAARIDIAgfCmQKBAQAAwASBCMCLwMaViBTdHJ1Y3R1cmVkIGxvZyBtZXNzYWdlIHRoYXQg
aXMgZW1pdHRlZCB3aGVuIGFuIGV2ZW50IGlzIHB1Ymxpc2hlZCB0byBhCiBtZXNzYWdlIGJ1
cy4KCgwKBQQAAwABEgMjChMKUwoGBAADAAIAEgMlBBsaRCBUaGUgbWVzc2FnZSBidXMgYXNz
b2NpYXRlZCB3aXRoIHRoaXMgR29vZ2xlQXBpRXZlbnQgY29uZmlndXJhdGlvbi4KCg4KBwQA
AwACAAUSAyUECgoOCgcEAAMAAgABEgMlCxYKDgoHBAADAAIAAxIDJRkaCjwKBgQAAwACARID
KAQeGi0gVGhlIGV2ZW50IHByb3ZpZGVyIHRoYXQgcHJvZHVjZWQgdGhlIGV2ZW50LgoKDgoH
BAADAAIBBRIDKAQKCg4KBwQAAwACAQESAygLGQoOCgcEAAMAAgEDEgMoHB0KQQoGBAADAAIC
EgMrBBcaMiBBbnkgYWRkaXRpb25hbCBpbmZvcm1hdGlvbiBhYm91dCB0aGUgZXZlbnQgc2Vu
dC4KCg4KBwQAAwACAgUSAysECgoOCgcEAAMAAgIBEgMrCxIKDgoHBAADAAICAxIDKxUWCjkK
BgQAAwACAxIDLgQgGiogTG9nZ2VkIGlmIHRoZSBldmVudCBlbmNvdW50ZXJzIGFuIGVycm9y
LgoKDgoHBAADAAIDBhIDLgQVCg4KBwQAAwACAwESAy4WGwoOCgcEAAMAAgMDEgMuHh8KggEK
BAQAAgASAzMCQhp1IFRoZSB1bmlxdWUgc3lzdGVtIGdlbmVyYXRlZCBJRCB3aGVuIGEgbWVz
c2FnZSBidXMgcmVjZWl2ZXMgYW4gZXZlbnQuIFRoaXMKIElEIGlzIHByb3BhZ2F0ZWQgdGhy
b3VnaG91dCB0aGUgcmVxdWVzdC4KCgwKBQQAAgAFEgMzAggKDAoFBAACAAESAzMJFAoMCgUE
AAIAAxIDMxcYCgwKBQQAAgAIEgMzGUEKEgoLBAACAAjM8fmKAQESAzMaQApNCgQEAAIBEgM2
AiUaQCBUaGUgQ2xvdWRFdmVudCBJRCBhbmQgc291cmNlIGZyb20gdGhlIGF0dHJpYnV0ZXMg
b2YgdGhlIGV2ZW50LgoKDAoFBAACAQYSAzYCFQoMCgUEAAIBARIDNhYgCgwKBQQAAgEDEgM2
IyQKPAoEBAACAhIDOQIuGi8gVGhlIHBvaW50IGluIHRpbWUgd2hlbiB0aGUgYWN0aXZpdHkg
b2NjdXJyZWQuCgoMCgUEAAICBhIDOQIbCgwKBQQAAgIBEgM5HCkKDAoFBAACAgMSAzksLQpm
CgQEAAgAEgQ9AkADGlggT25lIG9mIHRoZSBhY3Rpdml0aWVzIHRoYXQgY2FuIGJlIGxvZ2dl
ZCBkdXJpbmcgdGhlIHByb2Nlc3Npbmcgb2YgYSBHb29nbGUKIEFQSSBldmVudC4KCgwKBQQA
CAABEgM9CBAKQgoEBAACAxIDPwQcGjUgTG9nZ2VkIHdoZW4gYW4gZXZlbnQgaXMgcHVibGlz
aGVkIHRvIGEgbWVzc2FnZSBidXMuCgoMCgUEAAIDBhIDPwQNCgwKBQQAAgMBEgM/DhcKDAoF
BAACAwMSAz8aG2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity ===
    # Fields for GoogleApiSourceActivity
    # Field: message_uid Type: 9 ()
    # Field: attributes Type: 11 (.google.cloud.eventarc.logging.v1.GoogleApiSourceActivity.AttributesEntry)
    # Field: activity_time Type: 11 (.google.protobuf.Timestamp)
    # Field: published Type: 11 (.google.cloud.eventarc.logging.v1.GoogleApiSourceActivity.Published)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity - Compiled Protocol Buffers messages for google/cloud/eventarc/logging/v1/google_api_source_activity.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity;

    my $msg = Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity->new({
        message_uid => $message_uid,
        attributes => $attributes,
        activity_time => $activity_time,
        published => $published,
    });

    # Read or update a field
    my $val = $msg->message_uid();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/logging/v1/google_api_source_activity.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity

Logged during the processing of a Google API event being sent to a
message bus.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message_uid() >> / C<< $msg->message_uid($value) >>

Type: C<String>

The unique system generated ID when a message bus receives an event. This
ID is propagated throughout the request.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity::AttributesEntry>)

The CloudEvent ID and source from the attributes of the event.

=item * C<< $msg->activity_time() >> / C<< $msg->activity_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The point in time when the activity occurred.

=item * C<< $msg->published() >> / C<< $msg->published($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::GoogleApiSourceActivity::Published>)

Logged when an event is published to a message bus.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::Logging::V1::GoogleApiSourceActivity::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
