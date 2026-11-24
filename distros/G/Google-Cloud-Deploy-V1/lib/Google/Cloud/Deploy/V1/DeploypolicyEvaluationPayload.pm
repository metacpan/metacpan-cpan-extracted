package Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Deploy::V1::CloudDeploy };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvZGVwbG95L3YxL2RlcGxveXBvbGljeV9ldmFsdWF0aW9uX3BheWxv
YWQucHJvdG8SFmdvb2dsZS5jbG91ZC5kZXBsb3kudjEaKWdvb2dsZS9jbG91ZC9kZXBsb3kv
djEvY2xvdWRfZGVwbG95LnByb3RvIrUGChtEZXBsb3lQb2xpY3lFdmFsdWF0aW9uRXZlbnQS
GAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZRIbCglydWxlX3R5cGUYAiABKAlSCHJ1bGVUeXBl
EhIKBHJ1bGUYAyABKAlSBHJ1bGUSIQoMcGlwZWxpbmVfdWlkGAQgASgJUgtwaXBlbGluZVVp
ZBIrChFkZWxpdmVyeV9waXBlbGluZRgFIAEoCVIQZGVsaXZlcnlQaXBlbGluZRIdCgp0YXJn
ZXRfdWlkGAYgASgJUgl0YXJnZXRVaWQSFgoGdGFyZ2V0GAcgASgJUgZ0YXJnZXQSRgoHaW52
b2tlchgIIAEoDjIsLmdvb2dsZS5jbG91ZC5kZXBsb3kudjEuRGVwbG95UG9saWN5Lkludm9r
ZXJSB2ludm9rZXISIwoNZGVwbG95X3BvbGljeRgJIAEoCVIMZGVwbG95UG9saWN5EioKEWRl
cGxveV9wb2xpY3lfdWlkGAogASgJUg9kZXBsb3lQb2xpY3lVaWQSGAoHYWxsb3dlZBgLIAEo
CFIHYWxsb3dlZBJbCgd2ZXJkaWN0GAwgASgOMkEuZ29vZ2xlLmNsb3VkLmRlcGxveS52MS5E
ZXBsb3lQb2xpY3lFdmFsdWF0aW9uRXZlbnQuUG9saWN5VmVyZGljdFIHdmVyZGljdBJnCglv
dmVycmlkZXMYDSADKA4ySS5nb29nbGUuY2xvdWQuZGVwbG95LnYxLkRlcGxveVBvbGljeUV2
YWx1YXRpb25FdmVudC5Qb2xpY3lWZXJkaWN0T3ZlcnJpZGVSCW92ZXJyaWRlcyJcCg1Qb2xp
Y3lWZXJkaWN0Eh4KGlBPTElDWV9WRVJESUNUX1VOU1BFQ0lGSUVEEAASFQoRQUxMT1dFRF9C
WV9QT0xJQ1kQARIUChBERU5JRURfQllfUE9MSUNZEAIibQoVUG9saWN5VmVyZGljdE92ZXJy
aWRlEicKI1BPTElDWV9WRVJESUNUX09WRVJSSURFX1VOU1BFQ0lGSUVEEAASFQoRUE9MSUNZ
X09WRVJSSURERU4QARIUChBQT0xJQ1lfU1VTUEVOREVEEAJCdgoaY29tLmdvb2dsZS5jbG91
ZC5kZXBsb3kudjFCIkRlcGxveVBvbGljeUV2YWx1YXRpb25QYXlsb2FkUHJvdG9QAVoyY2xv
dWQuZ29vZ2xlLmNvbS9nby9kZXBsb3kvYXBpdjEvZGVwbG95cGI7ZGVwbG95cGJK2RoKBhIE
DgBkAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdvb2dsZSBMTEMKCiBMaWNlbnNl
ZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2Ui
KTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0
aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBh
dAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBV
bmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRp
bmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmli
dXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJ
VElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhl
IExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lv
bnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHwoJCgID
ABIDEgAzCggKAQgSAxQASQoJCgIICxIDFABJCggKAQgSAxUAIgoJCgIIChIDFQAiCggKAQgS
AxYAQwoJCgIICBIDFgBDCggKAQgSAxcAMwoJCgIIARIDFwAzCpwBCgIEABIEGwBkARqPASBQ
YXlsb2FkIHByb3RvIGZvciAiY2xvdWRkZXBsb3kuZ29vZ2xlYXBpcy5jb20vZGVwbG95cG9s
aWN5X2V2YWx1YXRpb24iCiBQbGF0Zm9ybSBMb2cgZXZlbnQgdGhhdCBkZXNjcmliZXMgdGhl
IGRlcGxveSBwb2xpY3kgZXZhbHVhdGlvbiBldmVudC4KCgoKAwQAARIDGwgjCjIKBAQABAAS
BB0CKAMaJCBUaGUgcG9saWN5IHZlcmRpY3Qgb2YgdGhlIHJlcXVlc3QuCgoMCgUEAAQAARID
HQcUCioKBgQABAACABIDHwQjGhsgVGhpcyBzaG91bGQgbmV2ZXIgaGFwcGVuLgoKDgoHBAAE
AAIAARIDHwQeCg4KBwQABAACAAISAx8hIgqxAQoGBAAEAAIBEgMkBBoaoQEgQWxsb3dlZCBi
eSBwb2xpY3kuIFRoaXMgZW51bSB2YWx1ZSBpcyBub3QgY3VycmVudGx5IHVzZWQgYnV0IG1h
eSBiZSB1c2VkCiBpbiB0aGUgZnV0dXJlLiBDdXJyZW50bHkgbG9ncyBhcmUgb25seSBnZW5l
cmF0ZWQgd2hlbiBhIHJlcXVlc3QgaXMgZGVuaWVkCiBieSBwb2xpY3kuCgoOCgcEAAQAAgEB
EgMkBBUKDgoHBAAEAAIBAhIDJBgZCiIKBgQABAACAhIDJwQZGhMgRGVuaWVkIGJ5IHBvbGlj
eS4KCg4KBwQABAACAgESAycEFAoOCgcEAAQAAgICEgMnFxgKnAEKBAQABAESBCwCNQMajQEg
VGhpbmdzIHRoYXQgY291bGQgaGF2ZSBvdmVycmlkZGVuIHRoZSBwb2xpY3kgdmVyZGljdC4g
V2hlbiBvdmVycmlkZXMgYXJlCiB1c2VkLCB0aGUgcmVxdWVzdCB3aWxsIGJlIGFsbG93ZWQg
ZXZlbiBpZiBpdCBpcyBERU5JRURfQllfUE9MSUNZLgoKDAoFBAAEAQESAywHHAoqCgYEAAQB
AgASAy4ELBobIFRoaXMgc2hvdWxkIG5ldmVyIGhhcHBlbi4KCg4KBwQABAECAAESAy4EJwoO
CgcEAAQBAgACEgMuKisKKwoGBAAEAQIBEgMxBBoaHCBUaGUgcG9saWN5IHdhcyBvdmVycmlk
ZGVuLgoKDgoHBAAEAQIBARIDMQQVCg4KBwQABAECAQISAzEYGQoqCgYEAAQBAgISAzQEGRob
IFRoZSBwb2xpY3kgd2FzIHN1c3BlbmRlZC4KCg4KBwQABAECAgESAzQEFAoOCgcEAAQBAgIC
EgM0FxgKQwoEBAACABIDOAIVGjYgRGVidWcgbWVzc2FnZSBmb3Igd2hlbiBhIGRlcGxveSBw
b2xpY3kgZXZlbnQgb2NjdXJzLgoKDAoFBAACAAUSAzgCCAoMCgUEAAIAARIDOAkQCgwKBQQA
AgADEgM4ExQKMgoEBAACARIDOwIXGiUgUnVsZSB0eXBlIChlLmcuIFJlc3RyaWN0IFJvbGxv
dXRzKS4KCgwKBQQAAgEFEgM7AggKDAoFBAACAQESAzsJEgoMCgUEAAIBAxIDOxUWChcKBAQA
AgISAz4CEhoKIFJ1bGUgaWQuCgoMCgUEAAICBRIDPgIICgwKBQQAAgIBEgM+CQ0KDAoFBAAC
AgMSAz4QEQo8CgQEAAIDEgNBAhoaLyBVbmlxdWUgaWRlbnRpZmllciBvZiB0aGUgYERlbGl2
ZXJ5IFBpcGVsaW5lYC4KCgwKBQQAAgMFEgNBAggKDAoFBAACAwESA0EJFQoMCgUEAAIDAxID
QRgZCjMKBAQAAgQSA0QCHxomIFRoZSBuYW1lIG9mIHRoZSBgRGVsaXZlcnkgUGlwZWxpbmVg
LgoKDAoFBAACBAUSA0QCCAoMCgUEAAIEARIDRAkaCgwKBQQAAgQDEgNEHR4KhQEKBAQAAgUS
A0gCGBp4IFVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBgVGFyZ2V0YC4gVGhpcyBpcyBhbiBv
cHRpb25hbCBmaWVsZCwgYXMgYSBgVGFyZ2V0YAogbWF5IG5vdCBhbHdheXMgYmUgYXBwbGlj
YWJsZSB0byBhIHBvbGljeS4KCgwKBQQAAgUFEgNIAggKDAoFBAACBQESA0gJEwoMCgUEAAIF
AxIDSBYXCnwKBAQAAgYSA0wCFBpvIFRoZSBuYW1lIG9mIHRoZSBgVGFyZ2V0YC4gVGhpcyBp
cyBhbiBvcHRpb25hbCBmaWVsZCwgYXMgYSBgVGFyZ2V0YCBtYXkgbm90CiBhbHdheXMgYmUg
YXBwbGljYWJsZSB0byBhIHBvbGljeS4KCgwKBQQAAgYFEgNMAggKDAoFBAACBgESA0wJDwoM
CgUEAAIGAxIDTBITCkMKBAQAAgcSA08CIxo2IFdoYXQgaW52b2tlZCB0aGUgYWN0aW9uIChl
LmcuIGEgdXNlciBvciBhdXRvbWF0aW9uKS4KCgwKBQQAAgcGEgNPAhYKDAoFBAACBwESA08X
HgoMCgUEAAIHAxIDTyEiCi4KBAQAAggSA1ICGxohIFRoZSBuYW1lIG9mIHRoZSBgRGVwbG95
UG9saWN5YC4KCgwKBQQAAggFEgNSAggKDAoFBAACCAESA1IJFgoMCgUEAAIIAxIDUhkaCjcK
BAQAAgkSA1UCIBoqIFVuaXF1ZSBpZGVudGlmaWVyIG9mIHRoZSBgRGVwbG95UG9saWN5YC4K
CgwKBQQAAgkFEgNVAggKDAoFBAACCQESA1UJGgoMCgUEAAIJAxIDVR0fCpgCCgQEAAIKEgNc
AhQaigIgV2hldGhlciB0aGUgcmVxdWVzdCBpcyBhbGxvd2VkLiBBbGxvd2VkIGlzIHNldCBh
cyB0cnVlIGlmOgogKDEpIHRoZSByZXF1ZXN0IGNvbXBsaWVzIHdpdGggdGhlIHBvbGljeTsg
b3IKICgyKSB0aGUgcmVxdWVzdCBkb2Vzbid0IGNvbXBseSB3aXRoIHRoZSBwb2xpY3kgYnV0
IHRoZSBwb2xpY3kgd2FzCiBvdmVycmlkZGVuOyBvcgogKDMpIHRoZSByZXF1ZXN0IGRvZXNu
J3QgY29tcGx5IHdpdGggdGhlIHBvbGljeSBidXQgdGhlIHBvbGljeSB3YXMgc3VzcGVuZGVk
CgoMCgUEAAIKBRIDXAIGCgwKBQQAAgoBEgNcBw4KDAoFBAACCgMSA1wREwoxCgQEAAILEgNf
Ah0aJCBUaGUgcG9saWN5IHZlcmRpY3Qgb2YgdGhlIHJlcXVlc3QuCgoMCgUEAAILBhIDXwIP
CgwKBQQAAgsBEgNfEBcKDAoFBAACCwMSA18aHAqMAQoEBAACDBIDYwIwGn8gVGhpbmdzIHRo
YXQgY291bGQgaGF2ZSBvdmVycmlkZGVuIHRoZSBwb2xpY3kgdmVyZGljdC4gT3ZlcnJpZGVz
IHRvZ2V0aGVyCiB3aXRoIHZlcmRpY3QgZGVjaWRlIHdoZXRoZXIgdGhlIHJlcXVlc3QgaXMg
YWxsb3dlZC4KCgwKBQQAAgwEEgNjAgoKDAoFBAACDAYSA2MLIAoMCgUEAAIMARIDYyEqCgwK
BQQAAgwDEgNjLS9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload::DeployPolicyEvaluationEvent ===
    # Fields for DeployPolicyEvaluationEvent
    # Field: message Type: 9 ()
    # Field: rule_type Type: 9 ()
    # Field: rule Type: 9 ()
    # Field: pipeline_uid Type: 9 ()
    # Field: delivery_pipeline Type: 9 ()
    # Field: target_uid Type: 9 ()
    # Field: target Type: 9 ()
    # Field: invoker Type: 14 (.google.cloud.deploy.v1.DeployPolicy.Invoker)
    # Field: deploy_policy Type: 9 ()
    # Field: deploy_policy_uid Type: 9 ()
    # Field: allowed Type: 8 ()
    # Field: verdict Type: 14 (.google.cloud.deploy.v1.DeployPolicyEvaluationEvent.PolicyVerdict)
    # Field: overrides Type: 14 (.google.cloud.deploy.v1.DeployPolicyEvaluationEvent.PolicyVerdictOverride)

