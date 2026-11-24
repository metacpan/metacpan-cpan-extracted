package Google::Cloud::Deploy::V1::AutomationrunPayload;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Cloud::Deploy::V1::LogEnums };
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvZGVwbG95L3YxL2F1dG9tYXRpb25ydW5fcGF5bG9hZC5wcm90bxIW
Z29vZ2xlLmNsb3VkLmRlcGxveS52MRomZ29vZ2xlL2Nsb3VkL2RlcGxveS92MS9sb2dfZW51
bXMucHJvdG8inAIKEkF1dG9tYXRpb25SdW5FdmVudBIYCgdtZXNzYWdlGAEgASgJUgdtZXNz
YWdlEiUKDmF1dG9tYXRpb25fcnVuGAIgASgJUg1hdXRvbWF0aW9uUnVuEiEKDHBpcGVsaW5l
X3VpZBgDIAEoCVILcGlwZWxpbmVVaWQSIwoNYXV0b21hdGlvbl9pZBgEIAEoCVIMYXV0b21h
dGlvbklkEhcKB3J1bGVfaWQYBSABKAlSBnJ1bGVJZBIyChVkZXN0aW5hdGlvbl90YXJnZXRf
aWQYBiABKAlSE2Rlc3RpbmF0aW9uVGFyZ2V0SWQSMAoEdHlwZRgHIAEoDjIcLmdvb2dsZS5j
bG91ZC5kZXBsb3kudjEuVHlwZVIEdHlwZUJtChpjb20uZ29vZ2xlLmNsb3VkLmRlcGxveS52
MUIZQXV0b21hdGlvblJ1blBheWxvYWRQcm90b1ABWjJjbG91ZC5nb29nbGUuY29tL2dvL2Rl
cGxveS9hcGl2MS9kZXBsb3lwYjtkZXBsb3lwYkr1DAoGEgQOADEBCrwECgEMEgMOABIysQQg
Q29weXJpZ2h0IDIwMjUgR29vZ2xlIExMQwoKIExpY2Vuc2VkIHVuZGVyIHRoZSBBcGFjaGUg
TGljZW5zZSwgVmVyc2lvbiAyLjAgKHRoZSAiTGljZW5zZSIpOwogeW91IG1heSBub3QgdXNl
IHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgogWW91
IG1heSBvYnRhaW4gYSBjb3B5IG9mIHRoZSBMaWNlbnNlIGF0CgogICAgIGh0dHA6Ly93d3cu
YXBhY2hlLm9yZy9saWNlbnNlcy9MSUNFTlNFLTIuMAoKIFVubGVzcyByZXF1aXJlZCBieSBh
cHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIGRpc3Ry
aWJ1dGVkIHVuZGVyIHRoZSBMaWNlbnNlIGlzIGRpc3RyaWJ1dGVkIG9uIGFuICJBUyBJUyIg
QkFTSVMsCiBXSVRIT1VUIFdBUlJBTlRJRVMgT1IgQ09ORElUSU9OUyBPRiBBTlkgS0lORCwg
ZWl0aGVyIGV4cHJlc3Mgb3IgaW1wbGllZC4KIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNw
ZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIGxpbWl0YXRpb25z
IHVuZGVyIHRoZSBMaWNlbnNlLgoKCAoBAhIDEAAfCgkKAgMAEgMSADAKCAoBCBIDFABJCgkK
AggLEgMUAEkKCAoBCBIDFQAiCgkKAggKEgMVACIKCAoBCBIDFgA6CgkKAggIEgMWADoKCAoB
CBIDFwAzCgkKAggBEgMXADMKkQEKAgQAEgQbADEBGoQBIFBheWxvYWQgcHJvdG8gZm9yICJj
bG91ZGRlcGxveS5nb29nbGVhcGlzLmNvbS9hdXRvbWF0aW9uX3J1biIKIFBsYXRmb3JtIExv
ZyBldmVudCB0aGF0IGRlc2NyaWJlcyB0aGUgQXV0b21hdGlvblJ1biByZWxhdGVkIGV2ZW50
cy4KCgoKAwQAARIDGwgaCpYBCgQEAAIAEgMeAhUaiAEgRGVidWcgbWVzc2FnZSBmb3Igd2hl
biB0aGVyZSBpcyBhbiB1cGRhdGUgb24gdGhlIEF1dG9tYXRpb25SdW4uCiBQcm92aWRlcyBm
dXJ0aGVyIGRldGFpbHMgYWJvdXQgdGhlIHJlc291cmNlIGNyZWF0aW9uIG9yIHN0YXRlIGNo
YW5nZS4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAESAx4JEAoMCgUEAAIAAxIDHhMUCi8KBAQA
AgESAyECHBoiIFRoZSBuYW1lIG9mIHRoZSBgQXV0b21hdGlvblJ1bmAuCgoMCgUEAAIBBRID
IQIICgwKBQQAAgEBEgMhCRcKDAoFBAACAQMSAyEaGwo7CgQEAAICEgMkAhoaLiBVbmlxdWUg
aWRlbnRpZmllciBvZiB0aGUgYERlbGl2ZXJ5UGlwZWxpbmVgLgoKDAoFBAACAgUSAyQCCAoM
CgUEAAICARIDJAkVCgwKBQQAAgIDEgMkGBkKLgoEBAACAxIDJwIbGiEgSWRlbnRpZmllciBv
ZiB0aGUgYEF1dG9tYXRpb25gLgoKDAoFBAACAwUSAycCCAoMCgUEAAIDARIDJwkWCgwKBQQA
AgMDEgMnGRoKMwoEBAACBBIDKgIVGiYgSWRlbnRpZmllciBvZiB0aGUgYEF1dG9tYXRpb25g
IHJ1bGUuCgoMCgUEAAIEBRIDKgIICgwKBQQAAgQBEgMqCRAKDAoFBAACBAMSAyoTFApKCgQE
AAIFEgMtAiMaPSBJRCBvZiB0aGUgYFRhcmdldGAgdG8gd2hpY2ggdGhlIGBBdXRvbWF0aW9u
UnVuYCBpcyBjcmVhdGVkLgoKDAoFBAACBQUSAy0CCAoMCgUEAAIFARIDLQkeCgwKBQQAAgUD
EgMtISIKRQoEBAACBhIDMAIQGjggVHlwZSBvZiB0aGlzIG5vdGlmaWNhdGlvbiwgZS5nLiBm
b3IgYSBQdWIvU3ViIGZhaWx1cmUuCgoMCgUEAAIGBhIDMAIGCgwKBQQAAgYBEgMwBwsKDAoF
BAACBgMSAzAOD2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::AutomationrunPayload::AutomationRunEvent ===
    # Fields for AutomationRunEvent
    # Field: message Type: 9 ()
    # Field: automation_run Type: 9 ()
    # Field: pipeline_uid Type: 9 ()
    # Field: automation_id Type: 9 ()
    # Field: rule_id Type: 9 ()
    # Field: destination_target_id Type: 9 ()
    # Field: type Type: 14 (.google.cloud.deploy.v1.Type)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::AutomationrunPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/automationrun_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::AutomationrunPayload;

    my $msg = Google::Cloud::Deploy::V1::AutomationrunPayload::AutomationRunEvent->new({
        message => $message,
        automation_run => $automation_run,
        pipeline_uid => $pipeline_uid,
        automation_id => $automation_id,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::AutomationrunPayload::AutomationRunEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/automationrun_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::AutomationrunPayload::AutomationRunEvent

Payload proto for "clouddeploy.googleapis.com/automation_run"
Platform Log event that describes the AutomationRun related events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when there is an update on the AutomationRun.
Provides further details about the resource creation or state change.

=item * C<< $msg->automation_run() >> / C<< $msg->automation_run($value) >>

Type: C<String>

The name of the `AutomationRun`.

=item * C<< $msg->pipeline_uid() >> / C<< $msg->pipeline_uid($value) >>

Type: C<String>

Unique identifier of the `DeliveryPipeline`.

=item * C<< $msg->automation_id() >> / C<< $msg->automation_id($value) >>

Type: C<String>

Identifier of the `Automation`.

=item * C<< $msg->rule_id() >> / C<< $msg->rule_id($value) >>

Type: C<String>

Identifier of the `Automation` rule.

=item * C<< $msg->destination_target_id() >> / C<< $msg->destination_target_id($value) >>

Type: C<String>

ID of the `Target` to which the `AutomationRun` is created.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a Pub/Sub failure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::AutomationrunPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
