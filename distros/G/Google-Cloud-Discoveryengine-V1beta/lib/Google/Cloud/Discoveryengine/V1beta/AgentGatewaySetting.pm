package Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting;

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
Cj9nb29nbGUvY2xvdWQvZGlzY292ZXJ5ZW5naW5lL3YxYmV0YS9hZ2VudF9nYXRld2F5X3Nl
dHRpbmcucHJvdG8SI2dvb2dsZS5jbG91ZC5kaXNjb3ZlcnllbmdpbmUudjFiZXRhGh9nb29n
bGUvYXBpL2ZpZWxkX2JlaGF2aW9yLnByb3RvGhlnb29nbGUvYXBpL3Jlc291cmNlLnByb3Rv
IpECChNBZ2VudEdhdGV3YXlTZXR0aW5nEpQBChxkZWZhdWx0X2VncmVzc19hZ2VudF9nYXRl
d2F5GAEgASgLMk4uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGEuQWdlbnRH
YXRld2F5U2V0dGluZy5BZ2VudEdhdGV3YXlSZWZlcmVuY2VCA+BBAVIZZGVmYXVsdEVncmVz
c0FnZW50R2F0ZXdheRpjChVBZ2VudEdhdGV3YXlSZWZlcmVuY2USSgoEbmFtZRgBIAEoCUI2
4EEC4EEF+kEtCituZXR3b3Jrc2VydmljZXMuZ29vZ2xlYXBpcy5jb20vQWdlbnRHYXRld2F5
UgRuYW1lQp8CCidjb20uZ29vZ2xlLmNsb3VkLmRpc2NvdmVyeWVuZ2luZS52MWJldGFCGEFn
ZW50R2F0ZXdheVNldHRpbmdQcm90b1ABWlFjbG91ZC5nb29nbGUuY29tL2dvL2Rpc2NvdmVy
eWVuZ2luZS9hcGl2MWJldGEvZGlzY292ZXJ5ZW5naW5lcGI7ZGlzY292ZXJ5ZW5naW5lcGKi
Ag9ESVNDT1ZFUllFTkdJTkWqAiNHb29nbGUuQ2xvdWQuRGlzY292ZXJ5RW5naW5lLlYxQmV0
YcoCI0dvb2dsZVxDbG91ZFxEaXNjb3ZlcnlFbmdpbmVcVjFiZXRh6gImR29vZ2xlOjpDbG91
ZDo6RGlzY292ZXJ5RW5naW5lOjpWMWJldGFKhw0KBhIEDgA4AQq8BAoBDBIDDgASMrEEIENv
cHlyaWdodCAyMDI2IEdvb2dsZSBMTEMKCiBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExp
Y2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIHlvdSBtYXkgbm90IHVzZSB0
aGlzIGZpbGUgZXhjZXB0IGluIGNvbXBsaWFuY2Ugd2l0aCB0aGUgTGljZW5zZS4KIFlvdSBt
YXkgb2J0YWluIGEgY29weSBvZiB0aGUgTGljZW5zZSBhdAoKICAgICBodHRwOi8vd3d3LmFw
YWNoZS5vcmcvbGljZW5zZXMvTElDRU5TRS0yLjAKCiBVbmxlc3MgcmVxdWlyZWQgYnkgYXBw
bGljYWJsZSBsYXcgb3IgYWdyZWVkIHRvIGluIHdyaXRpbmcsIHNvZnR3YXJlCiBkaXN0cmli
dXRlZCB1bmRlciB0aGUgTGljZW5zZSBpcyBkaXN0cmlidXRlZCBvbiBhbiAiQVMgSVMiIEJB
U0lTLAogV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVp
dGhlciBleHByZXNzIG9yIGltcGxpZWQuCiBTZWUgdGhlIExpY2Vuc2UgZm9yIHRoZSBzcGVj
aWZpYyBsYW5ndWFnZSBnb3Zlcm5pbmcgcGVybWlzc2lvbnMgYW5kCiBsaW1pdGF0aW9ucyB1
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAALAoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoB
CBIDFQBACgkKAgglEgMVAEAKCAoBCBIDFgBoCgkKAggLEgMWAGgKCAoBCBIDFwAiCgkKAggK
EgMXACIKCAoBCBIDGAA5CgkKAggIEgMYADkKCAoBCBIDGQBACgkKAggBEgMZAEAKCAoBCBID
GgAtCgkKAggkEgMaAC0KCAoBCBIDGwBACgkKAggpEgMbAEAKCAoBCBIDHAA/CgkKAggtEgMc
AD8KvQEKAgQAEgQhADgBGrABIEFnZW50IEdhdGV3YXkgc2V0dGluZywgd2hpY2ggbWF5IGJl
IGF0dGFjaGVkIHRvIEdlbWluaSBFbnRlcnByaXNlIHJlc291cmNlcwogZm9yIGVncmVzcyBj
b250cm9sIG9mIEdlbWluaSBFbnRlcnByaXNlIGFnZW50cyB0byBhZ2VudHMgYW5kIHRvb2xz
IG91dHNpZGUgb2YKIEdlbWluaSBFbnRlcnByaXNlLgoKCgoDBAABEgMhCBsKNwoEBAADABIE
IwIvAxopIFJlZmVyZW5jZSB0byBhbiBBZ2VudCBHYXRld2F5IHJlc291cmNlLgoKDAoFBAAD
AAESAyMKHwqzAQoGBAADAAIAEgQoBC4GGqIBIFJlcXVpcmVkLiBJbW11dGFibGUuIFRoZSBy
ZXNvdXJjZSBuYW1lIG9mIHRoZSBhZ2VudCBnYXRld2F5LgoKIEV4cGVjdGVkIGZvcm1hdDoK
IGBwcm9qZWN0cy97cHJvamVjdF9udW1iZXJ9L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50
R2F0ZXdheXMve2FnZW50X2dhdGV3YXl9YC4KCg4KBwQAAwACAAUSAygECgoOCgcEAAMAAgAB
EgMoCw8KDgoHBAADAAIAAxIDKBITCg8KBwQAAwACAAgSBCgULgUKEQoKBAADAAIACJwIABID
KQYsChEKCgQAAwACAAicCAESAyoGLQoRCgkEAAMAAgAInwgSBCsGLQcK6QEKBAQAAgASBDYC
Ny8a2gEgT3B0aW9uYWwuIFRoZSBkZWZhdWx0IGVncmVzcyBhZ2VudCBnYXRld2F5IHRvIHVz
ZSwgd2hlbiB0aGlzIHNldHRpbmcgaXMKIGFwcGxpZWQgdG8gYSBHZW1pbmkgRW50ZXJwcmlz
ZSByZXNvdXJjZS4KCiBUaGUgZGVwbG95bWVudCBtb2RlIG11c3QgYmUgR09PR0xFX01BTkFH
RUQsIGFuZCB0aGUgZ292ZXJuZWQgYWNjZXNzIHBhdGgKIG11c3QgYmUgQUdFTlRfVE9fQU5Z
V0hFUkUuCgoMCgUEAAIABhIDNgIXCgwKBQQAAgABEgM2GDQKDAoFBAACAAMSAzY3OAoMCgUE
AAIACBIDNwYuCg8KCAQAAgAInAgAEgM3By1iBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting ===
    # Fields for AgentGatewaySetting
    # Field: default_egress_agent_gateway Type: 11 (.google.cloud.discoveryengine.v1beta.AgentGatewaySetting.AgentGatewayReference)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting - Compiled Protocol Buffers messages for google/cloud/discoveryengine/v1beta/agent_gateway_setting.proto

=head1 SYNOPSIS

    use Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting;

    my $msg = Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting->new({
        default_egress_agent_gateway => $default_egress_agent_gateway,
    });

    # Read or update a field
    my $val = $msg->default_egress_agent_gateway();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/discoveryengine/v1beta/agent_gateway_setting.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting

Agent Gateway setting, which may be attached to Gemini Enterprise resources
for egress control of Gemini Enterprise agents to agents and tools outside of
Gemini Enterprise.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->default_egress_agent_gateway() >> / C<< $msg->default_egress_agent_gateway($value) >>

Type: C<Message> (L<Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::AgentGatewaySetting::AgentGatewayReference>)

Optional. The default egress agent gateway to use, when this setting is
applied to a Gemini Enterprise resource.

The deployment mode must be GOOGLE_MANAGED, and the governed access path
must be AGENT_TO_ANYWHERE.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Discoveryengine::V1beta::AgentGatewaySetting::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
