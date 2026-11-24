package Google::Cloud::Osconfig::V1alpha::ConfigCommon;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjFnb29nbGUvY2xvdWQvb3Njb25maWcvdjFhbHBoYS9jb25maWdfY29tbW9uLnByb3RvEh1n
b29nbGUuY2xvdWQub3Njb25maWcudjFhbHBoYSLOAwoaT1NQb2xpY3lSZXNvdXJjZUNvbmZp
Z1N0ZXASUgoEdHlwZRgBIAEoDjI+Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLk9T
UG9saWN5UmVzb3VyY2VDb25maWdTdGVwLlR5cGVSBHR5cGUSWwoHb3V0Y29tZRgCIAEoDjJB
Lmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhhLk9TUG9saWN5UmVzb3VyY2VDb25maWdT
dGVwLk91dGNvbWVSB291dGNvbWUSIwoNZXJyb3JfbWVzc2FnZRgDIAEoCVIMZXJyb3JNZXNz
YWdlIpIBCgRUeXBlEhQKEFRZUEVfVU5TUEVDSUZJRUQQABIOCgpWQUxJREFUSU9OEAESFwoT
REVTSVJFRF9TVEFURV9DSEVDSxACEh0KGURFU0lSRURfU1RBVEVfRU5GT1JDRU1FTlQQAxIo
CiRERVNJUkVEX1NUQVRFX0NIRUNLX1BPU1RfRU5GT1JDRU1FTlQQBBoCGAEiQQoHT3V0Y29t
ZRIXChNPVVRDT01FX1VOU1BFQ0lGSUVEEAASDQoJU1VDQ0VFREVEEAESCgoGRkFJTEVEEAIa
AhgBOgIYASLVAwoaT1NQb2xpY3lSZXNvdXJjZUNvbXBsaWFuY2USMQoVb3NfcG9saWN5X3Jl
c291cmNlX2lkGAEgASgJUhJvc1BvbGljeVJlc291cmNlSWQSXAoMY29uZmlnX3N0ZXBzGAIg
AygLMjkuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLnYxYWxwaGEuT1NQb2xpY3lSZXNvdXJjZUNv
bmZpZ1N0ZXBSC2NvbmZpZ1N0ZXBzEkwKBXN0YXRlGAMgASgOMjYuZ29vZ2xlLmNsb3VkLm9z
Y29uZmlnLnYxYWxwaGEuT1NQb2xpY3lDb21wbGlhbmNlU3RhdGVSBXN0YXRlEoABChRleGVj
X3Jlc291cmNlX291dHB1dBgEIAEoCzJMLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy52MWFscGhh
Lk9TUG9saWN5UmVzb3VyY2VDb21wbGlhbmNlLkV4ZWNSZXNvdXJjZU91dHB1dEgAUhJleGVj
UmVzb3VyY2VPdXRwdXQaRwoSRXhlY1Jlc291cmNlT3V0cHV0Ei0KEmVuZm9yY2VtZW50X291
dHB1dBgCIAEoDFIRZW5mb3JjZW1lbnRPdXRwdXQ6AhgBOgIYAUIICgZvdXRwdXQqlwEKF09T
UG9saWN5Q29tcGxpYW5jZVN0YXRlEioKJk9TX1BPTElDWV9DT01QTElBTkNFX1NUQVRFX1VO
U1BFQ0lGSUVEEAASDQoJQ09NUExJQU5UEAESEQoNTk9OX0NPTVBMSUFOVBACEgsKB1VOS05P
V04QAxIdChlOT19PU19QT0xJQ0lFU19BUFBMSUNBQkxFEAQaAhgBQtoBCiFjb20uZ29vZ2xl
LmNsb3VkLm9zY29uZmlnLnYxYWxwaGFCEUNvbmZpZ0NvbW1vblByb3RvUAFaPWNsb3VkLmdv
b2dsZS5jb20vZ28vb3Njb25maWcvYXBpdjFhbHBoYS9vc2NvbmZpZ3BiO29zY29uZmlncGKq
Ah1Hb29nbGUuQ2xvdWQuT3NDb25maWcuVjFBbHBoYcoCHUdvb2dsZVxDbG91ZFxPc0NvbmZp
Z1xWMWFscGhh6gIgR29vZ2xlOjpDbG91ZDo6T3NDb25maWc6OlYxYWxwaGFKjB4KBxIFDgCE
AQEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACYKCAoBCBID
EwA6CgkKAgglEgMTADoKCAoBCBIDFABUCgkKAggLEgMUAFQKCAoBCBIDFQAiCgkKAggKEgMV
ACIKCAoBCBIDFgAyCgkKAggIEgMWADIKCAoBCBIDFwA6CgkKAggBEgMXADoKCAoBCBIDGAA6
CgkKAggpEgMYADoKCAoBCBIDGQA5CgkKAggtEgMZADkKcAoCBAASBB0AUQEaZCBTdGVwIHBl
cmZvcm1lZCBieSB0aGUgT1MgQ29uZmlnIGFnZW50IGZvciBjb25maWd1cmluZyBhbiBgT1NQ
b2xpY3lSZXNvdXJjZWAKIHRvIGl0cyBkZXNpcmVkIHN0YXRlLgoKCgoDBAABEgMdCCIKCgoD
BAAHEgMeAhsKCwoEBAAHAxIDHgIbCjIKBAQABAASBCECOAMaJCBTdXBwb3J0ZWQgY29uZmln
dXJhdGlvbiBzdGVwIHR5cGVzCgoMCgUEAAQAARIDIQcLCgwKBQQABAADEgMiBB0KDQoGBAAE
AAMDEgMiBB0KNQoGBAAEAAIAEgMlBBkaJiBEZWZhdWx0IHZhbHVlLiBUaGlzIHZhbHVlIGlz
IHVudXNlZC4KCg4KBwQABAACAAESAyUEFAoOCgcEAAQAAgACEgMlFxgKTQoGBAAEAAIBEgMo
BBMaPiBWYWxpZGF0aW9uIHRvIGRldGVjdCByZXNvdXJjZSBjb25mbGljdHMsIHNjaGVtYSBl
cnJvcnMsIGV0Yy4KCg4KBwQABAACAQESAygEDgoOCgcEAAQAAgECEgMoERIKSAoGBAAEAAIC
EgMrBBwaOSBDaGVjayB0aGUgY3VycmVudCBkZXNpcmVkIHN0YXRlIHN0YXR1cyBvZiB0aGUg
cmVzb3VyY2UuCgoOCgcEAAQAAgIBEgMrBBcKDgoHBAAEAAICAhIDKxobClcKBgQABAACAxID
LgQiGkggRW5mb3JjZSB0aGUgZGVzaXJlZCBzdGF0ZSBmb3IgYSByZXNvdXJjZSB0aGF0IGlz
IG5vdCBpbiBkZXNpcmVkIHN0YXRlLgoKDgoHBAAEAAIDARIDLgQdCg4KBwQABAACAwISAy4g
IQqDAwoGBAAEAAIEEgM3BC0a8wIgUmUtY2hlY2sgZGVzaXJlZCBzdGF0ZSBzdGF0dXMgZm9y
IGEgcmVzb3VyY2UgYWZ0ZXIgZW5mb3JjZW1lbnQgb2YgYWxsCiByZXNvdXJjZXMgaW4gdGhl
IGN1cnJlbnQgY29uZmlndXJhdGlvbiBydW4uCgogVGhpcyBzdGVwIGlzIHVzZWQgdG8gZGV0
ZXJtaW5lIHRoZSBmaW5hbCBkZXNpcmVkIHN0YXRlIHN0YXR1cyBmb3IgdGhlCiByZXNvdXJj
ZS4gSXQgYWNjb3VudHMgZm9yIGFueSByZXNvdXJjZXMgdGhhdCBtaWdodCBoYXZlIGRyaWZ0
ZWQgZnJvbQogdGhlaXIgZGVzaXJlZCBzdGF0ZSBkdWUgdG8gc2lkZSBlZmZlY3RzIGZyb20g
Y29uZmlndXJpbmcgb3RoZXIgcmVzb3VyY2VzCiBkdXJpbmcgdGhlIGN1cnJlbnQgY29uZmln
dXJhdGlvbiBydW4uCgoOCgcEAAQAAgQBEgM3BCgKDgoHBAAEAAIEAhIDNyssCjwKBAQABAES
BDsCRgMaLiBTdXBwb3J0ZWQgb3V0Y29tZXMgZm9yIGEgY29uZmlndXJhdGlvbiBzdGVwLgoK
DAoFBAAEAQESAzsHDgoMCgUEAAQBAxIDPAQdCg0KBgQABAEDAxIDPAQdCjUKBgQABAECABID
PwQcGiYgRGVmYXVsdCB2YWx1ZS4gVGhpcyB2YWx1ZSBpcyB1bnVzZWQuCgoOCgcEAAQBAgAB
EgM/BBcKDgoHBAAEAQIAAhIDPxobCiQKBgQABAECARIDQgQSGhUgVGhlIHN0ZXAgc3VjY2Vl
ZGVkLgoKDgoHBAAEAQIBARIDQgQNCg4KBwQABAECAQISA0IQEQohCgYEAAQBAgISA0UEDxoS
IFRoZSBzdGVwIGZhaWxlZC4KCg4KBwQABAECAgESA0UECgoOCgcEAAQBAgICEgNFDQ4KJwoE
BAACABIDSQIQGhogQ29uZmlndXJhdGlvbiBzdGVwIHR5cGUuCgoMCgUEAAIABhIDSQIGCgwK
BQQAAgABEgNJBwsKDAoFBAACAAMSA0kODwoxCgQEAAIBEgNMAhYaJCBPdXRjb21lIG9mIHRo
ZSBjb25maWd1cmF0aW9uIHN0ZXAuCgoMCgUEAAIBBhIDTAIJCgwKBQQAAgEBEgNMChEKDAoF
BAACAQMSA0wUFQpzCgQEAAICEgNQAhsaZiBBbiBlcnJvciBtZXNzYWdlIHJlY29yZGVkIGR1
cmluZyB0aGUgZXhlY3V0aW9uIG9mIHRoaXMgc3RlcC4KIE9ubHkgcG9wdWxhdGVkIHdoZW4g
b3V0Y29tZSBpcyBGQUlMRUQuCgoMCgUEAAICBRIDUAIICgwKBQQAAgIBEgNQCRYKDAoFBAAC
AgMSA1AZGgo4CgIEARIEVABvARosIENvbXBsaWFuY2UgZGF0YSBmb3IgYW4gT1MgcG9saWN5
IHJlc291cmNlLgoKCgoDBAEBEgNUCCIKCgoDBAEHEgNVAhsKCwoEBAEHAxIDVQIbCi0KBAQB
AwASBFgCXgMaHyBFeGVjUmVzb3VyY2Ugc3BlY2lmaWMgb3V0cHV0LgoKDAoFBAEDAAESA1gK
HAoMCgUEAQMABxIDWQQdCg0KBgQBAwAHAxIDWQQdCmsKBgQBAwACABIDXQQhGlwgT3V0cHV0
IGZyb20gRW5mb3JjZW1lbnQgcGhhc2Ugb3V0cHV0IGZpbGUgKGlmIHJ1bikuCiBPdXRwdXQg
c2l6ZSBpcyBsaW1pdGVkIHRvIDEwMEsgYnl0ZXMuCgoOCgcEAQMAAgAFEgNdBAkKDgoHBAED
AAIAARIDXQocCg4KBwQBAwACAAMSA10fIAowCgQEAQIAEgNhAiMaIyBUaGUgaWQgb2YgdGhl
IE9TIHBvbGljeSByZXNvdXJjZS4KCgwKBQQBAgAFEgNhAggKDAoFBAECAAESA2EJHgoMCgUE
AQIAAxIDYSEiCmIKBAQBAgESA2UCNxpVIE9yZGVyZWQgbGlzdCBvZiBjb25maWd1cmF0aW9u
IHN0ZXBzIHRha2VuIGJ5IHRoZSBhZ2VudCBmb3IgdGhlIE9TIHBvbGljeQogcmVzb3VyY2Uu
CgoMCgUEAQIBBBIDZQIKCgwKBQQBAgEGEgNlCyUKDAoFBAECAQESA2UmMgoMCgUEAQIBAxID
ZTU2CjoKBAQBAgISA2gCJBotIENvbXBsaWFuY2Ugc3RhdGUgb2YgdGhlIE9TIHBvbGljeSBy
ZXNvdXJjZS4KCgwKBQQBAgIGEgNoAhkKDAoFBAECAgESA2gaHwoMCgUEAQICAxIDaCIjCikK
BAQBCAASBGsCbgMaGyBSZXNvdXJjZSBzcGVjaWZpYyBvdXRwdXQuCgoMCgUEAQgAARIDawgO
CiwKBAQBAgMSA20EMBofIEV4ZWNSZXNvdXJjZSBzcGVjaWZpYyBvdXRwdXQuCgoMCgUEAQID
BhIDbQQWCgwKBQQBAgMBEgNtFysKDAoFBAECAwMSA20uLwo0CgIFABIFcgCEAQEaJyBTdXBw
b3J0ZWQgT1NQb2xpY3kgY29tcGxpYW5jZSBzdGF0ZXMuCgoKCgMFAAESA3IFHAoKCgMFAAMS
A3MCGwoLCgQFAAMDEgNzAhsKMwoEBQACABIDdgItGiYgRGVmYXVsdCB2YWx1ZS4gVGhpcyB2
YWx1ZSBpcyB1bnVzZWQuCgoMCgUFAAIAARIDdgIoCgwKBQUAAgACEgN2KywKHwoEBQACARID
eQIQGhIgQ29tcGxpYW50IHN0YXRlLgoKDAoFBQACAQESA3kCCwoMCgUFAAIBAhIDeQ4PCiIK
BAUAAgISA3wCFBoVIE5vbi1jb21wbGlhbnQgc3RhdGUKCgwKBQUAAgIBEgN8Ag8KDAoFBQAC
AgISA3wSEwooCgQFAAIDEgN/Ag4aGyBVbmtub3duIGNvbXBsaWFuY2Ugc3RhdGUuCgoMCgUF
AAIDARIDfwIJCgwKBQUAAgMCEgN/DA0KdgoEBQACBBIEgwECIBpoIE5vIGFwcGxpY2FibGUg
T1MgcG9saWNpZXMgd2VyZSBmb3VuZCBmb3IgdGhlIGluc3RhbmNlLgogVGhpcyBzdGF0ZSBp
cyBvbmx5IGFwcGxpY2FibGUgdG8gdGhlIGluc3RhbmNlLgoKDQoFBQACBAESBIMBAhsKDQoF
BQACBAISBIMBHh9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::V1alpha::ConfigCommon::OSPolicyResourceConfigStep ===
    # Fields for OSPolicyResourceConfigStep
    # Field: type Type: 14 (.google.cloud.osconfig.v1alpha.OSPolicyResourceConfigStep.Type)
    # Field: outcome Type: 14 (.google.cloud.osconfig.v1alpha.OSPolicyResourceConfigStep.Outcome)
    # Field: error_message Type: 9 ()

