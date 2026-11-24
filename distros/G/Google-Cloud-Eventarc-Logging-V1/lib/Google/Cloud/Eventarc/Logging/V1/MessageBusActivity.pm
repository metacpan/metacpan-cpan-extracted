package Google::Cloud::Eventarc::Logging::V1::MessageBusActivity;

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
Cjtnb29nbGUvY2xvdWQvZXZlbnRhcmMvbG9nZ2luZy92MS9tZXNzYWdlX2J1c19hY3Rpdml0
eS5wcm90bxIgZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLmxvZ2dpbmcudjEaG2dvb2dsZS9hcGkv
ZmllbGRfaW5mby5wcm90bxofZ29vZ2xlL3Byb3RvYnVmL3RpbWVzdGFtcC5wcm90bxoXZ29v
Z2xlL3JwYy9zdGF0dXMucHJvdG8i3gMKEk1lc3NhZ2VCdXNBY3Rpdml0eRIpCgttZXNzYWdl
X3VpZBgBIAEoCUII4ozP1wgCCAFSCm1lc3NhZ2VVaWQSZAoKYXR0cmlidXRlcxgCIAMoCzJE
Lmdvb2dsZS5jbG91ZC5ldmVudGFyYy5sb2dnaW5nLnYxLk1lc3NhZ2VCdXNBY3Rpdml0eS5B
dHRyaWJ1dGVzRW50cnlSCmF0dHJpYnV0ZXMSPwoNYWN0aXZpdHlfdGltZRgDIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSDGFjdGl2aXR5VGltZRJbCghyZWNlaXZlZBgEIAEo
CzI9Lmdvb2dsZS5jbG91ZC5ldmVudGFyYy5sb2dnaW5nLnYxLk1lc3NhZ2VCdXNBY3Rpdml0
eS5SZWNlaXZlZEgAUghyZWNlaXZlZBpOCghSZWNlaXZlZBIYCgdkZXRhaWxzGAQgASgJUgdk
ZXRhaWxzEigKBWVycm9yGAUgASgLMhIuZ29vZ2xlLnJwYy5TdGF0dXNSBWVycm9yGj0KD0F0
dHJpYnV0ZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6
AjgBQgoKCGFjdGl2aXR5Qu4BCiRjb20uZ29vZ2xlLmNsb3VkLmV2ZW50YXJjLmxvZ2dpbmcu
djFCF01lc3NhZ2VCdXNBY3Rpdml0eVByb3RvUAFaPmNsb3VkLmdvb2dsZS5jb20vZ28vZXZl
bnRhcmMvbG9nZ2luZy9hcGl2MS9sb2dnaW5ncGI7bG9nZ2luZ3BiqgIgR29vZ2xlLkNsb3Vk
LkV2ZW50YXJjLkxvZ2dpbmcuVjHKAiBHb29nbGVcQ2xvdWRcRXZlbnRhcmNcTG9nZ2luZ1xW
MeoCJEdvb2dsZTo6Q2xvdWQ6OkV2ZW50YXJjOjpMb2dnaW5nOjpWMUriDgoGEgQOADoBCrwE
CgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVy
IHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91
IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBM
aWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAg
IGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyBy
ZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29m
dHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9u
IGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBP
RiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5z
ZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQK
IGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAApCgkKAgMAEgMSACUK
CQoCAwESAxMAKQoJCgIDAhIDFAAhCggKAQgSAxYAPQoJCgIIJRIDFgA9CggKAQgSAxcAVQoJ
CgIICxIDFwBVCggKAQgSAxgAIgoJCgIIChIDGAAiCggKAQgSAxkAOAoJCgIICBIDGQA4CggK
AQgSAxoAPQoJCgIIARIDGgA9CggKAQgSAxsAPgoJCgIIKRIDGwA+CggKAQgSAxwAPQoJCgII
LRIDHAA9ClIKAgQAEgQfADoBGkYgTG9nZ2VkIGR1cmluZyB0aGUgcHJvY2Vzc2luZyBvZiBh
biBldmVudCBwdWJsaXNoZWQgdG8gYSBtZXNzYWdlIGJ1cy4KCgoKAwQAARIDHwgaCmMKBAQA
AwASBCICKAMaVSBTdHJ1Y3R1cmVkIGxvZyBtZXNzYWdlIHRoYXQgaXMgZW1pdHRlZCB3aGVu
IGFuIGV2ZW50IGlzIHJlY2VpdmVkIGJ5IGEKIG1lc3NhZ2UgYnVzLgoKDAoFBAADAAESAyIK
EgpACgYEAAMAAgASAyQEFxoxIEluZm9ybWF0aW9uYWwgZGV0YWlscyBhYm91dCB0aGUgZXZl
bnQgcmVjZWl2ZWQuCgoOCgcEAAMAAgAFEgMkBAoKDgoHBAADAAIAARIDJAsSCg4KBwQAAwAC
AAMSAyQVFgpACgYEAAMAAgESAycEIBoxIExvZ2dlZCB3aGVuIHRoZSBlbnJvbGxtZW50IGVu
Y291bnRlcnMgYW4gZXJyb3IuCgoOCgcEAAMAAgEGEgMnBBUKDgoHBAADAAIBARIDJxYbCg4K
BwQAAwACAQMSAyceHwqCAQoEBAACABIDLAJCGnUgVGhlIHVuaXF1ZSBzeXN0ZW0gZ2VuZXJh
dGVkIElEIHdoZW4gYSBtZXNzYWdlIGJ1cyByZWNlaXZlcyBhbiBldmVudC4gVGhpcwogSUQg
aXMgcHJvcGFnYXRlZCB0aHJvdWdob3V0IHRoZSByZXF1ZXN0LgoKDAoFBAACAAUSAywCCAoM
CgUEAAIAARIDLAkUCgwKBQQAAgADEgMsFxgKDAoFBAACAAgSAywZQQoSCgsEAAIACMzx+YoB
ARIDLBpACk0KBAQAAgESAy8CJRpAIFRoZSBDbG91ZEV2ZW50IElEIGFuZCBzb3VyY2UgZnJv
bSB0aGUgYXR0cmlidXRlcyBvZiB0aGUgZXZlbnQuCgoMCgUEAAIBBhIDLwIVCgwKBQQAAgEB
EgMvFiAKDAoFBAACAQMSAy8jJAo8CgQEAAICEgMyAi4aLyBUaGUgcG9pbnQgaW4gdGltZSB3
aGVuIHRoZSBhY3Rpdml0eSBvY2N1cnJlZC4KCgwKBQQAAgIGEgMyAhsKDAoFBAACAgESAzIc
KQoMCgUEAAICAxIDMiwtCncKBAQACAASBDYCOQMaaSBPbmUgb2YgdGhlIGFjdGl2aXRpZXMg
dGhhdCBjYW4gYmUgbG9nZ2VkIGR1cmluZyB0aGUgcHJvY2Vzc2luZyBvZiBhbiBldmVudAog
cHVibGlzaGVkIHRvIGEgbWVzc2FnZSBidXMuCgoMCgUEAAgAARIDNggQCkEKBAQAAgMSAzgE
Gho0IExvZ2dlZCB3aGVuIGFuIGV2ZW50IGlzIHJlY2VpdmVkIGJ5IGEgbWVzc2FnZSBidXMu
CgoMCgUEAAIDBhIDOAQMCgwKBQQAAgMBEgM4DRUKDAoFBAACAwMSAzgYGWIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity ===
    # Fields for MessageBusActivity
    # Field: message_uid Type: 9 ()
    # Field: attributes Type: 11 (.google.cloud.eventarc.logging.v1.MessageBusActivity.AttributesEntry)
    # Field: activity_time Type: 11 (.google.protobuf.Timestamp)
    # Field: received Type: 11 (.google.cloud.eventarc.logging.v1.MessageBusActivity.Received)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Eventarc::Logging::V1::MessageBusActivity - Compiled Protocol Buffers messages for google/cloud/eventarc/logging/v1/message_bus_activity.proto

=head1 SYNOPSIS

    use Google::Cloud::Eventarc::Logging::V1::MessageBusActivity;

    my $msg = Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity->new({
        message_uid => $message_uid,
        attributes => $attributes,
        activity_time => $activity_time,
        received => $received,
    });

    # Read or update a field
    my $val = $msg->message_uid();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/eventarc/logging/v1/message_bus_activity.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity

Logged during the processing of an event published to a message bus.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message_uid() >> / C<< $msg->message_uid($value) >>

Type: C<String>

The unique system generated ID when a message bus receives an event. This
ID is propagated throughout the request.

=item * C<< $msg->attributes() >> / C<< $msg->attributes($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity::AttributesEntry>)

The CloudEvent ID and source from the attributes of the event.

=item * C<< $msg->activity_time() >> / C<< $msg->activity_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The point in time when the activity occurred.

=item * C<< $msg->received() >> / C<< $msg->received($value) >>

Type: C<Message> (L<Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::MessageBusActivity::Received>)

Logged when an event is received by a message bus.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Eventarc::Logging::V1::MessageBusActivity::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
