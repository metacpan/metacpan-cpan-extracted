package Google::Compute::Logging::Agentcontrolplane::V1::Logs;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CjZnb29nbGUvY29tcHV0ZS9sb2dnaW5nL2FnZW50Y29udHJvbHBsYW5lL3YxL2xvZ3MucHJv
dG8SK2dvb2dsZS5jb21wdXRlLmxvZ2dpbmcuYWdlbnRjb250cm9scGxhbmUudjEaH2dvb2ds
ZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8iggQKEFZtRXh0ZW5zaW9uRXZlbnQSOAoJdGlt
ZXN0YW1wGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFIJdGltZXN0YW1wEm8K
CmV2ZW50X3R5cGUYAiABKA4yUC5nb29nbGUuY29tcHV0ZS5sb2dnaW5nLmFnZW50Y29udHJv
bHBsYW5lLnYxLlZtRXh0ZW5zaW9uRXZlbnQuRXh0ZW5zaW9uRXZlbnRUeXBlUglldmVudFR5
cGUSJQoOZXh0ZW5zaW9uX25hbWUYAyABKAlSDWV4dGVuc2lvbk5hbWUSGwoJcG9saWN5X2lk
GAQgASgJUghwb2xpY3lJZBIfCgtyZXZpc2lvbl9pZBgFIAEoCVIKcmV2aXNpb25JZBIjCg1l
dmVudF9tZXNzYWdlGAYgASgJUgxldmVudE1lc3NhZ2UiuAEKEkV4dGVuc2lvbkV2ZW50VHlw
ZRIkCiBFWFRFTlNJT05fRVZFTlRfVFlQRV9VTlNQRUNJRklFRBAAEgsKB0NSQVNIRUQQARIS
Cg5JTlNUQUxMX0ZBSUxFRBACEg0KCUlOU1RBTExFRBADEhMKD1JPTExCQUNLX0ZBSUxFRBAE
Eg8KC1JPTExFRF9CQUNLEAUSEAoMSU5DT01QQVRJQkxFEAYSFAoQU0VSVklDRV9ESVNBQkxF
RBAHQqoCCi9jb20uZ29vZ2xlLmNvbXB1dGUubG9nZ2luZy5hZ2VudGNvbnRyb2xwbGFuZS52
MUIJTG9nc1Byb3RvUAFaXGdvb2dsZS5nb2xhbmcub3JnL2dlbnByb3RvL2dvb2dsZWFwaXMv
Y29tcHV0ZS9sb2dnaW5nL2FnZW50Y29udHJvbHBsYW5lL3YxO2FnZW50Y29udHJvbHBsYW5l
qgIrR29vZ2xlLkNvbXB1dGUuTG9nZ2luZy5BZ2VudENvbnRyb2xQbGFuZS5WMcoCK0dvb2ds
ZVxDb21wdXRlXExvZ2dpbmdcQWdlbnRDb250cm9sUGxhbmVcVjHqAi9Hb29nbGU6OkNvbXB1
dGU6OkxvZ2dpbmc6OkFnZW50Q29udHJvbFBsYW5lOjpWMUqeFgoGEgQOAFQBCrwECgEMEgMO
ABIysQQgQ29weXJpZ2h0IDIwMjYgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBB
cGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBu
b3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNl
LgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6
Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJl
ZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUK
IGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJB
UyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkg
S0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3Ig
dGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0
YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAA0CgkKAgMAEgMSACkKCAoBCBID
FABICgkKAgglEgMUAEgKCAoBCBIDFQBzCgkKAggLEgMVAHMKCAoBCBIDFgAiCgkKAggKEgMW
ACIKCAoBCBIDFwAqCgkKAggIEgMXACoKCAoBCBIDGABICgkKAggBEgMYAEgKCAoBCBIDGQBJ
CgkKAggpEgMZAEkKCAoBCBIDGgBICgkKAggtEgMaAEgKsgEKAgQAEgQgAFQBGlsgTG9nIG1l
c3NhZ2UgdXNlZCB0byBzZW5kIFBsYXRmb3JtIExvZ2dpbmcgZm9yIGNyaXRpY2FsIGV2ZW50
cyBpbiBWTSBFeHRlbnNpb24KIGxpZmVjeWNsZS4KMkkgVGhpcyBmaWxlIGRlZmluZXMgdGhl
IGZvcm1hdCBvZiBDbG91ZCBBZ2VudCBDb250cm9sIFBsYW5lIExvZ2dpbmcgTG9ncy4KCgoK
AwQAARIDIAgYClkKBAQABAASBCICPgMaSyBFbnVtIGZvciB0aGUgdHlwZXMgb2YgZXZlbnRz
IHRoYXQgYXJlIGNyaXRpY2FsIGluIFZNIEV4dGVuc2lvbiBsaWZlY3ljbGUuCgoMCgUEAAQA
ARIDIgcZCkEKBgQABAACABIDJAQpGjIgVW5zcGVjaWZpZWQgZXZlbnQgdHlwZSwgdXNlZCBh
cyBhIGRlZmF1bHQgdmFsdWUuCgoOCgcEAAQAAgABEgMkBCQKDgoHBAAEAAIAAhIDJCcoCqUB
CgYEAAQAAgESAykEEBqVASBFdmVudCBpbmRpY2F0aW5nIHRoYXQgdGhlIGV4dGVuc2lvbiBo
YXMgY3Jhc2hlZC4KIFRoaXMgaW5kaWNhdGVzIHRoYXQgdGhlIGV4dGVuc2lvbiB3YXMgb25j
ZSBpbnN0YWxsZWQgYW5kIHN0YXJ0ZWQKIHN1Y2Nlc3NmdWxseSwgYnV0IHRoZW4gY3Jhc2hl
ZC4KCg4KBwQABAACAQESAykECwoOCgcEAAQAAgECEgMpDg8KSAoGBAAEAAICEgMsBBcaOSBF
dmVudCBpbmRpY2F0aW5nIHRoYXQgdGhlIGV4dGVuc2lvbiBpbnN0YWxsIGhhcyBmYWlsZWQu
CgoOCgcEAAQAAgIBEgMsBBIKDgoHBAAEAAICAhIDLBUWClwKBgQABAACAxIDMAQSGk0gRXZl
bnQgaW5kaWNhdGluZyB0aGF0IHRoZSBleHRlbnNpb24gaXMgaW5zdGFsbGVkIGFuZCBzdGFy
dGVkCiBzdWNjZXNzZnVsbHkuCgoOCgcEAAQAAgMBEgMwBA0KDgoHBAAEAAIDAhIDMBARCkkK
BgQABAACBBIDMwQYGjogRXZlbnQgaW5kaWNhdGluZyB0aGF0IHRoZSBleHRlbnNpb24gcm9s
bGJhY2sgaGFzIGZhaWxlZC4KCg4KBwQABAACBAESAzMEEwoOCgcEAAQAAgQCEgMzFhcKTAoG
BAAEAAIFEgM2BBQaPSBFdmVudCBpbmRpY2F0aW5nIHRoYXQgdGhlIGV4dGVuc2lvbiByb2xs
YmFjayBoYXMgc3VjY2VlZGVkLgoKDgoHBAAEAAIFARIDNgQPCg4KBwQABAACBQISAzYSEwqh
AQoGBAAEAAIGEgM6BBUakQEgRXZlbnQgaW5kaWNhdGluZyB0aGF0IG5vbmUgb2YgdGhlIGV4
dGVuc2lvbiByZXZpc2lvbiBjYW5kaWRhdGVzIHNhdGlzZmllcwogdGhlIGluc3RhbGwgcmVx
dWlyZW1lbnRzLCBlLmcuIG9wZXJhdGluZyBzeXN0ZW0gYW5kL29yIGFyY2hpdGVjdHVyZS4K
Cg4KBwQABAACBgESAzoEEAoOCgcEAAQAAgYCEgM6ExQKQgoGBAAEAAIHEgM9BBkaMyBUaGUg
c2VydmljZSByZXF1aXJpbmcgdGhpcyBleHRlbnNpb24gaXMgZGlzYWJsZWQuCgoOCgcEAAQA
AgcBEgM9BBQKDgoHBAAEAAIHAhIDPRcYCh8KBAQAAgASA0ECKhoSIEV2ZW50IHRpbWVzdGFt
cC4KCgwKBQQAAgAGEgNBAhsKDAoFBAACAAESA0EcJQoMCgUEAAIAAxIDQSgpCkgKBAQAAgES
A0QCJBo7IFR5cGUgb2YgZXZlbnQgdGhhdCBpcyBjcml0aWNhbCBpbiBWTSBFeHRlbnNpb24g
bGlmZWN5Y2xlLgoKDAoFBAACAQYSA0QCFAoMCgUEAAIBARIDRBUfCgwKBQQAAgEDEgNEIiMK
KAoEBAACAhIDRwIcGhsgTmFtZSBvZiB0aGUgVk0gZXh0ZW5zaW9uLgoKDAoFBAACAgUSA0cC
CAoMCgUEAAICARIDRwkXCgwKBQQAAgIDEgNHGhsK8AEKBAQAAgMSA00CFxriASBQb2xpY3kg
SUQgdGhhdCBpcyBhc3NvY2lhdGVkIHdpdGggdGhpcyBWTSBleHRlbnNpb24gZXZlbnQgaWYg
YXBwbGljYWJsZS4KIEZvcm1hdDoKIHByb2plY3RzL3twcm9qZWN0fS96b25lcy97em9uZX0v
dm1FeHRlbnNpb25Qb2xpY2llcy97dm1FeHRlbnNpb25Qb2xpY3l9IG9yCiBwcm9qZWN0cy97
cHJvamVjdH0vZ2xvYmFsL3ZtRXh0ZW5zaW9uUG9saWNpZXMve3ZtRXh0ZW5zaW9uUG9saWN5
fQoKDAoFBAACAwUSA00CCAoMCgUEAAIDARIDTQkSCgwKBQQAAgMDEgNNFRYKLwoEBAACBBID
UAIZGiIgUmV2aXNpb24gSUQgb2YgdGhlIFZNIGV4dGVuc2lvbi4KCgwKBQQAAgQFEgNQAggK
DAoFBAACBAESA1AJFAoMCgUEAAIEAxIDUBcYCjoKBAQAAgUSA1MCGxotIE1lc3NhZ2UgdGhh
dCBkZXNjcmliZXMgdGhlIGV2ZW50IGluIGRldGFpbC4KCgwKBQQAAgUFEgNTAggKDAoFBAAC
BQESA1MJFgoMCgUEAAIFAxIDUxkaYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Compute::Logging::Agentcontrolplane::V1::Logs::VmExtensionEvent ===
    # Fields for VmExtensionEvent
    # Field: timestamp Type: 11 (.google.protobuf.Timestamp)
    # Field: event_type Type: 14 (.google.compute.logging.agentcontrolplane.v1.VmExtensionEvent.ExtensionEventType)
    # Field: extension_name Type: 9 ()
    # Field: policy_id Type: 9 ()
    # Field: revision_id Type: 9 ()
    # Field: event_message Type: 9 ()

