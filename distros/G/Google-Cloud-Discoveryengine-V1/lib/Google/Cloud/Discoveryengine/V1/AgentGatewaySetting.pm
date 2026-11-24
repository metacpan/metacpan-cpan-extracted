package Google::Cloud::Discoveryengine::V1::AgentGatewaySetting;

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
    my $descriptor_b64 = <<'EOF';
Cjtnb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxL2FnZW50X2dhdGV3YXlfc2V0dGlu
Zy5wcm90bxIfZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MRofZ29vZ2xlL2FwaS9m
aWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xlL2FwaS9yZXNvdXJjZS5wcm90byKNAgoTQWdl
bnRHYXRld2F5U2V0dGluZxKQAQocZGVmYXVsdF9lZ3Jlc3NfYWdlbnRfZ2F0ZXdheRgBIAEo
CzJKLmdvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjEuQWdlbnRHYXRld2F5U2V0dGlu
Zy5BZ2VudEdhdGV3YXlSZWZlcmVuY2VCA+BBAVIZZGVmYXVsdEVncmVzc0FnZW50R2F0ZXdh
eRpjChVBZ2VudEdhdGV3YXlSZWZlcmVuY2USSgoEbmFtZRgBIAEoCUI24EEC4EEF+kEtCitu
ZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vQWdlbnRHYXRld2F5UgRuYW1lQosCCiNj
b20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MUIYQWdlbnRHYXRld2F5U2V0dGlu
Z1Byb3RvUAFaTWNsb3VkLmdvb2dsZS5jb20vZ28vZGlzY292ZXJ5ZW5naW5lL2FwaXYxL2Rp
c2NvdmVyeWVuZ2luZXBiO2Rpc2NvdmVyeWVuZ2luZXBiogIPRElTQ09WRVJZRU5HSU5FqgIf
R29vZ2xlLkNsb3VkLkRpc2NvdmVyeUVuZ2luZS5WMcoCH0dvb2dsZVxDbG91ZFxEaXNjb3Zl
cnlFbmdpbmVcVjHqAiJHb29nbGU6OkNsb3VkOjpEaXNjb3ZlcnlFbmdpbmU6OlYxSocNCgYS
BA4AOAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5z
ZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNl
Iik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdp
dGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2Ug
YXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgog
VW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0
aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJp
YnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05E
SVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRo
ZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Np
b25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACgKCQoC
AwASAxIAKQoJCgIDARIDEwAjCggKAQgSAxUAPAoJCgIIJRIDFQA8CggKAQgSAxYAZAoJCgII
CxIDFgBkCggKAQgSAxcAIgoJCgIIChIDFwAiCggKAQgSAxgAOQoJCgIICBIDGAA5CggKAQgS
AxkAPAoJCgIIARIDGQA8CggKAQgSAxoALQoJCgIIJBIDGgAtCggKAQgSAxsAPAoJCgIIKRID
GwA8CggKAQgSAxwAOwoJCgIILRIDHAA7Cr0BCgIEABIEIQA4ARqwASBBZ2VudCBHYXRld2F5
IHNldHRpbmcsIHdoaWNoIG1heSBiZSBhdHRhY2hlZCB0byBHZW1pbmkgRW50ZXJwcmlzZSBy
ZXNvdXJjZXMKIGZvciBlZ3Jlc3MgY29udHJvbCBvZiBHZW1pbmkgRW50ZXJwcmlzZSBhZ2Vu
dHMgdG8gYWdlbnRzIGFuZCB0b29scyBvdXRzaWRlIG9mCiBHZW1pbmkgRW50ZXJwcmlzZS4K
CgoKAwQAARIDIQgbCjcKBAQAAwASBCMCLwMaKSBSZWZlcmVuY2UgdG8gYW4gQWdlbnQgR2F0
ZXdheSByZXNvdXJjZS4KCgwKBQQAAwABEgMjCh8KswEKBgQAAwACABIEKAQuBhqiASBSZXF1
aXJlZC4gSW1tdXRhYmxlLiBUaGUgcmVzb3VyY2UgbmFtZSBvZiB0aGUgYWdlbnQgZ2F0ZXdh
eS4KCiBFeHBlY3RlZCBmb3JtYXQ6CiBgcHJvamVjdHMve3Byb2plY3RfbnVtYmVyfS9sb2Nh
dGlvbnMve2xvY2F0aW9ufS9hZ2VudEdhdGV3YXlzL3thZ2VudF9nYXRld2F5fWAuCgoOCgcE
AAMAAgAFEgMoBAoKDgoHBAADAAIAARIDKAsPCg4KBwQAAwACAAMSAygSEwoPCgcEAAMAAgAI
EgQoFC4FChEKCgQAAwACAAicCAASAykGLAoRCgoEAAMAAgAInAgBEgMqBi0KEQoJBAADAAIA
CJ8IEgQrBi0HCukBCgQEAAIAEgQ2AjcvGtoBIE9wdGlvbmFsLiBUaGUgZGVmYXVsdCBlZ3Jl
c3MgYWdlbnQgZ2F0ZXdheSB0byB1c2UsIHdoZW4gdGhpcyBzZXR0aW5nIGlzCiBhcHBsaWVk
IHRvIGEgR2VtaW5pIEVudGVycHJpc2UgcmVzb3VyY2UuCgogVGhlIGRlcGxveW1lbnQgbW9k
ZSBtdXN0IGJlIEdPT0dMRV9NQU5BR0VELCBhbmQgdGhlIGdvdmVybmVkIGFjY2VzcyBwYXRo
CiBtdXN0IGJlIEFHRU5UX1RPX0FOWVdIRVJFLgoKDAoFBAACAAYSAzYCFwoMCgUEAAIAARID
Nhg0CgwKBQQAAgADEgM2NzgKDAoFBAACAAgSAzcGLgoPCggEAAIACJwIABIDNwctYgZwcm90
bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1::AgentGatewaySetting::AgentGatewaySetting ===
    # Fields for AgentGatewaySetting
    # Field: default_egress_agent_gateway Type: 11 (.google.cloud.discoveryengine.v1.AgentGatewaySetting.AgentGatewayReference)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1::AgentGatewaySetting - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1/agent_gateway_setting.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1::AgentGatewaySetting;

    my $msg = Google::Cloud::Discoveryengine::V1::AgentGatewaySetting::AgentGatewaySetting->new({
        default_egress_agent_gateway => $default_egress_agent_gateway,
    });

    # Read or update a field
    my $val = $msg->default_egress_agent_gateway();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1::AgentGatewaySetting::AgentGatewaySetting->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1/agent_gateway_setting.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1::AgentGatewaySetting::AgentGatewaySetting

Agent Gateway setting, which may be attached to Gemini Enterprise resources
for egress control of Gemini Enterprise agents to agents and tools outside of
Gemini Enterprise.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->default_egress_agent_gateway() >> / C<< $msg->default_egress_agent_gateway($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1::AgentGatewaySetting::AgentGatewaySetting::AgentGatewayReference>)

Optional. The default egress agent gateway to use, when this setting is
applied to a Gemini Enterprise resource.

The deployment mode must be GOOGLE_MANAGED, and the governed access path
must be AGENT_TO_ANYWHERE.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1::AgentGatewaySetting::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