# Enum: DeployPolicyEvaluationEvent::PolicyVerdict
our $DeployPolicyEvaluationEvent_POLICY_VERDICT_UNSPECIFIED = 0;
our $DeployPolicyEvaluationEvent_ALLOWED_BY_POLICY = 1;
our $DeployPolicyEvaluationEvent_DENIED_BY_POLICY = 2;

# Enum: DeployPolicyEvaluationEvent::PolicyVerdictOverride
our $DeployPolicyEvaluationEvent_POLICY_VERDICT_OVERRIDE_UNSPECIFIED = 0;
our $DeployPolicyEvaluationEvent_POLICY_OVERRIDDEN = 1;
our $DeployPolicyEvaluationEvent_POLICY_SUSPENDED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/deploypolicy_evaluation_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload;

    my $msg = Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload::DeployPolicyEvaluationEvent->new({
        message => $message,
        rule_type => $rule_type,
        rule => $rule,
        pipeline_uid => $pipeline_uid,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload::DeployPolicyEvaluationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/deploypolicy_evaluation_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload::DeployPolicyEvaluationEvent

Payload proto for "clouddeploy.googleapis.com/deploypolicy_evaluation"
Platform Log event that describes the deploy policy evaluation event.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when a deploy policy event occurs.

=item * C<< $msg->rule_type() >> / C<< $msg->rule_type($value) >>

Type: C<String>

Rule type (e.g. Restrict Rollouts).

=item * C<< $msg->rule() >> / C<< $msg->rule($value) >>

Type: C<String>

Rule id.

=item * C<< $msg->pipeline_uid() >> / C<< $msg->pipeline_uid($value) >>

Type: C<String>

Unique identifier of the `Delivery Pipeline`.

=item * C<< $msg->delivery_pipeline() >> / C<< $msg->delivery_pipeline($value) >>

Type: C<String>

The name of the `Delivery Pipeline`.

=item * C<< $msg->target_uid() >> / C<< $msg->target_uid($value) >>

Type: C<String>

Unique identifier of the `Target`. This is an optional field, as a `Target`
may not always be applicable to a policy.

=item * C<< $msg->target() >> / C<< $msg->target($value) >>

Type: C<String>

The name of the `Target`. This is an optional field, as a `Target` may not
always be applicable to a policy.

=item * C<< $msg->invoker() >> / C<< $msg->invoker($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::DeployPolicy::Invoker>)

What invoked the action (e.g. a user or automation).

=item * C<< $msg->deploy_policy() >> / C<< $msg->deploy_policy($value) >>

Type: C<String>

The name of the `DeployPolicy`.

=item * C<< $msg->deploy_policy_uid() >> / C<< $msg->deploy_policy_uid($value) >>

Type: C<String>

Unique identifier of the `DeployPolicy`.

=item * C<< $msg->allowed() >> / C<< $msg->allowed($value) >>

Type: C<Bool>

Whether the request is allowed. Allowed is set as true if:
(1) the request complies with the policy; or
(2) the request doesn't comply with the policy but the policy was
overridden; or
(3) the request doesn't comply with the policy but the policy was suspended

=item * C<< $msg->verdict() >> / C<< $msg->verdict($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::DeployPolicyEvaluationEvent::PolicyVerdict>)

The policy verdict of the request.

=item * C<< $msg->overrides() >> / C<< $msg->overrides($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::DeployPolicyEvaluationEvent::PolicyVerdictOverride>)

Things that could have overridden the policy verdict. Overrides together
with verdict decide whether the request is allowed.

=back

=head3 Enum: DeployPolicyEvaluationEvent::PolicyVerdict

=over 4

=item * C<POLICY_VERDICT_UNSPECIFIED> => C<0>

=item * C<ALLOWED_BY_POLICY> => C<1>

=item * C<DENIED_BY_POLICY> => C<2>

=back

=head3 Enum: DeployPolicyEvaluationEvent::PolicyVerdictOverride

=over 4

=item * C<POLICY_VERDICT_OVERRIDE_UNSPECIFIED> => C<0>

=item * C<POLICY_OVERRIDDEN> => C<1>

=item * C<POLICY_SUSPENDED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::DeploypolicyEvaluationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
