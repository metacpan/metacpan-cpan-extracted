package Google::Cloud::Dialogflow::V2::Toolset;

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
    eval { require Google::Cloud::Dialogflow::V2::Tool };
    my $descriptor_b64 = <<'EOF';
Cihnb29nbGUvY2xvdWQvZGlhbG9nZmxvdy92Mi90b29sc2V0LnByb3RvEhpnb29nbGUuY2xv
dWQuZGlhbG9nZmxvdy52MhofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29v
Z2xlL2FwaS9yZXNvdXJjZS5wcm90bxolZ29vZ2xlL2Nsb3VkL2RpYWxvZ2Zsb3cvdjIvdG9v
bC5wcm90byLtAQoLVG9vbHNldFRvb2wSPAoHdG9vbHNldBgBIAEoCUIi4EEC+kEcChpjZXMu
Z29vZ2xlYXBpcy5jb20vVG9vbHNldFIHdG9vbHNldBImCgxvcGVyYXRpb25faWQYAiABKAlC
A+BBAVILb3BlcmF0aW9uSWQSeAoYY29uZmlybWF0aW9uX3JlcXVpcmVtZW50GAMgASgOMjgu
Z29vZ2xlLmNsb3VkLmRpYWxvZ2Zsb3cudjIuVG9vbC5Db25maXJtYXRpb25SZXF1aXJlbWVu
dEID4EEBUhdjb25maXJtYXRpb25SZXF1aXJlbWVudEL4AQoeY29tLmdvb2dsZS5jbG91ZC5k
aWFsb2dmbG93LnYyQgxUb29sc2V0UHJvdG9QAVo+Y2xvdWQuZ29vZ2xlLmNvbS9nby9kaWFs
b2dmbG93L2FwaXYyL2RpYWxvZ2Zsb3dwYjtkaWFsb2dmbG93cGKiAgJERqoCGkdvb2dsZS5D
bG91ZC5EaWFsb2dmbG93LlYy6kFjChpjZXMuZ29vZ2xlYXBpcy5jb20vVG9vbHNldBJFcHJv
amVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FwcHMve2FwcH0vdG9vbHNl
dHMve3Rvb2xzZXR9SrULCgYSBA4AMgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBH
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
c2UuCgoICgECEgMQACMKCQoCAwASAxIAKQoJCgIDARIDEwAjCgkKAgMCEgMUAC8KCAoBCBID
FgA3CgkKAgglEgMWADcKCAoBCBIDFwBVCgkKAggLEgMXAFUKCAoBCBIDGAAiCgkKAggKEgMY
ACIKCAoBCBIDGQAtCgkKAggIEgMZAC0KCAoBCBIDGgA3CgkKAggBEgMaADcKCAoBCBIDGwAg
CgkKAggkEgMbACAKCQoBCBIEHAAfAgoMCgQInQgAEgQcAB8CCjQKAgQAEgQiADIBGiggQSB0
b29sIHRoYXQgaXMgY3JlYXRlZCBmcm9tIGEgdG9vbHNldC4KCgoKAwQAARIDIggTCqABCgQE
AAIAEgQmAikEGpEBIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0aGUgdG9vbHNldCB0byByZXRy
aWV2ZSB0aGUgc2NoZW1hIGZvci4KIEZvcm1hdDoKIGBwcm9qZWN0cy97cHJvamVjdH0vbG9j
YXRpb25zL3tsb2NhdGlvbn0vYXBwcy97YXBwfS90b29sc2V0cy97dG9vbHNldH1gCgoMCgUE
AAIABRIDJgIICgwKBQQAAgABEgMmCRAKDAoFBAACAAMSAyYTFAoNCgUEAAIACBIEJhUpAwoP
CggEAAIACJwIABIDJwQqCg4KBwQAAgAInwgSAygETAqFAQoEBAACARIDLQJDGnggT3B0aW9u
YWwuIFRoZSBvcGVyYXRpb25JZCBmaWVsZCBvZiB0aGUgT3BlbkFQSSBlbmRwb2ludC4gVGhl
IG9wZXJhdGlvbklkCiBtdXN0IGJlIHByZXNlbnQgaW4gdGhlIHRvb2xzZXQncyBkZWZpbml0
aW9uLgoKDAoFBAACAQUSAy0CCAoMCgUEAAIBARIDLQkVCgwKBQQAAgEDEgMtGBkKDAoFBAAC
AQgSAy0aQgoPCggEAAIBCJwIABIDLRtBClEKBAQAAgISBDACMS8aQyBPcHRpb25hbC4gSW5k
aWNhdGVzIHdoZXRoZXIgdGhlIHRvb2wgcmVxdWlyZXMgaHVtYW4gY29uZmlybWF0aW9uLgoK
DAoFBAACAgYSAzACHgoMCgUEAAICARIDMB83CgwKBQQAAgIDEgMwOjsKDAoFBAACAggSAzEG
LgoPCggEAAICCJwIABIDMQctYgZwcm90bzM=
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Dialogflow::V2::Toolset::ToolsetTool ===
    # Fields for ToolsetTool
    # Field: toolset Type: 9 ()
    # Field: operation_id Type: 9 ()
    # Field: confirmation_requirement Type: 14 (.google.cloud.dialogflow.v2.Tool.ConfirmationRequirement)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Dialogflow::V2::Toolset - Compiled Protocol Buffers messages for google/cloud/dialogflow/v2/toolset.proto

=head1 SYNOPSIS

    use Google::Cloud::Dialogflow::V2::Toolset;

    my $msg = Google::Cloud::Dialogflow::V2::Toolset::ToolsetTool->new({
        toolset => $toolset,
        operation_id => $operation_id,
        confirmation_requirement => $confirmation_requirement,
    });

    # Read or update a field
    my $val = $msg->toolset();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Dialogflow::V2::Toolset::ToolsetTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/dialogflow/v2/toolset.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Dialogflow::V2::Toolset::ToolsetTool

A tool that is created from a toolset.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->toolset() >> / C<< $msg->toolset($value) >>

Type: C<String>

Required. The name of the toolset to retrieve the schema for.
Format:
`projects/{project}/locations/{location}/apps/{app}/toolsets/{toolset}`

=item * C<< $msg->operation_id() >> / C<< $msg->operation_id($value) >>

Type: C<String>

Optional. The operationId field of the OpenAPI endpoint. The operationId
must be present in the toolset's definition.

=item * C<< $msg->confirmation_requirement() >> / C<< $msg->confirmation_requirement($value) >>

Type: C<Enum> (L<Google::Cloud::Dialogflow::V2::Tool::ConfirmationRequirement>)

Optional. Indicates whether the tool requires human confirmation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Dialogflow::V2::Toolset::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
