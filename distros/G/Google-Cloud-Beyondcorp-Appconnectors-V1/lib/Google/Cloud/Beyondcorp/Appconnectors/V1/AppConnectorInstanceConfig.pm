package Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Protobuf::Any };
    my $descriptor_b64 = <<'EOF';
Ckxnb29nbGUvY2xvdWQvYmV5b25kY29ycC9hcHBjb25uZWN0b3JzL3YxL2FwcF9jb25uZWN0
b3JfaW5zdGFuY2VfY29uZmlnLnByb3RvEihnb29nbGUuY2xvdWQuYmV5b25kY29ycC5hcHBj
b25uZWN0b3JzLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUv
cHJvdG9idWYvYW55LnByb3RvItICChpBcHBDb25uZWN0b3JJbnN0YW5jZUNvbmZpZxIsCg9z
ZXF1ZW5jZV9udW1iZXIYASABKANCA+BBAlIOc2VxdWVuY2VOdW1iZXISPQoPaW5zdGFuY2Vf
Y29uZmlnGAIgASgLMhQuZ29vZ2xlLnByb3RvYnVmLkFueVIOaW5zdGFuY2VDb25maWcSbQoT
bm90aWZpY2F0aW9uX2NvbmZpZxgDIAEoCzI8Lmdvb2dsZS5jbG91ZC5iZXlvbmRjb3JwLmFw
cGNvbm5lY3RvcnMudjEuTm90aWZpY2F0aW9uQ29uZmlnUhJub3RpZmljYXRpb25Db25maWcS
WAoMaW1hZ2VfY29uZmlnGAQgASgLMjUuZ29vZ2xlLmNsb3VkLmJleW9uZGNvcnAuYXBwY29u
bmVjdG9ycy52MS5JbWFnZUNvbmZpZ1ILaW1hZ2VDb25maWcigAIKEk5vdGlmaWNhdGlvbkNv
bmZpZxKNAQoTcHVic3ViX25vdGlmaWNhdGlvbhgBIAEoCzJaLmdvb2dsZS5jbG91ZC5iZXlv
bmRjb3JwLmFwcGNvbm5lY3RvcnMudjEuTm90aWZpY2F0aW9uQ29uZmlnLkNsb3VkUHViU3Vi
Tm90aWZpY2F0aW9uQ29uZmlnSABSEnB1YnN1Yk5vdGlmaWNhdGlvbhpQCh1DbG91ZFB1YlN1
Yk5vdGlmaWNhdGlvbkNvbmZpZxIvChNwdWJzdWJfc3Vic2NyaXB0aW9uGAEgASgJUhJwdWJz
dWJTdWJzY3JpcHRpb25CCAoGY29uZmlnIlMKC0ltYWdlQ29uZmlnEiEKDHRhcmdldF9pbWFn
ZRgBIAEoCVILdGFyZ2V0SW1hZ2USIQoMc3RhYmxlX2ltYWdlGAIgASgJUgtzdGFibGVJbWFn
ZUKqAgosY29tLmdvb2dsZS5jbG91ZC5iZXlvbmRjb3JwLmFwcGNvbm5lY3RvcnMudjFCH0Fw
cENvbm5lY3Rvckluc3RhbmNlQ29uZmlnUHJvdG9QAVpSY2xvdWQuZ29vZ2xlLmNvbS9nby9i
ZXlvbmRjb3JwL2FwcGNvbm5lY3RvcnMvYXBpdjEvYXBwY29ubmVjdG9yc3BiO2FwcGNvbm5l
Y3RvcnNwYqoCKEdvb2dsZS5DbG91ZC5CZXlvbmRDb3JwLkFwcENvbm5lY3RvcnMuVjHKAihH
b29nbGVcQ2xvdWRcQmV5b25kQ29ycFxBcHBDb25uZWN0b3JzXFYx6gIsR29vZ2xlOjpDbG91
ZDo6QmV5b25kQ29ycDo6QXBwQ29ubmVjdG9yczo6VjFK/RMKBhIEDgBJAQq8BAoBDBIDDgAS
MrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBh
Y2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90
IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4K
IFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8v
d3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQg
YnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBk
aXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMg
SVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJ
TkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRo
ZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0
aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAMQoJCgIDABIDEgApCgkKAgMBEgMT
ACMKCAoBCBIDFQBFCgkKAgglEgMVAEUKCAoBCBIDFgBpCgkKAggLEgMWAGkKCAoBCBIDFwAi
CgkKAggKEgMXACIKCAoBCBIDGABACgkKAggIEgMYAEAKCAoBCBIDGQBFCgkKAggBEgMZAEUK
CAoBCBIDGgBGCgkKAggpEgMaAEYKCAoBCBIDGwBFCgkKAggtEgMbAEUKVwoCBAASBB4ALgEa
SyBBcHBDb25uZWN0b3JJbnN0YW5jZUNvbmZpZyBkZWZpbmVzIHRoZSBpbnN0YW5jZSBjb25m
aWcgb2YgYSBBcHBDb25uZWN0b3IuCgoKCgMEAAESAx4IIgrVAQoEBAACABIDIgJFGscBIFJl
cXVpcmVkLiBBIG1vbm90b25pY2FsbHkgaW5jcmVhc2luZyBudW1iZXIgZ2VuZXJhdGVkIGFu
ZCBtYWludGFpbmVkCiBieSB0aGUgQVBJIHByb3ZpZGVyLiBFdmVyeSB0aW1lIGEgY29uZmln
IGNoYW5nZXMgaW4gdGhlIGJhY2tlbmQsIHRoZQogc2VxdWVuY2VOdW1iZXIgc2hvdWxkIGJl
IGJ1bXBlZCB1cCB0byByZWZsZWN0IHRoZSBjaGFuZ2UuCgoMCgUEAAIABRIDIgIHCgwKBQQA
AgABEgMiCBcKDAoFBAACAAMSAyIaGwoMCgUEAAIACBIDIhxECg8KCAQAAgAInAgAEgMiHUMK
NAoEBAACARIDJQIqGicgVGhlIFNMTSBpbnN0YW5jZSBhZ2VudCBjb25maWd1cmF0aW9uLgoK
DAoFBAACAQYSAyUCFQoMCgUEAAIBARIDJRYlCgwKBQQAAgEDEgMlKCkKlQEKBAQAAgISAykC
LRqHASBOb3RpZmljYXRpb25Db25maWcgZGVmaW5lcyB0aGUgbm90aWZpY2F0aW9uIG1lY2hh
bmlzbSB0aGF0IHRoZSByZW1vdGUKIGluc3RhbmNlIHNob3VsZCBzdWJzY3JpYmUgdG8gaW4g
b3JkZXIgdG8gcmVjZWl2ZSBub3RpZmljYXRpb24uCgoMCgUEAAICBhIDKQIUCgwKBQQAAgIB
EgMpFSgKDAoFBAACAgMSAykrLApfCgQEAAIDEgMtAh8aUiBJbWFnZUNvbmZpZyBkZWZpbmVz
IHRoZSBHQ1IgaW1hZ2VzIHRvIHJ1biBmb3IgdGhlIHJlbW90ZSBhZ2VudCdzIGNvbnRyb2wK
IHBsYW5lLgoKDAoFBAACAwYSAy0CDQoMCgUEAAIDARIDLQ4aCgwKBQQAAgMDEgMtHR4KUQoC
BAESBDEAPAEaRSBOb3RpZmljYXRpb25Db25maWcgZGVmaW5lcyB0aGUgbWVjaGFuaXNtcyB0
byBub3RpZnkgaW5zdGFuY2UgYWdlbnQuCgoKCgMEAQESAzEIGgpNCgQEAQMAEgQzAjYDGj8g
VGhlIGNvbmZpZ3VyYXRpb24gZm9yIFB1Yi9TdWIgbWVzc2FnaW5nIGZvciB0aGUgQXBwQ29u
bmVjdG9yLgoKDAoFBAEDAAESAzMKJwpZCgYEAQMAAgASAzUEIxpKIFRoZSBQdWIvU3ViIHN1
YnNjcmlwdGlvbiB0aGUgQXBwQ29ubmVjdG9yIHVzZXMgdG8gcmVjZWl2ZSBub3RpZmljYXRp
b25zLgoKDgoHBAEDAAIABRIDNQQKCg4KBwQBAwACAAESAzULHgoOCgcEAQMAAgADEgM1ISIK
DAoEBAEIABIEOAI7AwoMCgUEAQgAARIDOAgOCkQKBAQBAgASAzoEOho3IENsb3VkIFB1Yi9T
dWIgQ29uZmlndXJhdGlvbiB0byByZWNlaXZlIG5vdGlmaWNhdGlvbnMuCgoMCgUEAQIABhID
OgQhCgwKBQQBAgABEgM6IjUKDAoFBAECAAMSAzo4OQpCCgIEAhIEPwBJARo2IEltYWdlQ29u
ZmlnIGRlZmluZXMgdGhlIGNvbnRyb2wgcGxhbmUgaW1hZ2VzIHRvIHJ1bi4KCgoKAwQCARID
PwgTCqcBCgQEAgIAEgNDAhoamQEgVGhlIGluaXRpYWwgaW1hZ2UgdGhlIHJlbW90ZSBhZ2Vu
dCB3aWxsIGF0dGVtcHQgdG8gcnVuIGZvciB0aGUgY29udHJvbAogcGxhbmUuIEZvcm1hdCB3
b3VsZCBiZSBhIGdjciBpbWFnZSBwYXRoLCBlLmcuOgogZ2NyLmlvL1BST0pFQ1QtSUQvbXkt
aW1hZ2U6dGFnMQoKDAoFBAICAAUSA0MCCAoMCgUEAgIAARIDQwkVCgwKBQQCAgADEgNDGBkK
rAEKBAQCAgESA0gCGhqeASBUaGUgc3RhYmxlIGltYWdlIHRoYXQgdGhlIHJlbW90ZSBhZ2Vu
dCB3aWxsIGZhbGxiYWNrIHRvIGlmIHRoZSB0YXJnZXQgaW1hZ2UKIGZhaWxzLiBGb3JtYXQg
d291bGQgYmUgYSBnY3IgaW1hZ2UgcGF0aCwgZS5nLjoKIGdjci5pby9QUk9KRUNULUlEL215
LWltYWdlOnRhZzEKCgwKBQQCAgEFEgNIAggKDAoFBAICAQESA0gJFQoMCgUEAgIBAxIDSBgZ
YgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::AppConnectorInstanceConfig ===
    # Fields for AppConnectorInstanceConfig
    # Field: sequence_number Type: 3 ()
    # Field: instance_config Type: 11 (.google.protobuf.Any)
    # Field: notification_config Type: 11 (.google.cloud.beyondcorp.appconnectors.v1.NotificationConfig)
    # Field: image_config Type: 11 (.google.cloud.beyondcorp.appconnectors.v1.ImageConfig)

