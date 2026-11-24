package Google::Cloud::Support::V2beta::SupportEventSubscription;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Api::Resource };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvc3VwcG9ydC92MmJldGEvc3VwcG9ydF9ldmVudF9zdWJzY3JpcHRp
b24ucHJvdG8SG2dvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YRofZ29vZ2xlL2FwaS9maWVs
ZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90bxofZ29vZ2xlL3By
b3RvYnVmL3RpbWVzdGFtcC5wcm90byKhBwoYU3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uEhcK
BG5hbWUYASABKAlCA+BBCFIEbmFtZRInCg1wdWJfc3ViX3RvcGljGAIgASgJQgPgQQJSC3B1
YlN1YlRvcGljElYKBXN0YXRlGAMgASgOMjsuZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjJiZXRh
LlN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbi5TdGF0ZUID4EEDUgVzdGF0ZRJvCg5mYWlsdXJl
X3JlYXNvbhgEIAEoDjJDLmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyYmV0YS5TdXBwb3J0RXZl
bnRTdWJzY3JpcHRpb24uRmFpbHVyZVJlYXNvbkID4EEDUg1mYWlsdXJlUmVhc29uEkAKC2Ny
ZWF0ZV90aW1lGAUgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgpjcmVh
dGVUaW1lEkAKC3VwZGF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFt
cEID4EEDUgp1cGRhdGVUaW1lEkAKC2RlbGV0ZV90aW1lGAcgASgLMhouZ29vZ2xlLnByb3Rv
YnVmLlRpbWVzdGFtcEID4EEDUgpkZWxldGVUaW1lEj4KCnB1cmdlX3RpbWUYCCABKAsyGi5n
b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCXB1cmdlVGltZSJFCgVTdGF0ZRIVChFT
VEFURV9VTlNQRUNJRklFRBAAEgsKB1dPUktJTkcQARILCgdGQUlMSU5HEAISCwoHREVMRVRF
RBADImYKDUZhaWx1cmVSZWFzb24SHgoaRkFJTFVSRV9SRUFTT05fVU5TUEVDSUZJRUQQABIV
ChFQRVJNSVNTSU9OX0RFTklFRBABEhMKD1RPUElDX05PVF9GT1VORBACEgkKBU9USEVSEAM6
xAHqQcABCjRjbG91ZHN1cHBvcnQuZ29vZ2xlYXBpcy5jb20vU3VwcG9ydEV2ZW50U3Vic2Ny
aXB0aW9uElNvcmdhbml6YXRpb25zL3tvcmdhbml6YXRpb259L3N1cHBvcnRFdmVudFN1YnNj
cmlwdGlvbnMve3N1cHBvcnRfZXZlbnRfc3Vic2NyaXB0aW9ufSoZc3VwcG9ydEV2ZW50U3Vi
c2NyaXB0aW9uczIYc3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uQtoBCh9jb20uZ29vZ2xlLmNs
b3VkLnN1cHBvcnQudjJiZXRhQh1TdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25Qcm90b1ABWjlj
bG91ZC5nb29nbGUuY29tL2dvL3N1cHBvcnQvYXBpdjJiZXRhL3N1cHBvcnRwYjtzdXBwb3J0
cGKqAhtHb29nbGUuQ2xvdWQuU3VwcG9ydC5WMkJldGHKAhtHb29nbGVcQ2xvdWRcU3VwcG9y
dFxWMmJldGHqAh5Hb29nbGU6OkNsb3VkOjpTdXBwb3J0OjpWMmJldGFK1R4KBhIEDgB0AQq8
BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRl
ciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlv
dSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUg
TGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAg
ICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3Mg
cmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNv
ZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBv
biBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMg
T0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vu
c2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5k
CiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAJAoJCgIDABIDEgAp
CgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWADgKCQoCCCUSAxYAOAoICgEIEgMXAFAK
CQoCCAsSAxcAUAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEIEgMZAD4KCQoCCAgSAxkAPgoI
CgEIEgMaADgKCQoCCAESAxoAOAoICgEIEgMbADgKCQoCCCkSAxsAOAoICgEIEgMcADcKCQoC
CC0SAxwANwqiBQoCBAASBCwAdAEalQUgQSBzdXBwb3J0IGV2ZW50IHN1YnNjcmlwdGlvbi4K
CiBZb3UgY2FuIGFsc28gbWFuYWdlIHN1cHBvcnQgZXZlbnQgc3Vic2NyaXB0aW9ucyB1c2lu
ZyBvdGhlciB0b29sczoKCiAqIFtgZ2Nsb3VkIHN1cHBvcnQKIHN1cHBvcnQtZXZlbnQtc3Vi
c2NyaXB0aW9uc2BdKC9zZGsvZ2Nsb3VkL3JlZmVyZW5jZS9zdXBwb3J0L3N1cHBvcnQtZXZl
bnQtc3Vic2NyaXB0aW9ucykKIChvciBbYGdjbG91ZAogYmV0YWBdKC9zZGsvZ2Nsb3VkL3Jl
ZmVyZW5jZS9iZXRhL3N1cHBvcnQvc3VwcG9ydC1ldmVudC1zdWJzY3JpcHRpb25zKQogZm9y
IGJldGEpCiAqIFtUZXJyYWZvcm0KIGBnb29nbGVfY2xvdWRfc3VwcG9ydF9zdXBwb3J0X2V2
ZW50X3N1YnNjcmlwdGlvbmBdKGh0dHBzOi8vcmVnaXN0cnkudGVycmFmb3JtLmlvL3Byb3Zp
ZGVycy9oYXNoaWNvcnAvZ29vZ2xlL2xhdGVzdC9kb2NzL3Jlc291cmNlcy9jbG91ZF9zdXBw
b3J0X3N1cHBvcnRfZXZlbnRfc3Vic2NyaXB0aW9uKQogKG9yIFtnb29nbGUtYmV0YQogcHJv
dmlkZXJdKGh0dHBzOi8vcmVnaXN0cnkudGVycmFmb3JtLmlvL3Byb3ZpZGVycy9oYXNoaWNv
cnAvZ29vZ2xlLWJldGEvbGF0ZXN0L2RvY3MvcmVzb3VyY2VzL2Nsb3VkX3N1cHBvcnRfc3Vw
cG9ydF9ldmVudF9zdWJzY3JpcHRpb24pCiBmb3IgYmV0YSkKCgoKAwQAARIDLAggCgsKAwQA
BxIELQIyBAoNCgUEAAedCBIELQIyBAouCgQEAAQAEgQ1AkQDGiAgVGhlIHN0YXRlIG9mIHRo
ZSBzdWJzY3JpcHRpb24uCgoMCgUEAAQAARIDNQcMCiMKBgQABAACABIDNwQaGhQgVW5zcGVj
aWZpZWQgc3RhdGUuCgoOCgcEAAQAAgABEgM3BBUKDgoHBAAEAAIAAhIDNxgZCjQKBgQABAAC
ARIDOgQQGiUgU3Vic2NyaXB0aW9uIGlzIGFjdGl2ZSBhbmQgd29ya2luZy4KCg4KBwQABAAC
AQESAzoECwoOCgcEAAQAAgECEgM6Dg8KXQoGBAAEAAICEgM+BBAaTiBTdWJzY3JpcHRpb24g
aXMgZmFpbGluZy4gTm90aWZpY2F0aW9ucyBjYW5ub3QgYmUgcHVibGlzaGVkIGZvciBzb21l
CiByZWFzb24uCgoOCgcEAAQAAgIBEgM+BAsKDgoHBAAEAAICAhIDPg4PCsMBCgYEAAQAAgMS
A0MEEBqzASBTdWJzY3JpcHRpb24gaGFzIGJlZW4gZGVsZXRlZCBhbmQgaXMgcGVuZGluZyBw
dXJnZS4gTm90aWZpY2F0aW9ucyBhcmUgbm90CiBzZW50IGZvciBkZWxldGVkIHN1YnNjcmlw
dGlvbnMuIERlbGV0ZWQgc3Vic2NyaXB0aW9ucyBhcmUgcHVyZ2VkIGFmdGVyCiB0aGVpciBg
cHVyZ2VfdGltZWAgaGFzIHBhc3NlZC4KCg4KBwQABAACAwESA0MECwoOCgcEAAQAAgMCEgND
Dg8KOwoEBAAEARIERwJVAxotIFRoZSByZWFzb24gd2h5IHRoZSBzdWJzY3JpcHRpb24gaXMg
ZmFpbGluZy4KCgwKBQQABAEBEgNHBxQKLAoGBAAEAQIAEgNJBCMaHSBVbnNwZWNpZmllZCBm
YWlsdXJlIHJlYXNvbi4KCg4KBwQABAECAAESA0kEHgoOCgcEAAQBAgACEgNJISIKogEKBgQA
BAECARIDTgQaGpIBIFRoZSBzZXJ2aWNlIGFjY291bnQgKGkuZS4KIGNsb3VkLXN1cHBvcnQt
YXBpZXZlbnRzQHN5c3RlbS5nc2VydmljZWFjY291bnQuY29tKSBsYWNrcyB0aGUgcGVybWlz
c2lvbgogdG8gcHVibGlzaCB0byB0aGUgY3VzdG9tZXIncyBQdWIvU3ViIHRvcGljLgoKDgoH
BAAEAQIBARIDTgQVCg4KBwQABAECAQISA04YGQo8CgYEAAQBAgISA1EEGBotIFRoZSBzcGVj
aWZpZWQgUHViL1N1YiB0b3BpYyBkb2VzIG5vdCBleGlzdC4KCg4KBwQABAECAgESA1EEEwoO
CgcEAAQBAgICEgNRFhcKRgoGBAAEAQIDEgNUBA4aNyBNZXNzYWdlIGZhaWxlZCB0byBwdWJs
aXNoIGR1ZSB0byBhIHN5c3RlbS1zaWRlIGVycm9yLgoKDgoHBAAEAQIDARIDVAQJCg4KBwQA
BAECAwISA1QMDQpPCgQEAAIAEgNYAj0aQiBJZGVudGlmaWVyLiBUaGUgcmVzb3VyY2UgbmFt
ZSBvZiB0aGUgc3VwcG9ydCBldmVudCBzdWJzY3JpcHRpb24uCgoMCgUEAAIABRIDWAIICgwK
BQQAAgABEgNYCQ0KDAoFBAACAAMSA1gQEQoMCgUEAAIACBIDWBI8Cg8KCAQAAgAInAgAEgNY
EzsKfgoEBAACARIDXAJEGnEgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBQdWIvU3ViIHRv
cGljIHRvIHB1Ymxpc2ggbm90aWZpY2F0aW9ucyB0by4KIEZvcm1hdDogcHJvamVjdHMve3By
b2plY3R9L3RvcGljcy97dG9waWN9CgoMCgUEAAIBBRIDXAIICgwKBQQAAgEBEgNcCRYKDAoF
BAACAQMSA1wZGgoMCgUEAAIBCBIDXBtDCg8KCAQAAgEInAgAEgNcHEIKOgoEBAACAhIDXwI+
Gi0gT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGUgc3Vic2NyaXB0aW9uLgoKDAoFBAAC
AgYSA18CBwoMCgUEAAICARIDXwgNCgwKBQQAAgIDEgNfEBEKDAoFBAACAggSA18SPQoPCggE
AAICCJwIABIDXxM8CokBCgQEAAIDEgNjAk8afCBPdXRwdXQgb25seS4gUmVhc29uIHdoeSBz
dWJzY3JpcHRpb24gaXMgZmFpbGluZy4gU3RhdGUgb2Ygc3Vic2NyaXB0aW9uCiBtdXN0IGJl
IEZBSUxJTkcgaW4gb3JkZXIgZm9yIHRoaXMgdG8gaGF2ZSBhIHZhbHVlLgoKDAoFBAACAwYS
A2MCDwoMCgUEAAIDARIDYxAeCgwKBQQAAgMDEgNjISIKDAoFBAACAwgSA2MjTgoPCggEAAID
CJwIABIDYyRNCkwKBAQAAgQSBGYCZzIaPiBPdXRwdXQgb25seS4gVGhlIHRpbWUgYXQgd2hp
Y2ggdGhlIHN1YnNjcmlwdGlvbiB3YXMgY3JlYXRlZC4KCgwKBQQAAgQGEgNmAhsKDAoFBAAC
BAESA2YcJwoMCgUEAAIEAxIDZiorCgwKBQQAAgQIEgNnBjEKDwoIBAACBAicCAASA2cHMApR
CgQEAAIFEgRqAmsyGkMgT3V0cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoZSBzdWJz
Y3JpcHRpb24gd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgUGEgNqAhsKDAoFBAACBQESA2oc
JwoMCgUEAAIFAxIDaiorCgwKBQQAAgUIEgNrBjEKDwoIBAACBQicCAASA2sHMApMCgQEAAIG
EgRuAm8yGj4gT3V0cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdoaWNoIHRoZSBzdWJzY3JpcHRp
b24gd2FzIGRlbGV0ZWQuCgoMCgUEAAIGBhIDbgIbCgwKBQQAAgYBEgNuHCcKDAoFBAACBgMS
A24qKwoMCgUEAAIGCBIDbwYxCg8KCAQAAgYInAgAEgNvBzAKTwoEBAACBxIEcgJzMhpBIE91
dHB1dCBvbmx5LiBUaGUgdGltZSBhdCB3aGljaCB0aGUgc3Vic2NyaXB0aW9uIHdpbGwgYmUg
cHVyZ2VkLgoKDAoFBAACBwYSA3ICGwoMCgUEAAIHARIDchwmCgwKBQQAAgcDEgNyKSoKDAoF
BAACBwgSA3MGMQoPCggEAAIHCJwIABIDcwcwYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription ===
    # Fields for SupportEventSubscription
    # Field: name Type: 9 ()
    # Field: pub_sub_topic Type: 9 ()
    # Field: state Type: 14 (.google.cloud.support.v2beta.SupportEventSubscription.State)
    # Field: failure_reason Type: 14 (.google.cloud.support.v2beta.SupportEventSubscription.FailureReason)
    # Field: create_time Type: 11 (.google.protobuf.Timestamp)
    # Field: update_time Type: 11 (.google.protobuf.Timestamp)
    # Field: delete_time Type: 11 (.google.protobuf.Timestamp)
    # Field: purge_time Type: 11 (.google.protobuf.Timestamp)

