package Google::Cloud::Ces::V1beta::AgentTool;

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
Cihnb29nbGUvY2xvdWQvY2VzL3YxYmV0YS9hZ2VudF90b29sLnByb3RvEhdnb29nbGUuY2xv
dWQuY2VzLnYxYmV0YRofZ29vZ2xlL2FwaS9maWVsZF9iZWhhdmlvci5wcm90bxoZZ29vZ2xl
L2FwaS9yZXNvdXJjZS5wcm90byKDAQoJQWdlbnRUb29sEhcKBG5hbWUYASABKAlCA+BBAlIE
bmFtZRIlCgtkZXNjcmlwdGlvbhgCIAEoCUID4EEBUgtkZXNjcmlwdGlvbhI2CgVhZ2VudBgE
IAEoCUIg4EEB+kEaChhjZXMuZ29vZ2xlYXBpcy5jb20vQWdlbnRSBWFnZW50Ql4KG2NvbS5n
b29nbGUuY2xvdWQuY2VzLnYxYmV0YUIOQWdlbnRUb29sUHJvdG9QAVotY2xvdWQuZ29vZ2xl
LmNvbS9nby9jZXMvYXBpdjFiZXRhL2Nlc3BiO2Nlc3BiSpcKCgYSBA4AKAEKvAQKAQwSAw4A
EjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQgdW5kZXIgdGhlIEFw
YWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7CiB5b3UgbWF5IG5v
dCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGggdGhlIExpY2Vuc2Uu
CiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKCiAgICAgaHR0cDov
L3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5sZXNzIHJlcXVpcmVk
IGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5nLCBzb2Z0d2FyZQog
ZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFT
IElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJT05TIE9GIEFOWSBL
SU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBMaWNlbnNlIGZvciB0
aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25zIGFuZAogbGltaXRh
dGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACAKCQoCAwASAxIAKQoJCgIDARID
EwAjCggKAQgSAxUARAoJCgIICxIDFQBECggKAQgSAxYAIgoJCgIIChIDFgAiCggKAQgSAxcA
LwoJCgIICBIDFwAvCggKAQgSAxgANAoJCgIIARIDGAA0CkwKAgQAEgQbACgBGkAgUmVwcmVz
ZW50cyBhIHRvb2wgdGhhdCBhbGxvd3MgdGhlIGFnZW50IHRvIGNhbGwgYW5vdGhlciBhZ2Vu
dC4KCgoKAwQAARIDGwgRCjQKBAQAAgASAx0COxonIFJlcXVpcmVkLiBUaGUgbmFtZSBvZiB0
aGUgYWdlbnQgdG9vbC4KCgwKBQQAAgAFEgMdAggKDAoFBAACAAESAx0JDQoMCgUEAAIAAxID
HRARCgwKBQQAAgAIEgMdEjoKDwoIBAACAAicCAASAx0TOQo7CgQEAAIBEgMgAkIaLiBPcHRp
b25hbC4gRGVzY3JpcHRpb24gb2YgdGhlIHRvb2wncyBwdXJwb3NlLgoKDAoFBAACAQUSAyAC
CAoMCgUEAAIBARIDIAkUCgwKBQQAAgEDEgMgFxgKDAoFBAACAQgSAyAZQQoPCggEAAIBCJwI
ABIDIBpACqABCgQEAAICEgQkAicEGpEBIE9wdGlvbmFsLiBUaGUgcmVzb3VyY2UgbmFtZSBv
ZiB0aGUgYWdlbnQgdGhhdCBpcyB0aGUgZW50cnkgcG9pbnQgb2YgdGhlCiB0b29sLiBGb3Jt
YXQ6IGBwcm9qZWN0cy97cHJvamVjdH0vbG9jYXRpb25zL3tsb2NhdGlvbn0vYWdlbnRzL3th
Z2VudH1gCgoMCgUEAAICBRIDJAIICgwKBQQAAgIBEgMkCQ4KDAoFBAACAgMSAyQREgoNCgUE
AAICCBIEJBMnAwoPCggEAAICCJwIABIDJQQqCg4KBwQAAgIInwgSAyYESmIGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1beta::AgentTool::AgentTool ===
    # Fields for AgentTool
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: agent Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1beta::AgentTool - Compiled Protocol Buffers messages for google/cloud/ces/v1beta/agent_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1beta::AgentTool;

    my $msg = Google::Cloud::Ces::V1beta::AgentTool::AgentTool->new({
        name => $name,
        description => $description,
        agent => $agent,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1beta::AgentTool::AgentTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1beta/agent_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1beta::AgentTool::AgentTool

Represents a tool that allows the agent to call another agent.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Required. The name of the agent tool.

=item * C<< $msg->description() >> / C<< $msg->description($value) >>

Type: C<String>

Optional. Description of the tool's purpose.

=item * C<< $msg->agent() >> / C<< $msg->agent($value) >>

Type: C<String>

Optional. The resource name of the agent that is the entry point of the
tool. Format: `projects/{project}/locations/{location}/agents/{agent}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1beta::AgentTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
