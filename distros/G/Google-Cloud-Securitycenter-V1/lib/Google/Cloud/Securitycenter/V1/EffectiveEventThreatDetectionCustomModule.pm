package Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule;

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
    eval { require Google::Protobuf::Struct };
    my $descriptor_b64 = <<'EOF';
ClNnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvZWZmZWN0aXZlX2V2ZW50X3RocmVh
dF9kZXRlY3Rpb25fY3VzdG9tX21vZHVsZS5wcm90bxIeZ29vZ2xlLmNsb3VkLnNlY3VyaXR5
Y2VudGVyLnYxGh9nb29nbGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBp
L3Jlc291cmNlLnByb3RvGhxnb29nbGUvcHJvdG9idWYvc3RydWN0LnByb3RvIokGCilFZmZl
Y3RpdmVFdmVudFRocmVhdERldGVjdGlvbkN1c3RvbU1vZHVsZRIXCgRuYW1lGAEgASgJQgPg
QQNSBG5hbWUSNAoGY29uZmlnGAIgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdEID4EED
UgZjb25maWcSiQEKEGVuYWJsZW1lbnRfc3RhdGUYAyABKA4yWS5nb29nbGUuY2xvdWQuc2Vj
dXJpdHljZW50ZXIudjEuRWZmZWN0aXZlRXZlbnRUaHJlYXREZXRlY3Rpb25DdXN0b21Nb2R1
bGUuRW5hYmxlbWVudFN0YXRlQgPgQQNSD2VuYWJsZW1lbnRTdGF0ZRIXCgR0eXBlGAQgASgJ
QgPgQQNSBHR5cGUSJgoMZGlzcGxheV9uYW1lGAUgASgJQgPgQQNSC2Rpc3BsYXlOYW1lEiUK
C2Rlc2NyaXB0aW9uGAYgASgJQgPgQQNSC2Rlc2NyaXB0aW9uIk4KD0VuYWJsZW1lbnRTdGF0
ZRIgChxFTkFCTEVNRU5UX1NUQVRFX1VOU1BFQ0lGSUVEEAASCwoHRU5BQkxFRBABEgwKCERJ
U0FCTEVEEAI6yALqQcQCCkdzZWN1cml0eWNlbnRlci5nb29nbGVhcGlzLmNvbS9FZmZlY3Rp
dmVFdmVudFRocmVhdERldGVjdGlvbkN1c3RvbU1vZHVsZRJZb3JnYW5pemF0aW9ucy97b3Jn
YW5pemF0aW9ufS9ldmVudFRocmVhdERldGVjdGlvblNldHRpbmdzL2VmZmVjdGl2ZUN1c3Rv
bU1vZHVsZXMve21vZHVsZX0STWZvbGRlcnMve2ZvbGRlcn0vZXZlbnRUaHJlYXREZXRlY3Rp
b25TZXR0aW5ncy9lZmZlY3RpdmVDdXN0b21Nb2R1bGVzL3ttb2R1bGV9Ek9wcm9qZWN0cy97
cHJvamVjdH0vZXZlbnRUaHJlYXREZXRlY3Rpb25TZXR0aW5ncy9lZmZlY3RpdmVDdXN0b21N
b2R1bGVzL3ttb2R1bGV9QogCCiJjb20uZ29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYx
Qi5FZmZlY3RpdmVFdmVudFRocmVhdERldGVjdGlvbkN1c3RvbU1vZHVsZVByb3RvUAFaSmNs
b3VkLmdvb2dsZS5jb20vZ28vc2VjdXJpdHljZW50ZXIvYXBpdjEvc2VjdXJpdHljZW50ZXJw
YjtzZWN1cml0eWNlbnRlcnBiqgIeR29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYxygIe
R29vZ2xlXENsb3VkXFNlY3VyaXR5Q2VudGVyXFYx6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJp
dHlDZW50ZXI6OlYxSuMXCgYSBA4AVAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBH
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
c2UuCgoICgECEgMQACcKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUACYKCAoBCBID
FgA7CgkKAgglEgMWADsKCAoBCBIDFwBhCgkKAggLEgMXAGEKCAoBCBIDGAAiCgkKAggKEgMY
ACIKCAoBCBIDGQBPCgkKAggIEgMZAE8KCAoBCBIDGgA7CgkKAggBEgMaADsKCAoBCBIDGwA7
CgkKAggpEgMbADsKCAoBCBIDHAA6CgkKAggtEgMcADoKqQUKAgQAEgQnAFQBGpwFIEFuIEVm
ZmVjdGl2ZUV2ZW50VGhyZWF0RGV0ZWN0aW9uQ3VzdG9tTW9kdWxlIGlzIHRoZSByZXByZXNl
bnRhdGlvbiBvZgogYW4gRXZlbnQgVGhyZWF0IERldGVjdGlvbiBjdXN0b20gbW9kdWxlIGF0
IGEgc3BlY2lmaWVkIGxldmVsIG9mIHRoZQogcmVzb3VyY2UgaGllcmFyY2h5OiBvcmdhbml6
YXRpb24sIGZvbGRlciwgb3IgcHJvamVjdC4gSWYgYSBjdXN0b20gbW9kdWxlIGlzCiBpbmhl
cml0ZWQgZnJvbSBhIHBhcmVudCBvcmdhbml6YXRpb24gb3IgZm9sZGVyLCB0aGUgdmFsdWUg
b2YgdGhlCiBgZW5hYmxlbWVudF9zdGF0ZWAgcHJvcGVydHkgaW4gRWZmZWN0aXZlRXZlbnRU
aHJlYXREZXRlY3Rpb25DdXN0b21Nb2R1bGUgaXMKIHNldCB0byB0aGUgdmFsdWUgdGhhdCBp
cyBlZmZlY3RpdmUgaW4gdGhlIHBhcmVudCwgaW5zdGVhZCBvZiBgSU5IRVJJVEVEYC4KIEZv
ciBleGFtcGxlLCBpZiB0aGUgbW9kdWxlIGlzIGVuYWJsZWQgaW4gYSBwYXJlbnQgb3JnYW5p
emF0aW9uIG9yIGZvbGRlciwgdGhlCiBlZmZlY3RpdmUgYGVuYWJsZW1lbnRfc3RhdGVgIGZv
ciB0aGUgbW9kdWxlIGluIGFsbCBjaGlsZCBmb2xkZXJzIG9yIHByb2plY3RzCiBpcyBhbHNv
IGBlbmFibGVkYC4gRWZmZWN0aXZlRXZlbnRUaHJlYXREZXRlY3Rpb25DdXN0b21Nb2R1bGUg
aXMgcmVhZC1vbmx5LgoKCgoDBAABEgMnCDEKCwoDBAAHEgQoAi0ECg0KBQQAB50IEgQoAi0E
CjMKBAQABAASBDACOQMaJSBUaGUgZW5hYmxlbWVudCBzdGF0ZSBvZiB0aGUgbW9kdWxlLgoK
DAoFBAAEAAESAzAHFgouCgYEAAQAAgASAzIEJRofIFVuc3BlY2lmaWVkIGVuYWJsZW1lbnQg
c3RhdGUuCgoOCgcEAAQAAgABEgMyBCAKDgoHBAAEAAIAAhIDMiMkCjoKBgQABAACARIDNQQQ
GisgVGhlIG1vZHVsZSBpcyBlbmFibGVkIGF0IHRoZSBnaXZlbiBsZXZlbC4KCg4KBwQABAAC
AQESAzUECwoOCgcEAAQAAgECEgM1Dg8KOwoGBAAEAAICEgM4BBEaLCBUaGUgbW9kdWxlIGlz
IGRpc2FibGVkIGF0IHRoZSBnaXZlbiBsZXZlbC4KCg4KBwQABAACAgESAzgEDAoOCgcEAAQA
AgICEgM4DxAK9AIKBAQAAgASA0ICPhrmAiBPdXRwdXQgb25seS4gVGhlIHJlc291cmNlIG5h
bWUgb2YgdGhlIGVmZmVjdGl2ZSBFVEQgY3VzdG9tIG1vZHVsZS4KCiBJdHMgZm9ybWF0IGlz
OgoKICAgKiBgb3JnYW5pemF0aW9ucy97b3JnYW5pemF0aW9ufS9ldmVudFRocmVhdERldGVj
dGlvblNldHRpbmdzL2VmZmVjdGl2ZUN1c3RvbU1vZHVsZXMve21vZHVsZX1gLgogICAqIGBm
b2xkZXJzL3tmb2xkZXJ9L2V2ZW50VGhyZWF0RGV0ZWN0aW9uU2V0dGluZ3MvZWZmZWN0aXZl
Q3VzdG9tTW9kdWxlcy97bW9kdWxlfWAuCiAgICogYHByb2plY3RzL3twcm9qZWN0fS9ldmVu
dFRocmVhdERldGVjdGlvblNldHRpbmdzL2VmZmVjdGl2ZUN1c3RvbU1vZHVsZXMve21vZHVs
ZX1gLgoKDAoFBAACAAUSA0ICCAoMCgUEAAIAARIDQgkNCgwKBQQAAgADEgNCEBEKDAoFBAAC
AAgSA0ISPQoPCggEAAIACJwIABIDQhM8CjwKBAQAAgESA0UCUBovIE91dHB1dCBvbmx5LiBD
b25maWcgZm9yIHRoZSBlZmZlY3RpdmUgbW9kdWxlLgoKDAoFBAACAQYSA0UCGAoMCgUEAAIB
ARIDRRkfCgwKBQQAAgEDEgNFIiMKDAoFBAACAQgSA0UkTwoPCggEAAIBCJwIABIDRSVOCnMK
BAQAAgISBEkCSjIaZSBPdXRwdXQgb25seS4gVGhlIGVmZmVjdGl2ZSBzdGF0ZSBvZiBlbmFi
bGVtZW50IGZvciB0aGUgbW9kdWxlIGF0IHRoZSBnaXZlbgogbGV2ZWwgb2YgdGhlIGhpZXJh
cmNoeS4KCgwKBQQAAgIGEgNJAhEKDAoFBAACAgESA0kSIgoMCgUEAAICAxIDSSUmCgwKBQQA
AgIIEgNKBjEKDwoIBAACAgicCAASA0oHMApKCgQEAAIDEgNNAj4aPSBPdXRwdXQgb25seS4g
VHlwZSBmb3IgdGhlIG1vZHVsZS4gZS5nLiBDT05GSUdVUkFCTEVfQkFEX0lQLgoKDAoFBAAC
AwUSA00CCAoMCgUEAAIDARIDTQkNCgwKBQQAAgMDEgNNEBEKDAoFBAACAwgSA00SPQoPCggE
AAIDCJwIABIDTRM8ClMKBAQAAgQSA1ACRhpGIE91dHB1dCBvbmx5LiBUaGUgaHVtYW4gcmVh
ZGFibGUgbmFtZSB0byBiZSBkaXNwbGF5ZWQgZm9yIHRoZSBtb2R1bGUuCgoMCgUEAAIEBRID
UAIICgwKBQQAAgQBEgNQCRUKDAoFBAACBAMSA1AYGQoMCgUEAAIECBIDUBpFCg8KCAQAAgQI
nAgAEgNQG0QKOwoEBAACBRIDUwJFGi4gT3V0cHV0IG9ubHkuIFRoZSBkZXNjcmlwdGlvbiBm
b3IgdGhlIG1vZHVsZS4KCgwKBQQAAgUFEgNTAggKDAoFBAACBQESA1MJFAoMCgUEAAIFAxID
UxcYCgwKBQQAAgUIEgNTGUQKDwoIBAACBQicCAASA1MaQ2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule ===
    # Fields for EffectiveEventThreatDetectionCustomModule
    # Field: name Type: 9 ()
    # Field: config Type: 11 (.google.protobuf.Struct)
    # Field: enablement_state Type: 14 (.google.cloud.securitycenter.v1.EffectiveEventThreatDetectionCustomModule.EnablementState)
    # Field: type Type: 9 ()
    # Field: display_name Type: 9 ()
    # Field: description Type: 9 ()

