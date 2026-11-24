package Google::Cloud::Deploy::V1::RolloutUpdatePayload;

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
CjNnb29nbGUvY2xvdWQvZGVwbG95L3YxL3JvbGxvdXRfdXBkYXRlX3BheWxvYWQucHJvdG8S
Fmdvb2dsZS5jbG91ZC5kZXBsb3kudjEaJmdvb2dsZS9jbG91ZC9kZXBsb3kvdjEvbG9nX2Vu
dW1zLnByb3RvIu4EChJSb2xsb3V0VXBkYXRlRXZlbnQSGAoHbWVzc2FnZRgGIAEoCVIHbWVz
c2FnZRIhCgxwaXBlbGluZV91aWQYASABKAlSC3BpcGVsaW5lVWlkEh8KC3JlbGVhc2VfdWlk
GAIgASgJUgpyZWxlYXNlVWlkEhgKB3JlbGVhc2UYCCABKAlSB3JlbGVhc2USGAoHcm9sbG91
dBgDIAEoCVIHcm9sbG91dBIbCgl0YXJnZXRfaWQYBCABKAlSCHRhcmdldElkEjAKBHR5cGUY
ByABKA4yHC5nb29nbGUuY2xvdWQuZGVwbG95LnYxLlR5cGVSBHR5cGUSbAoTcm9sbG91dF91
cGRhdGVfdHlwZRgFIAEoDjI8Lmdvb2dsZS5jbG91ZC5kZXBsb3kudjEuUm9sbG91dFVwZGF0
ZUV2ZW50LlJvbGxvdXRVcGRhdGVUeXBlUhFyb2xsb3V0VXBkYXRlVHlwZSKIAgoRUm9sbG91
dFVwZGF0ZVR5cGUSIwofUk9MTE9VVF9VUERBVEVfVFlQRV9VTlNQRUNJRklFRBAAEgsKB1BF
TkRJTkcQARITCg9QRU5ESU5HX1JFTEVBU0UQAhIPCgtJTl9QUk9HUkVTUxADEg4KCkNBTkNF
TExJTkcQBBINCglDQU5DRUxMRUQQBRIKCgZIQUxURUQQBhINCglTVUNDRUVERUQQBxIKCgZG
QUlMRUQQCBIVChFBUFBST1ZBTF9SRVFVSVJFRBAJEgwKCEFQUFJPVkVEEAoSDAoIUkVKRUNU
RUQQCxIUChBBRFZBTkNFX1JFUVVJUkVEEAwSDAoIQURWQU5DRUQQDUJtChpjb20uZ29vZ2xl
LmNsb3VkLmRlcGxveS52MUIZUm9sbG91dFVwZGF0ZVBheWxvYWRQcm90b1ABWjJjbG91ZC5n
b29nbGUuY29tL2dvL2RlcGxveS9hcGl2MS9kZXBsb3lwYjtkZXBsb3lwYkq2FwoGEgQOAGIB
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
bmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMS
ADAKCAoBCBIDFABJCgkKAggLEgMUAEkKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgA6
CgkKAggIEgMWADoKCAoBCBIDFwAzCgkKAggBEgMXADMKiAEKAgQAEgQbAGIBGnwgUGF5bG9h
ZCBwcm90byBmb3IgImNsb3VkZGVwbG95Lmdvb2dsZWFwaXMuY29tL3JvbGxvdXRfdXBkYXRl
IgogUGxhdGZvcm0gTG9nIGV2ZW50IHRoYXQgZGVzY3JpYmVzIHRoZSByb2xsb3V0IHVwZGF0
ZSBldmVudC4KCgoKAwQAARIDGwgaCksKBAQABAASBB0CRwMaPSBSb2xsb3V0VXBkYXRlVHlw
ZSBpbmRpY2F0ZXMgdGhlIHR5cGUgb2YgdGhlIHJvbGxvdXQgdXBkYXRlLgoKDAoFBAAEAAES
Ax0HGAoxCgYEAAQAAgASAx8EKBoiIFJvbGxvdXQgdXBkYXRlIHR5cGUgdW5zcGVjaWZpZWQu
CgoOCgcEAAQAAgABEgMfBCMKDgoHBAAEAAIAAhIDHyYnCjIKBgQABAACARIDIgQQGiMgcm9s
bG91dCBzdGF0ZSB1cGRhdGVkIHRvIHBlbmRpbmcuCgoOCgcEAAQAAgEBEgMiBAsKDgoHBAAE
AAIBAhIDIg4PCjoKBgQABAACAhIDJQQYGisgUm9sbG91dCBzdGF0ZSB1cGRhdGVkIHRvIHBl
bmRpbmcgcmVsZWFzZS4KCg4KBwQABAACAgESAyUEEwoOCgcEAAQAAgICEgMlFhcKNgoGBAAE
AAIDEgMoBBQaJyBSb2xsb3V0IHN0YXRlIHVwZGF0ZWQgdG8gaW4gcHJvZ3Jlc3MuCgoOCgcE
AAQAAgMBEgMoBA8KDgoHBAAEAAIDAhIDKBITCjUKBgQABAACBBIDKwQTGiYgUm9sbG91dCBz
dGF0ZSB1cGRhdGVkIHRvIGNhbmNlbGxpbmcuCgoOCgcEAAQAAgQBEgMrBA4KDgoHBAAEAAIE
AhIDKxESCjQKBgQABAACBRIDLgQSGiUgUm9sbG91dCBzdGF0ZSB1cGRhdGVkIHRvIGNhbmNl
bGxlZC4KCg4KBwQABAACBQESAy4EDQoOCgcEAAQAAgUCEgMuEBEKMQoGBAAEAAIGEgMxBA8a
IiBSb2xsb3V0IHN0YXRlIHVwZGF0ZWQgdG8gaGFsdGVkLgoKDgoHBAAEAAIGARIDMQQKCg4K
BwQABAACBgISAzENDgo0CgYEAAQAAgcSAzQEEholIFJvbGxvdXQgc3RhdGUgdXBkYXRlZCB0
byBzdWNjZWVkZWQuCgoOCgcEAAQAAgcBEgM0BA0KDgoHBAAEAAIHAhIDNBARCjEKBgQABAAC
CBIDNwQPGiIgUm9sbG91dCBzdGF0ZSB1cGRhdGVkIHRvIGZhaWxlZC4KCg4KBwQABAACCAES
AzcECgoOCgcEAAQAAggCEgM3DQ4KKwoGBAAEAAIJEgM6BBoaHCBSb2xsb3V0IHJlcXVpcmVz
IGFwcHJvdmFsLgoKDgoHBAAEAAIJARIDOgQVCg4KBwQABAACCQISAzoYGQorCgYEAAQAAgoS
Az0EEhocIFJvbGxvdXQgaGFzIGJlZW4gYXBwcm92ZWQuCgoOCgcEAAQAAgoBEgM9BAwKDgoH
BAAEAAIKAhIDPQ8RCisKBgQABAACCxIDQAQSGhwgUm9sbG91dCBoYXMgYmVlbiByZWplY3Rl
ZC4KCg4KBwQABAACCwESA0AEDAoOCgcEAAQAAgsCEgNADxEKPAoGBAAEAAIMEgNDBBoaLSBS
b2xsb3V0IHJlcXVpcmVzIGFkdmFuY2UgdG8gdGhlIG5leHQgcGhhc2UuCgoOCgcEAAQAAgwB
EgNDBBQKDgoHBAAEAAIMAhIDQxcZCisKBgQABAACDRIDRgQSGhwgUm9sbG91dCBoYXMgYmVl
biBhZHZhbmNlZC4KCg4KBwQABAACDQESA0YEDAoOCgcEAAQAAg0CEgNGDxEKRAoEBAACABID
SgIVGjcgRGVidWcgbWVzc2FnZSBmb3Igd2hlbiBhIHJvbGxvdXQgdXBkYXRlIGV2ZW50IG9j
Y3Vycy4KCgwKBQQAAgAFEgNKAggKDAoFBAACAAESA0oJEAoMCgUEAAIAAxIDShMUCjEKBAQA
AgESA00CGhokIFVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBwaXBlbGluZS4KCgwKBQQAAgEF
EgNNAggKDAoFBAACAQESA00JFQoMCgUEAAIBAxIDTRgZCjAKBAQAAgISA1ACGRojIFVuaXF1
ZSBpZGVudGlmaWVyIG9mIHRoZSByZWxlYXNlLgoKDAoFBAACAgUSA1ACCAoMCgUEAAICARID
UAkUCgwKBQQAAgIDEgNQFxgKKQoEBAACAxIDUwIVGhwgVGhlIG5hbWUgb2YgdGhlIGBSZWxl
YXNlYC4KCgwKBQQAAgMFEgNTAggKDAoFBAACAwESA1MJEAoMCgUEAAIDAxIDUxMUCrcBCgQE
AAIEEgNYAhUaqQEgVGhlIG5hbWUgb2YgdGhlIHJvbGxvdXQuCiByb2xsb3V0X3VpZCBpcyBu
b3QgaW4gdGhpcyBsb2cgbWVzc2FnZSBiZWNhdXNlIHdlIHdyaXRlIHNvbWUgb2YgdGhlc2Ug
bG9nCiBtZXNzYWdlcyBhdCByb2xsb3V0IGNyZWF0aW9uIHRpbWUsIGJlZm9yZSB3ZSd2ZSBn
ZW5lcmF0ZWQgdGhlIHVpZC4KCgwKBQQAAgQFEgNYAggKDAoFBAACBAESA1gJEAoMCgUEAAIE
AxIDWBMUCiAKBAQAAgUSA1sCFxoTIElEIG9mIHRoZSB0YXJnZXQuCgoMCgUEAAIFBRIDWwII
CgwKBQQAAgUBEgNbCRIKDAoFBAACBQMSA1sVFgpKCgQEAAIGEgNeAhAaPSBUeXBlIG9mIHRo
aXMgbm90aWZpY2F0aW9uLCBlLmcuIGZvciBhIHJvbGxvdXQgdXBkYXRlIGV2ZW50LgoKDAoF
BAACBgYSA14CBgoMCgUEAAIGARIDXgcLCgwKBQQAAgYDEgNeDg8KLgoEBAACBxIDYQIsGiEg
VGhlIHR5cGUgb2YgdGhlIHJvbGxvdXQgdXBkYXRlLgoKDAoFBAACBwYSA2ECEwoMCgUEAAIH
ARIDYRQnCgwKBQQAAgcDEgNhKitiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::RolloutUpdatePayload::RolloutUpdateEvent ===
    # Fields for RolloutUpdateEvent
    # Field: message Type: 9 ()
    # Field: pipeline_uid Type: 9 ()
    # Field: release_uid Type: 9 ()
    # Field: release Type: 9 ()
    # Field: rollout Type: 9 ()
    # Field: target_id Type: 9 ()
    # Field: type Type: 14 (.google.cloud.deploy.v1.Type)
    # Field: rollout_update_type Type: 14 (.google.cloud.deploy.v1.RolloutUpdateEvent.RolloutUpdateType)