# === Message: Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::NotificationConfig ===
    # Fields for NotificationConfig
    # Field: pubsub_notification Type: 11 (.google.cloud.beyondcorp.appconnectors.v1.NotificationConfig.CloudPubSubNotificationConfig)

# === Message: Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::ImageConfig ===
    # Fields for ImageConfig
    # Field: target_image Type: 9 ()
    # Field: stable_image Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig - Compiled Protocol Buffers messages for google/cloud/beyondcorp/appconnectors/v1/app_connector_instance_config.proto

=head1 SYNOPSIS

    use Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig;

    my $msg = Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::AppConnectorInstanceConfig->new({
        sequence_number => $sequence_number,
        instance_config => $instance_config,
        notification_config => $notification_config,
        image_config => $image_config,
    });

    # Read or update a field
    my $val = $msg->sequence_number();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::AppConnectorInstanceConfig->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/beyondcorp/appconnectors/v1/app_connector_instance_config.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::AppConnectorInstanceConfig

AppConnectorInstanceConfig defines the instance config of a AppConnector.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->sequence_number() >> / C<< $msg->sequence_number($value) >>

Type: C<Int64>

Required. A monotonically increasing number generated and maintained
by the API provider. Every time a config changes in the backend, the
sequenceNumber should be bumped up to reflect the change.

