package Google::Cloud::Ces::V1::AgentTool;

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
CiRnb29nbGUvY2xvdWQvY2VzL3YxL2FnZW50X3Rvb2wucHJvdG8SE2dvb2dsZS5jbG91ZC5j
ZXMudjEaH2dvb2dsZS9hcGkvZmllbGRfYmVoYXZpb3IucHJvdG8aGWdvb2dsZS9hcGkvcmVz
b3VyY2UucHJvdG8ijAEKCUFnZW50VG9vbBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWUSJQoL
ZGVzY3JpcHRpb24YAiABKAlCA+BBAVILZGVzY3JpcHRpb24SPwoKcm9vdF9hZ2VudBgDIAEo
CUIg4EEB+kEaChhjZXMuZ29vZ2xlYXBpcy5jb20vQWdlbnRSCXJvb3RBZ2VudEJWChdjb20u
Z29vZ2xlLmNsb3VkLmNlcy52MUIOQWdlbnRUb29sUHJvdG9QAVopY2xvdWQuZ29vZ2xlLmNv
bS9nby9jZXMvYXBpdjEvY2VzcGI7Y2VzcGJKnAoKBhIEDgAoAQq8BAoBDBIDDgASMrEEIENv
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
bmRlciB0aGUgTGljZW5zZS4KCggKAQISAxAAHAoJCgIDABIDEgApCgkKAgMBEgMTACMKCAoB
CBIDFQBACgkKAggLEgMVAEAKCAoBCBIDFgAiCgkKAggKEgMWACIKCAoBCBIDFwAvCgkKAggI
EgMXAC8KCAoBCBIDGAAwCgkKAggBEgMYADAKTAoCBAASBBsAKAEaQCBSZXByZXNlbnRzIGEg
dG9vbCB0aGF0IGFsbG93cyB0aGUgYWdlbnQgdG8gY2FsbCBhbm90aGVyIGFnZW50LgoKCgoD
BAABEgMbCBEKNAoEBAACABIDHQI7GicgUmVxdWlyZWQuIFRoZSBuYW1lIG9mIHRoZSBhZ2Vu
dCB0b29sLgoKDAoFBAACAAUSAx0CCAoMCgUEAAIAARIDHQkNCgwKBQQAAgADEgMdEBEKDAoF
BAACAAgSAx0SOgoPCggEAAIACJwIABIDHRM5CjsKBAQAAgESAyACQhouIE9wdGlvbmFsLiBE
ZXNjcmlwdGlvbiBvZiB0aGUgdG9vbCdzIHB1cnBvc2UuCgoMCgUEAAIBBRIDIAIICgwKBQQA
AgEBEgMgCRQKDAoFBAACAQMSAyAXGAoMCgUEAAIBCBIDIBlBCg8KCAQAAgEInAgAEgMgGkAK
pQEKBAQAAgISBCQCJwQalgEgT3B0aW9uYWwuIFRoZSByZXNvdXJjZSBuYW1lIG9mIHRoZSBy
b290IGFnZW50IHRoYXQgaXMgdGhlIGVudHJ5IHBvaW50IG9mCiB0aGUgdG9vbC4gRm9ybWF0
OiBgcHJvamVjdHMve3Byb2plY3R9L2xvY2F0aW9ucy97bG9jYXRpb259L2FnZW50cy97YWdl
bnR9YAoKDAoFBAACAgUSAyQCCAoMCgUEAAICARIDJAkTCgwKBQQAAgIDEgMkFhcKDQoFBAAC
AggSBCQYJwMKDwoIBAACAgicCAASAyUEKgoOCgcEAAICCJ8IEgMmBEpiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Ces::V1::AgentTool::AgentTool ===
    # Fields for AgentTool
    # Field: name Type: 9 ()
    # Field: description Type: 9 ()
    # Field: root_agent Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Ces::V1::AgentTool - Compiled Protocol Buffers messages for google/cloud/ces/v1/agent_tool.proto

=head1 SYNOPSIS

    use Google::Cloud::Ces::V1::AgentTool;

    my $msg = Google::Cloud::Ces::V1::AgentTool::AgentTool->new({
        name => $name,
        description => $description,
        root_agent => $root_agent,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Ces::V1::AgentTool::AgentTool->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/ces/v1/agent_tool.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Ces::V1::AgentTool::AgentTool

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

=item * C<< $msg->root_agent() >> / C<< $msg->root_agent($value) >>

Type: C<String>

Optional. The resource name of the root agent that is the entry point of
the tool. Format: `projects/{project}/locations/{location}/agents/{agent}`

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Ces::V1::AgentTool::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