# Enum: SupportEventSubscription::State
our $SupportEventSubscription_STATE_UNSPECIFIED = 0;
our $SupportEventSubscription_WORKING = 1;
our $SupportEventSubscription_FAILING = 2;
our $SupportEventSubscription_DELETED = 3;

# Enum: SupportEventSubscription::FailureReason
our $SupportEventSubscription_FAILURE_REASON_UNSPECIFIED = 0;
our $SupportEventSubscription_PERMISSION_DENIED = 1;
our $SupportEventSubscription_TOPIC_NOT_FOUND = 2;
our $SupportEventSubscription_OTHER = 3;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Support::V2beta::SupportEventSubscription - Compiled Protocol Buffers messages for google/cloud/support/v2beta/support_event_subscription.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2beta::SupportEventSubscription;

    my $msg = Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription->new({
        name => $name,
        pub_sub_topic => $pub_sub_topic,
        state => $state,
        failure_reason => $failure_reason,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2beta/support_event_subscription.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2beta::SupportEventSubscription::SupportEventSubscription

A support event subscription.

You can also manage support event subscriptions using other tools:

* [`gcloud support
support-event-subscriptions`](/sdk/gcloud/reference/support/support-event-subscriptions)
(or [`gcloud
beta`](/sdk/gcloud/reference/beta/support/support-event-subscriptions)
for beta)
* [Terraform
`google_cloud_support_support_event_subscription`](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_support_support_event_subscription)
(or [google-beta
provider](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/cloud_support_support_event_subscription)
for beta)

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Identifier. The resource name of the support event subscription.

=item * C<< $msg->pub_sub_topic() >> / C<< $msg->pub_sub_topic($value) >>

Type: C<String>

Required. The name of the Pub/Sub topic to publish notifications to.
Format: projects/{project}/topics/{topic}

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2beta::SupportEventSubscription::State>)

Output only. The state of the subscription.

=item * C<< $msg->failure_reason() >> / C<< $msg->failure_reason($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2beta::SupportEventSubscription::FailureReason>)

Output only. Reason why subscription is failing. State of subscription
must be FAILING in order for this to have a value.

=item * C<< $msg->create_time() >> / C<< $msg->create_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the subscription was created.

=item * C<< $msg->update_time() >> / C<< $msg->update_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the subscription was last updated.

=item * C<< $msg->delete_time() >> / C<< $msg->delete_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the subscription was deleted.

=item * C<< $msg->purge_time() >> / C<< $msg->purge_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Output only. The time at which the subscription will be purged.

=back

=head3 Enum: SupportEventSubscription::State

=over 4

=item * C<STATE_UNSPECIFIED> => C<0>

=item * C<WORKING> => C<1>

=item * C<FAILING> => C<2>

=item * C<DELETED> => C<3>

=back

=head3 Enum: SupportEventSubscription::FailureReason

=over 4

=item * C<FAILURE_REASON_UNSPECIFIED> => C<0>

=item * C<PERMISSION_DENIED> => C<1>

=item * C<TOPIC_NOT_FOUND> => C<2>

=item * C<OTHER> => C<3>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2beta::SupportEventSubscription::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
