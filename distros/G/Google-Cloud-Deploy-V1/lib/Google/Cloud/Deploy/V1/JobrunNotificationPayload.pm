package Google::Cloud::Deploy::V1::JobrunNotificationPayload;

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
Cjhnb29nbGUvY2xvdWQvZGVwbG95L3YxL2pvYnJ1bl9ub3RpZmljYXRpb25fcGF5bG9hZC5w
cm90bxIWZ29vZ2xlLmNsb3VkLmRlcGxveS52MRomZ29vZ2xlL2Nsb3VkL2RlcGxveS92MS9s
b2dfZW51bXMucHJvdG8itAIKF0pvYlJ1bk5vdGlmaWNhdGlvbkV2ZW50EhgKB21lc3NhZ2UY
ASABKAlSB21lc3NhZ2USFwoHam9iX3J1bhgCIAEoCVIGam9iUnVuEiEKDHBpcGVsaW5lX3Vp
ZBgDIAEoCVILcGlwZWxpbmVVaWQSHwoLcmVsZWFzZV91aWQYBCABKAlSCnJlbGVhc2VVaWQS
GAoHcmVsZWFzZRgIIAEoCVIHcmVsZWFzZRIfCgtyb2xsb3V0X3VpZBgFIAEoCVIKcm9sbG91
dFVpZBIYCgdyb2xsb3V0GAkgASgJUgdyb2xsb3V0EhsKCXRhcmdldF9pZBgGIAEoCVIIdGFy
Z2V0SWQSMAoEdHlwZRgHIAEoDjIcLmdvb2dsZS5jbG91ZC5kZXBsb3kudjEuVHlwZVIEdHlw
ZUJyChpjb20uZ29vZ2xlLmNsb3VkLmRlcGxveS52MUIeSm9iUnVuTm90aWZpY2F0aW9uUGF5
bG9hZFByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vZGVwbG95L2FwaXYxL2RlcGxveXBi
O2RlcGxveXBiSsQNCgYSBA4ANwEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
bGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIu
MCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBp
biBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkg
b2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2Vz
L0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFn
cmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExp
Y2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FS
UkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBp
bXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292
ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2Uu
CgoICgECEgMQAB8KCQoCAwASAxIAMAoICgEIEgMUAEkKCQoCCAsSAxQASQoICgEIEgMVACIK
CQoCCAoSAxUAIgoICgEIEgMWAD8KCQoCCAgSAxYAPwoICgEIEgMXADMKCQoCCAESAxcAMwq2
AQoCBAASBBwANwEaqQEgUGF5bG9hZCBwcm90byBmb3IgImNsb3VkZGVwbG95Lmdvb2dsZWFw
aXMuY29tL2pvYnJ1bl9ub3RpZmljYXRpb24iCiBQbGF0Zm9ybSBMb2cgZXZlbnQgdGhhdCBk
ZXNjcmliZXMgdGhlIGZhaWx1cmUgdG8gc2VuZCBKb2JSdW4gcmVzb3VyY2UgdXBkYXRlCiBQ
dWIvU3ViIG5vdGlmaWNhdGlvbi4KCgoKAwQAARIDHAgfCkMKBAQAAgASAx4CFRo2IERlYnVn
IG1lc3NhZ2UgZm9yIHdoZW4gYSBub3RpZmljYXRpb24gZmFpbHMgdG8gc2VuZC4KCgwKBQQA
AgAFEgMeAggKDAoFBAACAAESAx4JEAoMCgUEAAIAAxIDHhMUCigKBAQAAgESAyECFRobIFRo
ZSBuYW1lIG9mIHRoZSBgSm9iUnVuYC4KCgwKBQQAAgEFEgMhAggKDAoFBAACAQESAyEJEAoM
CgUEAAIBAxIDIRMUCjsKBAQAAgISAyQCGhouIFVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBg
RGVsaXZlcnlQaXBlbGluZWAuCgoMCgUEAAICBRIDJAIICgwKBQQAAgIBEgMkCRUKDAoFBAAC
AgMSAyQYGQoyCgQEAAIDEgMnAhkaJSBVbmlxdWUgaWRlbnRpZmllciBvZiB0aGUgYFJlbGVh
c2VgLgoKDAoFBAACAwUSAycCCAoMCgUEAAIDARIDJwkUCgwKBQQAAgMDEgMnFxgKKQoEBAAC
BBIDKgIVGhwgVGhlIG5hbWUgb2YgdGhlIGBSZWxlYXNlYC4KCgwKBQQAAgQFEgMqAggKDAoF
BAACBAESAyoJEAoMCgUEAAIEAxIDKhMUCjIKBAQAAgUSAy0CGRolIFVuaXF1ZSBpZGVudGlm
aWVyIG9mIHRoZSBgUm9sbG91dGAuCgoMCgUEAAIFBRIDLQIICgwKBQQAAgUBEgMtCRQKDAoF
BAACBQMSAy0XGAopCgQEAAIGEgMwAhUaHCBUaGUgbmFtZSBvZiB0aGUgYFJvbGxvdXRgLgoK
DAoFBAACBgUSAzACCAoMCgUEAAIGARIDMAkQCgwKBQQAAgYDEgMwExQKIgoEBAACBxIDMwIX
GhUgSUQgb2YgdGhlIGBUYXJnZXRgLgoKDAoFBAACBwUSAzMCCAoMCgUEAAIHARIDMwkSCgwK
BQQAAgcDEgMzFRYKRQoEBAACCBIDNgIQGjggVHlwZSBvZiB0aGlzIG5vdGlmaWNhdGlvbiwg
ZS5nLiBmb3IgYSBQdWIvU3ViIGZhaWx1cmUuCgoMCgUEAAIIBhIDNgIGCgwKBQQAAggBEgM2
BwsKDAoFBAACCAMSAzYOD2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::JobrunNotificationPayload::JobRunNotificationEvent ===
    # Fields for JobRunNotificationEvent
    # Field: message Type: 9 ()
    # Field: job_run Type: 9 ()
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

Google::Cloud::Deploy::V1::JobrunNotificationPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/jobrun_notification_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::JobrunNotificationPayload;

    my $msg = Google::Cloud::Deploy::V1::JobrunNotificationPayload::JobRunNotificationEvent->new({
        message => $message,
        job_run => $job_run,
        pipeline_uid => $pipeline_uid,
        release_uid => $release_uid,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::JobrunNotificationPayload::JobRunNotificationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/jobrun_notification_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::JobrunNotificationPayload::JobRunNotificationEvent

Payload proto for "clouddeploy.googleapis.com/jobrun_notification"
Platform Log event that describes the failure to send JobRun resource update
Pub/Sub notification.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when a notification fails to send.

=item * C<< $msg->job_run() >> / C<< $msg->job_run($value) >>

Type: C<String>

The name of the `JobRun`.

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

ID of the `Target`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a Pub/Sub failure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::JobrunNotificationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