# Enum: VmExtensionEvent::ExtensionEventType
our $VmExtensionEvent_EXTENSION_EVENT_TYPE_UNSPECIFIED = 0;
our $VmExtensionEvent_CRASHED = 1;
our $VmExtensionEvent_INSTALL_FAILED = 2;
our $VmExtensionEvent_INSTALLED = 3;
our $VmExtensionEvent_ROLLBACK_FAILED = 4;
our $VmExtensionEvent_ROLLED_BACK = 5;
our $VmExtensionEvent_INCOMPATIBLE = 6;
our $VmExtensionEvent_SERVICE_DISABLED = 7;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Compute::Logging::Agentcontrolplane::V1::Logs - Compiled Protocol Buffers messages for google/compute/logging/agentcontrolplane/v1/logs.proto

=head1 SYNOPSIS

    use Google::Compute::Logging::Agentcontrolplane::V1::Logs;

    my $msg = Google::Compute::Logging::Agentcontrolplane::V1::Logs::VmExtensionEvent->new({
        timestamp => $timestamp,
        event_type => $event_type,
        extension_name => $extension_name,
        policy_id => $policy_id,
    });

    # Read or update a field
    my $val = $msg->timestamp();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Compute::Logging::Agentcontrolplane::V1::Logs::VmExtensionEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/compute/logging/agentcontrolplane/v1/logs.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Compute::Logging::Agentcontrolplane::V1::Logs::VmExtensionEvent