=item * C<< $msg->instance_config() >> / C<< $msg->instance_config($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

The SLM instance agent configuration.

=item * C<< $msg->notification_config() >> / C<< $msg->notification_config($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::NotificationConfig>)

NotificationConfig defines the notification mechanism that the remote
instance should subscribe to in order to receive notification.

=item * C<< $msg->image_config() >> / C<< $msg->image_config($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::ImageConfig>)

ImageConfig defines the GCR images to run for the remote agent's control
plane.

=back

=head2 Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::NotificationConfig

NotificationConfig defines the mechanisms to notify instance agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->pubsub_notification() >> / C<< $msg->pubsub_notification($value) >>

Type: C<Message> (L<Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::NotificationConfig::CloudPubSubNotificationConfig>)

Cloud Pub/Sub Configuration to receive notifications.

=back

=head2 Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::ImageConfig

ImageConfig defines the control plane images to run.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->target_image() >> / C<< $msg->target_image($value) >>

Type: C<String>

The initial image the remote agent will attempt to run for the control
plane. Format would be a gcr image path, e.g.:
gcr.io/PROJECT-ID/my-image:tag1

=item * C<< $msg->stable_image() >> / C<< $msg->stable_image($value) >>

Type: C<String>

The stable image that the remote agent will fallback to if the target image
fails. Format would be a gcr image path, e.g.:
gcr.io/PROJECT-ID/my-image:tag1

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Beyondcorp::Appconnectors::V1::AppConnectorInstanceConfig::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