# Enum: EffectiveEventThreatDetectionCustomModule::EnablementState
our $EffectiveEventThreatDetectionCustomModule_ENABLEMENT_STATE_UNSPECIFIED = 0;
our $EffectiveEventThreatDetectionCustomModule_ENABLED = 1;
our $EffectiveEventThreatDetectionCustomModule_DISABLED = 2;

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/effective_event_threat_detection_custom_module.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule;

    my $msg = Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule->new({
        name => $name,
        config => $config,
        enablement_state => $enablement_state,
        type => $type,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/effective_event_threat_detection_custom_module.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EffectiveEventThreatDetectionCustomModule

An EffectiveEventThreatDetectionCustomModule is the representation of
an Event Threat Detection custom module at a specified level of the
resource hierarchy: organization, folder, or project. If a custom module is
inherited from a parent organization or folder, the value of the
`enablement_state` property in EffectiveEventThreatDetectionCustomModule is
set to the value that is effective in the parent, instead of `INHERITED`.
For example, if the module is enabled in a parent organization or folder, the
effective `enablement_state` for the module in all child folders or projects
is also `enabled`. EffectiveEventThreatDetectionCustomModule is read-only.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Output only. The resource name of the effective ETD custom module.

Its format is:

  * `organizations/{organization}/eventThreatDetectionSettings/effectiveCustomModules/{module}`.
  * `folders/{folder}/eventThreatDetectionSettings/effectiveCustomModules/{module}`.
  * `projects/{project}/eventThreatDetectionSettings/effectiveCustomModules/{module}`.

=item * C<< $msg->config() >> / C<< $msg->config($value) >>

Type: C<Message> (L<Google::Protobuf::Struct::Struct>)

Output only. Config for the effective module.

=item * C<< $msg->enablement_state() >> / C<< $msg->enablement_state($value) >>

Type: C<Enum> (L<Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::EnablementState>)

Output only. The effective state of enablement for the module at the given
level of the hierarchy.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<String>

Output only. Type for the module. e.g. CONFIGURABLE_BAD_IP.

=item * C<< $msg->display_name() >> / C<< $msg->display_name($value) >>

Type: C<String>

Output only. The human readable name to be displayed for the module.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Output only. The description for the module.

=back

=head3 Enum: EffectiveEventThreatDetectionCustomModule::EnablementState

=over 4

=item * C<ENABLEMENT_STATE_UNSPECIFIED> => C<0>

=item * C<ENABLED> => C<1>

=item * C<DISABLED> => C<2>

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::EffectiveEventThreatDetectionCustomModule::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