# Enum: OSPolicyResourceConfigStep::Type
our $OSPolicyResourceConfigStep_TYPE_UNSPECIFIED = 0;
our $OSPolicyResourceConfigStep_VALIDATION = 1;
our $OSPolicyResourceConfigStep_DESIRED_STATE_CHECK = 2;
our $OSPolicyResourceConfigStep_DESIRED_STATE_ENFORCEMENT = 3;
our $OSPolicyResourceConfigStep_DESIRED_STATE_CHECK_POST_ENFORCEMENT = 4;

# Enum: OSPolicyResourceConfigStep::Outcome
our $OSPolicyResourceConfigStep_OUTCOME_UNSPECIFIED = 0;
our $OSPolicyResourceConfigStep_SUCCEEDED = 1;
our $OSPolicyResourceConfigStep_FAILED = 2;

# === Message: Google::Cloud::Osconfig::V1alpha::ConfigCommon::OSPolicyResourceCompliance ===
    # Fields for OSPolicyResourceCompliance
    # Field: os_policy_resource_id Type: 9 ()
    # Field: config_steps Type: 11 (.google.cloud.osconfig.v1alpha.OSPolicyResourceConfigStep)
    # Field: state Type: 14 (.google.cloud.osconfig.v1alpha.OSPolicyComplianceState)
    # Field: exec_resource_output Type: 11 (.google.cloud.osconfig.v1alpha.OSPolicyResourceCompliance.ExecResourceOutput)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::V1alpha::ConfigCommon - Compiled Protocol Buffers messages for google/cloud/osconfig/v1alpha/config_common.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::V1alpha::ConfigCommon;

    my $msg = Google::Cloud::Osconfig::V1alpha::ConfigCommon::OSPolicyResourceConfigStep->new({
        type => $type,
        outcome => $outcome,
        error_message => $error_message,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::V1alpha::ConfigCommon::OSPolicyResourceConfigStep->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/v1alpha/config_common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::V1alpha::ConfigCommon::OSPolicyResourceConfigStep

Step performed by the OS Config agent for configuring an `OSPolicyResource`
to its desired state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1alpha::OSPolicyResourceConfigStep::Type>)

Configuration step type.

=item * C<< $msg->outcome() >> / C<< $msg->outcome($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1alpha::OSPolicyResourceConfigStep::Outcome>)

Outcome of the configuration step.

=item * C<< $msg->error_message() >> / C<< $msg->error_message($value) >>

Type: C<String>

An error message recorded during the execution of this step.
Only populated when outcome is FAILED.

=back

=head3 Enum: OSPolicyResourceConfigStep::Type

=over 4

=item * C<TYPE_UNSPECIFIED> => C<0>

=item * C<VALIDATION> => C<1>

=item * C<DESIRED_STATE_CHECK> => C<2>

=item * C<DESIRED_STATE_ENFORCEMENT> => C<3>

=item * C<DESIRED_STATE_CHECK_POST_ENFORCEMENT> => C<4>

=back

=head3 Enum: OSPolicyResourceConfigStep::Outcome

=over 4

=item * C<OUTCOME_UNSPECIFIED> => C<0>

=item * C<SUCCEEDED> => C<1>

=item * C<FAILED> => C<2>

=back

=head2 Google::Cloud::Osconfig::V1alpha::ConfigCommon::OSPolicyResourceCompliance

Compliance data for an OS policy resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_policy_resource_id() >> / C<< $msg->os_policy_resource_id($value) >>

Type: C<String>

The id of the OS policy resource.

=item * C<< $msg->config_steps() >> / C<< $msg->config_steps($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::ConfigCommon::OSPolicyResourceConfigStep>)

Ordered list of configuration steps taken by the agent for the OS policy
resource.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::V1alpha::OSPolicyComplianceState>)

Compliance state of the OS policy resource.

=item * C<< $msg->exec_resource_output() >> / C<< $msg->exec_resource_output($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::V1alpha::ConfigCommon::OSPolicyResourceCompliance::ExecResourceOutput>)

ExecResource specific output.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::V1alpha::ConfigCommon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
