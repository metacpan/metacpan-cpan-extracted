package Google::Cloud::Deploy::V1::RolloutNotificationPayload;

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
Cjlnb29nbGUvY2xvdWQvZGVwbG95L3YxL3JvbGxvdXRfbm90aWZpY2F0aW9uX3BheWxvYWQu
cHJvdG8SFmdvb2dsZS5jbG91ZC5kZXBsb3kudjEaJmdvb2dsZS9jbG91ZC9kZXBsb3kvdjEv
bG9nX2VudW1zLnByb3RvIpwCChhSb2xsb3V0Tm90aWZpY2F0aW9uRXZlbnQSGAoHbWVzc2Fn
ZRgBIAEoCVIHbWVzc2FnZRIhCgxwaXBlbGluZV91aWQYAiABKAlSC3BpcGVsaW5lVWlkEh8K
C3JlbGVhc2VfdWlkGAMgASgJUgpyZWxlYXNlVWlkEhgKB3JlbGVhc2UYByABKAlSB3JlbGVh
c2USHwoLcm9sbG91dF91aWQYCCABKAlSCnJvbGxvdXRVaWQSGAoHcm9sbG91dBgEIAEoCVIH
cm9sbG91dBIbCgl0YXJnZXRfaWQYBiABKAlSCHRhcmdldElkEjAKBHR5cGUYBSABKA4yHC5n
b29nbGUuY2xvdWQuZGVwbG95LnYxLlR5cGVSBHR5cGVCcwoaY29tLmdvb2dsZS5jbG91ZC5k
ZXBsb3kudjFCH1JvbGxvdXROb3RpZmljYXRpb25QYXlsb2FkUHJvdG9QAVoyY2xvdWQuZ29v
Z2xlLmNvbS9nby9kZXBsb3kvYXBpdjEvZGVwbG95cGI7ZGVwbG95cGJKkA0KBhIEDgA0AQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgIDABIDEgAw
CggKAQgSAxQASQoJCgIICxIDFABJCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgSAxYAQAoJ
CgIICBIDFgBACggKAQgSAxcAMwoJCgIIARIDFwAzCrYBCgIEABIEHAA0ARqpASBQYXlsb2Fk
IHByb3RvIGZvciAiY2xvdWRkZXBsb3kuZ29vZ2xlYXBpcy5jb20vcm9sbG91dF9ub3RpZmlj
YXRpb24iCiBQbGF0Zm9ybSBMb2cgZXZlbnQgdGhhdCBkZXNjcmliZXMgdGhlIGZhaWx1cmUg
dG8gc2VuZCByb2xsb3V0IHN0YXR1cyBjaGFuZ2UKIFB1Yi9TdWIgbm90aWZpY2F0aW9uLgoK
CgoDBAABEgMcCCAKQwoEBAACABIDHgIVGjYgRGVidWcgbWVzc2FnZSBmb3Igd2hlbiBhIG5v
dGlmaWNhdGlvbiBmYWlscyB0byBzZW5kLgoKDAoFBAACAAUSAx4CCAoMCgUEAAIAARIDHgkQ
CgwKBQQAAgADEgMeExQKOwoEBAACARIDIQIaGi4gVW5pcXVlIGlkZW50aWZpZXIgb2YgdGhl
IGBEZWxpdmVyeVBpcGVsaW5lYC4KCgwKBQQAAgEFEgMhAggKDAoFBAACAQESAyEJFQoMCgUE
AAIBAxIDIRgZCjIKBAQAAgISAyQCGRolIFVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBgUmVs
ZWFzZWAuCgoMCgUEAAICBRIDJAIICgwKBQQAAgIBEgMkCRQKDAoFBAACAgMSAyQXGAopCgQE
AAIDEgMnAhUaHCBUaGUgbmFtZSBvZiB0aGUgYFJlbGVhc2VgLgoKDAoFBAACAwUSAycCCAoM
CgUEAAIDARIDJwkQCgwKBQQAAgMDEgMnExQKMgoEBAACBBIDKgIZGiUgVW5pcXVlIGlkZW50
aWZpZXIgb2YgdGhlIGBSb2xsb3V0YC4KCgwKBQQAAgQFEgMqAggKDAoFBAACBAESAyoJFAoM
CgUEAAIEAxIDKhcYCikKBAQAAgUSAy0CFRocIFRoZSBuYW1lIG9mIHRoZSBgUm9sbG91dGAu
CgoMCgUEAAIFBRIDLQIICgwKBQQAAgUBEgMtCRAKDAoFBAACBQMSAy0TFApCCgQEAAIGEgMw
AhcaNSBJRCBvZiB0aGUgYFRhcmdldGAgdGhhdCB0aGUgcm9sbG91dCBpcyBkZXBsb3llZCB0
by4KCgwKBQQAAgYFEgMwAggKDAoFBAACBgESAzAJEgoMCgUEAAIGAxIDMBUWCkUKBAQAAgcS
AzMCEBo4IFR5cGUgb2YgdGhpcyBub3RpZmljYXRpb24sIGUuZy4gZm9yIGEgUHViL1N1YiBm
YWlsdXJlLgoKDAoFBAACBwYSAzMCBgoMCgUEAAIHARIDMwcLCgwKBQQAAgcDEgMzDg9iBnBy
b3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::RolloutNotificationPayload::RolloutNotificationEvent ===
    # Fields for RolloutNotificationEvent
    # Field: message Type: 9 ()
    # Field: pipeline_uid Type: 9 ()
    # Field: release_uid Type: 9 ()
    # Field: release Type: 9 ()
    # Field: rollout_uid Type: 9 ()
    # Field: rollout Type: 9 ()
    # Field: target_id Type: 9 ()
    # Field: type Type: 14 (.google.cloud.deploy.v1.Type)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::RolloutNotificationPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/rollout_notification_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::RolloutNotificationPayload;

    my $msg = Google::Cloud::Deploy::V1::RolloutNotificationPayload::RolloutNotificationEvent->new({
        message => $message,
        pipeline_uid => $pipeline_uid,
        release_uid => $release_uid,
        release => $release,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::RolloutNotificationPayload::RolloutNotificationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/rollout_notification_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::RolloutNotificationPayload::RolloutNotificationEvent

Payload proto for "clouddeploy.googleapis.com/rollout_notification"
Platform Log event that describes the failure to send rollout status change
Pub/Sub notification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when a notification fails to send.

=item * C<< $msg->pipeline_uid() >> / C<< $msg->pipeline_uid($value) >>

Type: C<String>

Unique identifier of the `DeliveryPipeline`.

=item * C<< $msg->release_uid() >> / C<< $msg->release_uid($value) >>

Type: C<String>

Unique identifier of the `Release`.

=item * C<< $msg->release() >> / C<< $msg->release($value) >>

Type: C<String>

The name of the `Release`.

=item * C<< $msg->rollout_uid() >> / C<< $msg->rollout_uid($value) >>

Type: C<String>

Unique identifier of the `Rollout`.

=item * C<< $msg->rollout() >> / C<< $msg->rollout($value) >>

Type: C<String>

The name of the `Rollout`.

=item * C<< $msg->target_id() >> / C<< $msg->target_id($value) >>

Type: C<String>

ID of the `Target` that the rollout is deployed to.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a Pub/Sub failure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::RolloutNotificationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