Log message used to send Platform Logging for critical events in VM Extension
lifecycle.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->timestamp() >> / C<< $msg->timestamp($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

Event timestamp.

=item * C<< $msg->event_type() >> / C<< $msg->event_type($value) >>

Type: C<Enum> (L<Google::Compute::Logging::Agentcontrolplane::V1::VmExtensionEvent::ExtensionEventType>)

Type of event that is critical in VM Extension lifecycle.

=item * C<< $msg->extension_name() >> / C<< $msg->extension_name($value) >>

Type: C<String>

Name of the VM extension.

=item * C<< $msg->policy_id() >> / C<< $msg->policy_id($value) >>

Type: C<String>

Policy ID that is associated with this VM extension event if applicable.
Format:
projects/{project}/zones/{zone}/vmExtensionPolicies/{vmExtensionPolicy} or
projects/{project}/global/vmExtensionPolicies/{vmExtensionPolicy}

=item * C<< $msg->revision_id() >> / C<< $msg->revision_id($value) >>

Type: C<String>

Revision ID of the VM extension.

=item * C<< $msg->event_message() >> / C<< $msg->event_message($value) >>

Type: C<String>

Message that describes the event in detail.

=back

=head3 Enum: VmExtensionEvent::ExtensionEventType

=over 4

=item * C<EXTENSION_EVENT_TYPE_UNSPECIFIED> => C<0>

=item * C<CRASHED> => C<1>

=item * C<INSTALL_FAILED> => C<2>

=item * C<INSTALLED> => C<3>

=item * C<ROLLBACK_FAILED> => C<4>

=item * C<ROLLED_BACK> => C<5>

=item * C<INCOMPATIBLE> => C<6>

=item * C<SERVICE_DISABLED> => C<7>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Compute::Logging::Agentcontrolplane::V1::Logs::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
