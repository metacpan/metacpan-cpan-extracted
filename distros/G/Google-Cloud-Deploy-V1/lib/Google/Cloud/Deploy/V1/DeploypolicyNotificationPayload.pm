package Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload;

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
Cj5nb29nbGUvY2xvdWQvZGVwbG95L3YxL2RlcGxveXBvbGljeV9ub3RpZmljYXRpb25fcGF5
bG9hZC5wcm90bxIWZ29vZ2xlLmNsb3VkLmRlcGxveS52MRomZ29vZ2xlL2Nsb3VkL2RlcGxv
eS92MS9sb2dfZW51bXMucHJvdG8ivAEKHURlcGxveVBvbGljeU5vdGlmaWNhdGlvbkV2ZW50
EhgKB21lc3NhZ2UYASABKAlSB21lc3NhZ2USIwoNZGVwbG95X3BvbGljeRgCIAEoCVIMZGVw
bG95UG9saWN5EioKEWRlcGxveV9wb2xpY3lfdWlkGAMgASgJUg9kZXBsb3lQb2xpY3lVaWQS
MAoEdHlwZRgEIAEoDjIcLmdvb2dsZS5jbG91ZC5kZXBsb3kudjEuVHlwZVIEdHlwZUJ4Chpj
b20uZ29vZ2xlLmNsb3VkLmRlcGxveS52MUIkRGVwbG95UG9saWN5Tm90aWZpY2F0aW9uUGF5
bG9hZFByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vZGVwbG95L2FwaXYxL2RlcGxveXBi
O2RlcGxveXBiSscKCgYSBA4AKQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29n
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
CQoCCAoSAxUAIgoICgEIEgMWAEUKCQoCCAgSAxYARQoICgEIEgMXADMKCQoCCAESAxcAMwrT
AQoCBAASBBwAKQEaxgEgUGF5bG9hZCBwcm90byBmb3IgImNsb3VkZGVwbG95Lmdvb2dsZWFw
aXMuY29tL2RlcGxveXBvbGljeV9ub3RpZmljYXRpb24iLgogUGxhdGZvcm0gTG9nIGV2ZW50
IHRoYXQgZGVzY3JpYmVzIHRoZSBmYWlsdXJlIHRvIHNlbmQgYSBwdWIvc3ViIG5vdGlmaWNh
dGlvbgogd2hlbiB0aGVyZSBpcyBhIERlcGxveVBvbGljeSBzdGF0dXMgY2hhbmdlLgoKCgoD
BAABEgMcCCUKXAoEBAACABIDHwIVGk8gRGVidWcgbWVzc2FnZSBmb3Igd2hlbiBhIGRlcGxv
eSBwb2xpY3kgZmFpbHMgdG8gc2VuZCBhIHB1Yi9zdWIKIG5vdGlmaWNhdGlvbi4KCgwKBQQA
AgAFEgMfAggKDAoFBAACAAESAx8JEAoMCgUEAAIAAxIDHxMUCi4KBAQAAgESAyICGxohIFRo
ZSBuYW1lIG9mIHRoZSBgRGVwbG95UG9saWN5YC4KCgwKBQQAAgEFEgMiAggKDAoFBAACAQES
AyIJFgoMCgUEAAIBAxIDIhkaCjYKBAQAAgISAyUCHxopIFVuaXF1ZSBpZGVudGlmaWVyIG9m
IHRoZSBkZXBsb3kgcG9saWN5LgoKDAoFBAACAgUSAyUCCAoMCgUEAAICARIDJQkaCgwKBQQA
AgIDEgMlHR4KRQoEBAACAxIDKAIQGjggVHlwZSBvZiB0aGlzIG5vdGlmaWNhdGlvbiwgZS5n
LiBmb3IgYSBQdWIvU3ViIGZhaWx1cmUuCgoMCgUEAAIDBhIDKAIGCgwKBQQAAgMBEgMoBwsK
DAoFBAACAwMSAygOD2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload::DeployPolicyNotificationEvent ===
    # Fields for DeployPolicyNotificationEvent
    # Field: message Type: 9 ()
    # Field: deploy_policy Type: 9 ()
    # Field: deploy_policy_uid Type: 9 ()
    # Field: type Type: 14 (.google.cloud.deploy.v1.Type)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/deploypolicy_notification_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload;

    my $msg = Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload::DeployPolicyNotificationEvent->new({
        message => $message,
        deploy_policy => $deploy_policy,
        deploy_policy_uid => $deploy_policy_uid,
        type => $type,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload::DeployPolicyNotificationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/deploypolicy_notification_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload::DeployPolicyNotificationEvent

Payload proto for "clouddeploy.googleapis.com/deploypolicy_notification".
Platform Log event that describes the failure to send a pub/sub notification
when there is a DeployPolicy status change.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when a deploy policy fails to send a pub/sub
notification.

=item * C<< $msg->deploy_policy() >> / C<< $msg->deploy_policy($value) >>

Type: C<String>

The name of the `DeployPolicy`.

=item * C<< $msg->deploy_policy_uid() >> / C<< $msg->deploy_policy_uid($value) >>

Type: C<String>

Unique identifier of the deploy policy.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a Pub/Sub failure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::DeploypolicyNotificationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
