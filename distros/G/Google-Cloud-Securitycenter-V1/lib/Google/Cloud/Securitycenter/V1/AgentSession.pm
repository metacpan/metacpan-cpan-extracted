package Google::Cloud::Securitycenter::V1::AgentSession;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CjJnb29nbGUvY2xvdWQvc2VjdXJpdHljZW50ZXIvdjEvYWdlbnRfc2Vzc2lvbi5wcm90bxIe
Z29vZ2xlLmNsb3VkLnNlY3VyaXR5Y2VudGVyLnYxIi0KDEFnZW50U2Vzc2lvbhIdCgpzZXNz
aW9uX2lkGAEgASgJUglzZXNzaW9uSWRC6wEKImNvbS5nb29nbGUuY2xvdWQuc2VjdXJpdHlj
ZW50ZXIudjFCEUFnZW50U2Vzc2lvblByb3RvUAFaSmNsb3VkLmdvb2dsZS5jb20vZ28vc2Vj
dXJpdHljZW50ZXIvYXBpdjEvc2VjdXJpdHljZW50ZXJwYjtzZWN1cml0eWNlbnRlcnBiqgIe
R29vZ2xlLkNsb3VkLlNlY3VyaXR5Q2VudGVyLlYxygIeR29vZ2xlXENsb3VkXFNlY3VyaXR5
Q2VudGVyXFYx6gIhR29vZ2xlOjpDbG91ZDo6U2VjdXJpdHlDZW50ZXI6OlYxSpsHCgYSBA4A
HgEKvAQKAQwSAw4AEjKxBCBDb3B5cmlnaHQgMjAyNiBHb29nbGUgTExDCgogTGljZW5zZWQg
dW5kZXIgdGhlIEFwYWNoZSBMaWNlbnNlLCBWZXJzaW9uIDIuMCAodGhlICJMaWNlbnNlIik7
CiB5b3UgbWF5IG5vdCB1c2UgdGhpcyBmaWxlIGV4Y2VwdCBpbiBjb21wbGlhbmNlIHdpdGgg
dGhlIExpY2Vuc2UuCiBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQK
CiAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCgogVW5s
ZXNzIHJlcXVpcmVkIGJ5IGFwcGxpY2FibGUgbGF3IG9yIGFncmVlZCB0byBpbiB3cml0aW5n
LCBzb2Z0d2FyZQogZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0
ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIFdJVEhPVVQgV0FSUkFOVElFUyBPUiBDT05ESVRJ
T05TIE9GIEFOWSBLSU5ELCBlaXRoZXIgZXhwcmVzcyBvciBpbXBsaWVkLgogU2VlIHRoZSBM
aWNlbnNlIGZvciB0aGUgc3BlY2lmaWMgbGFuZ3VhZ2UgZ292ZXJuaW5nIHBlcm1pc3Npb25z
IGFuZAogbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgoICgECEgMQACcKCAoBCBID
EgA7CgkKAgglEgMSADsKCAoBCBIDEwBhCgkKAggLEgMTAGEKCAoBCBIDFAAiCgkKAggKEgMU
ACIKCAoBCBIDFQAyCgkKAggIEgMVADIKCAoBCBIDFgA7CgkKAggBEgMWADsKCAoBCBIDFwA7
CgkKAggpEgMXADsKCAoBCBIDGAA6CgkKAggtEgMYADoKTQoCBAASBBsAHgEaQSBSZXByZXNl
bnRzIGEgY29udmVyc2F0aW9uYWwgc2Vzc2lvbiB3aGVyZSB0aGUgZmluZGluZyBvY2N1cnJl
ZC4KCgoKAwQAARIDGwgUCjAKBAQAAgASAx0CGBojIFRoZSBzZXNzaW9uIElEIG9mIGEgY29u
dmVyc2F0aW9uLgoKDAoFBAACAAUSAx0CCAoMCgUEAAIAARIDHQkTCgwKBQQAAgADEgMdFhdi
BnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Cloud::Securitycenter::V1::AgentSession::AgentSession ===
    # Fields for AgentSession
    # Field: session_id Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Cloud::Securitycenter::V1::AgentSession - Compiled Protocol Buffers messages for google/cloud/securitycenter/v1/agent_session.proto

=head1 SYNOPSIS

    use Google::Cloud::Securitycenter::V1::AgentSession;

    my $msg = Google::Cloud::Securitycenter::V1::AgentSession::AgentSession->new({
        session_id => $session_id,
    });

    # Read or update a field
    my $val = $msg->session_id();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Cloud::Securitycenter::V1::AgentSession::AgentSession->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/cloud/securitycenter/v1/agent_session.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Cloud::Securitycenter::V1::AgentSession::AgentSession

Represents a conversational session where the finding occurred.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->session_id() >> / C<< $msg->session_id($value) >>

Type: C<String>

The session ID of a conversation.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Cloud::Securitycenter::V1::AgentSession::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