# Enum: RolloutUpdateEvent::RolloutUpdateType
our $RolloutUpdateEvent_ROLLOUT_UPDATE_TYPE_UNSPECIFIED = 0;
our $RolloutUpdateEvent_PENDING = 1;
our $RolloutUpdateEvent_PENDING_RELEASE = 2;
our $RolloutUpdateEvent_IN_PROGRESS = 3;
our $RolloutUpdateEvent_CANCELLING = 4;
our $RolloutUpdateEvent_CANCELLED = 5;
our $RolloutUpdateEvent_HALTED = 6;
our $RolloutUpdateEvent_SUCCEEDED = 7;
our $RolloutUpdateEvent_FAILED = 8;
our $RolloutUpdateEvent_APPROVAL_REQUIRED = 9;
our $RolloutUpdateEvent_APPROVED = 10;
our $RolloutUpdateEvent_REJECTED = 11;
our $RolloutUpdateEvent_ADVANCE_REQUIRED = 12;
our $RolloutUpdateEvent_ADVANCED = 13;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::RolloutUpdatePayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/rollout_update_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::RolloutUpdatePayload;

    my $msg = Google::Cloud::Deploy::V1::RolloutUpdatePayload::RolloutUpdateEvent->new({
        message => $message,
        pipeline_uid => $pipeline_uid,
        release_uid => $release_uid,
        release => $release,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::RolloutUpdatePayload::RolloutUpdateEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/rollout_update_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::RolloutUpdatePayload::RolloutUpdateEvent

Payload proto for "clouddeploy.googleapis.com/rollout_update"
Platform Log event that describes the rollout update event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when a rollout update event occurs.

=item * C<< $msg->pipeline_uid() >> / C<< $msg->pipeline_uid($value) >>

Type: C<String>

Unique identifier of the pipeline.

=item * C<< $msg->release_uid() >> / C<< $msg->release_uid($value) >>

Type: C<String>

Unique identifier of the release.

=item * C<< $msg->release() >> / C<< $msg->release($value) >>

Type: C<String>

The name of the `Release`.

=item * C<< $msg->rollout() >> / C<< $msg->rollout($value) >>

Type: C<String>

The name of the rollout.
rollout_uid is not in this log message because we write some of these log
messages at rollout creation time, before we've generated the uid.

=item * C<< $msg->target_id() >> / C<< $msg->target_id($value) >>

Type: C<String>

ID of the target.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a rollout update event.

=item * C<< $msg->rollout_update_type() >> / C<< $msg->rollout_update_type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::RolloutUpdateEvent::RolloutUpdateType>)

The type of the rollout update.

=back

=head3 Enum: RolloutUpdateEvent::RolloutUpdateType

=over 4

=item * C<ROLLOUT_UPDATE_TYPE_UNSPECIFIED> => C<0>

=item * C<PENDING> => C<1>

=item * C<PENDING_RELEASE> => C<2>

=item * C<IN_PROGRESS> => C<3>

=item * C<CANCELLING> => C<4>

=item * C<CANCELLED> => C<5>

=item * C<HALTED> => C<6>

=item * C<SUCCEEDED> => C<7>

=item * C<FAILED> => C<8>

=item * C<APPROVAL_REQUIRED> => C<9>

=item * C<APPROVED> => C<10>

=item * C<REJECTED> => C<11>

=item * C<ADVANCE_REQUIRED> => C<12>

=item * C<ADVANCED> => C<13>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::RolloutUpdatePayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
