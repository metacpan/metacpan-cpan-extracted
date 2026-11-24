package Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Cjpnb29nbGUvY2xvdWQvb3Njb25maWcvYWdlbnRlbmRwb2ludC92MS9jb25maWdfY29tbW9u
LnByb3RvEiZnb29nbGUuY2xvdWQub3Njb25maWcuYWdlbnRlbmRwb2ludC52MSLUAwoaT1NQ
b2xpY3lSZXNvdXJjZUNvbmZpZ1N0ZXASWwoEdHlwZRgBIAEoDjJHLmdvb2dsZS5jbG91ZC5v
c2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLk9TUG9saWN5UmVzb3VyY2VDb25maWdTdGVwLlR5
cGVSBHR5cGUSZAoHb3V0Y29tZRgCIAEoDjJKLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2Vu
dGVuZHBvaW50LnYxLk9TUG9saWN5UmVzb3VyY2VDb25maWdTdGVwLk91dGNvbWVSB291dGNv
bWUSIwoNZXJyb3JfbWVzc2FnZRgDIAEoCVIMZXJyb3JNZXNzYWdlIo4BCgRUeXBlEhQKEFRZ
UEVfVU5TUEVDSUZJRUQQABIOCgpWQUxJREFUSU9OEAESFwoTREVTSVJFRF9TVEFURV9DSEVD
SxACEh0KGURFU0lSRURfU1RBVEVfRU5GT1JDRU1FTlQQAxIoCiRERVNJUkVEX1NUQVRFX0NI
RUNLX1BPU1RfRU5GT1JDRU1FTlQQBCI9CgdPdXRjb21lEhcKE09VVENPTUVfVU5TUEVDSUZJ
RUQQABINCglTVUNDRUVERUQQARIKCgZGQUlMRUQQAiLoAwoaT1NQb2xpY3lSZXNvdXJjZUNv
bXBsaWFuY2USMQoVb3NfcG9saWN5X3Jlc291cmNlX2lkGAEgASgJUhJvc1BvbGljeVJlc291
cmNlSWQSZQoMY29uZmlnX3N0ZXBzGAIgAygLMkIuZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFn
ZW50ZW5kcG9pbnQudjEuT1NQb2xpY3lSZXNvdXJjZUNvbmZpZ1N0ZXBSC2NvbmZpZ1N0ZXBz
ElUKBXN0YXRlGAMgASgOMj8uZ29vZ2xlLmNsb3VkLm9zY29uZmlnLmFnZW50ZW5kcG9pbnQu
djEuT1NQb2xpY3lDb21wbGlhbmNlU3RhdGVSBXN0YXRlEokBChRleGVjX3Jlc291cmNlX291
dHB1dBgEIAEoCzJVLmdvb2dsZS5jbG91ZC5vc2NvbmZpZy5hZ2VudGVuZHBvaW50LnYxLk9T
UG9saWN5UmVzb3VyY2VDb21wbGlhbmNlLkV4ZWNSZXNvdXJjZU91dHB1dEgAUhJleGVjUmVz
b3VyY2VPdXRwdXQaQwoSRXhlY1Jlc291cmNlT3V0cHV0Ei0KEmVuZm9yY2VtZW50X291dHB1
dBgCIAEoDFIRZW5mb3JjZW1lbnRPdXRwdXRCCAoGb3V0cHV0KpMBChdPU1BvbGljeUNvbXBs
aWFuY2VTdGF0ZRIqCiZPU19QT0xJQ1lfQ09NUExJQU5DRV9TVEFURV9VTlNQRUNJRklFRBAA
Eg0KCUNPTVBMSUFOVBABEhEKDU5PTl9DT01QTElBTlQQAhILCgdVTktOT1dOEAMSHQoZTk9f
T1NfUE9MSUNJRVNfQVBQTElDQUJMRRAEQpMBCipjb20uZ29vZ2xlLmNsb3VkLm9zY29uZmln
LmFnZW50ZW5kcG9pbnQudjFCEUNvbmZpZ0NvbW1vblByb3RvUAFaUGNsb3VkLmdvb2dsZS5j
b20vZ28vb3Njb25maWcvYWdlbnRlbmRwb2ludC9hcGl2MS9hZ2VudGVuZHBvaW50cGI7YWdl
bnRlbmRwb2ludHBiSp4cCgYSBA4AdAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBH
b29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9u
IDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2Vw
dCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNv
cHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vu
c2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9y
IGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhl
IExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQg
V0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBv
ciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2Ug
Z292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vu
c2UuCgoICgECEgMQAC8KCAoBCBIDEgBnCgkKAggLEgMSAGcKCAoBCBIDEwAiCgkKAggKEgMT
ACIKCAoBCBIDFAAyCgkKAggIEgMUADIKCAoBCBIDFQBDCgkKAggBEgMVAEMKcAoCBAASBBkA
RwEaZCBTdGVwIHBlcmZvcm1lZCBieSB0aGUgT1MgQ29uZmlnIGFnZW50IGZvciBjb25maWd1
cmluZyBhbiBgT1NQb2xpY3lSZXNvdXJjZWAKIHRvIGl0cyBkZXNpcmVkIHN0YXRlLgoKCgoD
BAABEgMZCCIKMgoEBAAEABIEGwIwAxokIFN1cHBvcnRlZCBjb25maWd1cmF0aW9uIHN0ZXAg
dHlwZXMKCgwKBQQABAABEgMbBwsKNQoGBAAEAAIAEgMdBBkaJiBEZWZhdWx0IHZhbHVlLiBU
aGlzIHZhbHVlIGlzIHVudXNlZC4KCg4KBwQABAACAAESAx0EFAoOCgcEAAQAAgACEgMdFxgK
TQoGBAAEAAIBEgMgBBMaPiBWYWxpZGF0aW9uIHRvIGRldGVjdCByZXNvdXJjZSBjb25mbGlj
dHMsIHNjaGVtYSBlcnJvcnMsIGV0Yy4KCg4KBwQABAACAQESAyAEDgoOCgcEAAQAAgECEgMg
ERIKSAoGBAAEAAICEgMjBBwaOSBDaGVjayB0aGUgY3VycmVudCBkZXNpcmVkIHN0YXRlIHN0
YXR1cyBvZiB0aGUgcmVzb3VyY2UuCgoOCgcEAAQAAgIBEgMjBBcKDgoHBAAEAAICAhIDIxob
ClUKBgQABAACAxIDJgQiGkYgQXBwbHkgdGhlIGRlc2lyZWQgc3RhdGUgZm9yIGEgcmVzb3Vy
Y2UgdGhhdCBpcyBub3QgaW4gZGVzaXJlZCBzdGF0ZS4KCg4KBwQABAACAwESAyYEHQoOCgcE
AAQAAgMCEgMmICEK/QIKBgQABAACBBIDLwQtGu0CIFJlLWNoZWNrIGRlc2lyZWQgc3RhdGUg
c3RhdHVzIGZvciBhIHJlc291cmNlIGFmdGVyIGFwcGx5aW5nIGFsbAogcmVzb3VyY2VzIGlu
IHRoZSBjdXJyZW50IGNvbmZpZ3VyYXRpb24gcnVuLgoKIFRoaXMgc3RlcCBpcyB1c2VkIHRv
IGRldGVybWluZSB0aGUgZmluYWwgZGVzaXJlZCBzdGF0ZSBzdGF0dXMgZm9yIHRoZQogcmVz
b3VyY2UuIEl0IGFjY291bnRzIGZvciBhbnkgcmVzb3VyY2VzIHRoYXQgbWlnaHQgaGF2ZSBk
cmlmdGVkIGZyb20KIHRoZWlyIGRlc2lyZWQgc3RhdGUgZHVlIHRvIHNpZGUgZWZmZWN0cyBm
cm9tIGNvbmZpZ3VyaW5nIG90aGVyIHJlc291cmNlcwogZHVyaW5nIHRoZSBjdXJyZW50IGNv
bmZpZ3VyYXRpb24gcnVuLgoKDgoHBAAEAAIEARIDLwQoCg4KBwQABAACBAISAy8rLAo8CgQE
AAQBEgQzAjwDGi4gU3VwcG9ydGVkIG91dGNvbWVzIGZvciBhIGNvbmZpZ3VyYXRpb24gc3Rl
cC4KCgwKBQQABAEBEgMzBw4KNQoGBAAEAQIAEgM1BBwaJiBEZWZhdWx0IHZhbHVlLiBUaGlz
IHZhbHVlIGlzIHVudXNlZC4KCg4KBwQABAECAAESAzUEFwoOCgcEAAQBAgACEgM1GhsKJAoG
BAAEAQIBEgM4BBIaFSBUaGUgc3RlcCBzdWNjZWVkZWQuCgoOCgcEAAQBAgEBEgM4BA0KDgoH
BAAEAQIBAhIDOBARCiEKBgQABAECAhIDOwQPGhIgVGhlIHN0ZXAgZmFpbGVkLgoKDgoHBAAE
AQICARIDOwQKCg4KBwQABAECAgISAzsNDgonCgQEAAIAEgM/AhAaGiBDb25maWd1cmF0aW9u
IHN0ZXAgdHlwZS4KCgwKBQQAAgAGEgM/AgYKDAoFBAACAAESAz8HCwoMCgUEAAIAAxIDPw4P
CjEKBAQAAgESA0ICFhokIE91dGNvbWUgb2YgdGhlIGNvbmZpZ3VyYXRpb24gc3RlcC4KCgwK
BQQAAgEGEgNCAgkKDAoFBAACAQESA0IKEQoMCgUEAAIBAxIDQhQVCnMKBAQAAgISA0YCGxpm
IEFuIGVycm9yIG1lc3NhZ2UgcmVjb3JkZWQgZHVyaW5nIHRoZSBleGVjdXRpb24gb2YgdGhp
cyBzdGVwLgogT25seSBwb3B1bGF0ZWQgd2hlbiBvdXRjb21lIGlzIEZBSUxFRC4KCgwKBQQA
AgIFEgNGAggKDAoFBAACAgESA0YJFgoMCgUEAAICAxIDRhkaCjgKAgQBEgRKAGEBGiwgQ29t
cGxpYW5jZSBkYXRhIGZvciBhbiBPUyBwb2xpY3kgcmVzb3VyY2UuCgoKCgMEAQESA0oIIgot
CgQEAQMAEgRMAlADGh8gRXhlY1Jlc291cmNlIHNwZWNpZmljIG91dHB1dC4KCgwKBQQBAwAB
EgNMChwKawoGBAEDAAIAEgNPBCEaXCBPdXRwdXQgZnJvbSBFbmZvcmNlbWVudCBwaGFzZSBv
dXRwdXQgZmlsZSAoaWYgcnVuKS4KIE91dHB1dCBzaXplIGlzIGxpbWl0ZWQgdG8gMTAwSyBi
eXRlcy4KCg4KBwQBAwACAAUSA08ECQoOCgcEAQMAAgABEgNPChwKDgoHBAEDAAIAAxIDTx8g
CjAKBAQBAgASA1MCIxojIFRoZSBpZCBvZiB0aGUgT1MgcG9saWN5IHJlc291cmNlLgoKDAoF
BAECAAUSA1MCCAoMCgUEAQIAARIDUwkeCgwKBQQBAgADEgNTISIKYgoEBAECARIDVwI3GlUg
T3JkZXJlZCBsaXN0IG9mIGNvbmZpZ3VyYXRpb24gc3RlcHMgdGFrZW4gYnkgdGhlIGFnZW50
IGZvciB0aGUgT1MgcG9saWN5CiByZXNvdXJjZS4KCgwKBQQBAgEEEgNXAgoKDAoFBAECAQYS
A1cLJQoMCgUEAQIBARIDVyYyCgwKBQQBAgEDEgNXNTYKOgoEBAECAhIDWgIkGi0gQ29tcGxp
YW5jZSBzdGF0ZSBvZiB0aGUgT1MgcG9saWN5IHJlc291cmNlLgoKDAoFBAECAgYSA1oCGQoM
CgUEAQICARIDWhofCgwKBQQBAgIDEgNaIiMKKQoEBAEIABIEXQJgAxobIFJlc291cmNlIHNw
ZWNpZmljIG91dHB1dC4KCgwKBQQBCAABEgNdCA4KLAoEBAECAxIDXwQwGh8gRXhlY1Jlc291
cmNlIHNwZWNpZmljIG91dHB1dC4KCgwKBQQBAgMGEgNfBBYKDAoFBAECAwESA18XKwoMCgUE
AQIDAxIDXy4vCjMKAgUAEgRkAHQBGicgU3VwcG9ydGVkIE9TUG9saWN5IGNvbXBsaWFuY2Ug
c3RhdGVzLgoKCgoDBQABEgNkBRwKMwoEBQACABIDZgItGiYgRGVmYXVsdCB2YWx1ZS4gVGhp
cyB2YWx1ZSBpcyB1bnVzZWQuCgoMCgUFAAIAARIDZgIoCgwKBQUAAgACEgNmKywKHwoEBQAC
ARIDaQIQGhIgQ29tcGxpYW50IHN0YXRlLgoKDAoFBQACAQESA2kCCwoMCgUFAAIBAhIDaQ4P
CiIKBAUAAgISA2wCFBoVIE5vbi1jb21wbGlhbnQgc3RhdGUKCgwKBQUAAgIBEgNsAg8KDAoF
BQACAgISA2wSEwooCgQFAAIDEgNvAg4aGyBVbmtub3duIGNvbXBsaWFuY2Ugc3RhdGUuCgoM
CgUFAAIDARIDbwIJCgwKBQUAAgMCEgNvDA0KdQoEBQACBBIDcwIgGmggTm8gYXBwbGljYWJs
ZSBPUyBwb2xpY2llcyB3ZXJlIGZvdW5kIGZvciB0aGUgaW5zdGFuY2UuCiBUaGlzIHN0YXRl
IGlzIG9ubHkgYXBwbGljYWJsZSB0byB0aGUgaW5zdGFuY2UuCgoMCgUFAAIEARIDcwIbCgwK
BQUAAgQCEgNzHh9iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon::OSPolicyResourceConfigStep ===
    # Fields for OSPolicyResourceConfigStep
    # Field: type Type: 14 (.google.cloud.osconfig.agentendpoint.v1.OSPolicyResourceConfigStep.Type)
    # Field: outcome Type: 14 (.google.cloud.osconfig.agentendpoint.v1.OSPolicyResourceConfigStep.Outcome)
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

