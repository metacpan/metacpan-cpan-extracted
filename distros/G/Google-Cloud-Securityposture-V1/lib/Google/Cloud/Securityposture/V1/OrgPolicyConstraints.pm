package Google::Cloud::Securityposture::V1::OrgPolicyConstraints;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Api::FieldBehavior };
    eval { require Google::Cloud::Securityposture::V1::OrgPolicyConfig };
    my $descriptor_b64 = <<'EOF';
Cjxnb29nbGUvY2xvdWQvc2VjdXJpdHlwb3N0dXJlL3YxL29yZ19wb2xpY3lfY29uc3RyYWlu
dHMucHJvdG8SH2dvb2dsZS5jbG91ZC5zZWN1cml0eXBvc3R1cmUudjEaH2dvb2dsZS9hcGkv
ZmllbGRfYmVoYXZpb3IucHJvdG8aN2dvb2dsZS9jbG91ZC9zZWN1cml0eXBvc3R1cmUvdjEv
b3JnX3BvbGljeV9jb25maWcucHJvdG8ioQEKE09yZ1BvbGljeUNvbnN0cmFpbnQSNQoUY2Fu
bmVkX2NvbnN0cmFpbnRfaWQYASABKAlCA+BBAlISY2FubmVkQ29uc3RyYWludElkElMKDHBv
bGljeV9ydWxlcxgCIAMoCzIrLmdvb2dsZS5jbG91ZC5zZWN1cml0eXBvc3R1cmUudjEuUG9s
aWN5UnVsZUID4EECUgtwb2xpY3lSdWxlcyLVAQoZT3JnUG9saWN5Q29uc3RyYWludEN1c3Rv
bRJjChFjdXN0b21fY29uc3RyYWludBgBIAEoCzIxLmdvb2dsZS5jbG91ZC5zZWN1cml0eXBv
c3R1cmUudjEuQ3VzdG9tQ29uc3RyYWludEID4EECUhBjdXN0b21Db25zdHJhaW50ElMKDHBv
bGljeV9ydWxlcxgCIAMoCzIrLmdvb2dsZS5jbG91ZC5zZWN1cml0eXBvc3R1cmUudjEuUG9s
aWN5UnVsZUID4EECUgtwb2xpY3lSdWxlc0KRAQojY29tLmdvb2dsZS5jbG91ZC5zZWN1cml0
eXBvc3R1cmUudjFCGU9yZ1BvbGljeUNvbnN0cmFpbnRzUHJvdG9QAVpNY2xvdWQuZ29vZ2xl
LmNvbS9nby9zZWN1cml0eXBvc3R1cmUvYXBpdjEvc2VjdXJpdHlwb3N0dXJlcGI7c2VjdXJp
dHlwb3N0dXJlcGJK2QoKBhIEDgArAQq8BAoBDBIDDgASMrEEIENvcHlyaWdodCAyMDI1IEdv
b2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24g
Mi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0aGlzIGZpbGUgZXhjZXB0
IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBtYXkgb2J0YWluIGEgY29w
eSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFwYWNoZS5vcmcvbGljZW5z
ZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBwbGljYWJsZSBsYXcgb3Ig
YWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmlidXRlZCB1bmRlciB0aGUg
TGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJBU0lTLAogV0lUSE9VVCBX
QVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9y
IGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVjaWZpYyBsYW5ndWFnZSBn
b3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1bmRlciB0aGUgTGljZW5z
ZS4KCggKAQISAxAAKAoJCgIDABIDEgApCgkKAgMBEgMTAEEKCAoBCBIDFQBkCgkKAggLEgMV
AGQKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwA6CgkKAggIEgMXADoKCAoBCBIDGAA8
CgkKAggBEgMYADwKNwoCBAASBBsAIQEaKyBNZXNzYWdlIGZvciBPcmcgUG9saWN5IENhbm5l
ZCBDb25zdHJhaW50LgoKCgoDBAABEgMbCBsKOQoEBAACABIDHQJLGiwgUmVxdWlyZWQuIE9y
ZyBQb2xpY3kgQ2FubmVkIENvbnN0cmFpbnQgaWQuCgoMCgUEAAIABRIDHQIICgwKBQQAAgAB
EgMdCR0KDAoFBAACAAMSAx0gIQoMCgUEAAIACBIDHSJKCg8KCAQAAgAInAgAEgMdI0kKLgoE
BAACARIDIAJQGiEgUmVxdWlyZWQuIE9yZyBQb2xpY3lTcGVjIHJ1bGVzLgoKDAoFBAACAQQS
AyACCgoMCgUEAAIBBhIDIAsVCgwKBQQAAgEBEgMgFiIKDAoFBAACAQMSAyAlJgoMCgUEAAIB
CBIDICdPCg8KCAQAAgEInAgAEgMgKE4KNwoCBAESBCQAKwEaKyBNZXNzYWdlIGZvciBPcmcg
UG9saWN5IEN1c3RvbSBDb25zdHJhaW50LgoKCgoDBAEBEgMkCCEKNwoEBAECABIEJgInLxop
IFJlcXVpcmVkLiBPcmcgUG9saWN5IEN1c3RvbSBDb25zdHJhaW50LgoKDAoFBAECAAYSAyYC
EgoMCgUEAQIAARIDJhMkCgwKBQQBAgADEgMmJygKDAoFBAECAAgSAycGLgoPCggEAQIACJwI
ABIDJwctCi4KBAQBAgESAyoCUBohIFJlcXVpcmVkLiBPcmcgUG9saWN5c3BlYyBydWxlcy4K
CgwKBQQBAgEEEgMqAgoKDAoFBAECAQYSAyoLFQoMCgUEAQIBARIDKhYiCgwKBQQBAgEDEgMq
JSYKDAoFBAECAQgSAyonTwoPCggEAQIBCJwIABIDKihOYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraint ===
    # Fields for OrgPolicyConstraint
    # Field: canned_constraint_id Type: 9 ()
    # Field: policy_rules Type: 11 (.google.cloud.securityposture.v1.PolicyRule)

