package Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Deploy::V1::LogEnums };
    my $descriptor_b64 = <<'EOF';
CkJnb29nbGUvY2xvdWQvZGVwbG95L3YxL2N1c3RvbXRhcmdldHR5cGVfbm90aWZpY2F0aW9u
X3BheWxvYWQucHJvdG8SFmdvb2dsZS5jbG91ZC5kZXBsb3kudjEaJmdvb2dsZS9jbG91ZC9k
ZXBsb3kvdjEvbG9nX2VudW1zLnByb3RvItIBCiFDdXN0b21UYXJnZXRUeXBlTm90aWZpY2F0
aW9uRXZlbnQSGAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZRIzChZjdXN0b21fdGFyZ2V0X3R5
cGVfdWlkGAQgASgJUhNjdXN0b21UYXJnZXRUeXBlVWlkEiwKEmN1c3RvbV90YXJnZXRfdHlw
ZRgCIAEoCVIQY3VzdG9tVGFyZ2V0VHlwZRIwCgR0eXBlGAMgASgOMhwuZ29vZ2xlLmNsb3Vk
LmRlcGxveS52MS5UeXBlUgR0eXBlQnwKGmNvbS5nb29nbGUuY2xvdWQuZGVwbG95LnYxQihD
dXN0b21UYXJnZXRUeXBlTm90aWZpY2F0aW9uUGF5bG9hZFByb3RvUAFaMmNsb3VkLmdvb2ds
ZS5jb20vZ28vZGVwbG95L2FwaXYxL2RlcGxveXBiO2RlcGxveXBiSrAKCgYSBA4AKAEKvAQK
AQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIg
dGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3Ug
bWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExp
Y2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAg
aHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJl
cXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0
d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24g
YW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9G
IEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNl
IGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAog
bGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQAB8KCQoCAwASAxIAMAoI
CgEIEgMUAEkKCQoCCAsSAxQASQoICgEIEgMVACIKCQoCCAoSAxUAIgoICgEIEgMWAEkKCQoC
CAgSAxYASQoICgEIEgMXADMKCQoCCAESAxcAMwrMAQoCBAASBBwAKAEavwEgUGF5bG9hZCBw
cm90byBmb3IgImNsb3VkZGVwbG95Lmdvb2dsZWFwaXMuY29tL2N1c3RvbXRhcmdldHR5cGVf
bm90aWZpY2F0aW9uIgogUGxhdGZvcm0gTG9nIGV2ZW50IHRoYXQgZGVzY3JpYmVzIHRoZSBm
YWlsdXJlIHRvIHNlbmQgYSBjdXN0b20gdGFyZ2V0IHR5cGUKIHN0YXR1cyBjaGFuZ2UgUHVi
L1N1YiBub3RpZmljYXRpb24uCgoKCgMEAAESAxwIKQpDCgQEAAIAEgMeAhUaNiBEZWJ1ZyBt
ZXNzYWdlIGZvciB3aGVuIGEgbm90aWZpY2F0aW9uIGZhaWxzIHRvIHNlbmQuCgoMCgUEAAIA
BRIDHgIICgwKBQQAAgABEgMeCRAKDAoFBAACAAMSAx4TFAo7CgQEAAIBEgMhAiQaLiBVbmlx
dWUgaWRlbnRpZmllciBvZiB0aGUgYEN1c3RvbVRhcmdldFR5cGVgLgoKDAoFBAACAQUSAyEC
CAoMCgUEAAIBARIDIQkfCgwKBQQAAgEDEgMhIiMKMgoEBAACAhIDJAIgGiUgVGhlIG5hbWUg
b2YgdGhlIGBDdXN0b21UYXJnZXRUeXBlYC4KCgwKBQQAAgIFEgMkAggKDAoFBAACAgESAyQJ
GwoMCgUEAAICAxIDJB4fCkUKBAQAAgMSAycCEBo4IFR5cGUgb2YgdGhpcyBub3RpZmljYXRp
b24sIGUuZy4gZm9yIGEgUHViL1N1YiBmYWlsdXJlLgoKDAoFBAACAwYSAycCBgoMCgUEAAID
ARIDJwcLCgwKBQQAAgMDEgMnDg9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload::CustomTargetTypeNotificationEvent ===
    # Fields for CustomTargetTypeNotificationEvent
    # Field: message Type: 9 ()
    # Field: custom_target_type_uid Type: 9 ()
    # Field: custom_target_type Type: 9 ()
    # Field: type Type: 14 (.google.cloud.deploy.v1.Type)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/customtargettype_notification_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload;

    my $msg = Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload::CustomTargetTypeNotificationEvent->new({
        message => $message,
        custom_target_type_uid => $custom_target_type_uid,
        custom_target_type => $custom_target_type,
        type => $type,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload::CustomTargetTypeNotificationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/customtargettype_notification_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload::CustomTargetTypeNotificationEvent

Payload proto for "clouddeploy.googleapis.com/customtargettype_notification"
Platform Log event that describes the failure to send a custom target type
status change Pub/Sub notification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when a notification fails to send.

=item * C<< $msg->custom_target_type_uid() >> / C<< $msg->custom_target_type_uid($value) >>

Type: C<String>

Unique identifier of the `CustomTargetType`.

=item * C<< $msg->custom_target_type() >> / C<< $msg->custom_target_type($value) >>

Type: C<String>

The name of the `CustomTargetType`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a Pub/Sub failure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::CustomtargettypeNotificationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
