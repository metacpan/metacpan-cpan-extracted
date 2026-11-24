package Google::Cloud::Deploy::V1::AutomationPayload;

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
Ci9nb29nbGUvY2xvdWQvZGVwbG95L3YxL2F1dG9tYXRpb25fcGF5bG9hZC5wcm90bxIWZ29v
Z2xlLmNsb3VkLmRlcGxveS52MRomZ29vZ2xlL2Nsb3VkL2RlcGxveS92MS9sb2dfZW51bXMu
cHJvdG8ioAEKD0F1dG9tYXRpb25FdmVudBIYCgdtZXNzYWdlGAEgASgJUgdtZXNzYWdlEh4K
CmF1dG9tYXRpb24YAiABKAlSCmF1dG9tYXRpb24SIQoMcGlwZWxpbmVfdWlkGAMgASgJUgtw
aXBlbGluZVVpZBIwCgR0eXBlGAQgASgOMhwuZ29vZ2xlLmNsb3VkLmRlcGxveS52MS5UeXBl
UgR0eXBlQmoKGmNvbS5nb29nbGUuY2xvdWQuZGVwbG95LnYxQhZBdXRvbWF0aW9uUGF5bG9h
ZFByb3RvUAFaMmNsb3VkLmdvb2dsZS5jb20vZ28vZGVwbG95L2FwaXYxL2RlcGxveXBiO2Rl
cGxveXBiSr4KCgYSBA4AKAEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNSBHb29nbGUg
TExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAo
dGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBj
b21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2Yg
dGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJ
Q0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVl
ZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vu
c2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFO
VElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBs
aWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJu
aW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoI
CgECEgMQAB8KCQoCAwASAxIAMAoICgEIEgMUAEkKCQoCCAsSAxQASQoICgEIEgMVACIKCQoC
CAoSAxUAIgoICgEIEgMWADcKCQoCCAgSAxYANwoICgEIEgMXADMKCQoCCAESAxcAMwqJAQoC
BAASBBsAKAEafSBQYXlsb2FkIHByb3RvIGZvciAiY2xvdWRkZXBsb3kuZ29vZ2xlYXBpcy5j
b20vYXV0b21hdGlvbiIKIFBsYXRmb3JtIExvZyBldmVudCB0aGF0IGRlc2NyaWJlcyB0aGUg
QXV0b21hdGlvbiByZWxhdGVkIGV2ZW50cy4KCgoKAwQAARIDGwgXCpYBCgQEAAIAEgMeAhUa
iAEgRGVidWcgbWVzc2FnZSBmb3Igd2hlbiB0aGVyZSBpcyBhbiB1cGRhdGUgb24gdGhlIEF1
dG9tYXRpb25SdW4uCiBQcm92aWRlcyBmdXJ0aGVyIGRldGFpbHMgYWJvdXQgdGhlIHJlc291
cmNlIGNyZWF0aW9uIG9yIHN0YXRlIGNoYW5nZS4KCgwKBQQAAgAFEgMeAggKDAoFBAACAAES
Ax4JEAoMCgUEAAIAAxIDHhMUCi8KBAQAAgESAyECGBoiIFRoZSBuYW1lIG9mIHRoZSBgQXV0
b21hdGlvblJ1bmAuCgoMCgUEAAIBBRIDIQIICgwKBQQAAgEBEgMhCRMKDAoFBAACAQMSAyEW
Fwo7CgQEAAICEgMkAhoaLiBVbmlxdWUgaWRlbnRpZmllciBvZiB0aGUgYERlbGl2ZXJ5UGlw
ZWxpbmVgLgoKDAoFBAACAgUSAyQCCAoMCgUEAAICARIDJAkVCgwKBQQAAgIDEgMkGBkKRQoE
BAACAxIDJwIQGjggVHlwZSBvZiB0aGlzIG5vdGlmaWNhdGlvbiwgZS5nLiBmb3IgYSBQdWIv
U3ViIGZhaWx1cmUuCgoMCgUEAAIDBhIDJwIGCgwKBQQAAgMBEgMnBwsKDAoFBAACAwMSAycO
D2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Deploy::V1::AutomationPayload::AutomationEvent ===
    # Fields for AutomationEvent
    # Field: message Type: 9 ()
    # Field: automation Type: 9 ()
    # Field: pipeline_uid Type: 9 ()
    # Field: type Type: 14 (.google.cloud.deploy.v1.Type)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Deploy::V1::AutomationPayload - Compiled Protocol Buffers messages for google/cloud/deploy/v1/automation_payload.proto

=head1 SYNOPSIS

    use Google::Cloud::Deploy::V1::AutomationPayload;

    my $msg = Google::Cloud::Deploy::V1::AutomationPayload::AutomationEvent->new({
        message => $message,
        automation => $automation,
        pipeline_uid => $pipeline_uid,
        type => $type,
    });

    # Read or update a field
    my $val = $msg->message();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Deploy::V1::AutomationPayload::AutomationEvent->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/deploy/v1/automation_payload.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Deploy::V1::AutomationPayload::AutomationEvent

Payload proto for "clouddeploy.googleapis.com/automation"
Platform Log event that describes the Automation related events.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->message() >> / C<< $msg->message($value) >>

Type: C<String>

Debug message for when there is an update on the AutomationRun.
Provides further details about the resource creation or state change.

=item * C<< $msg->automation() >> / C<< $msg->automation($value) >>

Type: C<String>

The name of the `AutomationRun`.

=item * C<< $msg->pipeline_uid() >> / C<< $msg->pipeline_uid($value) >>

Type: C<String>

Unique identifier of the `DeliveryPipeline`.

=item * C<< $msg->type() >> / C<< $msg->type($value) >>

Type: C<Enum> (L<Google::Cloud::Deploy::V1::Type>)

Type of this notification, e.g. for a Pub/Sub failure.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Deploy::V1::AutomationPayload::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
