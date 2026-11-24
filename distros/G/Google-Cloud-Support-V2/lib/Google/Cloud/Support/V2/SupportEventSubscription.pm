package Google::Cloud::Support::V2::SupportEventSubscription;

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
Cjhnb29nbGUvY2xvdWQvc3VwcG9ydC92Mi9zdXBwb3J0X2V2ZW50X3N1YnNjcmlwdGlvbi5w
cm90bxIXZ29vZ2xlLmNsb3VkLnN1cHBvcnQudjIaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZp
b3IucHJvdG8aGWdvb2dsZS9hcGkvcmVzb3VyY2UucHJvdG8aH2dvb2dsZS9wcm90b2J1Zi90
aW1lc3RhbXAucHJvdG8imQcKGFN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbhIXCgRuYW1lGAEg
ASgJQgPgQQhSBG5hbWUSJwoNcHViX3N1Yl90b3BpYxgCIAEoCUID4EECUgtwdWJTdWJUb3Bp
YxJSCgVzdGF0ZRgDIAEoDjI3Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLlN1cHBvcnRFdmVu
dFN1YnNjcmlwdGlvbi5TdGF0ZUID4EEDUgVzdGF0ZRJrCg5mYWlsdXJlX3JlYXNvbhgEIAEo
DjI/Lmdvb2dsZS5jbG91ZC5zdXBwb3J0LnYyLlN1cHBvcnRFdmVudFN1YnNjcmlwdGlvbi5G
YWlsdXJlUmVhc29uQgPgQQNSDWZhaWx1cmVSZWFzb24SQAoLY3JlYXRlX3RpbWUYBSABKAsy
Gi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCmNyZWF0ZVRpbWUSQAoLdXBkYXRl
X3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPgQQNSCnVwZGF0ZVRp
bWUSQAoLZGVsZXRlX3RpbWUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgPg
QQNSCmRlbGV0ZVRpbWUSPgoKcHVyZ2VfdGltZRgIIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5U
aW1lc3RhbXBCA+BBA1IJcHVyZ2VUaW1lIkUKBVN0YXRlEhUKEVNUQVRFX1VOU1BFQ0lGSUVE
EAASCwoHV09SS0lORxABEgsKB0ZBSUxJTkcQAhILCgdERUxFVEVEEAMiZgoNRmFpbHVyZVJl
YXNvbhIeChpGQUlMVVJFX1JFQVNPTl9VTlNQRUNJRklFRBAAEhUKEVBFUk1JU1NJT05fREVO
SUVEEAESEwoPVE9QSUNfTk9UX0ZPVU5EEAISCQoFT1RIRVIQAzrEAepBwAEKNGNsb3Vkc3Vw
cG9ydC5nb29nbGVhcGlzLmNvbS9TdXBwb3J0RXZlbnRTdWJzY3JpcHRpb24SU29yZ2FuaXph
dGlvbnMve29yZ2FuaXphdGlvbn0vc3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9ucy97c3VwcG9y
dF9ldmVudF9zdWJzY3JpcHRpb259KhlzdXBwb3J0RXZlbnRTdWJzY3JpcHRpb25zMhhzdXBw
b3J0RXZlbnRTdWJzY3JpcHRpb25CxgEKG2NvbS5nb29nbGUuY2xvdWQuc3VwcG9ydC52MkId
U3VwcG9ydEV2ZW50U3Vic2NyaXB0aW9uUHJvdG9QAVo1Y2xvdWQuZ29vZ2xlLmNvbS9nby9z
dXBwb3J0L2FwaXYyL3N1cHBvcnRwYjtzdXBwb3J0cGKqAhdHb29nbGUuQ2xvdWQuU3VwcG9y
dC5WMsoCF0dvb2dsZVxDbG91ZFxTdXBwb3J0XFYy6gIaR29vZ2xlOjpDbG91ZDo6U3VwcG9y
dDo6VjJK1R4KBhIEDgB0AQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI2IEdvb2dsZSBM
TEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0
aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNv
bXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0
aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElD
RU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVk
IHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5z
ZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5U
SUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxp
ZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5p
bmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggK
AQISAxAAIAoJCgIDABIDEgApCgkKAgMBEgMTACMKCQoCAwISAxQAKQoICgEIEgMWADQKCQoC
CCUSAxYANAoICgEIEgMXAEwKCQoCCAsSAxcATAoICgEIEgMYACIKCQoCCAoSAxgAIgoICgEI
EgMZAD4KCQoCCAgSAxkAPgoICgEIEgMaADQKCQoCCAESAxoANAoICgEIEgMbADQKCQoCCCkS
AxsANAoICgEIEgMcADMKCQoCCC0SAxwAMwqiBQoCBAASBCwAdAEalQUgQSBzdXBwb3J0IGV2
ZW50IHN1YnNjcmlwdGlvbi4KCiBZb3UgY2FuIGFsc28gbWFuYWdlIHN1cHBvcnQgZXZlbnQg
c3Vic2NyaXB0aW9ucyB1c2luZyBvdGhlciB0b29sczoKCiAqIFtgZ2Nsb3VkIHN1cHBvcnQK
IHN1cHBvcnQtZXZlbnQtc3Vic2NyaXB0aW9uc2BdKC9zZGsvZ2Nsb3VkL3JlZmVyZW5jZS9z
dXBwb3J0L3N1cHBvcnQtZXZlbnQtc3Vic2NyaXB0aW9ucykKIChvciBbYGdjbG91ZAogYmV0
YWBdKC9zZGsvZ2Nsb3VkL3JlZmVyZW5jZS9iZXRhL3N1cHBvcnQvc3VwcG9ydC1ldmVudC1z
dWJzY3JpcHRpb25zKQogZm9yIGJldGEpCiAqIFtUZXJyYWZvcm0KIGBnb29nbGVfY2xvdWRf
c3VwcG9ydF9zdXBwb3J0X2V2ZW50X3N1YnNjcmlwdGlvbmBdKGh0dHBzOi8vcmVnaXN0cnku
dGVycmFmb3JtLmlvL3Byb3ZpZGVycy9oYXNoaWNvcnAvZ29vZ2xlL2xhdGVzdC9kb2NzL3Jl
c291cmNlcy9jbG91ZF9zdXBwb3J0X3N1cHBvcnRfZXZlbnRfc3Vic2NyaXB0aW9uKQogKG9y
IFtnb29nbGUtYmV0YQogcHJvdmlkZXJdKGh0dHBzOi8vcmVnaXN0cnkudGVycmFmb3JtLmlv
L3Byb3ZpZGVycy9oYXNoaWNvcnAvZ29vZ2xlLWJldGEvbGF0ZXN0L2RvY3MvcmVzb3VyY2Vz
L2Nsb3VkX3N1cHBvcnRfc3VwcG9ydF9ldmVudF9zdWJzY3JpcHRpb24pCiBmb3IgYmV0YSkK
CgoKAwQAARIDLAggCgsKAwQABxIELQIyBAoNCgUEAAedCBIELQIyBAouCgQEAAQAEgQ1AkQD
GiAgVGhlIHN0YXRlIG9mIHRoZSBzdWJzY3JpcHRpb24uCgoMCgUEAAQAARIDNQcMCiMKBgQA
BAACABIDNwQaGhQgVW5zcGVjaWZpZWQgc3RhdGUuCgoOCgcEAAQAAgABEgM3BBUKDgoHBAAE
AAIAAhIDNxgZCjQKBgQABAACARIDOgQQGiUgU3Vic2NyaXB0aW9uIGlzIGFjdGl2ZSBhbmQg
d29ya2luZy4KCg4KBwQABAACAQESAzoECwoOCgcEAAQAAgECEgM6Dg8KXQoGBAAEAAICEgM+
BBAaTiBTdWJzY3JpcHRpb24gaXMgZmFpbGluZy4gTm90aWZpY2F0aW9ucyBjYW5ub3QgYmUg
cHVibGlzaGVkIGZvciBzb21lCiByZWFzb24uCgoOCgcEAAQAAgIBEgM+BAsKDgoHBAAEAAIC
AhIDPg4PCsMBCgYEAAQAAgMSA0MEEBqzASBTdWJzY3JpcHRpb24gaGFzIGJlZW4gZGVsZXRl
ZCBhbmQgaXMgcGVuZGluZyBwdXJnZS4gTm90aWZpY2F0aW9ucyBhcmUgbm90CiBzZW50IGZv
ciBkZWxldGVkIHN1YnNjcmlwdGlvbnMuIERlbGV0ZWQgc3Vic2NyaXB0aW9ucyBhcmUgcHVy
Z2VkIGFmdGVyCiB0aGVpciBgcHVyZ2VfdGltZWAgaGFzIHBhc3NlZC4KCg4KBwQABAACAwES
A0MECwoOCgcEAAQAAgMCEgNDDg8KOwoEBAAEARIERwJVAxotIFRoZSByZWFzb24gd2h5IHRo
ZSBzdWJzY3JpcHRpb24gaXMgZmFpbGluZy4KCgwKBQQABAEBEgNHBxQKLAoGBAAEAQIAEgNJ
BCMaHSBVbnNwZWNpZmllZCBmYWlsdXJlIHJlYXNvbi4KCg4KBwQABAECAAESA0kEHgoOCgcE
AAQBAgACEgNJISIKogEKBgQABAECARIDTgQaGpIBIFRoZSBzZXJ2aWNlIGFjY291bnQgKGku
ZS4KIGNsb3VkLXN1cHBvcnQtYXBpZXZlbnRzQHN5c3RlbS5nc2VydmljZWFjY291bnQuY29t
KSBsYWNrcyB0aGUgcGVybWlzc2lvbgogdG8gcHVibGlzaCB0byB0aGUgY3VzdG9tZXIncyBQ
dWIvU3ViIHRvcGljLgoKDgoHBAAEAQIBARIDTgQVCg4KBwQABAECAQISA04YGQo8CgYEAAQB
AgISA1EEGBotIFRoZSBzcGVjaWZpZWQgUHViL1N1YiB0b3BpYyBkb2VzIG5vdCBleGlzdC4K
Cg4KBwQABAECAgESA1EEEwoOCgcEAAQBAgICEgNRFhcKRgoGBAAEAQIDEgNUBA4aNyBNZXNz
YWdlIGZhaWxlZCB0byBwdWJsaXNoIGR1ZSB0byBhIHN5c3RlbS1zaWRlIGVycm9yLgoKDgoH
BAAEAQIDARIDVAQJCg4KBwQABAECAwISA1QMDQpPCgQEAAIAEgNYAj0aQiBJZGVudGlmaWVy
LiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgc3VwcG9ydCBldmVudCBzdWJzY3JpcHRpb24u
CgoMCgUEAAIABRIDWAIICgwKBQQAAgABEgNYCQ0KDAoFBAACAAMSA1gQEQoMCgUEAAIACBID
WBI8Cg8KCAQAAgAInAgAEgNYEzsKfgoEBAACARIDXAJEGnEgUmVxdWlyZWQuIFRoZSBuYW1l
IG9mIHRoZSBQdWIvU3ViIHRvcGljIHRvIHB1Ymxpc2ggbm90aWZpY2F0aW9ucyB0by4KIEZv
cm1hdDogcHJvamVjdHMve3Byb2plY3R9L3RvcGljcy97dG9waWN9CgoMCgUEAAIBBRIDXAII
CgwKBQQAAgEBEgNcCRYKDAoFBAACAQMSA1wZGgoMCgUEAAIBCBIDXBtDCg8KCAQAAgEInAgA
EgNcHEIKOgoEBAACAhIDXwI+Gi0gT3V0cHV0IG9ubHkuIFRoZSBzdGF0ZSBvZiB0aGUgc3Vi
c2NyaXB0aW9uLgoKDAoFBAACAgYSA18CBwoMCgUEAAICARIDXwgNCgwKBQQAAgIDEgNfEBEK
DAoFBAACAggSA18SPQoPCggEAAICCJwIABIDXxM8CokBCgQEAAIDEgNjAk8afCBPdXRwdXQg
b25seS4gUmVhc29uIHdoeSBzdWJzY3JpcHRpb24gaXMgZmFpbGluZy4gU3RhdGUgb2Ygc3Vi
c2NyaXB0aW9uCiBtdXN0IGJlIEZBSUxJTkcgaW4gb3JkZXIgZm9yIHRoaXMgdG8gaGF2ZSBh
IHZhbHVlLgoKDAoFBAACAwYSA2MCDwoMCgUEAAIDARIDYxAeCgwKBQQAAgMDEgNjISIKDAoF
BAACAwgSA2MjTgoPCggEAAIDCJwIABIDYyRNCkwKBAQAAgQSBGYCZzIaPiBPdXRwdXQgb25s
eS4gVGhlIHRpbWUgYXQgd2hpY2ggdGhlIHN1YnNjcmlwdGlvbiB3YXMgY3JlYXRlZC4KCgwK
BQQAAgQGEgNmAhsKDAoFBAACBAESA2YcJwoMCgUEAAIEAxIDZiorCgwKBQQAAgQIEgNnBjEK
DwoIBAACBAicCAASA2cHMApRCgQEAAIFEgRqAmsyGkMgT3V0cHV0IG9ubHkuIFRoZSB0aW1l
IGF0IHdoaWNoIHRoZSBzdWJzY3JpcHRpb24gd2FzIGxhc3QgdXBkYXRlZC4KCgwKBQQAAgUG
EgNqAhsKDAoFBAACBQESA2ocJwoMCgUEAAIFAxIDaiorCgwKBQQAAgUIEgNrBjEKDwoIBAAC
BQicCAASA2sHMApMCgQEAAIGEgRuAm8yGj4gT3V0cHV0IG9ubHkuIFRoZSB0aW1lIGF0IHdo
aWNoIHRoZSBzdWJzY3JpcHRpb24gd2FzIGRlbGV0ZWQuCgoMCgUEAAIGBhIDbgIbCgwKBQQA
AgYBEgNuHCcKDAoFBAACBgMSA24qKwoMCgUEAAIGCBIDbwYxCg8KCAQAAgYInAgAEgNvBzAK
TwoEBAACBxIEcgJzMhpBIE91dHB1dCBvbmx5LiBUaGUgdGltZSBhdCB3aGljaCB0aGUgc3Vi
c2NyaXB0aW9uIHdpbGwgYmUgcHVyZ2VkLgoKDAoFBAACBwYSA3ICGwoMCgUEAAIHARIDchwm
CgwKBQQAAgcDEgNyKSoKDAoFBAACBwgSA3MGMQoPCggEAAIHCJwIABIDcwcwYgZwcm90bzM=

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription ===
    # Fields for SupportEventSubscription
    # Field: name Type: 9 ()
    # Field: pub_sub_topic Type: 9 ()
    # Field: state Type: 14 (.google.cloud.support.v2.SupportEventSubscription.State)
    # Field: failure_reason Type: 14 (.google.cloud.support.v2.SupportEventSubscription.FailureReason)
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

Google::Cloud::Support::V2::SupportEventSubscription - Compiled Protocol Buffers messages for google/cloud/support/v2/support_event_subscription.proto

=head1 SYNOPSIS

    use Google::Cloud::Support::V2::SupportEventSubscription;

    my $msg = Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription->new({
        name => $name,
        pub_sub_topic => $pub_sub_topic,
        state => $state,
        failure_reason => $failure_reason,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/support/v2/support_event_subscription.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Support::V2::SupportEventSubscription::SupportEventSubscription

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

Type: C<Enum> (L<Google::Cloud::Support::V2::SupportEventSubscription::State>)

Output only. The state of the subscription.

=item * C<< $msg->failure_reason() >> / C<< $msg->failure_reason($value) >>

Type: C<Enum> (L<Google::Cloud::Support::V2::SupportEventSubscription::FailureReason>)

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

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Support::V2::SupportEventSubscription::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