# === Message: Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraintCustom ===
    # Fields for OrgPolicyConstraintCustom
    # Field: custom_constraint Type: 11 (.google.cloud.securityposture.v1.CustomConstraint)
    # Field: policy_rules Type: 11 (.google.cloud.securityposture.v1.PolicyRule)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securityposture::V1::OrgPolicyConstraints - Compiled Protocol Buffers messages for google/cloud/securityposture/v1/org_policy_constraints.proto

=head1 SYNOPSIS

    use Google::Cloud::Securityposture::V1::OrgPolicyConstraints;

    my $msg = Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraint->new({
        canned_constraint_id => $canned_constraint_id,
        policy_rules => $policy_rules,
    });

    # Read or update a field
    my $val = $msg->canned_constraint_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraint->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securityposture/v1/org_policy_constraints.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraint

Message for Org Policy Canned Constraint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->canned_constraint_id() >> / C<< $msg->canned_constraint_id($value) >>

Type: C<String>

Required. Org Policy Canned Constraint id.

=item * C<< $msg->policy_rules() >> / C<< $msg->policy_rules($value) >>

Type: C<Message> (L<Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule>)

Required. Org PolicySpec rules.

=back

=head2 Google::Cloud::Securityposture::V1::OrgPolicyConstraints::OrgPolicyConstraintCustom

Message for Org Policy Custom Constraint.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->custom_constraint() >> / C<< $msg->custom_constraint($value) >>

Type: C<Message> (L<Google::Cloud::Securityposture::V1::OrgPolicyConfig::CustomConstraint>)

Required. Org Policy Custom Constraint.

=item * C<< $msg->policy_rules() >> / C<< $msg->policy_rules($value) >>

Type: C<Message> (L<Google::Cloud::Securityposture::V1::OrgPolicyConfig::PolicyRule>)

Required. Org Policyspec rules.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securityposture::V1::OrgPolicyConstraints::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