# === Message: Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon::OSPolicyResourceCompliance ===
    # Fields for OSPolicyResourceCompliance
    # Field: os_policy_resource_id Type: 9 ()
    # Field: config_steps Type: 11 (.google.cloud.osconfig.agentendpoint.v1.OSPolicyResourceConfigStep)
    # Field: state Type: 14 (.google.cloud.osconfig.agentendpoint.v1.OSPolicyComplianceState)
    # Field: exec_resource_output Type: 11 (.google.cloud.osconfig.agentendpoint.v1.OSPolicyResourceCompliance.ExecResourceOutput)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon - Compiled Protocol Buffers messages for google/cloud/osconfig/agentendpoint/v1/config_common.proto

=head1 SYNOPSIS

    use Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon;

    my $msg = Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon::OSPolicyResourceConfigStep->new({
        type => $type,
        outcome => $outcome,
        error_message => $error_message,
    });

    # Read or update a field
    my $val = $msg->type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon::OSPolicyResourceConfigStep->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/osconfig/agentendpoint/v1/config_common.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon::OSPolicyResourceConfigStep

Step performed by the OS Config agent for configuring an `OSPolicyResource`
to its desired state.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::OSPolicyResourceConfigStep::Type>)

Configuration step type.

=item * C<< $msg->outcome() >> / C<< $msg->outcome($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::OSPolicyResourceConfigStep::Outcome>)

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

=head2 Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon::OSPolicyResourceCompliance

Compliance data for an OS policy resource.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->os_policy_resource_id() >> / C<< $msg->os_policy_resource_id($value) >>

Type: C<String>

The id of the OS policy resource.

=item * C<< $msg->config_steps() >> / C<< $msg->config_steps($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon::OSPolicyResourceConfigStep>)

Ordered list of configuration steps taken by the agent for the OS policy
resource.

=item * C<< $msg->state() >> / C<< $msg->state($value) >>

Type: C<Enum> (L<Google::Cloud::Osconfig::Agentendpoint::V1::OSPolicyComplianceState>)

Compliance state of the OS policy resource.

=item * C<< $msg->exec_resource_output() >> / C<< $msg->exec_resource_output($value) >>

Type: C<Message> (L<Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon::OSPolicyResourceCompliance::ExecResourceOutput>)

ExecResource specific output.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Osconfig::Agentendpoint::V1::ConfigCommon::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
