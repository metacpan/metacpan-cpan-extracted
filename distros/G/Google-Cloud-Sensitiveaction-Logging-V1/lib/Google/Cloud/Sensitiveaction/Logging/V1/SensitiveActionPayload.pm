package Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Securitycenter::V1::Access };
    eval { require Google::Protobuf::Timestamp };
    my $descriptor_b64 = <<'EOF';
CkZnb29nbGUvY2xvdWQvc2Vuc2l0aXZlYWN0aW9uL2xvZ2dpbmcvdjEvc2Vuc2l0aXZlX2Fj
dGlvbl9wYXlsb2FkLnByb3RvEidnb29nbGUuY2xvdWQuc2Vuc2l0aXZlYWN0aW9uLmxvZ2dp
bmcudjEaK2dvb2dsZS9jbG91ZC9zZWN1cml0eWNlbnRlci92MS9hY2Nlc3MucHJvdG8aH2dv
b2dsZS9wcm90b2J1Zi90aW1lc3RhbXAucHJvdG8ioAQKD1NlbnNpdGl2ZUFjdGlvbhIfCgth
Y3Rpb25fdHlwZRgBIAEoCVIKYWN0aW9uVHlwZRI7CgthY3Rpb25fdGltZRgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmFjdGlvblRpbWUSLQoSYWZmZWN0ZWRfcmVzb3Vy
Y2VzGAMgAygJUhFhZmZlY3RlZFJlc291cmNlcxJqCg5zb3VyY2VfbG9nX2lkcxgEIAMoCzJE
Lmdvb2dsZS5jbG91ZC5zZW5zaXRpdmVhY3Rpb24ubG9nZ2luZy52MS5TZW5zaXRpdmVBY3Rp
b24uU291cmNlTG9nSWRSDHNvdXJjZUxvZ0lkcxIkCg5sZWFybl9tb3JlX3VyaRgFIAEoCVIM
bGVhcm5Nb3JlVXJpEj4KBmFjY2VzcxgGIAEoCzImLmdvb2dsZS5jbG91ZC5zZWN1cml0eWNl
bnRlci52MS5BY2Nlc3NSBmFjY2VzcxqtAQoLU291cmNlTG9nSWQSLQoScmVzb3VyY2VfY29u
dGFpbmVyGAEgASgJUhFyZXNvdXJjZUNvbnRhaW5lchI1Cghsb2dfdGltZRgCIAEoCzIaLmdv
b2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2xvZ1RpbWUSGwoJaW5zZXJ0X2lkGAMgASgJUghp
bnNlcnRJZBIbCglxdWVyeV91cmkYBCABKAlSCHF1ZXJ5VXJpQpUCCitjb20uZ29vZ2xlLmNs
b3VkLnNlbnNpdGl2ZWFjdGlvbi5sb2dnaW5nLnYxQhtTZW5zaXRpdmVBY3Rpb25QYXlsb2Fk
UHJvdG9QAVpFY2xvdWQuZ29vZ2xlLmNvbS9nby9zZW5zaXRpdmVhY3Rpb24vbG9nZ2luZy9h
cGl2MS9sb2dnaW5ncGI7bG9nZ2luZ3BiqgInR29vZ2xlLkNsb3VkLlNlbnNpdGl2ZUFjdGlv
bi5Mb2dnaW5nLlYxygInR29vZ2xlXENsb3VkXFNlbnNpdGl2ZUFjdGlvblxMb2dnaW5nXFYx
6gIrR29vZ2xlOjpDbG91ZDo6U2Vuc2l0aXZlQWN0aW9uOjpMb2dnaW5nOjpWMUrtEAoGEgQO
AEEBCrwECgEMEgMOABIysQQgQ29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2Vk
IHVuZGVyIHRoZSBBcGFjaGUgTGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIp
OwogeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRo
IHRoZSBMaWNlbnNlLgogWW91IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0
CgogICAgIGh0dHA6Ly93d3cuYXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVu
bGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGlu
Zywgc29mdHdhcmUKIGRpc3RyaWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1
dGVkIG9uIGFuICJBUyBJUyIgQkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElU
SU9OUyBPRiBBTlkgS0lORCwgZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUg
TGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9u
cyBhbmQKIGxpbWl0YXRpb25zIHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAwCgkKAgMA
EgMSADUKCQoCAwESAxMAKQoICgEIEgMVAEQKCQoCCCUSAxUARAoICgEIEgMWAFwKCQoCCAsS
AxYAXAoICgEIEgMXACIKCQoCCAoSAxcAIgoICgEIEgMYADwKCQoCCAgSAxgAPAoICgEIEgMZ
AEQKCQoCCAESAxkARAoICgEIEgMaAEUKCQoCCCkSAxoARQoICgEIEgMbAEQKCQoCCC0SAxsA
RAp7CgIEABIEHwBBARpvIFBheWxvYWQgcHJvdG8gZm9yIHNlbnNpdGl2ZWFjdGlvbi5nb29n
bGVhcGlzLmNvbS9hY3Rpb24KIFBsYXRmb3JtIExvZyBldmVudCB0aGF0IGRlc2NyaWJlcyBh
IHNlbnNpdGl2ZSBhY3Rpb24KCgoKAwQAARIDHwgXCkQKBAQAAwASBCECLgMaNiBVc2VkIHRv
IHJlZmVyZW5jZSBhIHNwZWNpZmljIENsb3VkIExvZ2dpbmcgTG9nRW50cnkuCgoMCgUEAAMA
ARIDIQoVCmIKBgQAAwACABIDJAQiGlMgVGhlIEdDUCByZXNvdXJjZSAob3JnYW5pemF0aW9u
LCBmb2xkZXIsIG9yIHByb2plY3QpIHRoYXQgdGhlIExvZ0VudHJ5CiBjYW1lIGZyb20uCgoO
CgcEAAMAAgAFEgMkBAoKDgoHBAADAAIAARIDJAsdCg4KBwQAAwACAAMSAyQgIQovCgYEAAMA
AgESAycEKxogIFRoZSB0aW1lc3RhbXAgb2YgdGhlIExvZ0VudHJ5LgoKDgoHBAADAAIBBhID
JwQdCg4KBwQAAwACAQESAyceJgoOCgcEAAMAAgEDEgMnKSoKLwoGBAADAAICEgMqBBkaICBU
aGUgaW5zZXJ0X2lkIG9mIHRoZSBMb2dFbnRyeS4KCg4KBwQAAwACAgUSAyoECgoOCgcEAAMA
AgIBEgMqCxQKDgoHBAADAAICAxIDKhcYClUKBgQAAwACAxIDLQQZGkYgQSBsaW5rIHRvIHRo
ZSBDbG91ZCBMb2dnaW5nIGRhc2hib2FyZCB3aXRoIGEgcXVlcnkgZm9yIHRoZSBMb2dFbnRy
eS4KCg4KBwQAAwACAwUSAy0ECgoOCgcEAAMAAgMBEgMtCxQKDgoHBAADAAIDAxIDLRcYCkUK
BAQAAgASAzECGRo4IFRoZSB0eXBlIG9mIGFjdGlvbiAoZWcuICJjaGFuZ2Vfb3JnYW5pemF0
aW9uX3BvbGljeSIpLgoKDAoFBAACAAUSAzECCAoMCgUEAAIAARIDMQkUCgwKBQQAAgADEgMx
FxgKMQoEBAACARIDNAIsGiQgVGhlIHRpbWUgdGhpcyBhY3Rpb24gd2FzIGRldGVjdGVkLgoK
DAoFBAACAQYSAzQCGwoMCgUEAAIBARIDNBwnCgwKBQQAAgEDEgM0KisKPQoEBAACAhIDNwIp
GjAgR0NQIHJlc291cmNlcyB0aGF0IGFyZSBpbnZvbHZlZCBpbiB0aGUgYWN0aW9uLgoKDAoF
BAACAgQSAzcCCgoMCgUEAAICBRIDNwsRCgwKBQQAAgIBEgM3EiQKDAoFBAACAgMSAzcnKApL
CgQEAAIDEgM6AioaPiBDbG91ZCBMb2dnaW5nIGVudHJpZXMgdGhhdCB3ZXJlIHVzZWQgdG8g
aWRlbnRpZnkgdGhlIGFjdGlvbi4KCgwKBQQAAgMEEgM6AgoKDAoFBAACAwYSAzoLFgoMCgUE
AAIDARIDOhclCgwKBQQAAgMDEgM6KCkKVgoEBAACBBIDPQIcGkkgTGluayB0byBkb2N1bWVu
dGF0aW9uIHdoZXJlIHlvdSBjYW4gbGVhcm4gbW9yZSBhYm91dCBzZW5zaXRpdmUgYWN0aW9u
cy4KCgwKBQQAAgQFEgM9AggKDAoFBAACBAESAz0JFwoMCgUEAAIEAxIDPRobCkEKBAQAAgUS
A0ACMxo0IEFjY2VzcyBkZXRhaWxzIGFzc29jaWF0ZWQgdG8gdGhlIHNlbnNpdGl2ZSBhY3Rp
b24uCgoMCgUEAAIFBhIDQAInCgwKBQQAAgUBEgNAKC4KDAoFBAACBQMSA0AxMmIGcHJvdG8z

EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction ===
    # Fields for SensitiveAction
    # Field: action_type Type: 9 ()
    # Field: action_time Type: 11 (.google.protobuf.Timestamp)
    # Field: affected_resources Type: 9 ()
    # Field: source_log_ids Type: 11 (.google.cloud.sensitiveaction.logging.v1.SensitiveAction.SourceLogId)
    # Field: learn_more_uri Type: 9 ()
    # Field: access Type: 11 (.google.cloud.securitycenter.v1.Access)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload - Compiled Protocol Buffers messages for google/cloud/sensitiveaction/logging/v1/sensitive_action_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload;

    my $msg = Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction->new({
        action_type => $action_type,
        action_time => $action_time,
        affected_resources => $affected_resources,
        source_log_ids => $source_log_ids,
    });

    # Read or update a field
    my $val = $msg->action_type();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/sensitiveaction/logging/v1/sensitive_action_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction

Payload proto for sensitiveaction.googleapis.com/action
Platform Log event that describes a sensitive action

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->action_type() >> / C<< $msg->action_type($value) >>

Type: C<String>

The type of action (eg. "change_organization_policy").

=item * C<< $msg->action_time() >> / C<< $msg->action_time($value) >>

Type: C<Message> (L<Google::Protobuf::Timestamp::Timestamp>)

The time this action was detected.

=item * C<< $msg->affected_resources() >> / C<< $msg->affected_resources($value) >>

Type: C<String>

GCP resources that are involved in the action.

=item * C<< $msg->source_log_ids() >> / C<< $msg->source_log_ids($value) >>

Type: C<Message> (L<Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::SensitiveAction::SourceLogId>)

Cloud Logging entries that were used to identify the action.

=item * C<< $msg->learn_more_uri() >> / C<< $msg->learn_more_uri($value) >>

Type: C<String>

Link to documentation where you can learn more about sensitive actions.

=item * C<< $msg->access() >> / C<< $msg->access($value) >>

Type: C<Message> (L<Google::Cloud::Securitycenter::V1::Access::Access>)

Access details associated to the sensitive action.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Sensitiveaction::Logging::V1::SensitiveActionPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
